import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../pricing/defaults.dart';

part 'owner_database.g.dart';

@DriftDatabase(include: {'owner.drift'})
class OwnerDatabase extends _$OwnerDatabase {
  OwnerDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'owner'));

  // Bump this and add an onUpgrade step for every schema change.
  // Real data lives on the owner's phone, so reinstalling is never an option.
  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    // Runs once, when the database file is first created. Never on later
    // launches, so it can't overwrite anything the owner has edited.
    onCreate: (m) async {
      await m.createAll();
      await _seedDefaults();
    },
    onUpgrade: (m, from, to) async {
      // Each step must keep existing data: the owner's phone holds the real
      // catalog, so reinstalling is never an option.
      if (from < 2) {
        // Margin warning basis (separate from the retail basis).
        await customStatement(
          "ALTER TABLE settings ADD COLUMN margin_basis TEXT NOT NULL "
          "DEFAULT 'latest' CHECK (margin_basis IN ('latest', 'average'))",
        );
        await customStatement(
          'ALTER TABLE settings ADD COLUMN margin_avg_count INTEGER NOT NULL '
          'DEFAULT 3 CHECK (margin_avg_count BETWEEN 2 AND 20)',
        );
      }
      if (from < 3) {
        // Retail price proposed after a supplier price change, awaiting the
        // owner's confirmation.
        await customStatement(
          'ALTER TABLE products ADD COLUMN pending_retail INTEGER '
          'CHECK (pending_retail IS NULL OR pending_retail > 0)',
        );
      }
      if (from < 4) {
        // The last retail price change (for "Diubah 12 hari lalu (sebelumnya
        // ...)"), kept by a trigger.
        await customStatement(
          'ALTER TABLE products ADD COLUMN retail_prev INTEGER',
        );
        await customStatement(
          'ALTER TABLE products ADD COLUMN retail_changed_at TEXT',
        );
        await m.createTrigger(productsRetailChanged);
        // The "current price" view now breaks ties between prices with the same
        // date by which was recorded last. Without that, a second PO on the
        // same date was ignored by the supplier price list and by price
        // suggestions while the margin already used it.
        await m.drop(currentSupplierPrices);
        await m.createView(currentSupplierPrices);
      }
      if (from < 5) {
        // A recommended price the owner chose to ignore.
        await customStatement(
          'ALTER TABLE products ADD COLUMN ignored_recommendation INTEGER',
        );
      }
    },
  );

  Future<void> _seedDefaults() async {
    await customStatement('INSERT INTO settings (id) VALUES (1)');
    for (final (supply, retail) in defaultAnchors) {
      await customInsert(
        'INSERT INTO pricing_anchors (supply_price, retail_price) VALUES (?, ?)',
        variables: [Variable.withInt(supply), Variable.withInt(retail)],
      );
    }
    for (final (min, max, pct) in defaultMarginThresholds) {
      await customInsert(
        'INSERT INTO margin_thresholds (min_supply, max_supply, min_margin_pct) '
        'VALUES (?, ?, ?)',
        variables: [
          Variable.withInt(min),
          Variable<int>(max),
          Variable.withReal(pct),
        ],
      );
    }
  }
}
