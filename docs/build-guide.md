# Store Price Guide App: Build Guide (local-first)

For: one developer, comfortable with Go, new to shipping apps, building in Flutter
on Windows/Linux.

Companion files:

- `local_schema.sql`: SQLite database on the phones (tested on SQLite 3.45)
- `server_schema.sql`: Supabase/PostgreSQL database on the server (tested on PostgreSQL 16)

---

## 1. Architecture

The **owner's phone is the source of truth**. All real data and processing live there:
suppliers, supply prices, price history, pricing rules, product matching, and PO review.

The server does only three things:

1. **Employee catalog:** stores the employee-safe product list and serves it to staff.
2. **Access:** owner account, invite codes, employee membership, revoke.
3. **PO reading:** receives PO photos, runs the AI, returns JSON, then deletes the photos.

```
 OWNER PHONE (all data, all logic)                SERVER (Supabase)
 ┌──────────────────────────────┐                ┌─────────────────────────┐
 │ SQLite: products, suppliers, │  publish safe  │ catalog_items           │◄── employee
 │ supplier_prices, anchors,    │ ─── fields ──► │ (name, model, unit,     │    phones
 │ POs, aliases                 │                │  photo, retail price)   │    (SQLite
 │                              │                │                         │     copy)
 │ Dart: pricing, matching,     │  PO photos ──► │ extraction_jobs ◄──► Go │
 │ review, recalculation        │ ◄── JSON ───── │ (photos deleted after)  worker
 └──────────────────────────────┘                └─────────────────────────┘
```

Supplier names and supply prices **never leave the owner's phone**. The phone sends
only employee fields, and the server's `publish_catalog()` reads only whitelisted
fields, so even a bug that sends extra data can't store it. The server table has no
columns for supplier data at all.

### What this design gives up

- **One owner device.** The data lives on one phone. Using the owner account on two
  phones would need a full sync system, which is out of scope for the MVP.
- **Backups are your job.** If the phone is lost and there's no backup, the supplier
  data is gone. Section 8 covers this. Treat it as a required feature.

---

## 2. Stack

| Part | Choice | Why |
|---|---|---|
| Mobile app | Flutter (Dart) | One codebase for Android and iOS |
| Local database | SQLite via `drift` | Typed queries, migrations, works offline |
| Server | Supabase (free tier) | Auth, small Postgres, file storage |
| Extraction worker | Go | Your strongest language; runs in the cloud or on your laptop |
| AI model | Decided later | Hidden behind one interface in the worker |

---

## 3. Set up your machine

1. **Git** and **VS Code** (Flutter, Dart, and Go extensions).
2. **Flutter SDK** (stable). Run `flutter doctor` until Android is green. The iOS line
   stays red on Windows/Linux, which is expected.
3. **Android Studio**, for the Android SDK and emulator.
4. **Go** (latest stable).
5. **Docker** and the **Supabase CLI**, to run the server locally during development.
   Not needed until Milestone 3.
6. A **real Android phone** with USB debugging on.

---

## 4. Project structure

```
store-price-guide/
├── app/                           Flutter app (owner + employee modes)
│   └── lib/
│       ├── data/
│       │   ├── local.drift        ← local_schema.sql
│       │   └── database.dart      drift database class, default data seeding
│       ├── core/                  supabase client, router, Rupiah formatting
│       ├── pricing/               calcRetail, recalculation
│       ├── matching/              name normalization and similarity
│       ├── inbox/                 Story 1: upload, share intent, job polling
│       ├── review/                Story 2: review and save
│       ├── products/              owner product list and detail
│       ├── settings/              Story 3 + backup
│       ├── team/                  Story 4: invites, members
│       ├── publish/               push changes to employee catalog
│       └── catalog/               Story 5: employee search + sync
├── worker/                        Go extraction worker
│   ├── main.go                    job loop
│   └── extractor/                 interface + fake, ollama, cloud implementations
├── supabase/migrations/
│   └── 0001_init.sql              ← server_schema.sql
└── shared/
    └── pricing_vectors.json       test cases for calcRetail
```

### Flutter packages

| Package | Used for |
|---|---|
| `drift`, `drift_flutter` | Local SQLite database |
| `uuid` | Ids generated on the phone |
| `supabase_flutter` | Login, server calls, file uploads |
| `flutter_riverpod` | State management |
| `go_router` | Screens and deep link routes |
| `image_picker` | Camera and gallery |
| `flutter_image_compress` | Shrink PO photos before upload |
| `receive_sharing_intent` | Receiving images shared from WhatsApp, Gallery, etc. |
| `app_links` | Opening the app from invite links |
| `share_plus`, `file_picker` | Backup export (share sheet) and restore picker; the Download folder is our own MediaStore channel |
| `intl` | `Rp 15.000` formatting |

