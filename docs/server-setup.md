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
