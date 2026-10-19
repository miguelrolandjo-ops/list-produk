import 'package:drift/drift.dart';

import '../data/owner_database.dart';
import '../products/product_service.dart';
import 'margin.dart';

/// One row of the margin screen: margin limit for supply prices below
/// [upTo] (exclusive). The last row has no upper limit (null).
typedef MarginLimit = (int? upTo, double pct);

/// Margin limits per supply range, and which products fall below them.
class MarginService {
  MarginService(this._db, this._products);

  final OwnerDatabase _db;
  final ProductService _products;

  /// Null when [limits] are usable, otherwise a message for the owner.
  static String? validate(List<MarginLimit> limits) {
    if (limits.isEmpty) return 'Minimal harus ada satu rentang';
    int? previous;
    for (var i = 0; i < limits.length; i++) {
      final (upTo, pct) = limits[i];
      final isLast = i == limits.length - 1;
      if (pct < 0 || pct >= 100) return 'Margin harus antara 0 dan 100%';
      if (isLast) {
        if (upTo != null) return 'Rentang terakhir harus tanpa batas atas';
      } else {
        if (upTo == null) return 'Hanya rentang terakhir tanpa batas atas';
        if (upTo <= 0 || (previous != null && upTo <= previous)) {
          return 'Batas atas harus makin besar';
        }
        previous = upTo;
      }
    }
    return null;
  }

  static List<MarginRange> toRanges(List<MarginLimit> limits) {
    var min = 0;
    final ranges = <MarginRange>[];
    for (final (upTo, pct) in limits) {
      ranges.add((min, upTo, pct));
      min = upTo ?? min;
    }
    return ranges;
  }

  static List<MarginLimit> toLimits(List<MarginRange> ranges) => [
    for (final (_, max, pct) in ranges) (max, pct),
  ];

  Future<List<MarginLimit>> load() async =>
      toLimits(await _products.marginThresholds());

  Future<void> save(List<MarginLimit> limits) async {
    final error = validate(limits);
    if (error != null) throw ArgumentError(error);
    await _db.transaction(() async {
      await _db.delete(_db.marginThresholds).go();
      for (final (min, max, pct) in toRanges(limits)) {
        await _db
            .into(_db.marginThresholds)
            .insert(
              MarginThresholdsCompanion.insert(
                minSupply: Value(min),
                maxSupply: Value(max),
                minMarginPct: pct,
              ),
            );
      }
    });
  }

  /// Which supply price the margin warning uses: 'latest' or 'average', and
  /// the number of POs averaged. Separate from the retail price basis.
  Future<({String basis, int count})> loadBasis() async {
    final s = await (_db.select(
      _db.settings,
    )..where((s) => s.id.equals(1))).getSingle();
    return (basis: s.marginBasis, count: s.marginAvgCount);
  }

  Future<void> saveBasis(String basis, int count) async {
    if (basis != 'latest' && basis != 'average') {
      throw ArgumentError('Dasar margin tidak dikenal');
    }
    if (count < 2 || count > 20) {
      throw ArgumentError('Jumlah PO harus antara 2 dan 20');
    }
    await (_db.update(_db.settings)..where((s) => s.id.equals(1))).write(
      SettingsCompanion(marginBasis: Value(basis), marginAvgCount: Value(count)),
    );
  }

  /// Ids of products whose margin is below the limit for their supply range.
  Future<Set<String>> productsBelowMargin() async {
    final ranges = await _products.marginThresholds();
    if (ranges.isEmpty) return {};
    final supplyByProduct = await _products.marginSupplyPrices();
    final products = await (_db.select(
      _db.products,
    )..where((p) => p.deletedAt.isNull() & p.retailPrice.isNotNull())).get();

    final flagged = <String>{};
    for (final p in products) {
      final supply = supplyByProduct[p.id];
      if (supply != null && isBelowMargin(supply, p.retailPrice, ranges)) {
        flagged.add(p.id!);
      }
    }
    return flagged;
  }
}
