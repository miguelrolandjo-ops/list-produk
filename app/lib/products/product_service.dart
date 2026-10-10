import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../data/owner_database.dart';
import '../pricing/calc_retail.dart';
import '../pricing/margin.dart';

class NewProductInput {
  const NewProductInput({
    required this.name,
    required this.supplierName,
    required this.supplyPrice,
    this.model,
    this.categoryName,
    this.unit = 'pcs',
    this.retailPrice,
  });

  final String name;
  final String? model;
  final String? categoryName;
  final String unit;
  final String supplierName;
  final int supplyPrice;

  /// Owner's own retail price. Saved as an override only if it differs from
  /// the calculated price.
  final int? retailPrice;
}

class RetailPreview {
  const RetailPreview(this.retail, this.marginPct);
  final int retail;
  final double? marginPct;
}

/// Saving products and recalculating retail prices. No UI dependencies.
class ProductService {
  ProductService(
    this._db, {
    this._uuid = const Uuid(),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final OwnerDatabase _db;
  final Uuid _uuid;
  final DateTime Function() _now;

  Future<List<String>> categoryNames() async => [
    for (final c in await (_db.select(
      _db.categories,
    )..orderBy([(c) => OrderingTerm.asc(c.name)])).get())
      c.name,
  ];

  Future<List<String>> supplierNames() async => [
    for (final s in await (_db.select(
      _db.suppliers,
    )..orderBy([(s) => OrderingTerm.asc(s.name)])).get())
      s.name,
  ];

  /// Calculated retail price and margin for a single supply price.
  Future<RetailPreview> preview(int supplyPrice) async {
    final retail = await _calc(supplyPrice);
    return RetailPreview(retail, marginPct(supplyPrice, retail));
  }

  /// Creates the product, its first supplier price, and its retail price in
  /// one transaction. Returns the new product id.
  Future<String> addManual(NewProductInput input) {
    final name = input.name.trim();
    if (name.isEmpty) throw ArgumentError('Nama produk wajib diisi');
    if (input.supplierName.trim().isEmpty) {
      throw ArgumentError('Supplier wajib diisi');
    }
    _checkSupply(input.supplyPrice);
    final override = input.retailPrice;
    if (override != null) _checkRetail(override);

    return _db.transaction(() async {
      final categoryId = await _findOrCreateCategory(input.categoryName);
      final supplierId = await _findOrCreateSupplier(input.supplierName);
      final productId = _uuid.v4();
      final model = input.model?.trim();

      await _db
          .into(_db.products)
          .insert(
            ProductsCompanion.insert(
              id: Value(productId),
              name: name,
              model: Value(model == null || model.isEmpty ? null : model),
              categoryId: Value(categoryId),
              unit: Value(input.unit),
            ),
          );
      final calculated = await recordSupplierPrice(
        productId,
        supplierId,
        input.supplyPrice,
      );

      if (override != null && override != calculated) {
        await (_db.update(
          _db.products,
        )..where((p) => p.id.equals(productId))).write(
          ProductsCompanion(
            retailPrice: Value(override),
            retailIsOverride: const Value(1),
          ),
        );
      }
      return productId;
    });
  }

  /// Stores a new supplier price (history is never overwritten), then
  /// recalculates the product's retail price unless it is an override.
  /// Returns the product's retail price afterwards.
  Future<int?> recordSupplierPrice(
    String productId,
    String supplierId,
    int unitPrice, {
    DateTime? observedAt,
  }) {
    _checkSupply(unitPrice);
    return _db.transaction(() async {
      await _db
          .into(_db.supplierPrices)
          .insert(
            SupplierPricesCompanion.insert(
              id: Value(_uuid.v4()),
              productId: productId,
              supplierId: supplierId,
              unitPrice: unitPrice,
              observedAt: Value(
                (observedAt ?? _now()).toUtc().toIso8601String(),
              ),
            ),
          );
      return recalcRetail(productId);
    });
  }

  /// Recomputes retail_price from the supplier prices, using settings.basis.
  /// Products with retail_is_override = 1 are never touched. Returns the
  /// product's retail price after the call.
  Future<int?> recalcRetail(String productId) async {
    final product = await (_db.select(
      _db.products,
    )..where((p) => p.id.equals(productId))).getSingle();
    if (product.retailIsOverride == 1) return product.retailPrice;

    final supply = await _basisSupply(productId, await _settings());
    if (supply == null) return product.retailPrice;

    final retail = await _calc(supply);
    // Skip a no-op write: the products_touch trigger would mark the product
    // as changed and re-publish it for nothing.
    if (retail != product.retailPrice) {
      await (_db.update(_db.products)..where((p) => p.id.equals(productId)))
          .write(ProductsCompanion(retailPrice: Value(retail)));
    }
    return retail;
  }

  Future<Setting> _settings() =>
      (_db.select(_db.settings)..where((s) => s.id.equals(1))).getSingle();

  Future<int> _calc(int supply) async {
    final s = await _settings();
    final rows = await (_db.select(
      _db.pricingAnchors,
    )..orderBy([(a) => OrderingTerm.asc(a.supplyPrice)])).get();
    return calcRetail(
      supply,
      [for (final a in rows) (a.supplyPrice, a.retailPrice)],
      minRetail: s.minRetail,
      roundTo: s.roundTo,
      aboveMarkupPct: s.aboveMarkupPct,
    );
  }

  /// The supply price that drives the retail price (highest/lowest/latest
  /// across suppliers' current prices), or null if there are none.
  Future<int?> _basisSupply(String productId, Setting s) async {
    final rows = await (_db.select(
      _db.currentSupplierPrices,
    )..where((c) => c.productId.equals(productId))).get();
    if (rows.isEmpty) return null;
    switch (s.basis) {
      case 'lowest':
        return rows.map((r) => r.unitPrice).reduce((a, b) => a < b ? a : b);
      case 'latest':
        // ISO-8601 UTC strings sort chronologically.
        return (rows.toList()
              ..sort((a, b) => a.observedAt.compareTo(b.observedAt)))
            .last
            .unitPrice;
      default:
        return rows.map((r) => r.unitPrice).reduce((a, b) => a > b ? a : b);
    }
  }

  Future<String?> _findOrCreateCategory(String? raw) async {
    final name = raw?.trim() ?? '';
    if (name.isEmpty) return null;
    final existing =
        await (_db.select(_db.categories)
              ..where((c) => c.name.lower().equals(name.toLowerCase())))
            .getSingleOrNull();
    if (existing != null) return existing.id!;
    final id = _uuid.v4();
    await _db
        .into(_db.categories)
        .insert(CategoriesCompanion.insert(id: Value(id), name: name));
    return id;
  }

  Future<String> _findOrCreateSupplier(String raw) async {
    final name = raw.trim();
    final existing =
        await (_db.select(_db.suppliers)
              ..where((s) => s.name.lower().equals(name.toLowerCase())))
            .getSingleOrNull();
    if (existing != null) return existing.id!;
    final id = _uuid.v4();
    await _db
        .into(_db.suppliers)
        .insert(SuppliersCompanion.insert(id: Value(id), name: name));
    return id;
  }

  void _checkSupply(int price) {
    if (price <= 0) throw ArgumentError('Harga supplier harus lebih dari 0');
  }

  void _checkRetail(int price) {
    if (price <= 0 || price % 5000 != 0) {
      throw ArgumentError('Harga jual harus kelipatan Rp 5.000');
    }
  }
}
