import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../backup/backup_service.dart';

import '../backup/backup_exporter.dart';
import '../data/owner_database.dart';
import '../pricing/bulk_adjust_service.dart';
import '../pricing/margin_service.dart';
import '../pricing/pricing_settings_service.dart';
import '../inbox/po_import_service.dart';
import '../products/product_service.dart';
import '../review/review_draft_loader.dart';
import '../review/review_service.dart';

final ownerDbProvider = Provider<OwnerDatabase>((ref) {
  final db = OwnerDatabase();
  ref.onDispose(db.close);
  return db;
});

final productServiceProvider = Provider<ProductService>(
  (ref) => ProductService(ref.watch(ownerDbProvider)),
);

final poImportServiceProvider = Provider<PoImportService>(
  (ref) => PoImportService(ref.watch(ownerDbProvider)),
);

final reviewDraftLoaderProvider = Provider<ReviewDraftLoader>(
  (ref) => ReviewDraftLoader(ref.watch(ownerDbProvider)),
);

final reviewServiceProvider = Provider<ReviewService>(
  (ref) => ReviewService(
    ref.watch(ownerDbProvider),
    ref.watch(productServiceProvider),
  ),
);

final pricingSettingsServiceProvider = Provider<PricingSettingsService>(
  (ref) => PricingSettingsService(
    ref.watch(ownerDbProvider),
    ref.watch(productServiceProvider),
  ),
);

final marginServiceProvider = Provider<MarginService>(
  (ref) => MarginService(
    ref.watch(ownerDbProvider),
    ref.watch(productServiceProvider),
  ),
);

final bulkAdjustServiceProvider = Provider<BulkAdjustService>(
  (ref) => BulkAdjustService(ref.watch(ownerDbProvider)),
);

/// Where the owner database lives (same place drift_flutter uses by default).
final backupExporterProvider = Provider<BackupExporter>(
  (ref) => PlatformBackupExporter(),
);

final backupServiceProvider = FutureProvider<BackupService>((ref) async {
  final documents = await getApplicationDocumentsDirectory();
  final temp = await getTemporaryDirectory();
  return BackupService(
    db: ref.watch(ownerDbProvider),
    databaseFile: File(p.join(documents.path, 'owner.sqlite')),
    tempDir: Directory(p.join(temp.path, 'backup')),
  );
});

class BackupStatus {
  const BackupStatus({required this.lastBackup, required this.productCount});
  final DateTime? lastBackup;
  final int productCount;
}

/// Last backup time and product count, for the backup screen and banner.
final backupStatusProvider = StreamProvider<BackupStatus>((ref) {
  final db = ref.watch(ownerDbProvider);
  return db
      .customSelect(
        'SELECT last_backup_at, (SELECT COUNT(*) FROM products) AS n '
        'FROM settings WHERE id = 1',
        readsFrom: {db.settings, db.products},
      )
      .watchSingle()
      .map((row) {
        final raw = row.readNullable<String>('last_backup_at');
        return BackupStatus(
          lastBackup: raw == null ? null : DateTime.tryParse(raw)?.toLocal(),
          productCount: row.read<int>('n'),
        );
      });
});

/// Ids of products below their margin limit. Recomputed whenever products,
/// supplier prices, limits or settings change.
final marginWarningsProvider = StreamProvider<Set<String>>((ref) async* {
  final db = ref.watch(ownerDbProvider);
  final service = ref.watch(marginServiceProvider);
  yield await service.productsBelowMargin();
  final changes = db.tableUpdates(
    TableUpdateQuery.onAllTables([
      db.products,
      db.supplierPrices,
      db.marginThresholds,
      db.settings,
    ]),
  );
  await for (final _ in changes) {
    yield await service.productsBelowMargin();
  }
});

/// Products that are not soft-deleted, by name. [query] is split into words;
/// every word must appear in the name or the model ("kabel c" finds
/// "Kabel USB-C"). Filtering happens in SQL, so the list stays cheap.
///
/// [ProductFilter.categoryId] null means all categories;
/// [uncategorizedFilter] means products without a category.
typedef ProductFilter = ({String query, String? categoryId});

const uncategorizedFilter = '-';

