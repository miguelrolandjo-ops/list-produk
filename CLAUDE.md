# Store Price Guide App

Local-first Flutter app for a small Indonesian store. The owner turns supplier purchase
order (PO) photos into a price catalog; employees look up retail prices.

## Source-of-truth documents

- `docs/spec.md`: product spec v2 (Stories 1–5)
- `docs/build-guide.md`: architecture, milestones, contracts, code snippets
- `docs/mockups/`: approved screen mockups
- `app/lib/data/owner.drift`, `app/lib/data/employee.drift`: local schemas
- `supabase/migrations/0001_init.sql`: server schema
- `shared/pricing_vectors.json`: required pricing test cases

If code and these documents disagree, stop and ask me before changing either.

## Architecture rules (do not break these)

- The owner's phone is the source of truth. Pricing, matching, review, and
  recalculation run in Dart on the device.
- The server only handles: the employee catalog, access/invites, and the PO
  extraction queue.
- Supplier names, supplier aliases, supply prices, margins, and PO images must never
  be sent to `publish_catalog`. Publish only the fields in the `products_to_publish` view.
- Never put the Supabase service role key anywhere under `app/`. The app uses the anon
  key only. The Go worker reads the service role credential from an environment variable.
- Money is whole Rupiah as `int` (Dart), `INTEGER` (SQLite), `bigint` (Postgres).
  Never use `double` for prices. Percentages may be `double`.
- Retail pricing lives in `app/lib/pricing/` and must pass every case in
  `shared/pricing_vectors.json`. Don't change the rule without asking me.
- Products with `retail_is_override = 1` are never recalculated automatically.
  Bulk-adjust results are saved as overrides.
- After publishing, set `published_at` to the `updated_at` value that was sent,
  never to the current time.
- Local schema changes go through drift migrations (bump `schemaVersion`). Real data
  will be on the owner's phone, so a change must never require reinstalling the app.

## Conventions

- UI text: Bahasa Indonesia, sentence case. Code, comments, and commit messages: English.
- Rupiah format: `Rp 15.000` via `intl` with the `id_ID` locale.
- State management: Riverpod. Routing: go_router. Folder layout: build guide section 4.
- Keep business logic in plain Dart classes (services/repositories) that can be unit
  tested without widgets.
- Every pricing, matching, publish, and sync function gets unit tests.

## Commands

App (run inside `app/`):
- `flutter pub get`
- `dart run build_runner build --delete-conflicting-outputs` (after editing drift files)
- `flutter analyze`
- `flutter test`
- `flutter run`

Worker (run inside `worker/`):
- `go vet ./...`
- `go test ./...`
- `go run .`

Server:
- `supabase start`
- `supabase db reset` (re-applies migrations to the local database)

## Environment

- Development on Windows, testing on a real Android phone.
- No Mac: don't attempt iOS build or Xcode steps. Leave `app/ios/` as generated.

## How to work with me

- I know Go well but I'm new to Flutter and to shipping apps. When you pick a package
  or pattern, explain why in one or two sentences.
- Work in small steps. After each step, run `flutter analyze` and `flutter test`
  (or the Go equivalents), then tell me exactly what to check on my phone.
- Before adding or using a package, check its current documentation; package APIs change.
- Don't move to the next milestone until I confirm its "done when" check from the
  build guide.
- Don't commit secrets. `.env` files stay out of git.

## Current status

Current milestone: 4 (PO import with fake data), built but not yet verified
on phones; see `docs/server-setup.md` sections 6 to 8. Milestones 1 to 3 are
verified done.

Milestone 4 pieces: Go worker (`worker/`: queue, storage, job runner; tested
against Postgres), Inbox (`lib/inbox/`), camera/gallery via image_picker,
share-from-WhatsApp handled natively in `MainActivity.kt` (no plugin).

Also added with Milestone 3: first-launch screen (create shop / restore / join),
onboarding by shop type with starter categories and emoji (`lib/onboarding/`),
category-first home with emoji cards, phone bottom bar / tablet sidebar
(`lib/core/app_shell.dart`, look in `lib/core/ui.dart`). Owner schema is v6
(`categories.emoji`).

Run the app with the server: `flutter run --dart-define-from-file=config.json`
(copy `config.example.json`). Without it the app runs offline.

Employees join by code or by invite link (`lib/welcome/invite_link.dart`,
`MainActivity.kt` channel harga_toko/invite, landing page in `invite-site/`).
The link parameter is `kode`, never `code` (Supabase treats `code` as a login
callback).
