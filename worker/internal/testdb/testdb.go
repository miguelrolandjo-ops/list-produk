// Package testdb gives tests a Postgres database with the app's server schema.
//
// Set TEST_DATABASE_URL to run them; without it the database tests are
// skipped. Two ways:
//
//   - Local Supabase (`supabase start` in the repo root, migrations applied):
//     TEST_DATABASE_URL=postgres://postgres:postgres@127.0.0.1:54322/postgres
//   - Any plain Postgres 15+: the schema is applied on first use, with small
//     stand-ins for Supabase's auth and storage schemas.
//
// Tests empty the tables they use. Never point this at the real project.
package testdb

import (
	"context"
	"os"
	"path/filepath"
	"runtime"
	"testing"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Stand-ins for what Supabase provides, only as much as 0001_init.sql needs.
const supabaseStubs = `
create schema if not exists auth;
create table if not exists auth.users (id uuid primary key);
create or replace function auth.uid() returns uuid language sql stable as
  $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
create schema if not exists storage;
create table if not exists storage.objects (
  id uuid primary key default gen_random_uuid(), bucket_id text, name text);
create or replace function storage.foldername(name text) returns text[]
  language sql immutable as
  $$ select (string_to_array(name, '/'))[1:array_length(string_to_array(name, '/'), 1) - 1] $$;
`

// Open connects, applies the schema if it is missing, and empties the tables.
func Open(t *testing.T) *pgxpool.Pool {
	t.Helper()
	url := os.Getenv("TEST_DATABASE_URL")
	if url == "" {
		t.Skip("TEST_DATABASE_URL not set; skipping database test")
	}
	ctx := context.Background()
	cfg, err := pgxpool.ParseConfig(url)
	if err != nil {
		t.Fatal(err)
	}
	// Same mode as the worker uses in production.
	cfg.ConnConfig.DefaultQueryExecMode = pgx.QueryExecModeSimpleProtocol
	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)

	var exists bool
	if err := pool.QueryRow(ctx,
		`select to_regclass('public.extraction_jobs') is not null`).Scan(&exists); err != nil {
		t.Fatal(err)
	}
	if !exists {
		if _, err := pool.Exec(ctx, supabaseStubs); err != nil {
			t.Fatalf("stubs: %v", err)
		}
		sql, err := os.ReadFile(migrationPath())
		if err != nil {
			t.Fatal(err)
		}
		if _, err := pool.Exec(ctx, string(sql)); err != nil {
			t.Fatalf("migration: %v", err)
		}
	}
	if _, err := pool.Exec(ctx,
		`truncate extraction_jobs, invites, catalog_items, store_members, stores cascade`); err != nil {
		t.Fatal(err)
	}
	return pool
}

// NewStore inserts a store and returns its id.
func NewStore(t *testing.T, pool *pgxpool.Pool) string {
	t.Helper()
	var id string
	if err := pool.QueryRow(context.Background(),
		`insert into stores (name) values ('Toko Uji') returning id::text`).Scan(&id); err != nil {
		t.Fatal(err)
	}
	return id
}

func migrationPath() string {
	_, file, _, _ := runtime.Caller(0)
	// worker/internal/testdb -> repo root
	root := filepath.Join(filepath.Dir(file), "..", "..", "..")
	return filepath.Join(root, "supabase", "migrations", "0001_init.sql")
}
