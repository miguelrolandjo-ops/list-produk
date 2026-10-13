import 'package:drift/native.dart';
import 'package:flutter_application_1/data/owner_database.dart';
import 'package:flutter_application_1/pricing/bulk_adjust_service.dart';
import 'package:flutter_application_1/pricing/defaults.dart';
import 'package:flutter_application_1/pricing/margin.dart';
import 'package:flutter_application_1/pricing/margin_service.dart';
import 'package:flutter_application_1/pricing/pricing_settings_service.dart';
import 'package:flutter_application_1/products/product_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('minMarginFor / isBelowMargin', () {
    const ranges = defaultMarginThresholds;

    test('picks the range, lower bound inclusive, upper exclusive', () {
      expect(minMarginFor(1000, ranges), 30);
      expect(minMarginFor(64999, ranges), 30);
      expect(minMarginFor(65000, ranges), 15);
      expect(minMarginFor(399999, ranges), 15);
      expect(minMarginFor(400000, ranges), 20);
      expect(minMarginFor(5000000, ranges), 20);
    });

    test('flags only margins strictly below the limit', () {
      // 9.500 -> 15.000 is 36,7%: fine. 12.000 -> 15.000 is 20%: below 30%.
      expect(isBelowMargin(9500, 15000, ranges), isFalse);
      expect(isBelowMargin(12000, 15000, ranges), isTrue);
      // Exactly 30%: 7.000 -> 10.000.
      expect(isBelowMargin(7000, 10000, ranges), isFalse);
      expect(isBelowMargin(7000, null, ranges), isFalse);
      expect(isBelowMargin(7000, 10000, const []), isFalse);
    });
  });

  group('MarginService.validate', () {
    test('accepts the defaults and rejects broken lists', () {
      expect(
        MarginService.validate(MarginService.toLimits(defaultMarginThresholds)),
        isNull,
      );
      expect(MarginService.validate([]), isNotNull);
      expect(
        MarginService.validate([(1000, 30)]),
        isNotNull,
      ); // last needs null
      expect(MarginService.validate([(null, 30), (null, 20)]), isNotNull);
      expect(
        MarginService.validate([(5000, 30), (4000, 20), (null, 10)]),
        isNotNull,
      );
      expect(MarginService.validate([(null, 120)]), isNotNull);
      expect(MarginService.validate([(null, 25)]), isNull);
    });

    test('toRanges chains each range onto the previous upper bound', () {
      expect(
        MarginService.toRanges([(65000, 30), (400000, 15), (null, 20)]),
        defaultMarginThresholds,
      );
    });
  });

  group('with a database', () {
    late OwnerDatabase db;
    late ProductService products;
    late MarginService margins;
    late BulkAdjustService bulk;

    setUp(() {
      db = OwnerDatabase(NativeDatabase.memory());
      products = ProductService(db);
      margins = MarginService(db, products);
      bulk = BulkAdjustService(db);
    });
    tearDown(() => db.close());

    Future<String> add(String name, int supply, {int? retail}) =>
        products.addManual(
          NewProductInput(
            name: name,
            supplierName: 'CV Maju',
            supplyPrice: supply,
            retailPrice: retail,
          ),
        );

    Future<({int? retail, int override})> row(String id) async {
      final p = await (db.select(
        db.products,
      )..where((t) => t.id.equals(id))).getSingle();
      return (retail: p.retailPrice, override: p.retailIsOverride);
    }

    test(
      'save replaces the limits and productsBelowMargin uses them',
      () async {
        // 12.000 -> 20.000 (anchor) is 40%; override to 15.000 is 20%.
        final low = await add('Murah', 12000, retail: 15000);
        final ok = await add('Normal', 9500); // 36,7%
        expect(await margins.productsBelowMargin(), {low});

        await margins.save([(null, 15)]); // 15% everywhere
        expect(await margins.productsBelowMargin(), isEmpty);
        expect(await margins.load(), [(null, 15.0)]);

        await margins.save([(null, 40)]);
        expect(await margins.productsBelowMargin(), {low, ok});
      },
    );

    test('invalid limits are rejected and nothing is saved', () async {
      await expectLater(margins.save([(1000, 30)]), throwsArgumentError);
      expect(await margins.load(), hasLength(3));
    });

    test('detail carries the margin limit of the supply range', () async {
      final id = await add('Kabel', 9500);
      expect((await products.detail(id))!.minMarginPct, 30);
    });

    group('adjusted', () {
      test('percent rounds up to 5.000 and ignores float noise', () {
        const up10 = BulkAdjustInput.percent(10);
        expect(BulkAdjustService.adjusted(15000, up10), 20000); // 16.500
        expect(BulkAdjustService.adjusted(50000, up10), 55000); // exactly
        const down10 = BulkAdjustInput.percent(-10);
        expect(BulkAdjustService.adjusted(20000, down10), 20000); // 18.000
      });

      test('rupiah rounds up to 5.000', () {
        expect(
          BulkAdjustService.adjusted(15000, const BulkAdjustInput.rupiah(2000)),
          20000,
        );
        expect(
          BulkAdjustService.adjusted(
            15000,
            const BulkAdjustInput.rupiah(-3000),
          ),
          15000, // 12.000 rounds up
        );
      });

      test('never below the minimum retail price', () {
        expect(
          BulkAdjustService.adjusted(
            10000,
            const BulkAdjustInput.rupiah(-50000),
          ),
          5000,
        );
        expect(
          BulkAdjustService.adjusted(10000, const BulkAdjustInput.percent(-99)),
          5000,
        );
      });
    });

    test(
      'bulk apply changes only products in range and saves overrides',
      () async {
        final inRange = await add('Kabel', 9500); // 15.000
        final other = await add('Charger', 45000); // 70.000, out of range
        final manual = await add('Manual', 9000, retail: 25000); // override
        const input = BulkAdjustInput.rupiah(
          5000,
          minSupply: 5000,
          maxSupply: 20000,
        );

        final p = await bulk.preview(input);
        expect(p.changes.map((c) => c.name), ['Kabel']);
        expect(p.overrideCount, 1);
        expect((await row(inRange)).retail, 15000); // preview wrote nothing

        expect(await bulk.apply(input), 1);
        expect(await row(inRange), (retail: 20000, override: 1));
        expect(await row(other), (retail: 70000, override: 0));
        expect(await row(manual), (retail: 25000, override: 1));
      },
    );

    test(
      'a bulk-adjusted product is not touched by later anchor changes',
      () async {
        final id = await add('Kabel', 9500);
        await bulk.apply(const BulkAdjustInput.percent(20));
        final adjusted = (await row(id)).retail;

        await PricingSettingsService(
          db,
          products,
        ).apply([for (final a in defaultAnchors) (a.$1, a.$2 + 5000)], 30);
        expect((await row(id)).retail, adjusted);
      },
    );

    test(
      'a change that rounds to the same price does not become an override',
      () async {
        final id = await add('Kabel', 9500); // 15.000
        expect(await bulk.apply(const BulkAdjustInput.percent(1)), 1); // 15.150
        expect((await row(id)).retail, 20000);

        final same = await add('Sama', 9500);
        expect(await bulk.apply(const BulkAdjustInput.percent(0)), 0);
        expect((await row(same)).override, 0);
      },
    );
  });
}
