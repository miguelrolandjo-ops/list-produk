import 'package:drift/native.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/data/owner_database.dart';
import 'package:flutter_application_1/products/product_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late OwnerDatabase db;
  late ProviderContainer container;
  late ProductService service;

  setUp(() async {
    db = OwnerDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [ownerDbProvider.overrideWithValue(db)],
    );
    service = container.read(productServiceProvider);
    Future<void> add(String name, String? category) => service.addManual(
      NewProductInput(
        name: name,
        categoryName: category,
        supplierName: 'CV Maju',
        supplyPrice: 9500,
      ),
    );
    await add('Kabel USB-C', 'Kabel');
    await add('Kabel Lightning', 'Kabel');
    await add('Charger 20W', 'Charger');
    await add('Casing', null);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<List<String>> names(String? categoryId, [String query = '']) async {
    final provider = productsProvider((query: query, categoryId: categoryId));
    // Riverpod 3 pauses a provider nobody listens to, so listen first.
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);
    final items = await container.read(provider.future);
    return [for (final p in items) p.name];
  }

  Future<String> idOf(String category) async => (await (db.select(
    db.categories,
  )..where((c) => c.name.equals(category))).getSingle()).id!;

  test('no category filter shows everything', () async {
    expect(await names(null), hasLength(4));
  });

  test('filters by category and combines with the search words', () async {
    expect(await names(await idOf('Kabel')), [
      'Kabel Lightning',
      'Kabel USB-C',
    ]);
    expect(await names(await idOf('Kabel'), 'usb'), ['Kabel USB-C']);
    expect(await names(await idOf('Charger'), 'usb'), isEmpty);
  });

  test('uncategorized filter shows products without a category', () async {
    expect(await names(uncategorizedFilter), ['Casing']);
  });

  test('counts per category skip archived products', () async {
    container.listen(categoryCountsProvider, (_, _) {});
    var counts = await container.read(categoryCountsProvider.future);
    expect(
      {for (final c in counts.categories) c.name: c.count},
      {'Charger': 1, 'Kabel': 2},
    );
    expect(counts.uncategorized, 1);
    expect(counts.total, 4);

    final products = await db.select(db.products).get();
    final casing = products.firstWhere((p) => p.name == 'Casing');
    await service.archiveProduct(casing.id!);

    container.invalidate(categoryCountsProvider);
    counts = await container.read(categoryCountsProvider.future);
    expect(counts.uncategorized, 0);
    expect(counts.total, 3);
  });
}
