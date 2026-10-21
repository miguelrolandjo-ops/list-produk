import 'package:drift/drift.dart';

import '../data/owner_database.dart';
import '../products/product_service.dart';
import 'basis.dart';
import 'defaults.dart';

class PriceChange {
  const PriceChange({
    required this.productId,
    required this.name,
    required this.oldPrice,
    required this.newPrice,
  });
  final String productId;
  final String name;
  final int? oldPrice;
  final int newPrice;
}

class PricingPreview {
  const PricingPreview({required this.changes, required this.overrideCount});

  /// Products whose retail price would change.
  final List<PriceChange> changes;

  /// Products with a manual price. They are never recalculated.
  final int overrideCount;
}

/// Editing the anchors and markup, and recalculating products afterwards.
/// No UI dependencies.
class PricingSettingsService {
  PricingSettingsService(this._db, this._products);

  final OwnerDatabase _db;
  final ProductService _products;

  /// Null when [anchors] are usable, otherwise a message for the owner.
  /// Rules: supply prices are unique and positive, retail prices are
  /// multiples of Rp 5.000, and retail rises with supply.
  static String? validateAnchors(List<Anchor> anchors) {
    if (anchors.isEmpty) return 'Minimal harus ada satu titik harga';
    final sorted = [...anchors]..sort((a, b) => a.$1.compareTo(b.$1));
    for (var i = 0; i < sorted.length; i++) {
      final (supply, retail) = sorted[i];
      if (supply <= 0 || retail <= 0) return 'Harga harus lebih dari 0';
      if (retail % 5000 != 0) {
        return 'Harga jual ${_fmt(retail)} bukan kelipatan Rp 5.000';
      }
      if (i == 0) continue;
      final (prevSupply, prevRetail) = sorted[i - 1];
      if (supply == prevSupply) {
        return 'Harga supplier ${_fmt(supply)} muncul dua kali';
      }
      if (retail <= prevRetail) {
        return 'Harga jual harus naik: ${_fmt(supply)} tidak boleh '
            '≤ ${_fmt(prevRetail)}';
      }
    }
    return null;
  }

  static String _fmt(int v) {
    final s = v.toString();
    final out = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) out.write('.');
      out.write(s[i]);
    }
    return out.toString();
  }

  /// Which products would change if [anchors] and [aboveMarkupPct] were
  /// applied. Reads only; nothing is written.
  Future<PricingPreview> preview(
    List<Anchor> anchors,
    double aboveMarkupPct,
  ) async {
    final error = validateAnchors(anchors);
    if (error != null) throw ArgumentError(error);
    final s = await (_db.select(
      _db.settings,
    )..where((t) => t.id.equals(1))).getSingle();
    final config = PricingConfig(
      anchors: [...anchors]..sort((a, b) => a.$1.compareTo(b.$1)),
      minRetail: s.minRetail,
      roundTo: s.roundTo,
      aboveMarkupPct: aboveMarkupPct,
    );

    final products = await (_db.select(
      _db.products,
    )..where((p) => p.deletedAt.isNull())).get();
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
      if (p.retailIsOverride == 1) {
        overrides++;
        continue;
      }
      final supply = pickBasisSupply(s.basis, byProduct[p.id] ?? const []);
      if (supply == null) continue;
      final next = config.calc(supply);
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

  /// Saves the anchors and markup and recalculates every non-override
  /// product, all in one transaction. Returns how many products changed.
  Future<int> apply(List<Anchor> anchors, double aboveMarkupPct) async {
    final preview = await this.preview(anchors, aboveMarkupPct);
    await _db.transaction(() async {
      await _db.delete(_db.pricingAnchors).go();
      for (final (supply, retail) in anchors) {
        await _db
            .into(_db.pricingAnchors)
            .insert(
              PricingAnchorsCompanion.insert(
                supplyPrice: Value(supply),
                retailPrice: retail,
              ),
            );
      }
      await (_db.update(_db.settings)..where((s) => s.id.equals(1))).write(
        SettingsCompanion(aboveMarkupPct: Value(aboveMarkupPct)),
      );
      for (final c in preview.changes) {
        await (_db.update(_db.products)..where((p) => p.id.equals(c.productId)))
            .write(ProductsCompanion(retailPrice: Value(c.newPrice)));
      }
      // Every calculated price was just brought up to date (and previewed by
      // the owner), so a pending suggestion has nothing left to propose.
      await _db.customUpdate(
        'UPDATE products SET pending_retail = NULL '
        'WHERE pending_retail IS NOT NULL AND retail_is_override = 0',
        updates: {_db.products},
      );
    });
    _products.invalidatePricingConfig();
    return preview.changes.length;
  }
}
