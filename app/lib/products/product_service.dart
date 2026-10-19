import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../data/owner_database.dart';
import '../pricing/basis.dart';
import '../pricing/calc_retail.dart';
import '../pricing/defaults.dart';
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

class SupplierPriceEntry {
  const SupplierPriceEntry({
    required this.supplierId,
    required this.supplierName,
    required this.unitPrice,
    required this.observedAt,
  });
  final String supplierId;
  final String supplierName;
  final int unitPrice;
  final DateTime observedAt;
}

class ProductDetail {
  const ProductDetail({
    required this.product,
    required this.categoryName,
    required this.basis,
    required this.basisSupply,
    required this.marginSupply,
    required this.marginBasis,
    required this.marginAvgCount,
    required this.minMarginPct,
    required this.currentPrices,
  });

  final Product product;
  final String? categoryName;

  /// settings.basis: 'highest', 'lowest' or 'latest'.
  final String basis;

  /// The supply price the retail price is based on, if any.
  final int? basisSupply;

  /// The supply price the margin warning uses (settings.margin_basis), which
  /// is not necessarily [basisSupply]. Null if the product has no prices.
  final int? marginSupply;

  /// settings.margin_basis ('latest' or 'average') and the N for 'average'.
  final String marginBasis;
  final int marginAvgCount;

  /// Margin limit for [marginSupply], or null if none applies.
  final double? minMarginPct;
  final List<SupplierPriceEntry> currentPrices;
}

/// Immutable snapshot of the pricing rule's inputs. [calc] is synchronous, so
/// the UI can preview prices without awaiting anything.
class PricingConfig {
  const PricingConfig({
    required this.anchors,
    required this.minRetail,
    required this.roundTo,
    required this.aboveMarkupPct,
  });

  final List<Anchor> anchors;
  final int minRetail;
  final int roundTo;
  final double aboveMarkupPct;