final productsProvider = StreamProvider.family<List<Product>, ProductFilter>((
  ref,
  filter,
) {
  final db = ref.watch(ownerDbProvider);
  final words = filter.query
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty);
  final categoryId = filter.categoryId;
  return (db.select(db.products)
        ..where((p) {
          Expression<bool> where = words.fold<Expression<bool>>(
            p.deletedAt.isNull(),
            (acc, w) => acc & (p.name.contains(w) | p.model.contains(w)),
          );
          if (categoryId == uncategorizedFilter) {
            where = where & p.categoryId.isNull();
          } else if (categoryId != null) {
            where = where & p.categoryId.equals(categoryId);
          }
          return where;
        })
        ..orderBy([(p) => OrderingTerm.asc(p.name)]))
      .watch();
});

class CategoryCount {
  const CategoryCount(this.id, this.name, this.count);
  final String id;
  final String name;
  final int count;
}

class CategoryCounts {
  const CategoryCounts({required this.categories, required this.uncategorized});
  final List<CategoryCount> categories;
  final int uncategorized;

  int get total => uncategorized + categories.fold(0, (s, c) => s + c.count);
}

/// Number of (not deleted) products per category, for the category menu.
final categoryCountsProvider = StreamProvider<CategoryCounts>((ref) async* {
  final db = ref.watch(ownerDbProvider);

  Future<CategoryCounts> load() async {
    final rows = await db
        .customSelect(
          'SELECT c.id AS id, c.name AS name, '
          '(SELECT COUNT(*) FROM products p '
          ' WHERE p.category_id = c.id AND p.deleted_at IS NULL) AS n '
          'FROM categories c ORDER BY c.name COLLATE NOCASE',
        )
        .get();
    final none = await db
        .customSelect(
          'SELECT COUNT(*) AS n FROM products '
          'WHERE category_id IS NULL AND deleted_at IS NULL',
        )
        .getSingle();
    return CategoryCounts(
      categories: [
        for (final r in rows)
          CategoryCount(
            r.read<String>('id'),
            r.read<String>('name'),
            r.read<int>('n'),
          ),
      ],
      uncategorized: none.read<int>('n'),
    );
  }

  yield await load();
  final changes = db.tableUpdates(
    TableUpdateQuery.onAllTables([db.products, db.categories]),
  );
  await for (final _ in changes) {
    yield await load();
  }
});

class SupplierCount {
  const SupplierCount(this.id, this.name, this.count);
  final String id;
  final String name;

  /// Products (not deleted) that have a price from this supplier.
  final int count;
}

/// Every supplier with the number of products it has prices for, for
/// "Kelola supplier".
final supplierCountsProvider = StreamProvider<List<SupplierCount>>((ref) async* {
  final db = ref.watch(ownerDbProvider);

  Future<List<SupplierCount>> load() async => [
    for (final r in await db
        .customSelect(
          'SELECT s.id AS id, s.name AS name, ('
          ' SELECT COUNT(DISTINCT sp.product_id) FROM supplier_prices sp'
          ' JOIN products p ON p.id = sp.product_id'
          ' WHERE sp.supplier_id = s.id AND p.deleted_at IS NULL) AS n '
          'FROM suppliers s ORDER BY s.name COLLATE NOCASE',
        )
        .get())
      SupplierCount(
        r.read<String>('id'),
        r.read<String>('name'),
        r.read<int>('n'),
      ),
  ];

  yield await load();
  final changes = db.tableUpdates(
    TableUpdateQuery.onAllTables([db.suppliers, db.supplierPrices, db.products]),
  );
  await for (final _ in changes) {
    yield await load();
  }
});

/// Retail price suggestions waiting for the owner (most urgent first),
/// recomputed whenever products, prices, limits or settings change.
final priceSuggestionsProvider = StreamProvider<List<PriceSuggestion>>((
  ref,
) async* {
  final db = ref.watch(ownerDbProvider);
  final service = ref.watch(productServiceProvider);
  yield await service.pendingSuggestions();
  final changes = db.tableUpdates(
    TableUpdateQuery.onAllTables([
      db.products,
      db.supplierPrices,
      db.marginThresholds,
      db.settings,
    ]),
  );
  await for (final _ in changes) {
    yield await service.pendingSuggestions();
  }
});

final productDetailProvider = FutureProvider.autoDispose
    .family<ProductDetail?, String>(
      (ref, id) => ref.watch(productServiceProvider).detail(id),
    );