Check each package's README for current setup. The Android manifest changes for
`receive_sharing_intent` and `app_links` are the most common beginner mistakes.

---

## 5. Databases

### Owner phone (`local_schema.sql`, owner section)

| Table | Holds |
|---|---|
| `settings` | Single row: pricing settings, server store id, last backup time |
| `pricing_anchors`, `margin_thresholds` | Story 3 rules |
| `suppliers`, `categories`, `products` | The catalog |
| `product_aliases` | Supplier-specific names → one product |
| `supplier_prices` | Every price seen, never overwritten |
| `purchase_orders`, `po_pages`, `po_lines` | POs, local photos, extracted lines |

Helpers:

- View `current_supplier_prices`: the latest price per product per supplier.
- View `products_to_publish`: products whose employee-visible fields changed since the
  last publish, already shaped as the server expects.
- Triggers bump `products.updated_at` only when an employee-visible field changes
  (name, model, category, unit, photo, retail price, deleted). Changing a supply price
  doesn't make a product "dirty"; changing its retail price does.

On first launch, seed `settings` (one row, `id = 1`) and `pricing_anchors` with the
default table, and the three default margin ranges (0–65k: 30%, 65k–400k: 15%,
above 400k: 20%).

### Employee phone (`local_schema.sql`, employee section)

A separate, small database: `catalog` plus an FTS5 full-text index for instant
partial-word search (`kab*` finds "Kabel"). The triggers keep the index in sync.

### Server (`server_schema.sql`)

| Table | Holds |
|---|---|
| `stores`, `store_members`, `invites` | Access |
| `catalog_items` | Employee-safe fields only |
| `extraction_jobs` | PO reading queue; results cleared after the owner fetches them |

Server functions the app calls:

| Function | Who | Does |
|---|---|---|
| `create_store(name)` | Owner, once | Creates store + owner membership; save the id in `settings.store_id` |
| `publish_catalog(store, items)` | Owner | Upserts changed products (whitelisted fields only) |
| `employee_catalog(store, since)` | Everyone | Incremental catalog download |
| `create_invite(store)` | Owner | 8-character code, valid 7 days |
| `accept_invite(code, name, device)` | Employee | Joins the store |
| `submit_extraction(store, paths)` | Owner | Queues uploaded PO pages |
| `mark_extraction_fetched(job)` | Owner | Clears the result from the server |

Money is whole Rupiah everywhere: `INTEGER` in SQLite, `bigint` in Postgres, `int` in
Dart. Never use floating point for prices.

---

## 6. Pricing (all in Dart)

Pricing now runs only on the owner phone, so there's one implementation.

```dart
int calcRetail(int supply, List<(int, int)> anchors,
    {int minRetail = 5000, int roundTo = 5000, double aboveMarkupPct = 30}) {
  int roundUp(num v) => ((v / roundTo).ceil()) * roundTo;
  if (supply <= anchors.first.$1) return supply == anchors.first.$1 ? anchors.first.$2 : minRetail;
  final last = anchors.last;
  if (supply > last.$1) {
    final r = roundUp(supply * (1 + aboveMarkupPct / 100));
    return r > last.$2 ? r : last.$2;
  }
  for (var i = 1; i < anchors.length; i++) {
    final (a, b) = anchors[i - 1];
    final (c, d) = anchors[i];
    if (supply == c) return d;
    if (supply < c) return roundUp(b + (supply - a) * (d - b) / (c - a));
  }
  return last.$2;
}
```

`shared/pricing_vectors.json`. Write a unit test that checks every pair:

```json
[
  [1500, 5000], [2000, 5000], [3000, 10000], [9500, 15000], [11000, 20000],
  [45000, 70000], [90000, 130000], [130000, 180000], [330000, 410000],
  [700000, 935000], [1000000, 1350000], [1050000, 1365000],
  [1100000, 1430000], [2000000, 2600000]
]
```

**When to recalculate a product's retail price** (skip if `retail_is_override = 1`):

- After saving a PO review, a manual add or a product edit that inserts
  `supplier_prices`: the product's first price sets `retail_price`; any later change
  only stores the calculated price in `products.pending_retail` (when it differs from
  `retail_price`) for the owner to confirm (`applySuggestion`) or refuse
  (`dismissSuggestion`). The next supplier price change recomputes it, which is the
  only way a refused suggestion comes back. `pending_retail` is local only and never
  published; applying it changes `retail_price`, which is published as usual.
- After anchors or settings change: first compute all new prices and show the preview
  ("23 products will change"), then write them in one transaction (this also clears
  every `pending_retail`).

