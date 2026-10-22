import 'package:drift/native.dart';
import 'package:flutter_application_1/data/owner_database.dart';
import 'package:flutter_application_1/pricing/basis.dart';
import 'package:flutter_application_1/pricing/margin_service.dart';
import 'package:flutter_application_1/products/product_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pickMarginSupply', () {
    test('latest takes the newest price', () {
      expect(pickMarginSupply('latest', 3, [9500, 12000, 20000]), 9500);
    });

    test('average takes the mean of the newest N, rounded', () {
      expect(pickMarginSupply('average', 3, [9500, 9500, 20000, 99999]), 13000);
      expect(pickMarginSupply('average', 2, [10000, 10001]), 10001); // 10000.5
    });

    test('average with fewer prices than N uses what exists', () {
      expect(pickMarginSupply('average', 5, [9000, 11000]), 10000);
      expect(pickMarginSupply('average', 3, [9500]), 9500);
    });

    test('no prices gives null', () {
      expect(pickMarginSupply('latest', 3, []), isNull);
      expect(pickMarginSupply('average', 3, []), isNull);
    });
  });

  group('margin supply from the database', () {
    late OwnerDatabase db;
    late ProductService products;
    late MarginService margins;

    setUp(() {
      db = OwnerDatabase(NativeDatabase.memory());
      products = ProductService(db);
      margins = MarginService(db, products);
    });
    tearDown(() => db.close());

    Future<String> addProduct(String name, String supplier, int price, DateTime at) async {
      final id = await products.addManual(
        NewProductInput(name: name, supplierName: supplier, supplyPrice: price),
      );
      // addManual stamps "now"; move that first price to the time we want.
      await db.customStatement(
        'UPDATE supplier_prices SET observed_at = ? WHERE product_id = ?',
        [at.toUtc().toIso8601String(), id],
      );
      return id;
    }

    Future<void> price(String product, String supplier, int amount, DateTime at) async =>
        products.recordSupplierPrice(
          product,
          await products.findOrCreateSupplier(supplier),
          amount,
          observedAt: at,
        );

    Future<void> setMargin(String basis, [int count = 3]) =>
        margins.saveBasis(basis, count);

    final t1 = DateTime.utc(2026, 9, 1);
    final t2 = DateTime.utc(2026, 9, 10);
    final t3 = DateTime.utc(2026, 9, 20);

    test('defaults to the latest PO price, N = 3', () async {
      final s = await margins.loadBasis();
      expect(s.basis, 'latest');
      expect(s.count, 3);
    });

    test('latest is the newest price from any supplier', () async {
      final id = await addProduct('Kabel', 'A', 20000, t1);
      await price(id, 'A', 9500, t2);
      // A cheaper price from another supplier, newest of all.
      await price(id, 'B', 8000, t3);
      expect((await products.marginSupplyPrices())[id], 8000);

      // Older than everything: not the latest, whatever its amount.
      await price(id, 'B', 30000, DateTime.utc(2026, 1, 1));
      expect((await products.marginSupplyPrices())[id], 8000);
    });

    test('average is over the last N recorded prices, across suppliers', () async {
      final id = await addProduct('Kabel', 'A', 20000, t1);
      await price(id, 'A', 9500, t2);
      await price(id, 'B', 9500, t3);
      await setMargin('average', 3);
      expect((await products.marginSupplyPrices())[id], 13000);
      await setMargin('average', 2);
      expect((await products.marginSupplyPrices())[id], 9500);
    });

    test('each product is judged on its own prices, and one can be asked for alone', () async {
      final a = await addProduct('A', 'S', 9500, t1);
      final b = await addProduct('B', 'S', 45000, t1);
      final all = await products.marginSupplyPrices();
      expect(all, {a: 9500, b: 45000});
      expect(await products.marginSupplyPrices(productId: b), {b: 45000});
      expect(await products.marginSupplyPrices(productId: 'nope'), isEmpty);
    });

    test('the warning follows the margin basis, not the retail basis', () async {
      // Retail follows the LOWEST supplier price (settings.basis), so it stays
      // 15.000 for 9.500. The margin check follows its own basis.
      await db.customStatement("UPDATE settings SET basis = 'lowest' WHERE id = 1");
      final id = await addProduct('Kabel', 'A', 9500, t1);
      await price(id, 'B', 20000, t3); // newest, and expensive
      expect((await products.detail(id))!.product.retailPrice, 15000);

      await setMargin('latest');
      expect(await margins.productsBelowMargin(), {id}); // 15.000 vs 20.000

      // Same data, but the retail basis alone would not have flagged it.
      await setMargin('average', 2); // (9.500 + 20.000) / 2 = 14.750
      expect(await margins.productsBelowMargin(), {id});
    });

    test('an older expensive price stops mattering under "latest"', () async {
      final id = await addProduct('Kabel', 'A', 20000, t1); // old, expensive
      await price(id, 'A', 9500, t3); // newest
      await products.applySuggestion(id); // the owner confirms: retail 15.000
      await setMargin('latest');
      expect(await margins.productsBelowMargin(), isEmpty);
      // The average still remembers the expensive one.
      await setMargin('average', 2); // 14.750 vs retail 15.000
      expect(await margins.productsBelowMargin(), {id});
    });

    test('detail reports the margin supply, its basis and the matching limit', () async {
      final id = await addProduct('Kabel', 'A', 20000, t1);
      await price(id, 'A', 9500, t3);
      var d = (await products.detail(id))!;
      expect(d.marginSupply, 9500);
      expect(d.marginBasis, 'latest');
      expect(d.basisSupply, 9500);

      await setMargin('average', 2);
      d = (await products.detail(id))!;
      expect(d.marginSupply, 14750);
      expect(d.marginBasis, 'average');
      expect(d.marginAvgCount, 2);
      // Limit for the range containing 14.750 (default: below 65.000 -> 30%).
      expect(d.minMarginPct, 30);
    });

    test('saveBasis stores the choice and rejects bad values', () async {
      await margins.saveBasis('average', 5);
      final s = await margins.loadBasis();
      expect((s.basis, s.count), ('average', 5));

      expect(() => margins.saveBasis('highest', 3), throwsArgumentError);
      expect(() => margins.saveBasis('average', 1), throwsArgumentError);
      expect(() => margins.saveBasis('average', 21), throwsArgumentError);
      expect((await margins.loadBasis()).count, 5); // unchanged
    });
  });

  group('upgrading an older database keeps what the owner has', () {
    // The tables an old phone has. Only what the upgrades touch matters here.
    const settingsV1 = '''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        store_id TEXT,
        min_retail INTEGER NOT NULL DEFAULT 5000,
        round_to INTEGER NOT NULL DEFAULT 5000 CHECK (round_to > 0),
        above_markup_pct REAL NOT NULL DEFAULT 30,
        basis TEXT NOT NULL DEFAULT 'highest'
          CHECK (basis IN ('highest', 'lowest', 'latest')),
        last_backup_at TEXT
      )''';
    const productsV2 = '''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        retail_price INTEGER,
        retail_is_override INTEGER NOT NULL DEFAULT 0
      )''';

    OwnerDatabase oldDatabase(void Function(dynamic raw) setup) =>
        OwnerDatabase(NativeDatabase.memory(setup: setup));

    test('version 1 gets the margin settings and the price suggestion column', () async {
      final db = oldDatabase((raw) {
        raw.execute(settingsV1);
        raw.execute("INSERT INTO settings (id, basis, above_markup_pct) VALUES (1, 'lowest', 42)");
        raw.execute(productsV2);
        raw.execute("INSERT INTO products (id, name, retail_price) VALUES ('p1', 'Kabel', 15000)");
        raw.execute('PRAGMA user_version = 1');
      });
      addTearDown(db.close);

      final s = (await db
              .customSelect('SELECT basis, above_markup_pct, margin_basis, margin_avg_count FROM settings')
              .getSingle())
          .data;
      expect(s['basis'], 'lowest'); // existing choice kept
      expect(s['above_markup_pct'], 42);
      expect(s['margin_basis'], 'latest'); // new defaults
      expect(s['margin_avg_count'], 3);
      final p = (await db.customSelect('SELECT name, retail_price, pending_retail FROM products').getSingle()).data;
      expect(p['name'], 'Kabel');
      expect(p['retail_price'], 15000);
      expect(p['pending_retail'], isNull); // nothing to confirm yet
      // The new CHECK constraints came along with the columns.
      await expectLater(
        db.customStatement("UPDATE settings SET margin_basis = 'highest'"),
        throwsA(anything),
      );
      await expectLater(
        db.customStatement("UPDATE products SET pending_retail = 0"),
        throwsA(anything),
      );
    });

    test('version 2 only gets the price suggestion column', () async {
      final db = oldDatabase((raw) {
        raw.execute(settingsV1.replaceFirst(
          'last_backup_at TEXT',
          "last_backup_at TEXT, margin_basis TEXT NOT NULL DEFAULT 'average', "
              'margin_avg_count INTEGER NOT NULL DEFAULT 5',
        ));
        raw.execute('INSERT INTO settings (id) VALUES (1)');
        raw.execute(productsV2);
        raw.execute("INSERT INTO products (id, name, retail_price) VALUES ('p1', 'Kabel', 15000)");
        raw.execute('PRAGMA user_version = 2');
      });
      addTearDown(db.close);

      // Their own margin choice is not reset to the default.
      final s = (await db.customSelect('SELECT margin_basis, margin_avg_count FROM settings').getSingle()).data;
      expect(s['margin_basis'], 'average');
      expect(s['margin_avg_count'], 5);
      final p = (await db.customSelect('SELECT retail_price, pending_retail FROM products').getSingle()).data;
      expect(p['retail_price'], 15000);
      expect(p['pending_retail'], isNull);
    });

    test('version 3 gets retail change tracking and the fixed "current price" view', () async {
      // A phone that already holds two prices with the same date: the old view
      // kept showing the older one.
      final db = oldDatabase((raw) {
        raw.execute('''
          CREATE TABLE products (
            id TEXT PRIMARY KEY, name TEXT NOT NULL, retail_price INTEGER,
            retail_is_override INTEGER NOT NULL DEFAULT 0, pending_retail INTEGER,
            updated_at TEXT NOT NULL DEFAULT '2026-01-01T00:00:00.000Z'
          )''');
        raw.execute('''
          CREATE TABLE supplier_prices (
            id TEXT PRIMARY KEY, product_id TEXT NOT NULL, supplier_id TEXT NOT NULL,
            unit_price INTEGER NOT NULL, po_line_id TEXT, observed_at TEXT NOT NULL
          )''');
        raw.execute('''
          CREATE VIEW current_supplier_prices AS
          SELECT product_id, supplier_id, unit_price, observed_at FROM (
            SELECT product_id, supplier_id, unit_price, observed_at,
                   ROW_NUMBER() OVER (PARTITION BY product_id, supplier_id
                                      ORDER BY observed_at DESC) AS rn
            FROM supplier_prices
          ) WHERE rn = 1''');
        raw.execute(settingsV1.replaceFirst(
          'last_backup_at TEXT',
          "last_backup_at TEXT, margin_basis TEXT NOT NULL DEFAULT 'latest', "
              'margin_avg_count INTEGER NOT NULL DEFAULT 3',
        ));
        raw.execute('INSERT INTO settings (id) VALUES (1)');
        raw.execute("INSERT INTO products (id, name, retail_price) VALUES ('p1', 'Kabel', 15000)");
        raw.execute("INSERT INTO supplier_prices VALUES ('a', 'p1', 's1', 9500, NULL, '2026-10-04T00:00:00.000Z')");
        raw.execute("INSERT INTO supplier_prices VALUES ('b', 'p1', 's1', 45000, NULL, '2026-10-04T00:00:00.000Z')");
        raw.execute('PRAGMA user_version = 3');
      });
      addTearDown(db.close);

      // The tie is now broken in favour of the price recorded last.
      final current = await db.customSelect('SELECT unit_price FROM current_supplier_prices').getSingle();
      expect(current.read<int>('unit_price'), 45000);

      // The new columns exist, nothing is recorded for old data...
      var p = (await db.customSelect('SELECT retail_prev, retail_changed_at FROM products').getSingle()).data;
      expect(p['retail_prev'], isNull);
      expect(p['retail_changed_at'], isNull);

      // ...and from now on every retail price change is remembered.
      await db.customStatement('UPDATE products SET retail_price = 70000');
      p = (await db.customSelect('SELECT retail_prev, retail_changed_at FROM products').getSingle()).data;
      expect(p['retail_prev'], 15000);
      expect(p['retail_changed_at'], isNotNull);
    });
  });
}
