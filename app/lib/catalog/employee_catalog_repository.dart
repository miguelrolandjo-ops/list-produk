import 'package:drift/drift.dart';

import '../core/server_api.dart';
import '../data/employee_database.dart';

/// One product as an employee sees it: no supplier, no supply price, no margin.
class CatalogEntry {
  const CatalogEntry({
    required this.id,
    required this.name,
    this.model,
    this.category,
    required this.unit,
    this.retailPrice,
  });

  final String id;
  final String name;
  final String? model;
  final String? category;
  final String unit;
  final int? retailPrice;
}

/// Category filter value for products without a category.
const noCategoryFilter = '-';

/// The employee's local copy of the catalog (employee.drift), searchable
/// offline with FTS5.
class EmployeeCatalogRepository {
  EmployeeCatalogRepository(this._db);

  final EmployeeDatabase _db;

  /// Applies rows from employee_catalog(): upserts, and removes deleted ones.
  Future<void> apply(List<CatalogRow> rows) => _db.transaction(() async {
    for (final r in rows) {
      if (r.isDeleted) {
        await _db.customUpdate(
          'DELETE FROM catalog WHERE id = ?',
          variables: [Variable.withString(r.id)],
          updates: {_db.catalog},
          updateKind: UpdateKind.delete,
        );
        continue;
      }
      await _db.customInsert(
        'INSERT INTO catalog '
        '(id, name, model, category, unit, photo_path, retail_price, updated_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?) '
        'ON CONFLICT (id) DO UPDATE SET name = excluded.name, '
        'model = excluded.model, category = excluded.category, '
        'unit = excluded.unit, photo_path = excluded.photo_path, '
        'retail_price = excluded.retail_price, updated_at = excluded.updated_at',
        variables: [
          Variable.withString(r.id),
          Variable.withString(r.name),
          Variable<String>(r.model),
          Variable<String>(r.category),
          Variable.withString(r.unit),
          Variable<String>(r.photoPath),
          Variable<int>(r.retailPrice),
          Variable.withString(r.updatedAt),
        ],
        updates: {_db.catalog},
      );
    }
  });

  /// Empties the catalog (leaving the store, or access revoked).
  Future<void> clear() => _db.customUpdate(
    'DELETE FROM catalog',
    updates: {_db.catalog},
    updateKind: UpdateKind.delete,
  );

  /// The FTS5 query for what was typed: every word must match the start of a
  /// word in the name, model or category ("kab ty" finds "Kabel Type C").
  /// Punctuation splits words, like the index does ("usb-c" = "usb" + "c").
  /// Null when nothing searchable was typed.
  static String? ftsQuery(String typed) {
    final words = typed
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty);
    if (words.isEmpty) return null;
    return words.map((w) => '"$w"*').join(' ');
  }

  /// Products matching [query] (all when empty) in [category] (all when null,
  /// uncategorised for [noCategoryFilter]). Re-emits when the catalog changes.
  Stream<List<CatalogEntry>> watchSearch(String query, {String? category}) {
    final fts = ftsQuery(query);
    final where = <String>[];
    final vars = <Variable>[];
    if (fts != null) {
      where.add('c.rowid IN (SELECT rowid FROM catalog_search '
          'WHERE catalog_search MATCH ?)');
      vars.add(Variable.withString(fts));
    }
    if (category == noCategoryFilter) {
      where.add('c.category IS NULL');
    } else if (category != null) {
      where.add('c.category = ?');
      vars.add(Variable.withString(category));
    }
    final sql =
        'SELECT c.id, c.name, c.model, c.category, c.unit, c.retail_price '
        'FROM catalog c'
        '${where.isEmpty ? '' : ' WHERE ${where.join(' AND ')}'} '
        'ORDER BY c.name COLLATE NOCASE';
    return _db
        .customSelect(sql, variables: vars, readsFrom: {_db.catalog})
        .watch()
        .map(
          (rows) => [
            for (final r in rows)
              CatalogEntry(
                id: r.read<String>('id'),
                name: r.read<String>('name'),
                model: r.readNullable<String>('model'),
                category: r.readNullable<String>('category'),
                unit: r.read<String>('unit'),
                retailPrice: r.readNullable<int>('retail_price'),
              ),
          ],
        );
  }

  Future<List<CatalogEntry>> search(String query, {String? category}) =>
      watchSearch(query, category: category).first;

  /// Category names in the catalog, alphabetically.
  Stream<List<String>> watchCategories() => _db
      .customSelect(
        'SELECT DISTINCT category FROM catalog WHERE category IS NOT NULL '
        'ORDER BY category COLLATE NOCASE',
        readsFrom: {_db.catalog},
      )
      .watch()
      .map((rows) => [for (final r in rows) r.read<String>('category')]);

  Future<int> count() async => (await _db
          .customSelect('SELECT COUNT(*) AS n FROM catalog')
          .getSingle())
      .read<int>('n');
}