The supply price that drives it comes from `current_supplier_prices` using
`settings.basis` (`MAX`, `MIN`, or latest `observed_at`).

**Bulk adjust** results should be saved with `retail_is_override = 1`, otherwise the
next recalculation would undo them.

---

## 7. Publishing to employees

```
1. SELECT * FROM products_to_publish        (remember each row's updated_at)
2. Upload any new product photos to 'product-photos/{store_id}/{product_id}.jpg'
   and save photo_remote_path
3. rpc('publish_catalog', {p_store, p_items})  in batches of ~200
4. For each sent product: SET published_at = the updated_at you read in step 1
```

Step 4 uses the value from step 1, not "now," so a product edited *while* the upload
was running stays dirty and goes out next time.

Publish automatically after saving a PO review, after a price change, and when the app
returns to the foreground. If there's no signal, nothing is lost: the products stay in
`products_to_publish` until it succeeds. Show a small "3 perubahan belum terkirim"
indicator so the owner knows.

**Employee sync:** call `employee_catalog(store, since)` with the largest
`updated_at` already stored, upsert the rows into `catalog`, delete rows where
`is_deleted` is true, and save the new cursor. Run it on app open and pull-to-refresh.
The cursor uses the server's clock, so a phone with the wrong time can't break sync.

---

## 8. Backup (required)

Since the owner phone holds the only copy of supplier data, build backup in
Milestone 2, before real data goes in. The server catalog is **not** a backup: it has
no suppliers or supply prices.

1. **Automatic baseline:** keep Android Auto Backup enabled (`android:allowBackup`).
   It backs up app data to the owner's Google account, but has a size limit, so don't
   rely on it for photos.
