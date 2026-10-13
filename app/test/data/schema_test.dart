import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/data/employee_database.dart';
import 'package:flutter_application_1/data/owner_database.dart';

void main() {
  test('owner schema opens and products_to_publish is queryable', () async {
    final db = OwnerDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.customStatement(
      "INSERT INTO products (id, name) VALUES ('p1', 'Kabel USB-C')",
    );
    final rows = await db
        .customSelect('SELECT id FROM products_to_publish')
        .get();
    expect(rows.map((r) => r.read<String>('id')), ['p1']);
  });

  test('employee FTS5 search finds partial words', () async {
    final db = EmployeeDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.customStatement(
      "INSERT INTO catalog (id, name, updated_at) VALUES ('c1', 'Kabel USB-C', 'x')",
    );
    final rows = await db
        .customSelect(
          "SELECT rowid FROM catalog_search WHERE catalog_search MATCH 'kab*'",
        )
        .get();
    expect(rows, hasLength(1));
  });
}

void seedTests() {
  test(
    'owner seeds settings, 18 anchors and 3 thresholds on first open',
    () async {
      final db = OwnerDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      Future<int> count(String table) async =>
          (await db
                  .customSelect('SELECT COUNT(*) AS n FROM $table')
                  .getSingle())
              .read<int>('n');
      expect(await count('settings'), 1);
      expect(await count('pricing_anchors'), 18);
      expect(await count('margin_thresholds'), 3);
    },
  );
}