  int calc(int supply) => calcRetail(
    supply,
    anchors,
    minRetail: minRetail,
    roundTo: roundTo,
    aboveMarkupPct: aboveMarkupPct,
  );
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
    final retail = (await pricingConfig()).calc(supplyPrice);
    return RetailPreview(retail, marginPct(supplyPrice, retail));
  }

  PricingConfig? _config;

  /// Settings and anchors, read from the database once and kept in memory so
  /// typing a price doesn't hit SQLite on every keystroke. Whoever edits
  /// settings or anchors (milestone 2) must call [invalidatePricingConfig].
  Future<PricingConfig> pricingConfig() async =>
      _config ??= await _loadPricingConfig();

  void invalidatePricingConfig() => _config = null;

  Future<PricingConfig> _loadPricingConfig() async {
    final s = await _settings();
    final rows = await (_db.select(
      _db.pricingAnchors,
    )..orderBy([(a) => OrderingTerm.asc(a.supplyPrice)])).get();
    return PricingConfig(
      anchors: [for (final a in rows) (a.supplyPrice, a.retailPrice)],
      minRetail: s.minRetail,
      roundTo: s.roundTo,
      aboveMarkupPct: s.aboveMarkupPct,
    );
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
      final supplierId = await findOrCreateSupplier(input.supplierName);
      final productId = await insertProduct(
        name: name,
        model: input.model,
        categoryName: input.categoryName,
        unit: input.unit,
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

  /// Inserts a product row with no price. Call inside a transaction together
  /// with [recordSupplierPrice]. Returns the new product id.
  Future<String> insertProduct({
    required String name,
    String? model,
    String? categoryName,
    String unit = 'pcs',
  }) async {
    final categoryId = await _findOrCreateCategory(categoryName);
    final productId = _uuid.v4();
    final m = model?.trim();
    await _db
        .into(_db.products)
        .insert(
          ProductsCompanion.insert(
            id: Value(productId),
            name: name.trim(),
            model: Value(m == null || m.isEmpty ? null : m),
            categoryId: Value(categoryId),
            unit: Value(unit),
          ),
        );
    return productId;
  }

  /// Stores a new supplier price (history is never overwritten), then
  /// recalculates the product's retail price unless it is an override.
  /// Returns the product's retail price afterwards.
  Future<int?> recordSupplierPrice(
    String productId,
    String supplierId,
    int unitPrice, {
    DateTime? observedAt,
    String? poLineId,
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
              poLineId: Value(poLineId),
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

  /// Margin limits per supply range, lowest range first.
  Future<List<MarginRange>> marginThresholds() async => [
    for (final t in await (_db.select(
      _db.marginThresholds,
    )..orderBy([(t) => OrderingTerm.asc(t.minSupply)])).get())
      (t.minSupply, t.maxSupply, t.minMarginPct),
  ];

  /// Everything the detail screen shows, or null if the product is gone.
  Future<ProductDetail?> detail(String productId) async {
    final product =
        await (_db.select(_db.products)
              ..where((p) => p.id.equals(productId) & p.deletedAt.isNull()))
            .getSingleOrNull();
    if (product == null) return null;

    final categoryId = product.categoryId;
    final category = categoryId == null
        ? null
        : await (_db.select(
            _db.categories,
          )..where((c) => c.id.equals(categoryId))).getSingleOrNull();

    final suppliers = {
      for (final s in await _db.select(_db.suppliers).get()) s.id!: s.name,
    };
    final current =
        await (_db.select(_db.currentSupplierPrices)
              ..where((c) => c.productId.equals(productId))
              ..orderBy([(c) => OrderingTerm.asc(c.unitPrice)]))
            .get();
    final settings = await _settings();
    final basisSupply = await _basisSupply(productId, settings);
    final marginSupply =
        (await marginSupplyPrices(productId: productId))[productId];

    return ProductDetail(
      product: product,
      categoryName: category?.name,
      basis: settings.basis,
      basisSupply: basisSupply,
      marginSupply: marginSupply,
      marginBasis: settings.marginBasis,
      marginAvgCount: settings.marginAvgCount,
      minMarginPct: marginSupply == null
          ? null
          : minMarginFor(marginSupply, await marginThresholds()),
      currentPrices: [
        for (final c in current)
          SupplierPriceEntry(
            supplierId: c.supplierId,
            supplierName: suppliers[c.supplierId] ?? '-',
            unitPrice: c.unitPrice,
            observedAt: DateTime.parse(c.observedAt).toLocal(),
          ),
      ],
    );
  }

  /// All supplier prices of a product, newest first.
  Future<List<SupplierPriceEntry>> priceHistory(String productId) async {
    final suppliers = {
      for (final s in await _db.select(_db.suppliers).get()) s.id!: s.name,
    };
    final rows =
        await (_db.select(_db.supplierPrices)
              ..where((p) => p.productId.equals(productId))
              ..orderBy([(p) => OrderingTerm.desc(p.observedAt)]))
            .get();
    return [
      for (final r in rows)
        SupplierPriceEntry(
          supplierId: r.supplierId,
          supplierName: suppliers[r.supplierId] ?? '-',
          unitPrice: r.unitPrice,
          observedAt: DateTime.parse(r.observedAt).toLocal(),
        ),
    ];
  }

  /// Deletes a category. Its products are kept and become uncategorized
  /// (done explicitly: SQLite only does it on its own with foreign keys on,
  /// and they are not). Products that change are re-published, because the
  /// category is an employee-visible field. Returns how many products lost
  /// their category.
  Future<int> deleteCategory(String categoryId) {
    return _db.transaction(() async {
      final changed = await _db.customUpdate(
        'UPDATE products SET category_id = NULL WHERE category_id = ?',
        variables: [Variable.withString(categoryId)],
        updates: {_db.products},
      );
      await _db.customUpdate(
        'DELETE FROM categories WHERE id = ?',
        variables: [Variable.withString(categoryId)],
        updates: {_db.categories},
        updateKind: UpdateKind.delete,
      );
      return changed;
    });
  }

  /// Edits a product's name, unit and category, and records new supplier
  /// prices, in one transaction.
  ///
  /// [supplyPrices] maps supplier id to the price now shown on the form. Only
  /// prices that differ from the supplier's current price are recorded, as new
  /// history entries (history is never overwritten), and each one recalculates
  /// retail unless the product has a manual price. A blank [categoryName]
  /// removes the category.
  Future<void> updateProduct(
    String productId, {
    required String name,
    required String unit,
    String? categoryName,
    Map<String, int> supplyPrices = const {},
  }) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ArgumentError('Nama produk wajib diisi');
    if (unit.trim().isEmpty) throw ArgumentError('Satuan wajib diisi');
    for (final price in supplyPrices.values) {
      _checkSupply(price);
    }

    return _db.transaction(() async {
      final exists = await (_db.select(
        _db.products,
      )..where((p) => p.id.equals(productId))).getSingleOrNull();
      if (exists == null) throw ArgumentError('Produk tidak ditemukan');

      final categoryId = await _findOrCreateCategory(categoryName);
      await (_db.update(
        _db.products,
      )..where((p) => p.id.equals(productId))).write(
        ProductsCompanion(
          name: Value(cleanName),
          unit: Value(unit.trim()),
          categoryId: Value(categoryId),
        ),
      );

      final current = {
        for (final c
            in await (_db.select(
              _db.currentSupplierPrices,
            )..where((c) => c.productId.equals(productId))).get())
          c.supplierId: c.unitPrice,
      };
      for (final e in supplyPrices.entries) {
        if (!current.containsKey(e.key)) {
          throw ArgumentError('Supplier tidak terdaftar untuk produk ini');
        }
        if (current[e.key] != e.value) {
          await recordSupplierPrice(productId, e.key, e.value);
        }
      }
    });
  }

  /// Sets the unit of many products at once. Returns how many actually
  /// changed: products that already have that unit are left alone, so they are
  /// not marked as changed and re-published for nothing.
  Future<int> setUnitForMany(Iterable<String> productIds, String unit) {
    final u = unit.trim();
    if (u.isEmpty) throw ArgumentError('Satuan wajib diisi');
    return _updateMany(
      productIds,
      set: 'unit = ?',
      differs: 'unit <> ?',
      value: Variable.withString(u),
    );
  }

  /// Sets (or, when [categoryName] is blank, clears) the category of many
  /// products at once. Returns how many actually changed.
  Future<int> setCategoryForMany(
    Iterable<String> productIds,
    String? categoryName,
  ) {
    return _db.transaction(() async {
      final categoryId = await _findOrCreateCategory(categoryName);
      return _updateMany(
        productIds,
        set: 'category_id = ?',
        differs: 'category_id IS NOT ?',
        value: Variable<String>(categoryId),
      );
    });
  }

  /// Deleted products are never touched. Ids go in chunks because SQLite
  /// limits the number of variables in one statement.
  Future<int> _updateMany(
    Iterable<String> productIds, {
    required String set,
    required String differs,
    required Variable<Object> value,
  }) async {
    final ids = productIds.toSet().toList();
    var changed = 0;
    await _db.transaction(() async {
      for (var i = 0; i < ids.length; i += 500) {
        final chunk = ids.sublist(i, (i + 500).clamp(0, ids.length));
        final marks = List.filled(chunk.length, '?').join(', ');
        changed += await _db.customUpdate(
          'UPDATE products SET $set WHERE deleted_at IS NULL AND $differs '
          'AND id IN ($marks)',
          variables: [value, value, for (final id in chunk) Variable.withString(id)],
          updates: {_db.products},
        );
      }
    });
    return changed;
  }

  /// The owner's own retail price. Marks the product as an override, so it is
  /// never recalculated automatically.
  Future<void> setRetailOverride(String productId, int price) async {
    _checkRetail(price);
    await (_db.update(
      _db.products,
    )..where((p) => p.id.equals(productId))).write(
      ProductsCompanion(
        retailPrice: Value(price),
        retailIsOverride: const Value(1),
      ),
    );
  }

  /// Deletes a product as far as the owner can tell: it disappears from the
  /// list and from employees' catalog. Underneath it is a soft delete
  /// (deleted_at), so employees learn about the removal and [restoreProduct]
  /// can undo it right after.
  Future<void> deleteProduct(String productId) async {
    await (_db.update(
      _db.products,
    )..where((p) => p.id.equals(productId))).write(
      ProductsCompanion(deletedAt: Value(_now().toUtc().toIso8601String())),
    );
  }

  /// Undoes [deleteProduct]. While deleted it was skipped by price
  /// recalculations, so its retail price is recalculated now (manual prices
  /// stay as they are).
  Future<void> restoreProduct(String productId) async {
    await _db.transaction(() async {
      await (_db.update(_db.products)..where((p) => p.id.equals(productId)))
          .write(const ProductsCompanion(deletedAt: Value(null)));
      await recalcRetail(productId);
    });
  }

  /// The supply price each product's margin is judged against, per
  /// settings.margin_basis: its latest PO price, or the average of its last N.
  /// Products without any supplier price are absent from the map. Pass
  /// [productId] to look at one product only.
  Future<Map<String, int>> marginSupplyPrices({String? productId}) async {
    final s = await _settings();
    final n = s.marginBasis == 'average' ? s.marginAvgCount : 1;
    final rows = await _db
        .customSelect(
          'SELECT product_id, unit_price FROM ('
          ' SELECT product_id, unit_price, ROW_NUMBER() OVER ('
          '  PARTITION BY product_id ORDER BY observed_at DESC, rowid DESC'
          ' ) AS rn FROM supplier_prices WHERE (?1 IS NULL OR product_id = ?1)'
          ') WHERE rn <= ?2 ORDER BY product_id, rn',
          variables: [Variable<String>(productId), Variable.withInt(n)],
          readsFrom: {_db.supplierPrices},
        )
        .get();
    final byProduct = <String, List<int>>{};
    for (final r in rows) {
      (byProduct[r.read<String>('product_id')] ??= []).add(
        r.read<int>('unit_price'),
      );
    }
    return {
      for (final e in byProduct.entries)
        e.key: pickMarginSupply(s.marginBasis, s.marginAvgCount, e.value)!,
    };
  }

  Future<Setting> _settings() =>
      (_db.select(_db.settings)..where((s) => s.id.equals(1))).getSingle();

  Future<int> _calc(int supply) async => (await pricingConfig()).calc(supply);

  /// The supply price that drives the retail price (highest/lowest/latest
  /// across suppliers' current prices), or null if there are none.
  Future<int?> _basisSupply(String productId, Setting s) async {
    final rows = await (_db.select(
      _db.currentSupplierPrices,
    )..where((c) => c.productId.equals(productId))).get();
    return pickBasisSupply(s.basis, [
      for (final r in rows) (unitPrice: r.unitPrice, observedAt: r.observedAt),
    ]);
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

  Future<String> findOrCreateSupplier(String raw) async {
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
    // Only the calculated price is rounded to Rp 5.000. The owner may type
    // any price by hand.
    if (price <= 0) throw ArgumentError('Harga jual harus lebih dari 0');
  }
}
