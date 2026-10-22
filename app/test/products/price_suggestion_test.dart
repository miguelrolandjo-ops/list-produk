import 'package:drift/native.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_application_1/data/owner_database.dart';
import 'package:flutter_application_1/inbox/po_import_service.dart';
import 'package:flutter_application_1/review/review_draft_loader.dart';
import 'package:flutter_application_1/review/review_service.dart';
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

  group('two prices with the same date (for example two POs on one day)', () {
    final day = DateTime.utc(2026, 10, 4);

    /// A product whose first price is dated [day], then a new PO price, also
    /// dated [day], recorded afterwards.
    Future<String> sameDay(int first, int second) async {
      final id = await add(supply: first);
      await db.customStatement(
        'UPDATE supplier_prices SET observed_at = ?',
        [day.toIso8601String()],
      );
      await service.recordSupplierPrice(
        id,
        await supplier('CV Maju'),
        second,
        observedAt: day,
      );
      return id;
    }

    test('the supplier price list shows the one recorded last', () async {
      final id = await sameDay(9500, 45000);
      final d = (await service.detail(id))!;
      expect(d.currentPrices.single.unitPrice, 45000);
    });

    test('the margin, the supplier list and the suggestion all agree', () async {
      final id = await sameDay(9500, 45000);
      final d = (await service.detail(id))!;
      expect(d.marginSupply, 45000);
      expect(d.currentPrices.single.unitPrice, d.marginSupply);
      // And the new price is offered as a retail suggestion (Saran harga).
      expect((await product(id)).pendingRetail, 70000);
      expect((await service.pendingSuggestions()).single.productId, id);
    });

    test('the history lists the one recorded last first', () async {
      final id = await sameDay(9500, 45000);
      expect((await service.priceHistory(id)).map((e) => e.unitPrice), [45000, 9500]);
    });

    test('a later PO on that day wins over an earlier one, however many there are', () async {
      final id = await sameDay(9500, 45000);
      await service.recordSupplierPrice(id, await supplier('CV Maju'), 12000, observedAt: day);
      expect((await service.detail(id))!.currentPrices.single.unitPrice, 12000);
      expect((await service.priceHistory(id)).first.unitPrice, 12000);
    });

    test('a price dated earlier than the current one still does not replace it', () async {
      final id = await add(supply: 9500); // dated "now"
      await service.recordSupplierPrice(
        id,
        await supplier('CV Maju'),
        45000,
        observedAt: DateTime.utc(2020, 1, 1),
      );
      expect((await service.detail(id))!.currentPrices.single.unitPrice, 9500);
    });

    test('importing and reviewing the same-dated PO twice updates everything', () async {
      // Exactly the flow that went wrong: the sample PO (dated 2026-10-04) is
      // reviewed once, then a new import of it comes in with a different price.
      final sample = jsonDecode(
        File('../shared/extraction_sample.json').readAsStringSync(),
      ) as Map<String, Object?>;
      final review = ReviewService(db, service);

      Future<void> importAndSave(String poId, int? price) async {
        final json = jsonDecode(jsonEncode(sample)) as Map<String, Object?>;
        final lines = json['lines']! as List;
        final cable = lines.firstWhere((l) => (l as Map)['name'] == 'Kabel Micro USB 1M') as Map;
        if (price != null) cable['unit_price'] = price;
        await db.customStatement(
          "INSERT INTO purchase_orders (id, status, source) VALUES (?, 'processing', 'gallery')",
          [poId],
        );
        await PoImportService(db).importResult(poId, jsonEncode(json));
        var d = await ReviewDraftLoader(db).load(poId);
        // Keep only the cable line.
        final i = d.lines.indexWhere((l) => l.rawName == 'Kabel Micro USB 1M');
        d = d.accept(i);
        for (var k = 0; k < d.lines.length; k++) {
          if (k != i) d = d.toggleIgnore(k);
        }
        await review.save(d.toReviewedPo());
      }

      await importAndSave('po1', null); // creates the product at 7.000
      final id = (await db
              .customSelect("SELECT id FROM products WHERE name = 'Kabel Micro USB 1M'")
              .getSingle())
          .read<String>('id');
      expect((await product(id)).retailPrice, isNotNull);

      await importAndSave('po2', 12000); // the same date, a higher price

      final d = (await service.detail(id))!;
      expect(d.currentPrices.single.unitPrice, 12000); // the supplier list changed
      expect(d.marginSupply, 12000); // the margin saw it too
      expect((await product(id)).pendingRetail, isNotNull); // and Saran harga appears
      expect((await service.priceHistory(id)).map((e) => e.unitPrice), [12000, 7000]);
    });
  });
}
