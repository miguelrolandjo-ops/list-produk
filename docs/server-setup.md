# Server setup (Supabase Cloud)

Project: `https://gculrkdumuuejsiqsniq.supabase.co`

The URL the app needs is the project URL **without** `/rest/v1/`.

## 1. Database

Supabase dashboard > **SQL Editor** > New query. Paste all of
`supabase/migrations/0001_init.sql` and run it once.

(Or with the Supabase CLI: `supabase link --project-ref gculrkdumuuejsiqsniq`
then `supabase db push`.)

## 2. Authentication

Dashboard > **Authentication** > **Sign In / Providers**:

- **Allow anonymous sign-ins: ON.** Employees join with an invite code and no
  email; without this, "Gabung" fails with "Server belum mengizinkan karyawan
  bergabung".
- **Email: ON** (the owner's account).
- **Confirm email:** either leave it on (the owner taps the link in the email
  once, then signs in in the app) or turn it off for a simpler start. The link
  opens the project's Site URL, which may show an error page; the account is
  confirmed anyway.

## 3. Storage (needed later)

Dashboard > **Storage** > New bucket, both **private**:
`po-images` (PO photos, Milestone 4) and `product-photos` (product photos, not
in the app yet). The access policies are already in the migration.

## 4. App configuration

Dashboard > **Project Settings** > **API Keys**: copy the **anon** (or
"publishable") key. Never the service role / secret key: anyone can read keys
out of an APK, and that one bypasses all security. It belongs to the Go worker
only.

```
cd app
cp config.example.json config.json   # then paste the anon key into it
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run --dart-define-from-file=config.json
```

`config.json` is in `.gitignore`. Without it the app still runs, fully
offline; the account and team screens then say the server isn't set up.

## 5. Check (Milestone 3 "done when")

1. Owner phone: Pengaturan > Akun dan toko > Daftar baru > Buat toko. The
   Katalog karyawan row shows "Terbaru" after a few seconds.
2. Tim > Undang karyawan > send the code by WhatsApp.
3. Second phone: fresh install > Gabung sebagai karyawan > code + name.
   The catalog appears grouped by category.
4. Second phone in airplane mode: search still works ("kab" finds "Kabel").
5. Owner changes a price; second phone pulls down to refresh: new price.
6. Owner: Tim > Cabut. Second phone refreshes: "Akses ke toko berakhir",
   catalog deleted, back to the welcome screen.

---

# Milestone 4: PO reading

## 6. Storage bucket (now required)

Dashboard > **Storage** > New bucket: **`po-images`**, **private** (public
off). The access policies are already in the migration: only the store's owner
can upload, the worker reads and deletes with the service key.

## 7. The worker on the Ubuntu server

The worker only makes outgoing connections (database and storage), so it needs
no open port, no domain and no HTTPS.

```bash
sudo apt install -y golang-go   # any Go 1.21+; it downloads Go 1.27 by itself (go.mod)
cd worker
go mod tidy                     # first time: fetches pgx and writes go.sum
go vet ./... && go test ./...   # database tests skip without TEST_DATABASE_URL
go build -o worker .
```

Then follow the steps at the top of `deploy/harga-toko-worker.service`, with
`.env.example` filled in as `/etc/harga-toko/worker.env`.

Watch it: `journalctl -u harga-toko-worker -f`. "job claimed" and "job done"
lines appear for every PO.

### Database tests

They need a Postgres you can wipe. Either a local Supabase (`supabase start`
in the repo root):

```bash
TEST_DATABASE_URL=postgres://postgres:postgres@127.0.0.1:54322/postgres go test ./...
```

or any Postgres 15+ (`sudo apt install postgresql`, create an empty database);
the schema is applied on first use. **Never point it at the real project**: the
tests empty the tables.

## 8. Check (Milestone 4 "done when")

1. Worker running (`journalctl` shows "worker started").
2. Owner phone: WhatsApp > long-press a nota photo > Bagikan > Harga Toko.
   The app opens on Inbox: "Foto baru" goes Antre > Mengunggah > Diproses >
   Perlu dicek within seconds (the fake extractor answers at once with the
   sample nota from CV Maju Elektrik).
3. Tap it, review, Simpan: products saved, and Katalog karyawan goes back to
   "Terbaru" after a few seconds.
4. Employee phone, pull to refresh: the new products appear.
5. Supabase > Storage > po-images is empty again (photos are deleted after
   reading), and the job row disappears from extraction_jobs on the worker's
   next daily cleanup.
