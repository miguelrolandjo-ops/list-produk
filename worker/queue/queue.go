// Package queue is the extraction_jobs table as a work queue.
//
// Jobs are claimed with FOR UPDATE SKIP LOCKED inside a single UPDATE, so
// several workers can run at once and each job goes to exactly one of them.
// The worker connects as the database owner (service role), which bypasses
// row level security; the phone only ever reads its own jobs.
package queue

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"

	"listproduk/worker/job"
)

// DB is what the queue needs from a connection or pool (*pgxpool.Pool fits).
type DB interface {
	Exec(ctx context.Context, sql string, args ...any) (pgconn.CommandTag, error)
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
	Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error)
}

type Queue struct {
	db DB
}

func New(db DB) *Queue { return &Queue{db: db} }

var _ job.Queue = (*Queue)(nil)

// Claim takes the oldest pending job and counts the attempt. Counting at
// claim time means a worker that crashes mid-job still uses up a try.
func (q *Queue) Claim(ctx context.Context, workerID string) (*job.Job, error) {
	var j job.Job
	err := q.db.QueryRow(ctx, `
		UPDATE extraction_jobs j
		   SET status = 'running', locked_by = $1, locked_at = now(),
		       attempts = j.attempts + 1
		 WHERE j.id = (SELECT id FROM extraction_jobs
		                WHERE status = 'pending'
		                ORDER BY created_at, id
		                LIMIT 1
		                FOR UPDATE SKIP LOCKED)
		RETURNING j.id::text, j.store_id::text, j.page_paths, j.attempts`,
		workerID,
	).Scan(&j.ID, &j.StoreID, &j.PagePaths, &j.Attempts)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &j, nil
}

// Complete stores the result for the owner's phone to fetch.
func (q *Queue) Complete(ctx context.Context, id string, result []byte) error {
	// The result goes as text and is cast in SQL, so it works over both the
	// extended and the simple protocol (Supabase's transaction pooler).
	_, err := q.db.Exec(ctx, `
		UPDATE extraction_jobs
		   SET status = 'done', result = $2::jsonb, finished_at = now(),
		       last_error = NULL, locked_by = NULL, locked_at = NULL
		 WHERE id = $1::uuid AND status = 'running'`,
		id, string(result),
	)
	return err
}

// Fail records msg. With retry the job goes back to pending; otherwise it is
// failed for good and the phone shows it as "Gagal".
func (q *Queue) Fail(ctx context.Context, id string, msg string, retry bool) error {
	_, err := q.db.Exec(ctx, `
		UPDATE extraction_jobs
		   SET status = (CASE WHEN $3::boolean THEN 'pending' ELSE 'failed' END)::job_status,
		       last_error = $2,
		       finished_at = CASE WHEN $3::boolean THEN NULL ELSE now() END,
		       locked_by = NULL, locked_at = NULL
		 WHERE id = $1::uuid AND status = 'running'`,
		id, truncate(msg, 1000), retry,
	)
	return err
}

// Release puts a running job back to pending without counting the attempt.
func (q *Queue) Release(ctx context.Context, id string) error {
	_, err := q.db.Exec(ctx, `
		UPDATE extraction_jobs
		   SET status = 'pending', attempts = greatest(attempts - 1, 0),
		       locked_by = NULL, locked_at = NULL
		 WHERE id = $1::uuid AND status = 'running'`,
		id,
	)
	return err
}

// Stale is a job taken back from a worker that stopped without finishing.
type Stale struct {
	ID        string
	PagePaths []string
	Failed    bool // out of attempts: its pages should be deleted
}

// RecoverStale handles jobs left 'running' for longer than olderThan (the
// worker died or lost its connection): back to pending, or failed when out
// of attempts.
func (q *Queue) RecoverStale(ctx context.Context, olderThan time.Duration) ([]Stale, error) {
	rows, err := q.db.Query(ctx, `
		UPDATE extraction_jobs
		   SET status = (CASE WHEN attempts >= $2::int THEN 'failed' ELSE 'pending' END)::job_status,
		       last_error = 'worker stopped while reading this job',
		       finished_at = CASE WHEN attempts >= $2::int THEN now() END,
		       locked_by = NULL, locked_at = NULL
		 WHERE status = 'running'
		   AND locked_at < now() - make_interval(secs => $1::float8)
		RETURNING id::text, page_paths, status = 'failed'`,
		olderThan.Seconds(), job.MaxAttempts,
	)
	if err != nil {
		return nil, err
	}
	return pgx.CollectRows(rows, func(r pgx.CollectableRow) (Stale, error) {
		var s Stale
		err := r.Scan(&s.ID, &s.PagePaths, &s.Failed)
		return s, err
	})
}

// Cleanup deletes jobs whose result the phone has fetched, and any job that
// finished more than keepFor ago. Their pages are already gone. Returns the
// number of deleted jobs.
func (q *Queue) Cleanup(ctx context.Context, keepFor time.Duration) (int64, error) {
	tag, err := q.db.Exec(ctx, `
		DELETE FROM extraction_jobs
		 WHERE fetched_at IS NOT NULL
		    OR finished_at < now() - make_interval(secs => $1::float8)`,
		keepFor.Seconds(),
	)
	if err != nil {
		return 0, err
	}
	return tag.RowsAffected(), nil
}

// truncate cuts s to at most n bytes without splitting a character
// (Postgres rejects invalid UTF-8).
func truncate(s string, n int) string {
	if len(s) <= n {
		return s
	}
	return strings.ToValidUTF8(s[:n], "")
}
