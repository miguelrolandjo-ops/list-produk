import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_application_1/data/owner_database.dart';
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

  Future<String> add(String name, String supplier, int supply) => service.addManual(
    NewProductInput(name: name, supplierName: supplier, supplyPrice: supply),
  );

  Future<String> supplierId(String name) async =>
      (await db.customSelect('SELECT id FROM suppliers WHERE name = ?', variables: [
        Variable.withString(name),
      ]).getSingle())
          .read<String>('id');

  Future<void> price(String product, String supplier, int amount) async =>
      service.recordSupplierPrice(
        product,
        await service.findOrCreateSupplier(supplier),
        amount,
      );

  Future<Product> product(String id) =>
      (db.select(db.products)..where((p) => p.id.equals(id))).getSingle();

  Future<int> count(String sql) async =>
      (await db.customSelect(sql).getSingle()).read<int>('n');

  test('removes the supplier with its prices and product names, keeps the products', () async {
    final a = await add('Kabel', 'CV Maju', 9500);
    final b = await add('Charger', 'CV Maju', 45000);
    await price(a, 'CV Maju', 9600);
    await db.customStatement(
      "INSERT INTO product_aliases (id, product_id, supplier_id, alias, alias_norm) "
      "VALUES ('al1', '$a', '${await supplierId('CV Maju')}', 'Kbl', 'kbl')",
    );

    final affected = await service.deleteSupplier(await supplierId('CV Maju'));

    expect(affected, 2); // both products had a price from it
    expect(await count('SELECT COUNT(*) AS n FROM suppliers'), 0);
    expect(await count('SELECT COUNT(*) AS n FROM supplier_prices'), 0);
    expect(await count('SELECT COUNT(*) AS n FROM product_aliases'), 0);
    // The products themselves are still there.
    expect(await count('SELECT COUNT(*) AS n FROM products WHERE deleted_at IS NULL'), 2);
    expect((await product(a)).name, 'Kabel');
    expect((await product(b)).name, 'Charger');
  });

  test('other suppliers are untouched', () async {
    final id = await add('Kabel', 'CV Maju', 9500);
    await price(id, 'Toko Lain', 12000);

    await service.deleteSupplier(await supplierId('CV Maju'));

    final d = (await service.detail(id))!;
    expect(d.currentPrices.single.supplierName, 'Toko Lain');
    expect(d.currentPrices.single.unitPrice, 12000);
    expect(await count('SELECT COUNT(*) AS n FROM suppliers'), 1);
  });

  test('past POs are kept, without a supplier', () async {
    await add('Kabel', 'CV Maju', 9500);
    final sup = await supplierId('CV Maju');
    await db.customStatement(
      "INSERT INTO purchase_orders (id, status, source, supplier_id) VALUES ('po1', 'saved', 'gallery', '$sup')",
    );
    await service.deleteSupplier(sup);
    final po = (await db.customSelect('SELECT supplier_id FROM purchase_orders').getSingle());
    expect(po.read<String?>('supplier_id'), isNull);
  });

  test('retail prices are not changed behind the owner\'s back: the new one is proposed', () async {
    // A quotes 45.000 (retail 70.000), B quotes 9.500. Highest drives the price.
    final id = await add('Kabel', 'A', 45000);
    await price(id, 'B', 9500);
    expect((await product(id)).retailPrice, 70000);
    expect((await product(id)).pendingRetail, isNull);

    await service.deleteSupplier(await supplierId('A'));

    final p = await product(id);
    expect(p.retailPrice, 70000); // unchanged
    expect(p.pendingRetail, 15000); // B's 9.500 is what is left: proposed
    expect((await service.pendingSuggestions()).single.suggestedRetail, 15000);
  });

  test('removing the last supplier clears a suggestion that had nothing left to rest on', () async {
    final id = await add('Kabel', 'CV Maju', 9500);
    await price(id, 'CV Maju', 45000); // suggestion 70.000 waiting
    expect((await product(id)).pendingRetail, 70000);

    await service.deleteSupplier(await supplierId('CV Maju'));

    final p = await product(id);
    expect(p.retailPrice, 15000); // its price stays
    expect(p.pendingRetail, isNull);
    expect((await service.detail(id))!.currentPrices, isEmpty);
    expect((await service.detail(id))!.marginSupply, isNull);
  });

  test('deleted products lose the prices too, but are not counted', () async {
    final live = await add('Kabel', 'CV Maju', 9500);
    final gone = await add('Lama', 'CV Maju', 5000);
    await service.deleteProduct(gone);

    final affected = await service.deleteSupplier(await supplierId('CV Maju'));

    expect(affected, 1);
    expect(await count('SELECT COUNT(*) AS n FROM supplier_prices'), 0);
    expect(live, isNotEmpty);
  });

  test('a supplier with no prices can be deleted; an unknown id changes nothing', () async {
    await add('Kabel', 'CV Maju', 9500);
    await db.customStatement("INSERT INTO suppliers (id, name) VALUES ('s9', 'Kosong')");
    expect(await service.deleteSupplier('s9'), 0);
    expect(await count('SELECT COUNT(*) AS n FROM suppliers'), 1);

    expect(await service.deleteSupplier('nope'), 0);
    expect(await count('SELECT COUNT(*) AS n FROM suppliers'), 1);
    expect(await count('SELECT COUNT(*) AS n FROM supplier_prices'), 1);
  });

  test('a supplier with the same name can be added again afterwards', () async {
    await add('Kabel', 'CV Maju', 9500);
    await service.deleteSupplier(await supplierId('CV Maju'));
    final id = await add('Charger', 'CV Maju', 12000); // creates it again
    expect((await service.detail(id))!.currentPrices.single.supplierName, 'CV Maju');
  });
}