2. **Manual export:** "Cadangkan data" in Settings creates a copy of the SQLite file
   (use SQLite's `VACUUM INTO` for a consistent copy), zips it with a small manifest
   (no photos: the backup is text only, so it stays small and portable; it holds all
   products, deleted and not), then asks where to put it: **Google Drive** (opens the
   share sheet, where Drive is a target) or **Simpan di HP**, which copies the zip
   straight into the public Download folder without asking for a location. That is
   our own small MediaStore channel in `MainActivity.kt` (no plugin, so nothing
   depends on the Kotlin Gradle plugin that future Flutter versions will reject):
   Android 10+ needs no permission and MediaStore picks a free name instead of
   overwriting. Android 9 and older are not supported there; the app says so and
   points to Google Drive.
3. **Restore:** "Pulihkan dari file" first looks in the Download folder for backups
   this app saved (name `harga-toko-cadangan-YYYYMMDD-HHMM.zip`) and lists them
   newest first, the newest marked "Terbaru"; "Pilih file lain" (or no backups found)
   opens the general file picker. The chosen zip is read directly (no manual
   extraction), checked, confirmed with the owner, and then replaces the local
   database. After a reinstall, Android hides files a previous install saved, so the
   list can be empty; the file picker then finds the zip in Download as usual.
4. **Reminder:** if `settings.last_backup_at` is older than 7 days, show a banner.

PO photos can be excluded from backups once a PO is saved, to keep files small.

---

## 9. PO reading

### Phone side

```
1. Create purchase_orders (status 'queued') + po_pages with compressed local photos
   (~1600px long side)
2. When online: upload pages to 'po-images/{store_id}/{po_id}/{n}.jpg', status 'uploading'
3. rpc('submit_extraction') → save server_job_id, status 'processing'
4. Poll the job every few seconds while the Inbox is open (or on app resume)
5. When 'done': save the JSON in raw_result, create po_lines, run matching,
   status 'needs_review', then rpc('mark_extraction_fetched')
6. Owner reviews and saves → products, aliases, supplier_prices, recalculation,
   publish — all in one local transaction, then publish
```

### Matching (Dart, on the phone)

```dart
String normalize(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

double similarity(String a, String b) {
  Set<String> grams(String s) {
    final t = ' ${normalize(s)} ';
    return {for (var i = 0; i < t.length - 2; i++) t.substring(i, i + 3)};
  }
  final x = grams(a), y = grams(b);
  if (x.isEmpty || y.isEmpty) return 0;
  return 2 * x.intersection(y).length / (x.length + y.length);
}
```

- Exact match on `product_aliases (supplier_id, alias_norm)` → `auto`.
- Otherwise the best product with similarity above ~0.5 → `suggested` (✓/✗ on Review).
- Otherwise → `new`.

A small store has a few thousand products at most, so comparing against all of them on
the phone is fast enough. Tune the 0.5 threshold with real data.

### Worker side (Go)

The worker is now simpler: it only turns photos into JSON.

```
every few seconds:
  BEGIN
  SELECT … FROM extraction_jobs WHERE status = 'pending'
    ORDER BY created_at LIMIT 1 FOR UPDATE SKIP LOCKED
  set status 'running', locked_by, locked_at
  COMMIT
  download page_paths from 'po-images'
  result := extractor.Extract(pages)
  set status 'done', result, finished_at
  delete the images from storage
  on error: attempts++, back to 'pending', or 'failed' after 3 tries
     (delete images on 'failed' too)
daily: delete jobs with fetched_at set, or finished more than 14 days ago
```

It connects with `pgx` using the service role connection, which bypasses row level
security. That credential must only live on the worker, never in the app.

### The extraction contract

```json
{
  "supplier": { "name": "CV Maju Elektrik", "phone": "0812xxxx", "address": "…", "confidence": 0.96 },
  "po_date": "2026-10-04",
  "lines": [
    { "name": "Kbl Type C 100cm", "qty": 20, "unit": "pcs", "unit_price": 9500,
      "confidence": { "name": 0.97, "qty": 0.99, "unit_price": 0.95 } }
  ]
}
```

```go
type Extractor interface {
    Extract(ctx context.Context, pages [][]byte) (Result, error)
}
```

Implementations: `FakeExtractor` (fixed sample data, for building), `OllamaExtractor`
(your laptop), `CloudExtractor` (paid API tier). Choose with an environment variable.

Prompt rules: prices as integers (Indonesian notas use `9.500` with a dot as the
thousands separator), `null` for anything unreadable rather than a guess, and one
entry per printed line.

---

## 10. Invite links

1. Link: `https://<your-domain>/j/7KQ2M9XA`.
2. **App installed:** Android App Links open `/j/:code` in the app. Requires
   `/.well-known/assetlinks.json` on the domain; a free static host works.
3. **App not installed:** the page shows the code in large text, a copy button, and a
   download button. On first launch, the app asks "Masukkan kode undangan" and offers
   to paste from the clipboard.

Employees use Supabase **anonymous sign-in** (enable it in the dashboard), so they
never need an email account.

---

## 11. Build plan

**Milestone 1: Local catalog (no server at all)**
drift database, default data seeding, manual add with supplier and supply price,
product list and detail, owner search.
*Done when:* 10 real products entered by hand show correct retail prices in airplane mode.

**Milestone 2: Pricing and backup**
Pricing settings, "Coba harga", anchor editing with preview, override, margin
warnings, bulk adjust, backup export/restore, backup reminder.
*Done when:* all pricing vectors pass, an override survives an anchor change, and a
backup restores correctly on a second phone or emulator.
**At this point the owner can use the app alone in the store.**

**Milestone 3: Server and employees**
Supabase project, owner sign-up + `create_store`, publishing, product photo upload,
invites, employee mode with offline search and sync, revoke.
*Done when:* a second phone joins, searches in airplane mode, sees a price change
after refresh, and loses access after revoke.

**Milestone 4: PO import with fake data**
Camera/gallery upload, share intent, Inbox statuses, Go worker with `FakeExtractor`,
matching, Review screen, save transaction.
*Done when:* sharing a photo from WhatsApp ends with saved products and an updated
employee catalog.

**Milestone 5: Real extraction**
Run the accuracy test with 10–20 real PO photos per candidate model, pick one, plug
it in.
*Done when:* real notas reach the Review screen with most lines correct.

Phase 2: WhatsApp Business webhook (the server creates jobs; the owner phone picks up
results the same way), iOS release.

---

## 12. Releasing

**Android first:** Use the Google Play **internal testing** track for your staff
(one-time USD 25 developer account). Check Google's current rules before a public
production release, since new personal accounts have extra testing requirements.

**iOS later, without a Mac:** Apple Developer Program (USD 99/year), cloud builds
with a Flutter CI service such as Codemagic, distribution through TestFlight. The
iOS Share Extension needs a one-time Xcode setup; rent a cloud Mac for a few hours.

---

## 13. Common traps

- **No backup before real data.** Build Milestone 2's backup before entering your
  whole catalog.
- **Service role key in the app.** Anyone can extract it from the APK. Only the anon
  key goes in Flutter.
- **Setting `published_at` to now.** Use the `updated_at` you sent (section 7).
- **Float prices.** Always integers.
- **Large photos.** Compress before upload; it's faster and cheaper, and enough for
  text reading.
- **Schema changes without migrations.** Use drift's schema versioning from day one;
  once real data is on the phone, you can't just reinstall.
- **Testing only on the emulator.** Share intents and deep links behave differently on
  real phones.
