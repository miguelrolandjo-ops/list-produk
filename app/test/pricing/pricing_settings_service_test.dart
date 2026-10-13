import 'package:drift/native.dart';
import 'package:flutter_application_1/data/owner_database.dart';
import 'package:flutter_application_1/pricing/defaults.dart';
import 'package:flutter_application_1/pricing/pricing_settings_service.dart';
import 'package:flutter_application_1/products/product_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late OwnerDatabase db;
  late ProductService products;
  late PricingSettingsService service;

  setUp(() {
    db = OwnerDatabase(NativeDatabase.memory());
    products = ProductService(db);
    service = PricingSettingsService(db, products);
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

  Future<int?> retailOf(String id) async => (await (db.select(
    db.products,
  )..where((p) => p.id.equals(id))).getSingle()).retailPrice;

  group('validateAnchors', () {
    test('accepts the default anchors', () {
      expect(PricingSettingsService.validateAnchors(defaultAnchors), isNull);
    });

    test('rejects empty, non-positive, duplicate, off-step and falling', () {
      final v = PricingSettingsService.validateAnchors;
      expect(v([]), isNotNull);
      expect(v([(0, 5000)]), isNotNull);
      expect(v([(1000, 5000), (1000, 10000)]), contains('dua kali'));
      expect(v([(1000, 7500)]), contains('kelipatan'));
      expect(v([(1000, 10000), (2000, 10000)]), contains('naik'));
      expect(v([(2000, 15000), (1000, 20000)]), contains('naik'));
    });

    test('does not depend on the order of the list', () {
      expect(
        PricingSettingsService.validateAnchors([(2000, 10000), (1000, 5000)]),
        isNull,
      );
    });
  });

  group('preview and apply', () {
    // Default: 9.500 -> 15.000, 45.000 -> 70.000.
    // New anchors raise 10.000 -> 20.000, so 9.500 and 45.000 both change.
    final raised = [for (final a in defaultAnchors) (a.$1, a.$2 + 5000)];

    test(
      'preview lists changed products and counts overrides, writes nothing',
      () async {
        final a = await add('Kabel', 9500);
        await add('Charger', 45000, retail: 100000); // override
        final p = await service.preview(raised, 30);

        expect(p.changes.map((c) => c.name), ['Kabel']);
        expect(p.changes.single.oldPrice, 15000);
        expect(p.changes.single.newPrice, 20000);
        expect(p.overrideCount, 1);
        expect(await retailOf(a), 15000);
      },
    );

    test('apply saves anchors, markup and recalculates in one go', () async {
      final a = await add('Kabel', 9500);
      final changed = await service.apply(raised, 40);

      expect(changed, 1);
      expect(await retailOf(a), 20000);
      final anchors = await db.select(db.pricingAnchors).get();
      expect(anchors, hasLength(defaultAnchors.length));
      final s = await (db.select(db.settings)).getSingle();
      expect(s.aboveMarkupPct, 40);
    });

    test('an override survives an anchor change', () async {
      final o = await add('Charger', 45000, retail: 123000);
      await service.apply(raised, 30);
      expect(await retailOf(o), 123000);
    });

    test('apply refreshes the cached pricing config', () async {
      await products.pricingConfig(); // warm the cache
      await service.apply(raised, 30);
      expect((await products.pricingConfig()).calc(9500), 20000);
    });

    test('invalid anchors are rejected and nothing changes', () async {
      final a = await add('Kabel', 9500);
      await expectLater(
        service.apply([(1000, 5000), (2000, 5000)], 30),
        throwsArgumentError,
      );
      expect(await retailOf(a), 15000);
      expect(await db.select(db.pricingAnchors).get(), hasLength(18));
    });

    test('no change means zero changed products', () async {
      await add('Kabel', 9500);
      expect(await service.apply(defaultAnchors, 30), 0);
    });
  });
}
