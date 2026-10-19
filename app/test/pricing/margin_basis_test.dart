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

  test('upgrading a version 1 database adds the margin settings and keeps data', () async {
    // A phone that still has the version 1 settings table, with real values.
    final db = OwnerDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
            CREATE TABLE settings (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              store_id TEXT,
              min_retail INTEGER NOT NULL DEFAULT 5000,
              round_to INTEGER NOT NULL DEFAULT 5000 CHECK (round_to > 0),
              above_markup_pct REAL NOT NULL DEFAULT 30,
              basis TEXT NOT NULL DEFAULT 'highest'
                CHECK (basis IN ('highest', 'lowest', 'latest')),
              last_backup_at TEXT
            )''');
          raw.execute("INSERT INTO settings (id, basis, above_markup_pct) VALUES (1, 'lowest', 42)");
          raw.execute('PRAGMA user_version = 1');
        },
      ),
    );
    addTearDown(db.close);

    final row = (await db
            .customSelect('SELECT basis, above_markup_pct, margin_basis, margin_avg_count FROM settings')
            .getSingle())
        .data;
    expect(row['basis'], 'lowest'); // existing choice kept
    expect(row['above_markup_pct'], 42);
    expect(row['margin_basis'], 'latest'); // new defaults
    expect(row['margin_avg_count'], 3);
    // The new CHECK constraints came along with the columns.
    await expectLater(
      db.customStatement("UPDATE settings SET margin_basis = 'highest'"),
      throwsA(anything),
    );
  });
}
