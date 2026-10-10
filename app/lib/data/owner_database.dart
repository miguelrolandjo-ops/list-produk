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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    // Runs once, when the database file is first created. Never on later
    // launches, so it can't overwrite anything the owner has edited.
    onCreate: (m) async {
      await m.createAll();
      await _seedDefaults();
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
