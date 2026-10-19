# Store Price Guide App: Product Spec v2

## Purpose
A mobile app (Android & iOS) that turns supplier purchase orders (photos) into a
searchable product catalog, so the owner can manage costs and margins and employees
can quickly look up retail prices and product models.

## Roles
- **Owner**: full access. Uploads POs, reviews extracted data, sets pricing, shares access.
- **Employee / Guest**: read-only. Sees product name, model, photo, and retail price only.

---

## Story 1: Import purchase order photos
As the owner, I want to get PO photos into the app from wherever I receive them,
so I don't have to retype supplier data.

**Input channels (MVP)**
- In-app upload: camera capture + pick from gallery (multi-select).
- System share sheet: app appears as a share target when sharing images from
  WhatsApp, Gallery, Files, etc.
  - Android: intent filter for ACTION_SEND / ACTION_SEND_MULTIPLE, image/*
  - iOS: Share Extension accepting images
- Manual "Add Product" button (no photo) for single items: name, model, category (pick or create), unit, supplier (pick or create), supply price. Retail price and margin preview live while typing; amounts show a thousands separator (15.000).

**Input channel (Phase 2)**
- WhatsApp Business number: suppliers or the owner send/forward PO photos to a
  dedicated store number. The server receives them via the WhatsApp Business
  Platform (Cloud API) webhook and queues them for processing.
  Note: a regular WhatsApp account cannot push to an API; this requires a
  WhatsApp Business Platform setup.

**Acceptance criteria**
- Shared/uploaded images land in an "Inbox" with status:
  Queued → Processing → Needs Review → Saved.
- Multiple pages can be grouped into one PO.
- Upload works on poor connections (retry, resumes later).

---

## Story 2: Extract products and group by supplier
As the owner, I want the app to read each PO and file its items under the right
supplier, so my catalog builds itself.

**Flow**
1. Identify supplier from the PO header (name, letterhead/logo, phone, address).
   - Match against known suppliers; if no match, propose a new supplier.
2. Extract line items: product name, model/variant, unit (pcs/pack/box/dus),
   quantity, unit price, PO date.
3. Match each line item to an existing catalog product or create a new one.
4. Show a **Review screen** before saving: owner can correct supplier, names,
   prices, and matches. Low-confidence fields are highlighted.

**Product matching rules**
- A catalog product has one canonical name plus **supplier-specific aliases**
  (e.g. Supplier A "Kabel USB-C 1M" and Supplier B "Kbl Type C 100cm" can both
  map to the same product).
- Exact alias match → auto-link. Similar name → suggest match, owner confirms.
  No match → new product.
- Once confirmed, the alias is remembered so future POs auto-match.

**Result**
- One product can show multiple supply prices, one per supplier, each with the
  latest PO date.
- Price history is kept per supplier (not overwritten).

---

## Story 3: Retail pricing

As the owner, I want a default retail price calculated from the supply price,
adjustable by range, with the ability to override individual products.

### Pricing model
- Owner maintains a list of **anchor points** (supply price → retail price) in Settings.
- For a supply price between two anchors, retail = straight-line interpolation
  between them, **rounded UP to the nearest Rp 5,000**.
- Below the first anchor: minimum retail price (default Rp 5,000).
- Above the last anchor (default Rp 1,000,000): owner chooses one of
  - a. markup % (e.g. 40%), rounded up to 5,000
  - b. "manual price required": product is flagged until priced

### Default anchor points (IDR)
| Supply | Retail |
|---|---|
| 2,000 | 5,000 |
| 5,000 | 10,000 |
| 10,000 | 15,000 |
| 12,000 | 20,000 |
| 14,000 | 25,000 |
| 18,000 | 30,000 |
| 20,000 | 35,000 |
| 25,000 | 40,000 |
| 65,000 | 100,000 |
| 120,000 | 165,000 |
| 160,000 | 220,000 |
| 210,000 | 265,000 |
| 240,000 | 300,000 |
| 280,000 | 340,000 |
| 310,000 | 370,000 |
| 350,000 | 450,000 |
| 400,000 | 520,000 |
| 1,000,000 | 1,300,000 |

- Above the last anchor (default Rp 1,000,000):
  retail = supply × 1.3, rounded UP to the nearest Rp 5,000,
  but never lower than the last anchor's retail price (default Rp 1,350,000).
  - The markup % (default 30%) is editable in Pricing Settings.

### Pricing Settings screen
- Editable anchor list: add, edit, delete rows; each row shows its margin %.
- Validation: retail must be a multiple of 5,000 and must increase with supply price.
- "Try a price" box: enter any supply price and see the calculated retail
  price and margin instantly.
- Optional chart of the pricing curve.

### Bulk adjust by range
- Owner selects a supply price range and applies +/- % or +/- Rp.
- Preview before applying: "23 products will change," with old → new prices.
- Result is rounded up to 5,000.

### Margin warnings (ranged)
- Minimum margin threshold is set per supply range, e.g.
  - < 65,000 → warn below 30%
  - 65,000 – 400,000 → warn below 15%
  - > 400,000 → warn below 20%
- Products below threshold are flagged after a new PO raises supply price.
- The margin is checked against the **latest PO price** of the product (the most
  recent supplier price recorded for it, from any supplier), not against the
  highest supplier price. This is separate from the price that drives the retail
  price (`settings.basis`, default highest).
- Optional setting (Batas margin screen): use the **average of the last N PO
  prices** instead (N from 2 to 20, default 3; the mean of the last N recorded
  supplier prices of the product, any supplier, rounded to a whole Rupiah).
  Stored as `settings.margin_basis` (`latest` or `average`) and
  `settings.margin_avg_count`.

### Overrides & recalculation
- Retail price is shown next to supply price(s) in the owner view.
- With multiple suppliers, the default uses the **highest** supply price.
- Owner can override retail price at review, manual add, or later. A manual price
  only has to be greater than 0 (any amount, not limited to multiples of 5,000);
  only the calculated price is rounded up to 5,000.
- Overridden prices are marked and never changed by anchor edits or bulk adjust,
  unless the owner chooses "reset to default."
- When anchors change, the app shows a preview of affected products before applying.

---

## Story 4: Share catalog with employees
As the owner, I want to give employees access via a link, without exposing
supplier information.

**Flow**
1. Owner taps "Invite" → server creates an invite link valid for 7 days.
2. Owner sends the link (e.g. via WhatsApp).
3. Employee taps the link:
   - App installed → app opens and joins the store catalog
     (Android App Links / iOS Universal Links).
   - App not installed → landing page with store download buttons; after
     install, the invite is applied on first launch (deferred deep link).
4. Employee sees the catalog in read-only Employee View.

**Access rules**
- The 7-day expiry applies to joining via the link. Once joined, access stays
  until the owner revokes it. ← confirm this is the intended behavior
- Owner can see the list of joined devices/employees and revoke any of them.
- Employees receive catalog updates automatically.

**Confidentiality (enforced on the server, not just hidden in the UI)**
- The employee API never returns supplier names, supplier aliases, supply
  prices, margins, or PO images.

---

## Story 5: Product lookup (employee + owner)
As an employee, I want to find a product's price in seconds while serving a customer.

- Search by name, alias, or model; tolerant of typos and partial words.
- Owner view (done in milestone 1): search by name or model, every typed word must match; product detail with retail price, margin, latest supplier price per supplier, price history, "Ubah harga" (override) and "Hapus produk" (to the owner this is a plain delete: the product leaves the list and the employee catalog, and a snackbar offers "Urungkan" for a few seconds. Underneath it is a soft delete, `deleted_at`, so employees are told about the removal; there is no archive screen and no restore from Settings). Settings can hide the margin-warning and manual-price icons on the home list.
- Browse by category.
- Product card: photo, name, model/variant, unit, retail price.
- Works offline with the last synced catalog; shows "last updated" time.

---

## Non-functional
- Language: Bahasa Indonesia (English optional).
- Currency: IDR, thousands separator (Rp 15.000).
- Platforms: Android first (likely majority of users), iOS second.
- Owner login required; employee access via invite only.

## Out of scope (MVP)
- Inventory/stock counts, sales/POS, supplier ordering.