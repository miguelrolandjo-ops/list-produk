import 'package:drift/native.dart';
import 'package:flutter_application_1/data/owner_database.dart';
import 'package:flutter_application_1/pricing/margin.dart';
import 'package:flutter_application_1/pricing/margin_service.dart';
import 'package:flutter_application_1/products/product_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('recommendedRetail', () {
    int rec(int supply, double limit, {int calculated = 0, int roundTo = 5000}) =>
        recommendedRetail(
          supply: supply,
          minMarginPct: limit,
          calculated: calculated,
          roundTo: roundTo,
        );

    test('the smallest rounded price that reaches the limit', () {
      expect(rec(12000, 30), 20000); // 12.000 / 0.7 = 17.143 -> 20.000
      expect(rec(9500, 30), 15000); // 13.572 -> 15.000
    });

    test('a price that meets the limit exactly is not pushed up a step', () {
      expect(rec(7000, 30), 10000); // exactly 30%: 7.000 / 0.7 = 10.000
      expect(marginPct(7000, 10000), closeTo(30, 1e-9));
      expect(rec(10000, 50), 20000); // exactly 50%
    });

    test('never below the normal calculated price', () {
      expect(rec(9500, 30, calculated: 25000), 25000);
      expect(rec(9500, 30, calculated: 10000), 15000); // the limit is higher
    });

    test('the result always reaches the limit', () {
      for (final supply in [1500, 3000, 9500, 12000, 45000, 64999, 130000, 330000]) {
        for (final limit in [0.0, 10.0, 15.0, 30.0, 49.5]) {
          final p = rec(supply, limit);
          expect(marginPct(supply, p)!, greaterThanOrEqualTo(limit - 1e-9));
          expect(p % 5000, 0);
        }
      }
    });

    test('respects another rounding step', () {
      expect(rec(12000, 30, roundTo: 1000), 18000); // 17.143 -> 18.000
    });
  });

  group('ProductService.recommendation', () {
    late OwnerDatabase db;
    late ProductService service;
    late MarginService margins;
    var tick = 0;

    setUp(() {
      db = OwnerDatabase(NativeDatabase.memory());
      tick = 0;
      service = ProductService(db, now: () => DateTime.utc(2026, 10, 4, 8, tick++));
      margins = MarginService(db, service);
    });
    tearDown(() => db.close());

    Future<String> add({int supply = 9500, int? retail, String name = 'Kabel'}) =>
        service.addManual(
          NewProductInput(
            name: name,
            supplierName: 'CV Maju',
            supplyPrice: supply,
            retailPrice: retail,
          ),
        );

    Future<void> newPrice(String id, int price) async => service.recordSupplierPrice(
      id,
      await service.findOrCreateSupplier('CV Maju'),
      price,
    );

    Future<Product> product(String id) =>
        (db.select(db.products)..where((p) => p.id.equals(id))).getSingle();

    test('a product within its margin limit gets no recommendation', () async {
      final id = await add(); // 9.500 -> 15.000: 36,7% >= 30%
      expect(await service.recommendation(id), isNull);
    });

    test('below the limit: recommends the waiting suggestion when it reaches the limit', () async {
      final id = await add();
      await newPrice(id, 12000); // 15.000 is now 20% (< 30%); suggestion 20.000
      final r = (await service.recommendation(id))!;
      expect(r.currentRetail, 15000);
      expect(r.recommendedRetail, 20000);
      expect(r.marginSupply, 12000);
      expect(r.minMarginPct, 30);
      expect(r.currentMargin, closeTo(20, 0.001));
      expect(r.recommendedMargin, closeTo(40, 0.001));
    });

    test('applying changes the price, clears the suggestion, and it stays calculated', () async {
      final id = await add();
      await newPrice(id, 12000);
      await service.applyRecommendation(id);

      final p = await product(id);
      expect(p.retailPrice, 20000);
      expect(p.pendingRetail, isNull);
      expect(p.retailIsOverride, 0);
      expect(p.retailPrev, 15000); // remembered for "sebelumnya"
      expect(await service.recommendation(id), isNull); // no longer below the limit
    });

    test('ignoring hides the card only while the recommendation stays the same', () async {
      final id = await add();
      await newPrice(id, 12000); // recommends 20.000
      expect((await service.detail(id))!.recommendationIgnored, isFalse);

      await service.ignoreRecommendation(id);
      var d = (await service.detail(id))!;
      expect(d.recommendationIgnored, isTrue);
      expect(d.recommendation!.recommendedRetail, 20000); // dialog still offers it
      expect((await product(id)).retailPrice, 15000); // nothing changed

      await newPrice(id, 18000); // a different recommendation: ask again
      d = (await service.detail(id))!;
      expect(d.recommendation!.recommendedRetail, isNot(20000));
      expect(d.recommendationIgnored, isFalse);
    });

    test('ignoring without a recommendation does nothing', () async {
      final id = await add();
      await service.ignoreRecommendation(id);
      expect((await product(id)).ignoredRecommendation, isNull);
    });

    test('addSupplierPrice adds a supplier and counts for the margin', () async {
      final id = await add();
      await service.addSupplierPrice(id, supplierName: 'UD Baru', unitPrice: 12000);
      final d = (await service.detail(id))!;
      expect(d.currentPrices.map((e) => e.supplierName), containsAll(['CV Maju', 'UD Baru']));
      expect(d.marginSupply, 12000); // the latest PO price
      expect(d.recommendation, isNotNull); // 15.000 is now 20% (< 30%)
    });

    test('addSupplierPrice refuses a supplier the product already has, and bad input', () async {
      final id = await add();
      expect(
        () => service.addSupplierPrice(id, supplierName: 'cv maju', unitPrice: 9000),
        throwsArgumentError,
      );
      expect(
        () => service.addSupplierPrice(id, supplierName: ' ', unitPrice: 9000),
        throwsArgumentError,
      );
      expect(
        () => service.addSupplierPrice(id, supplierName: 'UD Baru', unitPrice: 0),
        throwsArgumentError,
      );
      expect((await service.detail(id))!.currentPrices, hasLength(1));
    });

    test('a manual price below the limit gets a recommendation and stays manual', () async {
      final id = await add(retail: 11000); // 13,6% margin at 9.500
      final r = (await service.recommendation(id))!;
      expect(r.recommendedRetail, 15000);

      await service.applyRecommendation(id);
      final p = await product(id);
      expect(p.retailPrice, 15000);
      expect(p.retailIsOverride, 1); // the owner's manual price stays manual
    });

    test('a selling-at-a-loss price is recommended too', () async {
      final id = await add(retail: 5000); // below the 9.500 supply price
      expect((await service.recommendation(id))!.recommendedRetail, 15000);
    });

    test('a stricter limit gives a higher price than the calculated one', () async {
      await margins.save([(null, 50.0)]); // 50% everywhere
      final id = await add(retail: 15000);
      // 9.500 / 0.5 = 19.000 -> 20.000, above the calculated 15.000.
      expect((await service.recommendation(id))!.recommendedRetail, 20000);
    });

    test('follows the margin basis: the latest PO price', () async {
      final id = await add(supply: 12000); // retail 20.000 (40%)
      expect(await service.recommendation(id), isNull);
      await newPrice(id, 18000); // 20.000 is now 10% margin
      final r = (await service.recommendation(id))!;
      expect(r.marginSupply, 18000);
      expect(r.recommendedRetail, 30000); // 18.000 / 0.7 = 25.714 -> 30.000
    });

    test('nothing to recommend without a retail price, a limit, or when deleted', () async {
      expect(await service.recommendation('missing'), isNull);
      final id = await add(retail: 5000);
      expect(await service.recommendation(id), isNotNull);
      await service.deleteProduct(id);
      expect(await service.recommendation(id), isNull);
    });

    test('applying when it is no longer needed changes nothing', () async {
      final id = await add();
      await service.applyRecommendation(id);
      expect((await product(id)).retailPrice, 15000);
      expect((await product(id)).retailPrev, isNull);
    });
  });
}
