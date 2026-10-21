import 'package:drift/native.dart';
import 'package:flutter_application_1/data/owner_database.dart';
import 'package:flutter_application_1/pricing/bulk_adjust_service.dart';
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
    tick = 0;
    service = ProductService(db, now: () => DateTime.utc(2026, 10, 4, 8, tick++));
  });
  tearDown(() => db.close());

  Future<Product> product(String id) =>
      (db.select(db.products)..where((p) => p.id.equals(id))).getSingle();

  Future<String> add({
    String name = 'Kabel',
    String supplier = 'CV Maju',
    int supply = 9500,
    int? retail,
  }) => service.addManual(
    NewProductInput(
      name: name,
      supplierName: supplier,
      supplyPrice: supply,
      retailPrice: retail,
    ),
  );

  Future<String> supplier(String name) async => (await (db.select(
    db.suppliers,
  )..where((s) => s.name.equals(name))).getSingle()).id!;

  /// A new supply price from the product's own supplier.
  Future<void> newPrice(String id, int price, {String from = 'CV Maju'}) async =>
      service.recordSupplierPrice(id, await supplier(from), price);

  // Default anchors: 9.500 -> 15.000, 12.000 -> 20.000, 45.000 -> 70.000, 3.000 -> 10.000

  group('when a supplier price changes', () {
    test('a product\'s first price sets its retail price directly', () async {
      final id = await add();
      final p = await product(id);
      expect(p.retailPrice, 15000);
      expect(p.pendingRetail, isNull);
      expect(await service.pendingSuggestions(), isEmpty);
    });

    test('a higher price proposes a higher retail price and changes nothing yet', () async {
      final id = await add();
      await newPrice(id, 45000);

      final p = await product(id);
      expect(p.retailPrice, 15000); // not applied
      expect(p.pendingRetail, 70000);
      final s = (await service.pendingSuggestions()).single;
      expect((s.currentRetail, s.suggestedRetail, s.change), (15000, 70000, 55000));
    });

    test('a lower price proposes a lower retail price', () async {
      final id = await add(supply: 45000);
      expect((await product(id)).retailPrice, 70000);
      await newPrice(id, 9500);

      expect((await product(id)).retailPrice, 70000);
      expect((await product(id)).pendingRetail, 15000);
      expect((await service.pendingSuggestions()).single.change, -55000);
    });

    test('a price change that leaves the proper price the same proposes nothing', () async {
      final id = await add(supply: 9500);
      await newPrice(id, 9600); // still rounds to 15.000
      expect((await product(id)).pendingRetail, isNull);
    });

    test('a second change before answering replaces the suggestion', () async {
      final id = await add();
      await newPrice(id, 45000);
      expect((await product(id)).pendingRetail, 70000);
      await newPrice(id, 12000);
      expect((await product(id)).pendingRetail, 20000);
    });

    test('going back to the price the retail already matches clears it', () async {
      final id = await add();
      await newPrice(id, 45000);
      await newPrice(id, 9500);
      expect((await product(id)).pendingRetail, isNull);
    });

    test('proposing does not mark the product as changed for employees', () async {
      final id = await add();
      await db.customStatement('UPDATE products SET published_at = updated_at');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await newPrice(id, 45000);
      expect(await db.customSelect('SELECT id FROM products_to_publish').get(), isEmpty);
    });
  });

  group('manual prices are left alone', () {
    test('a product with a manual price gets no suggestion', () async {
      final id = await add(retail: 20000);
      await newPrice(id, 45000);
      final p = await product(id);
      expect(p.retailPrice, 20000);
      expect(p.pendingRetail, isNull);
      expect(await service.pendingSuggestions(), isEmpty);
    });

    test('setting a manual price clears a waiting suggestion', () async {
      final id = await add();
      await newPrice(id, 45000);
      await service.setRetailOverride(id, 25000);
      expect((await product(id)).pendingRetail, isNull);
      expect((await product(id)).retailPrice, 25000);
    });

    test('bulk adjust (saved as manual prices) clears waiting suggestions', () async {
      final id = await add();
      await newPrice(id, 45000);
      await BulkAdjustService(db).apply(
        const BulkAdjustInput.percent(10, maxSupply: 100000),
      );
      final p = await product(id);
      expect(p.retailIsOverride, 1);
      expect(p.pendingRetail, isNull);
    });
  });

  group('the owner answers', () {
    test('yes: the suggested price becomes the retail price', () async {
      final id = await add();
      await newPrice(id, 45000);
      await db.customStatement('UPDATE products SET published_at = updated_at');
      await Future<void>.delayed(const Duration(milliseconds: 5));

      await service.applySuggestion(id);

      final p = await product(id);
      expect(p.retailPrice, 70000);
      expect(p.pendingRetail, isNull);
      expect(p.retailIsOverride, 0); // still calculated: later changes propose again
      expect(await service.pendingSuggestions(), isEmpty);
      // The retail price changed, so employees get it.
      expect((await db.customSelect('SELECT id FROM products_to_publish').get()).length, 1);
    });

    test('no: the price stays and the suggestion is gone', () async {
      final id = await add();
      await newPrice(id, 45000);

      await service.dismissSuggestion(id);

      final p = await product(id);
      expect(p.retailPrice, 15000);
      expect(p.pendingRetail, isNull);
      expect(await service.pendingSuggestions(), isEmpty);
    });

    test('no: it is not asked again until the next price change', () async {
      final id = await add();
      await newPrice(id, 45000);
      await service.dismissSuggestion(id);

      // Other things happening do not bring it back.
      await service.updateProduct(id, name: 'Kabel baru', unit: 'pcs');
      await service.deleteProduct(id);
      await service.restoreProduct(id); // a plain undo: nothing new is asked
      expect((await product(id)).pendingRetail, isNull);
      expect(await service.pendingSuggestions(), isEmpty);

      // The next price change asks again.
      await newPrice(id, 12000);
      expect((await product(id)).pendingRetail, 20000);
      expect(await service.pendingSuggestions(), hasLength(1));
    });

    test('yes then another price change proposes again', () async {
      final id = await add();
      await newPrice(id, 45000);
      await service.applySuggestion(id);
      await newPrice(id, 12000);
      expect((await product(id)).retailPrice, 70000);
      expect((await product(id)).pendingRetail, 20000);
    });

    test('answering when nothing is waiting does nothing', () async {
      final id = await add();
      await service.applySuggestion(id);
      await service.dismissSuggestion(id);
      expect((await product(id)).retailPrice, 15000);
      await service.applySuggestion('missing'); // no such product: no error
    });
  });

  group('the list of suggestions', () {
    test('products that now sell below the margin limit come first', () async {
      final fine = await add(name: 'Alfa', supply: 9500);
      final urgent = await add(name: 'Zeta', supply: 9500);
      // Alfa's supplier price goes down: its margin only improves. Zeta's goes
      // up: its 15.000 retail price now sells below the margin limit.
      await newPrice(fine, 3000); // proper 5.000: lower, margin gets better
      await newPrice(urgent, 12000); // proper 20.000: 15.000 is now too low

      final list = await service.pendingSuggestions();
      expect(list.map((s) => s.name), ['Zeta', 'Alfa']);
      expect(list.first.belowMargin, isTrue);
      expect(list.last.belowMargin, isFalse);
      expect(list.first.marginSupply, 12000);
    });

    test('deleted products are not listed; Undo brings the suggestion back as it was', () async {
      final id = await add();
      await newPrice(id, 45000);
      await service.deleteProduct(id);
      expect(await service.pendingSuggestions(), isEmpty);
      await service.restoreProduct(id);
      expect((await service.pendingSuggestions()).single.suggestedRetail, 70000);
    });
  });

  group('changing the pricing rules', () {
    test('applying new anchors brings everything up to date and clears suggestions', () async {
      final id = await add();
      await newPrice(id, 45000);
      expect((await product(id)).pendingRetail, 70000);

      // The owner previews and confirms new anchors (+5.000 on every row).
      await PricingSettingsService(db, service).apply([
        for (final a in defaultAnchors) (a.$1, a.$2 + 5000),
      ], 30);

      final p = await product(id);
      expect(p.pendingRetail, isNull);
      expect(p.retailPrice, isNot(15000)); // recalculated, previewed first
    });

    test('a manual-price product is not touched by new anchors, as before', () async {
      final id = await add(retail: 20000);
      await PricingSettingsService(db, service).apply([
        for (final a in defaultAnchors) (a.$1, a.$2 + 5000),
      ], 30);
      expect((await product(id)).retailPrice, 20000);
    });
  });
}
