import 'package:drift/drift.dart';

import '../data/owner_database.dart';
import 'basis.dart';
import 'pricing_settings_service.dart';

/// A bulk change to retail prices of products in a supply price range.
/// Exactly one of [percent] / [rupiah] is set; negative values lower prices.
class BulkAdjustInput {
  const BulkAdjustInput.percent(
    double this.percent, {
    this.minSupply = 0,
    this.maxSupply,
  }) : rupiah = null;

  const BulkAdjustInput.rupiah(
    int this.rupiah, {
    this.minSupply = 0,
    this.maxSupply,
  }) : percent = null;

  /// Supply price range, both ends inclusive. [maxSupply] null = no limit.
  final int minSupply;
  final int? maxSupply;
  final double? percent;
  final int? rupiah;
}

/// "Ubah massal per rentang". Results are saved as overrides, otherwise the
/// next recalculation would undo them.
class BulkAdjustService {
  BulkAdjustService(this._db);

  final OwnerDatabase _db;

  /// New retail price: adjusted, rounded UP to [roundTo], never below
  /// [minRetail].
  static int adjusted(
    int current,
    BulkAdjustInput input, {
    int minRetail = 5000,
    int roundTo = 5000,
  }) {
    final percent = input.percent;
    final int next;
    if (percent != null) {
      // The epsilon keeps 1.1 * 100000 from rounding up a whole step because
      // of binary floating point.
      final v = current * (100 + percent) / 100;
      next = ((v / roundTo) - 1e-9).ceil() * roundTo;
    } else {
      final v = current + input.rupiah!;
      next = v <= 0 ? 0 : ((v + roundTo - 1) ~/ roundTo) * roundTo;
    }
    return next < minRetail ? minRetail : next;
  }

  /// Products that would change. Products with a manual price are skipped
  /// and counted in [PricingPreview.overrideCount]. Reads only.
  Future<PricingPreview> preview(BulkAdjustInput input) async {
    final s = await (_db.select(
      _db.settings,
    )..where((t) => t.id.equals(1))).getSingle();
    final products = await (_db.select(
      _db.products,
    )..where((p) => p.deletedAt.isNull() & p.retailPrice.isNotNull())).get();
    final byProduct = <String, List<({int unitPrice, String observedAt})>>{};
    for (final c in await _db.select(_db.currentSupplierPrices).get()) {
      (byProduct[c.productId] ??= []).add((
        unitPrice: c.unitPrice,
        observedAt: c.observedAt,
      ));
    }

    final changes = <PriceChange>[];
    var overrides = 0;
    for (final p in products) {
      final supply = pickBasisSupply(s.basis, byProduct[p.id] ?? const []);
      if (supply == null || supply < input.minSupply) continue;
      if (input.maxSupply != null && supply > input.maxSupply!) continue;
      if (p.retailIsOverride == 1) {
        overrides++;
        continue;
      }
      final next = adjusted(
        p.retailPrice!,
        input,
        minRetail: s.minRetail,
        roundTo: s.roundTo,
      );
      if (next != p.retailPrice) {
        changes.add(
          PriceChange(
            productId: p.id!,
            name: p.name,
            oldPrice: p.retailPrice,
            newPrice: next,
          ),
        );
      }
    }
    changes.sort((a, b) => a.name.compareTo(b.name));
    return PricingPreview(changes: changes, overrideCount: overrides);
  }

  /// Applies the change in one transaction and marks every changed product as
  /// an override. Returns how many products changed.
  Future<int> apply(BulkAdjustInput input) async {
    final preview = await this.preview(input);
    await _db.transaction(() async {
      for (final c in preview.changes) {
        await (_db.update(
          _db.products,
        )..where((p) => p.id.equals(c.productId))).write(
          ProductsCompanion(
            retailPrice: Value(c.newPrice),
            retailIsOverride: const Value(1),
          ),
        );
      }
    });
    return preview.changes.length;
  }
}
