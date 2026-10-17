import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_application_1/data/owner_database.dart';
import 'package:flutter_application_1/matching/match_repository.dart';
import 'package:flutter_application_1/matching/product_matcher.dart';
import 'package:flutter_application_1/products/product_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late OwnerDatabase db;
  late ProductService service;
  late MatchRepository repo;

  setUp(() {
    db = OwnerDatabase(NativeDatabase.memory());
    service = ProductService(db);
    repo = MatchRepository(db);
  });
  tearDown(() => db.close());

  Future<String> supplierId(String name) async => (await db
      .customSelect('SELECT id FROM suppliers WHERE name = ?', variables: [
        Variable.withString(name),
      ])
      .getSingle())
      .read<String>('id');

  Future<void> addAlias(String productId, String supplier, String alias) =>
      db.customStatement(
        'INSERT INTO product_aliases (id, product_id, supplier_id, alias, alias_norm) '
        'VALUES (?, ?, ?, ?, ?)',
        ['al-${alias.hashCode}', productId, supplier, alias, alias.toLowerCase()],
      );

  test('loads products with aliases and the latest supplier price', () async {
    final id = await service.addManual(
      const NewProductInput(
        name: 'Kabel USB-C',
        model: '1M',
        supplierName: 'CV Maju',
        supplyPrice: 9500,
      ),
    );
    final sup = await supplierId('CV Maju');
    await addAlias(id, sup, 'Kbl Type C 100cm');

    final c = (await repo.loadCandidates()).single;
    expect(c.productId, id);
    expect(c.name, 'Kabel USB-C');
    expect(c.model, '1M');
    expect(c.aliases.single.alias, 'Kbl Type C 100cm');
    expect(c.aliases.single.supplierId, sup);
    expect(c.lastPriceBySupplier, {sup: 9500});
  });

  test('archived products are left out', () async {
    final id = await service.addManual(
      const NewProductInput(
        name: 'Kabel Lama',
        supplierName: 'CV Maju',
        supplyPrice: 5000,
      ),
    );
    await db.customStatement(
      "UPDATE products SET deleted_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now') "
      'WHERE id = ?',
      [id],
    );
    expect(await repo.loadCandidates(), isEmpty);
  });

  test('buildMatcher auto-links a remembered alias end to end', () async {
    final id = await service.addManual(
      const NewProductInput(
        name: 'Kabel USB-C',
        supplierName: 'CV Maju',
        supplyPrice: 9500,
      ),
    );
    final sup = await supplierId('CV Maju');
    await addAlias(id, sup, 'kbl type c 100cm');

    final matcher = await repo.buildMatcher();
    final r = matcher.match(rawName: 'Kbl Type C 100CM', supplierId: sup);
    expect(r.status, MatchStatus.auto);
    expect(r.productId, id);
  });
}
