// Command worker reads PO photos into the extraction JSON (build guide
// section 9). It polls the extraction_jobs table, so it needs no inbound port:
// run it on a laptop, a small VPS, or the Ubuntu server.
//
// Configuration (environment variables, e.g. from an env file; never commit it):
//
//	DATABASE_URL          Postgres connection string of the Supabase project
//	                      (Project Settings > Database > Session pooler).
//	SUPABASE_URL          https://<project>.supabase.co
//	SUPABASE_SERVICE_KEY  service_role / secret key. Worker only, never the app.
//	EXTRACTOR             fake (default), later ollama or cloud
//	POLL_INTERVAL         how often to look for work when idle (default 3s)
//	JOB_TIMEOUT           limit for one job (default 3m)
//	WORKER_ID             name in locked_by (default hostname-pid)
package main

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"listproduk/worker/extractor"
	"listproduk/worker/job"
	"listproduk/worker/queue"
	"listproduk/worker/storage"
)

const (
	// A job still 'running' after this long belongs to a worker that died.
	staleAfter = 15 * time.Minute
	// Results the phone never fetched are deleted after this long.
	keepResults = 14 * 24 * time.Hour
)

type config struct {
	databaseURL  string
	supabaseURL  string
	serviceKey   string
	extractor    string
	pollInterval time.Duration
	jobTimeout   time.Duration
	workerID     string
}

func loadConfig() (config, error) {
	c := config{
		databaseURL: os.Getenv("DATABASE_URL"),
		supabaseURL: os.Getenv("SUPABASE_URL"),
		serviceKey:  os.Getenv("SUPABASE_SERVICE_KEY"),
		extractor:   os.Getenv("EXTRACTOR"),
		workerID:    os.Getenv("WORKER_ID"),
	}
	var missing []string
	for _, kv := range [][2]string{
		{"DATABASE_URL", c.databaseURL},
		{"SUPABASE_URL", c.supabaseURL},
		{"SUPABASE_SERVICE_KEY", c.serviceKey},
	} {
		if kv[1] == "" {
			missing = append(missing, kv[0])
		}
	}
	if len(missing) > 0 {
		return c, fmt.Errorf("missing environment variables: %v", missing)
	}
	var err error
	if c.pollInterval, err = durationEnv("POLL_INTERVAL", 3*time.Second); err != nil {
		return c, err
	}
	if c.jobTimeout, err = durationEnv("JOB_TIMEOUT", 3*time.Minute); err != nil {
		return c, err
	}
	if c.extractor == "" {
		c.extractor = "fake"
	}
	if c.workerID == "" {
		host, _ := os.Hostname()
		c.workerID = fmt.Sprintf("%s-%d", host, os.Getpid())
	}
	return c, nil
}

func durationEnv(name string, def time.Duration) (time.Duration, error) {
	v := os.Getenv(name)
	if v == "" {
		return def, nil
	}
	d, err := time.ParseDuration(v)
	if err != nil {
		return 0, fmt.Errorf("%s: %w", name, err)
	}
	return d, nil
}

func main() {
	log := slog.New(slog.NewTextHandler(os.Stderr, nil))
	if err := run(log); err != nil {
		log.Error("worker stopped", "err", err)
		os.Exit(1)
	}
}

func run(log *slog.Logger) error {
	cfg, err := loadConfig()
	if err != nil {
		return err
	}
	ext, err := extractor.New(cfg.extractor)
	if err != nil {
		return err
	}

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	poolCfg, err := pgxpool.ParseConfig(cfg.databaseURL)
	if err != nil {
		return fmt.Errorf("DATABASE_URL: %w", err)
	}
	// Simple protocol works through every Supabase pooler mode, including the
	// transaction pooler, which does not keep prepared statements.
	poolCfg.ConnConfig.DefaultQueryExecMode = pgx.QueryExecModeSimpleProtocol
	poolCfg.MaxConns = 2
	pool, err := pgxpool.NewWithConfig(ctx, poolCfg)
	if err != nil {
		return err
	}
	defer pool.Close()
	if err := pool.Ping(ctx); err != nil {
		return fmt.Errorf("database: %w", err)
	}

	q := queue.New(pool)
	images := storage.New(cfg.supabaseURL, cfg.serviceKey, "po-images")
	runner := &job.Runner{
		Queue:      q,
		Images:     images,
		Extractor:  ext,
		WorkerID:   cfg.workerID,
		JobTimeout: cfg.jobTimeout,
		Log:        log,
	}
	log.Info("worker started", "id", cfg.workerID, "extractor", cfg.extractor, "poll", cfg.pollInterval)

	maintain := func() {
		stale, err := q.RecoverStale(ctx, staleAfter)
		if err != nil {
			log.Error("recover stale jobs", "err", err)
		}
		for _, s := range stale {
			log.Warn("took back stale job", "job", s.ID, "failed", s.Failed)
			if s.Failed {
				job.DeletePages(ctx, images, log, s.PagePaths)
			}
		}
	}
	cleanup := func() {
		n, err := q.Cleanup(ctx, keepResults)
		if err != nil {
			log.Error("cleanup", "err", err)
		} else if n > 0 {
			log.Info("cleanup", "deleted_jobs", n)
		}
	}
	maintain()
	cleanup()
	lastMaintain, lastCleanup := time.Now(), time.Now()

	backoff := cfg.pollInterval
	for {
		if time.Since(lastMaintain) > time.Minute {
			maintain()
			lastMaintain = time.Now()
		}
		if time.Since(lastCleanup) > 24*time.Hour {
			cleanup()
			lastCleanup = time.Now()
		}
		worked, err := runner.ProcessOne(ctx)
		if ctx.Err() != nil {
			log.Info("worker stopping")
			return nil
		}
		switch {
		case err != nil:
			// Database trouble: wait longer each time, up to a minute.
			backoff = min(backoff*2, time.Minute)
			log.Error("queue", "err", err, "retry_in", backoff)
			if !sleep(ctx, backoff) {
				log.Info("worker stopping")
				return nil
			}
		case worked:
			backoff = cfg.pollInterval // more work may be waiting: no pause
		default:
			backoff = cfg.pollInterval
			if !sleep(ctx, cfg.pollInterval) {
				log.Info("worker stopping")
				return nil
			}
		}
	}
}

// sleep waits d, or returns false at once when ctx is cancelled.
func sleep(ctx context.Context, d time.Duration) bool {
	t := time.NewTimer(d)
	defer t.Stop()
	select {
	case <-ctx.Done():
		return false
	case <-t.C:
		return true
	}
}
