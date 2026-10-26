package queue_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"sync"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"listproduk/worker/extractor"
	"listproduk/worker/internal/testdb"
	"listproduk/worker/job"
	"listproduk/worker/queue"
)

// submit queues a job the way the phone does (submit_extraction inserts it).
func submit(t *testing.T, pool *pgxpool.Pool, store string, paths ...string) string {
	t.Helper()
	var id string
	err := pool.QueryRow(context.Background(), `
		insert into extraction_jobs (store_id, page_paths)
		values ($1::uuid, $2::text[]) returning id::text`, store, paths).Scan(&id)
	if err != nil {
		t.Fatal(err)
	}
	return id
}

type row struct {
	status, lastError, result string
	attempts                  int
	finished, locked          bool
}

func get(t *testing.T, pool *pgxpool.Pool, id string) row {
	t.Helper()
	var r row
	err := pool.QueryRow(context.Background(), `
		select status::text, coalesce(last_error, ''), coalesce(result::text, ''),
		       attempts, finished_at is not null, locked_by is not null
		  from extraction_jobs where id = $1::uuid`, id).
		Scan(&r.status, &r.lastError, &r.result, &r.attempts, &r.finished, &r.locked)
	if err != nil {
		t.Fatal(err)
	}
	return r
}

// memImages is the bucket in memory.
type memImages struct {
	mu      sync.Mutex
	objects map[string][]byte
	deleted []string
}

func newImages(paths ...string) *memImages {
	m := &memImages{objects: map[string][]byte{}}
	for _, p := range paths {
		m.objects[p] = []byte("jpeg " + p)
	}
	return m
}

func (m *memImages) Download(_ context.Context, p string) ([]byte, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	b, ok := m.objects[p]
	if !ok {
		return nil, fmt.Errorf("%s: %w", p, job.ErrPermanent)
	}
	return b, nil
}

func (m *memImages) Delete(_ context.Context, paths []string) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	for _, p := range paths {
		delete(m.objects, p)
		m.deleted = append(m.deleted, p)
	}
	return nil
}

type failingExtractor struct{ err error }

func (f failingExtractor) Extract(context.Context, [][]byte) (extractor.Result, error) {
	return extractor.Result{}, f.err
}

func runner(pool *pgxpool.Pool, images job.Images, ext extractor.Extractor) *job.Runner {
	return &job.Runner{
		Queue:     queue.New(pool),
		Images:    images,
		Extractor: ext,
		WorkerID:  "test-worker",
	}
}

func TestClaimTakesOldestPendingAndCountsTheAttempt(t *testing.T) {
	pool := testdb.Open(t)
	store := testdb.NewStore(t, pool)
	first := submit(t, pool, store, store+"/po1/1.jpg", store+"/po1/2.jpg")
	submit(t, pool, store, store+"/po2/1.jpg")
	q := queue.New(pool)
	ctx := context.Background()

	j, err := q.Claim(ctx, "w1")
	if err != nil {
		t.Fatal(err)
	}
	if j.ID != first || j.StoreID != store || j.Attempts != 1 {
		t.Fatalf("claimed %+v, want first job with attempt 1", j)
	}
	if len(j.PagePaths) != 2 || j.PagePaths[1] != store+"/po1/2.jpg" {
		t.Fatalf("pages out of order: %v", j.PagePaths)
	}
	if r := get(t, pool, first); r.status != "running" || !r.locked {
		t.Fatalf("after claim: %+v", r)
	}
}

func TestClaimReturnsNilWhenNothingIsPending(t *testing.T) {
	pool := testdb.Open(t)
	j, err := queue.New(pool).Claim(context.Background(), "w1")
	if err != nil || j != nil {
		t.Fatalf("got %v, %v; want nil, nil", j, err)
	}
}

