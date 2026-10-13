import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_application_1/data/owner_database.dart';
import 'package:flutter_application_1/pricing/defaults.dart';
import 'package:flutter_application_1/pricing/pricing_settings_service.dart';
import 'package:flutter_application_1/products/product_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late OwnerDatabase db;
  late ProductService service;
  var tick = 0;

  setUp(() {
    db = OwnerDatabase(NativeDatabase.memory());
    // Each call to "now" is one minute later, so "latest" is deterministic.
    tick = 0;
    service = ProductService(
      db,
      now: () => DateTime.utc(2026, 10, 4, 8, tick++),
    );
  });
  tearDown(() => db.close());

  Future<Product> product(String id) =>
      (db.select(db.products)..where((p) => p.id.equals(id))).getSingle();

  Future<String> supplierId(String name) async => (await (db.select(
    db.suppliers,
  )..where((s) => s.name.equals(name))).getSingle()).id!;

  Future<void> setBasis(String basis) =>
      db.customStatement("UPDATE settings SET basis = '$basis' WHERE id = 1");

  NewProductInput input({
    String supplier = 'CV Maju',
    int supply = 9500,
    int? retail,
    String? category,
  }) => NewProductInput(
    name: 'Kabel USB-C',
    model: '1M',
    categoryName: category,
    supplierName: supplier,
    supplyPrice: supply,
    retailPrice: retail,
  );

  test(
    'addManual saves product, supplier price and calculated retail',
    () async {
      final id = await service.addManual(input(category: 'Kabel'));

      final p = await product(id);
      expect(p.name, 'Kabel USB-C');
      expect(p.model, '1M');
      expect(p.retailPrice, 15000); // supply 9.500 -> 15.000 (pricing vector)
      expect(p.retailIsOverride, 0);
      expect(p.categoryId, isNotNull);

      final prices = await db.select(db.supplierPrices).get();
      expect(prices.single.unitPrice, 9500);
      expect(prices.single.productId, id);
    },
  );

  test(
    'reuses an existing supplier and category by name, ignoring case',
    () async {
      await service.addManual(input(category: 'Kabel'));
      await service.addManual(input(supplier: 'cv maju', category: 'KABEL'));

      expect(await db.select(db.suppliers).get(), hasLength(1));
      expect(await db.select(db.categories).get(), hasLength(1));
    },
  );

  test(
    'retail price that differs from the calculation becomes an override',
    () async {
      final id = await service.addManual(input(retail: 20000));
      final p = await product(id);
      expect(p.retailPrice, 20000);
      expect(p.retailIsOverride, 1);
    },
  );

  test('retail price equal to the calculation is not an override', () async {
    final id = await service.addManual(input(retail: 15000));
    expect((await product(id)).retailIsOverride, 0);
  });

  test(
    'any positive retail price is allowed, even off the 5.000 step',
    () async {
      final id = await service.addManual(input(retail: 17500));
      final p = await product(id);
      expect(p.retailPrice, 17500);
      expect(p.retailIsOverride, 1);
      expect(() => service.addManual(input(retail: 0)), throwsArgumentError);
    },
  );

  test('rejects empty name, empty supplier and non-positive supply price', () {
    expect(
      () => service.addManual(
        const NewProductInput(name: ' ', supplierName: 'A', supplyPrice: 1000),
      ),
      throwsArgumentError,
    );
    expect(
      () => service.addManual(
        const NewProductInput(name: 'X', supplierName: ' ', supplyPrice: 1000),
      ),
      throwsArgumentError,
    );
    expect(() => service.addManual(input(supply: 0)), throwsArgumentError);
  });

  test('addManual joins an outer transaction, so a later failure rolls it all back', () async {
    // Unknown product id makes the supplier price insert violate its foreign key.
    await db.customStatement('PRAGMA foreign_keys = ON');
    await expectLater(
      db.transaction(() async {
        await service.addManual(input());
        throw StateError('boom');
      }),
      throwsStateError,
    );
    expect(await db.select(db.supplierPrices).get(), isEmpty);
    expect(await db.select(db.suppliers).get(), isEmpty);
  });

  group('two suppliers with different prices', () {
    late String id;
    late String supplierB;

    setUp(() async {
      id = await service.addManual(
        input(supplier: 'A', supply: 9500),
      ); // -> 15.000
      await service.addManual(
        input(supplier: 'B', supply: 45000),
      ); // other product
      supplierB = await supplierId('B');
    });

    test('highest basis uses the higher price', () async {
      final retail = await service.recordSupplierPrice(id, supplierB, 45000);
      expect(retail, 70000); // 45.000 -> 70.000
      expect((await product(id)).retailPrice, 70000);
    });

    test('lowest basis uses the lower price', () async {
      await setBasis('lowest');
      final retail = await service.recordSupplierPrice(id, supplierB, 45000);
      expect(retail, 15000);
    });

    test('latest basis uses the most recently observed price', () async {
      await setBasis('latest');
      await service.recordSupplierPrice(id, supplierB, 45000); // newest
      expect((await product(id)).retailPrice, 70000);

      // Supplier A quotes again later, lower: A's new price is now the latest.
      await service.recordSupplierPrice(id, await supplierId('A'), 9500);
      expect((await product(id)).retailPrice, 15000);
    });

    test(
      'only each supplier\'s newest price counts, history is kept',
      () async {
        final a = await supplierId('A');
        await service.recordSupplierPrice(id, supplierB, 45000);
        await service.recordSupplierPrice(
          id,
          supplierB,
          3000,
        ); // B drops its price
        // Highest of current prices: A 9.500 vs B 3.000 -> 15.000
        expect((await product(id)).retailPrice, 15000);

        final history = await (db.select(
          db.supplierPrices,
        )..where((s) => s.productId.equals(id) & s.supplierId.equals(a))).get();
        expect(history, hasLength(1));
        final bHistory =
            await (db.select(db.supplierPrices)..where(
                  (s) =>
                      s.productId.equals(id) & s.supplierId.equals(supplierB),
                ))
                .get();
        expect(bHistory, hasLength(2));
      },
    );
  });

  test('an override survives a new supplier price', () async {
    final id = await service.addManual(input(retail: 20000));
    final other = await service.addManual(input(supplier: 'B', supply: 90000));
    expect(other, isNotEmpty);
    await service.recordSupplierPrice(id, await supplierId('B'), 90000);

    final p = await product(id);
    expect(p.retailPrice, 20000);
    expect(p.retailIsOverride, 1);
  });

  test(
    'recalculating to the same price does not mark the product changed',
    () async {
      final id = await service.addManual(input());
      final before = (await product(id)).updatedAt;
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await service.recalcRetail(id);
      expect((await product(id)).updatedAt, before);
    },
  );

  test('preview returns retail and margin for a supply price', () async {
    final p = await service.preview(9500);
    expect(p.retail, 15000);
    expect(p.marginPct, closeTo(36.67, 0.01)); // (15000 - 9500) / 15000
  });

  test('new product shows up in products_to_publish', () async {
    final id = await service.addManual(input());
    final rows = await db
        .customSelect('SELECT id FROM products_to_publish')
        .get();
    expect(rows.map((r) => r.read<String>('id')), contains(id));
  });

  group('detail, history, override and delete', () {
    test('detail lists the latest price per supplier and the basis', () async {
      final id = await service.addManual(input(supply: 9500));
      await service.recordSupplierPrice(id, await supplierId('CV Maju'), 10000);
      await service.addManual(input(supplier: 'UD Jaya', supply: 8000));
      await service.recordSupplierPrice(id, await supplierId('UD Jaya'), 12000);

      final d = (await service.detail(id))!;
      expect(d.basis, 'highest');
      expect(d.basisSupply, 12000);
      expect(d.currentPrices.map((e) => (e.supplierName, e.unitPrice)), [
        ('CV Maju', 10000),
        ('UD Jaya', 12000),
      ]);
    });

    test('priceHistory keeps every price, newest first', () async {
      final id = await service.addManual(input(supply: 9500));
      await service.recordSupplierPrice(id, await supplierId('CV Maju'), 10000);
      final h = await service.priceHistory(id);
      expect(h.map((e) => e.unitPrice), [10000, 9500]);
    });

    test('setRetailOverride accepts any positive price', () async {
      final id = await service.addManual(input());
      await service.setRetailOverride(id, 17500);
      final p = await product(id);
      expect(p.retailPrice, 17500);
      expect(p.retailIsOverride, 1);
      expect(
        () => service.setRetailOverride(id, 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('archiveProduct is a soft delete and hides the product', () async {
      final id = await service.addManual(input());
      await service.archiveProduct(id);
      expect((await product(id)).deletedAt, isNotNull);
      expect(await service.detail(id), isNull);
      // Employees learn about the removal through the publish view.
      final rows = await db
          .customSelect('SELECT is_deleted FROM products_to_publish')
          .get();
      expect(rows.single.read<int>('is_deleted'), 1);
    });

    test('deleteArchivedProduct removes the product and its prices', () async {
      final keep = await service.addManual(input(supplier: 'A', supply: 9500));
      final gone = await service.addManual(input(supplier: 'B', supply: 45000));
      await service.recordSupplierPrice(gone, await supplierId('B'), 50000);
      await service.archiveProduct(gone);

      await service.deleteArchivedProduct(gone);

      expect(await db.select(db.products).get(), hasLength(1));
      final prices = await db.select(db.supplierPrices).get();
      expect(prices.map((p) => p.productId).toSet(), {keep});
    });

    test('only archived products can be deleted for good', () async {
      final id = await service.addManual(input());
      await expectLater(
        service.deleteArchivedProduct(id),
        throwsA(isA<ArgumentError>()),
      );
      expect(await db.select(db.products).get(), hasLength(1));
    });

    test(
      'an archive employees have not received yet blocks deletion',
      () async {
        final id = await service.addManual(input());
        // Published, then archived afterwards: the archive is not published.
        await db.customStatement(
          "UPDATE products SET published_at = '2026-10-01T00:00:00.000Z' "
          "WHERE id = '$id'",
        );
        await service.archiveProduct(id);
        await expectLater(
          service.deleteArchivedProduct(id),
          throwsA(isA<ArgumentError>()),
        );

        // Once the archive has been published (published_at = updated_at).
        await db.customStatement(
          'UPDATE products SET published_at = updated_at '
          "WHERE id = '$id'",
        );
        await service.deleteArchivedProduct(id);
        expect(await db.select(db.products).get(), isEmpty);
      },
    );

    test('restoreProduct brings it back with a recalculated price', () async {
      final id = await service.addManual(input()); // 9.500 -> 15.000
      final manual = await service.addManual(
        input(supply: 9500, retail: 17500),
      );
      await service.archiveProduct(id);
      await service.archiveProduct(manual);

      // Anchors change while both are archived: 9.500 now maps to 20.000.
      await PricingSettingsService(
        db,
        service,
      ).apply([for (final a in defaultAnchors) (a.$1, a.$2 + 5000)], 30);
      expect((await product(id)).retailPrice, 15000); // skipped while archived

      await service.restoreProduct(id);
      await service.restoreProduct(manual);
      expect((await product(id)).deletedAt, isNull);
      expect((await product(id)).retailPrice, 20000);
      expect((await product(manual)).retailPrice, 17500); // override kept
      expect(await service.detail(id), isNotNull);
    });
  });
}
