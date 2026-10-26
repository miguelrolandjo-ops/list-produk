// Package job runs one extraction job at a time: claim it from the queue,
// download its pages, extract, store the result, delete the pages.
//
// The PO photos only live on the server while they are being read. They are
// deleted as soon as a job is done, and also when it has failed for good.
package job

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"time"

	"listproduk/worker/extractor"
)

// MaxAttempts is how often a job is tried before it is marked failed.
const MaxAttempts = 3

// Job is a claimed extraction job.
type Job struct {
	ID        string
	StoreID   string
	PagePaths []string // paths in the 'po-images' bucket, in page order
	Attempts  int      // including the current one
}

// Queue is the extraction_jobs table (see package queue).
type Queue interface {
	// Claim takes the oldest pending job, or returns nil when there is none.
	Claim(ctx context.Context, workerID string) (*Job, error)
	Complete(ctx context.Context, id string, result []byte) error
	// Fail records the error. With retry the job goes back to pending,
	// otherwise it is failed for good.
	Fail(ctx context.Context, id string, msg string, retry bool) error
	// Release puts a job back without counting the attempt (shutdown).
	Release(ctx context.Context, id string) error
}

// Images is the 'po-images' bucket (see package storage).
type Images interface {
	Download(ctx context.Context, path string) ([]byte, error)
	Delete(ctx context.Context, paths []string) error
}

// ErrPermanent marks failures that a retry cannot fix (a page that no longer
// exists). Such jobs fail at once instead of after MaxAttempts tries.
var ErrPermanent = errors.New("permanent")

// Runner processes jobs. One Runner handles one job at a time; run several
// workers for more throughput, the queue hands each job to only one of them.
type Runner struct {
	Queue     Queue
	Images    Images
	Extractor extractor.Extractor
	WorkerID  string
	// JobTimeout bounds downloading and extracting one job. Zero = no limit.
	JobTimeout time.Duration
	Log        *slog.Logger
}

func (r *Runner) logger() *slog.Logger {
	if r.Log != nil {
		return r.Log
	}
	return slog.Default()
}

// ProcessOne handles the next pending job. It reports whether there was one,
// so the caller knows to ask again at once rather than wait. The returned
// error is about the queue itself; a job that fails is recorded on the job.
func (r *Runner) ProcessOne(ctx context.Context) (bool, error) {
	j, err := r.Queue.Claim(ctx, r.WorkerID)
	if err != nil {
		return false, fmt.Errorf("claim: %w", err)
	}
	if j == nil {
		return false, nil
	}
	log := r.logger().With("job", j.ID, "attempt", j.Attempts, "pages", len(j.PagePaths))
	log.Info("job claimed")

	result, procErr := r.process(ctx, j)

	// Stopping (Ctrl+C, deploy) is not the job's fault: put it back as it was.
	// The context is cancelled, so the queue call gets a fresh one.
	if ctx.Err() != nil {
		bg, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		if err := r.Queue.Release(bg, j.ID); err != nil {
			return true, fmt.Errorf("release on shutdown: %w", err)
		}
		log.Info("job released on shutdown")
		return true, nil
	}

	if procErr == nil {
		if err := r.Queue.Complete(ctx, j.ID, result); err != nil {
			return true, fmt.Errorf("complete: %w", err)
		}
		r.deletePages(ctx, log, j)
		log.Info("job done")
		return true, nil
	}

	final := j.Attempts >= MaxAttempts || errors.Is(procErr, ErrPermanent)
	if err := r.Queue.Fail(ctx, j.ID, procErr.Error(), !final); err != nil {
		return true, fmt.Errorf("fail: %w", err)
	}
	if final {
		r.deletePages(ctx, log, j)
		log.Warn("job failed for good", "err", procErr)
	} else {
		log.Warn("job failed, will retry", "err", procErr)
	}
	return true, nil
}

// process downloads the pages and extracts. The result is validated JSON.
func (r *Runner) process(ctx context.Context, j *Job) ([]byte, error) {
	if r.JobTimeout > 0 {
		var cancel context.CancelFunc
		ctx, cancel = context.WithTimeout(ctx, r.JobTimeout)
		defer cancel()
	}
	if len(j.PagePaths) == 0 {
		return nil, fmt.Errorf("job has no pages: %w", ErrPermanent)
	}
	pages := make([][]byte, 0, len(j.PagePaths))
	for _, p := range j.PagePaths {
		b, err := r.Images.Download(ctx, p)
		if err != nil {
			return nil, fmt.Errorf("download %s: %w", p, err)
		}
		pages = append(pages, b)
	}
	res, err := r.Extractor.Extract(ctx, pages)
	if err != nil {
		return nil, fmt.Errorf("extract: %w", err)
	}
	// Model output is untrusted; the phone should never get a broken result.
	if err := res.Validate(); err != nil {
		return nil, fmt.Errorf("invalid result: %w", err)
	}
	b, err := json.Marshal(res)
	if err != nil {
		return nil, fmt.Errorf("encode result: %w", err)
	}
	return b, nil
}

// DeletePages removes a job's photos. Exported for the stale-job sweep.
func DeletePages(ctx context.Context, images Images, log *slog.Logger, paths []string) {
	if err := images.Delete(ctx, paths); err != nil {
		log.Error("could not delete pages", "paths", paths, "err", err)
	}
}

// deletePages: a failure is only logged. The result is already stored, and
// the owner's phone keeps its own copy of the photos.
func (r *Runner) deletePages(ctx context.Context, log *slog.Logger, j *Job) {
	DeletePages(ctx, r.Images, log, j.PagePaths)
}