func TestConcurrentWorkersNeverGetTheSameJob(t *testing.T) {
	pool := testdb.Open(t)
	store := testdb.NewStore(t, pool)
	const jobs = 20
	for i := 0; i < jobs; i++ {
		submit(t, pool, store, fmt.Sprintf("%s/po%d/1.jpg", store, i))
	}
	q := queue.New(pool)

	var mu sync.Mutex
	seen := map[string]string{}
	var wg sync.WaitGroup
	for w := 0; w < 5; w++ {
		wg.Add(1)
		go func(worker string) {
			defer wg.Done()
			for {
				j, err := q.Claim(context.Background(), worker)
				if err != nil {
					t.Error(err)
					return
				}
				if j == nil {
					return
				}
				mu.Lock()
				if other, dup := seen[j.ID]; dup {
					t.Errorf("job %s claimed by %s and %s", j.ID, other, worker)
				}
				seen[j.ID] = worker
				mu.Unlock()
			}
		}(fmt.Sprintf("w%d", w))
	}
	wg.Wait()
	if len(seen) != jobs {
		t.Fatalf("claimed %d jobs, want %d", len(seen), jobs)
	}
}

func TestRunnerDoneStoresResultAndDeletesPages(t *testing.T) {
	pool := testdb.Open(t)
	store := testdb.NewStore(t, pool)
	paths := []string{store + "/po1/1.jpg", store + "/po1/2.jpg"}
	id := submit(t, pool, store, paths...)
	images := newImages(paths...)

	worked, err := runner(pool, images, extractor.NewFake()).ProcessOne(context.Background())
	if err != nil || !worked {
		t.Fatalf("worked=%v err=%v", worked, err)
	}
	r := get(t, pool, id)
	if r.status != "done" || !r.finished || r.locked {
		t.Fatalf("after done: %+v", r)
	}
	var res extractor.Result
	if err := json.Unmarshal([]byte(r.result), &res); err != nil {
		t.Fatal(err)
	}
	if *res.Supplier.Name != "CV Maju Elektrik" || len(res.Lines) == 0 {
		t.Fatalf("unexpected result: %+v", res)
	}
	if len(images.objects) != 0 {
		t.Fatalf("pages left in the bucket: %v", images.objects)
	}
}

func TestRunnerRetriesThenFailsAfterThreeAttempts(t *testing.T) {
	pool := testdb.Open(t)
	store := testdb.NewStore(t, pool)
	path := store + "/po1/1.jpg"
	id := submit(t, pool, store, path)
	images := newImages(path)
	r := runner(pool, images, failingExtractor{errors.New("model busy")})
	ctx := context.Background()

	for attempt := 1; attempt <= 2; attempt++ {
		if _, err := r.ProcessOne(ctx); err != nil {
			t.Fatal(err)
		}
		got := get(t, pool, id)
		if got.status != "pending" || got.attempts != attempt || got.lastError == "" {
			t.Fatalf("after attempt %d: %+v", attempt, got)
		}
		if len(images.deleted) != 0 {
			t.Fatal("pages deleted before the last attempt")
		}
	}
	if _, err := r.ProcessOne(ctx); err != nil {
		t.Fatal(err)
	}
	got := get(t, pool, id)
	if got.status != "failed" || got.attempts != 3 || !got.finished {
		t.Fatalf("after attempt 3: %+v", got)
	}
	if len(images.deleted) != 1 {
		t.Fatalf("pages should be deleted when failed for good: %v", images.deleted)
	}
}

func TestRunnerFailsAtOnceWhenAPageIsMissing(t *testing.T) {
	pool := testdb.Open(t)
	store := testdb.NewStore(t, pool)
	id := submit(t, pool, store, store+"/po1/1.jpg", store+"/po1/2.jpg")
	images := newImages(store + "/po1/1.jpg") // page 2 never uploaded

	if _, err := runner(pool, images, extractor.NewFake()).ProcessOne(context.Background()); err != nil {
		t.Fatal(err)
	}
	if got := get(t, pool, id); got.status != "failed" || got.attempts != 1 {
		t.Fatalf("missing page: %+v", got)
	}
}

// invalidExtractor returns output that breaks the contract.
type invalidExtractor struct{}

func (invalidExtractor) Extract(context.Context, [][]byte) (extractor.Result, error) {
	bad := int64(-5)
	return extractor.Result{Lines: []extractor.Line{{Name: "X", UnitPrice: &bad}}}, nil
}

func TestRunnerNeverStoresAnInvalidResult(t *testing.T) {
	pool := testdb.Open(t)
	store := testdb.NewStore(t, pool)
	path := store + "/po1/1.jpg"
	id := submit(t, pool, store, path)

	if _, err := runner(pool, newImages(path), invalidExtractor{}).ProcessOne(context.Background()); err != nil {
		t.Fatal(err)
	}
	got := get(t, pool, id)
	if got.status != "pending" || got.result != "" {
		t.Fatalf("invalid result must not be stored: %+v", got)
	}
}

// blockingExtractor waits until the context is cancelled (a shutdown).
type blockingExtractor struct{ started chan struct{} }

func (b blockingExtractor) Extract(ctx context.Context, _ [][]byte) (extractor.Result, error) {
	close(b.started)
	<-ctx.Done()
	return extractor.Result{}, ctx.Err()
}

func TestShutdownPutsTheJobBackWithoutUsingAnAttempt(t *testing.T) {
	pool := testdb.Open(t)
	store := testdb.NewStore(t, pool)
	path := store + "/po1/1.jpg"
	id := submit(t, pool, store, path)
	images := newImages(path)
	ext := blockingExtractor{started: make(chan struct{})}

	ctx, cancel := context.WithCancel(context.Background())
	done := make(chan error)
	go func() {
		_, err := runner(pool, images, ext).ProcessOne(ctx)
		done <- err
	}()
	<-ext.started
	cancel()
	if err := <-done; err != nil {
		t.Fatal(err)
	}
	got := get(t, pool, id)
	if got.status != "pending" || got.attempts != 0 || got.locked {
		t.Fatalf("after shutdown: %+v", got)
	}
	if len(images.deleted) != 0 {
		t.Fatal("pages must stay for the next try")
	}
}

func TestRecoverStale(t *testing.T) {
	pool := testdb.Open(t)
	store := testdb.NewStore(t, pool)
	ctx := context.Background()
	retry := submit(t, pool, store, store+"/a/1.jpg")
	outOfTries := submit(t, pool, store, store+"/b/1.jpg")
	fresh := submit(t, pool, store, store+"/c/1.jpg")
	_, err := pool.Exec(ctx, `
		update extraction_jobs set status = 'running', locked_by = 'dead',
		       locked_at = now() - interval '1 hour',
		       attempts = case when id = $2::uuid then 3 else 1 end
		 where id in ($1::uuid, $2::uuid);
		`, retry, outOfTries)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Exec(ctx, `update extraction_jobs set status = 'running',
		locked_at = now() where id = $1::uuid`, fresh); err != nil {
		t.Fatal(err)
	}

	stale, err := queue.New(pool).RecoverStale(ctx, 15*time.Minute)
	if err != nil {
		t.Fatal(err)
	}
	if len(stale) != 2 {
		t.Fatalf("recovered %d jobs, want 2: %+v", len(stale), stale)
	}
	if got := get(t, pool, retry); got.status != "pending" {
		t.Fatalf("retry job: %+v", got)
	}
	if got := get(t, pool, outOfTries); got.status != "failed" || !got.finished {
		t.Fatalf("job out of tries: %+v", got)
	}
	if got := get(t, pool, fresh); got.status != "running" {
		t.Fatalf("a job still being worked on was taken: %+v", got)
	}
	for _, s := range stale {
		if s.ID == outOfTries && !s.Failed {
			t.Fatal("out-of-tries job should be reported failed (pages to delete)")
		}
	}
}

func TestCleanup(t *testing.T) {
	pool := testdb.Open(t)
	store := testdb.NewStore(t, pool)
	ctx := context.Background()
	fetched := submit(t, pool, store, "x")
	old := submit(t, pool, store, "y")
	recent := submit(t, pool, store, "z")
	pending := submit(t, pool, store, "w")
	_, err := pool.Exec(ctx, `
		update extraction_jobs set status = 'done', finished_at = now(), fetched_at = now()
		 where id = $1::uuid;`, fetched)
	if err != nil {
		t.Fatal(err)
	}
	_, err = pool.Exec(ctx, `
		update extraction_jobs set status = 'done', finished_at = now() - interval '15 days'
		 where id = $1::uuid;`, old)
	if err != nil {
		t.Fatal(err)
	}
	_, err = pool.Exec(ctx, `
		update extraction_jobs set status = 'done', finished_at = now() - interval '2 days'
		 where id = $1::uuid;`, recent)
	if err != nil {
		t.Fatal(err)
	}

	n, err := queue.New(pool).Cleanup(ctx, 14*24*time.Hour)
	if err != nil {
		t.Fatal(err)
	}
	if n != 2 {
		t.Fatalf("deleted %d, want 2", n)
	}
	left := map[string]bool{}
	rows, err := pool.Query(ctx, `select id::text from extraction_jobs`)
	if err != nil {
		t.Fatal(err)
	}
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			t.Fatal(err)
		}
		left[id] = true
	}
	if len(left) != 2 || !left[recent] || !left[pending] {
		t.Fatalf("left %v, want only the recent and the pending job", left)
	}
}

// The whole round trip through the functions the phone calls, as the owner:
// submit_extraction, the worker, reading the result, mark_extraction_fetched,
// and the cleanup that then removes the job.
func TestPhoneAndWorkerContract(t *testing.T) {
	pool := testdb.Open(t)
	ctx := context.Background()
	conn, err := pool.Acquire(ctx)
	if err != nil {
		t.Fatal(err)
	}
	defer conn.Release()

	// Sign in as the owner: auth.uid() reads this setting.
	owner := "11111111-1111-4111-8111-111111111111"
	if _, err := conn.Exec(ctx, `insert into auth.users (id) values ($1::uuid)
		on conflict do nothing`, owner); err != nil {
		t.Skip("not a plain Postgres with stub auth.users; skipping:", err)
	}
	if _, err := conn.Exec(ctx, `select set_config('request.jwt.claim.sub', $1, false)`, owner); err != nil {
		t.Fatal(err)
	}
	defer conn.Exec(ctx, `select set_config('request.jwt.claim.sub', '', false)`)

	var store, jobID string
	if err := conn.QueryRow(ctx, `select create_store('Toko Uji')::text`).Scan(&store); err != nil {
		t.Fatal(err)
	}
	paths := []string{store + "/po1/1.jpg"}
	if err := conn.QueryRow(ctx, `select submit_extraction($1::uuid, $2::text[])::text`,
		store, paths).Scan(&jobID); err != nil {
		t.Fatal(err)
	}

	// A job without pages is refused by the server.
	if _, err := conn.Exec(ctx, `select submit_extraction($1::uuid, '{}'::text[])`, store); err == nil {
		t.Fatal("submit_extraction accepted a job without pages")
	}

	if _, err := runner(pool, newImages(paths...), extractor.NewFake()).ProcessOne(ctx); err != nil {
		t.Fatal(err)
	}

	var status, result string
	if err := conn.QueryRow(ctx, `select status::text, result::text from extraction_jobs
		where id = $1::uuid`, jobID).Scan(&status, &result); err != nil {
		t.Fatal(err)
	}
	if status != "done" || result == "" {
		t.Fatalf("phone sees %s / %q", status, result)
	}

	if _, err := conn.Exec(ctx, `select mark_extraction_fetched($1::uuid)`, jobID); err != nil {
		t.Fatal(err)
	}
	var cleared bool
	if err := conn.QueryRow(ctx, `select result is null and fetched_at is not null
		from extraction_jobs where id = $1::uuid`, jobID).Scan(&cleared); err != nil {
		t.Fatal(err)
	}
	if !cleared {
		t.Fatal("mark_extraction_fetched should clear the result")
	}

	if n, err := queue.New(pool).Cleanup(ctx, 14*24*time.Hour); err != nil || n != 1 {
		t.Fatalf("cleanup deleted %d (%v), want the fetched job", n, err)
	}
}
