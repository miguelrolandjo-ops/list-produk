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

/// A retail price the app proposes after a supplier price changed, waiting
/// for the owner's yes or no.
class PriceSuggestion {
  const PriceSuggestion({
    required this.productId,
    required this.name,
    required this.currentRetail,
    required this.suggestedRetail,
    required this.marginSupply,
    required this.belowMargin,
  });

  final String productId;
  final String name;
  final int currentRetail;
  final int suggestedRetail;

  /// The supply price the margin is judged against (settings.margin_basis).
  final int? marginSupply;

  /// Keeping [currentRetail] now sells below the margin limit: the urgent
  /// kind of suggestion.
  final bool belowMargin;

  /// Positive: the suggestion raises the price.
  int get change => suggestedRetail - currentRetail;
}

/// What to do about a product whose retail price now sells below its margin
/// limit: a price that reaches the limit.
class PriceRecommendation {
  const PriceRecommendation({
    required this.productId,
    required this.currentRetail,
    required this.recommendedRetail,
    required this.marginSupply,
    required this.minMarginPct,
  });

  final String productId;
  final int currentRetail;
  final int recommendedRetail;

  /// The supply price the margin is judged against (settings.margin_basis).
  final int marginSupply;

  /// The limit that applies to [marginSupply].
  final double minMarginPct;

  /// Margin at the current price (below [minMarginPct]) and at the recommended
  /// price (at or above it), in percent.
  double get currentMargin => marginPct(marginSupply, currentRetail)!;
  double get recommendedMargin => marginPct(marginSupply, recommendedRetail)!;
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
    this.recommendation,
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

  /// Set when the current retail price sells below the margin limit.
  final PriceRecommendation? recommendation;
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

  /// Stores a new supplier price (history is never overwritten), then lets
  /// [_proposeRetail] decide what it means for the retail price: a first price
  /// sets it, a later change only proposes a new one for the owner to confirm.
  /// Returns the product's retail price afterwards (unchanged by a proposal).
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
      return _proposeRetail(productId);
    });
  }

  /// Decides what a supplier price change means for the retail price, and
  /// returns the product's retail price afterwards (which this never changes
  /// except for a product's very first price).
  ///
  /// - No retail price yet: the calculated price is set directly. There is
  ///   no price of the owner's to protect.
  /// - Manual price (retail_is_override = 1): left alone, nothing proposed.
  /// - Otherwise the calculated ("proper") price, higher or lower, is stored in
  ///   pending_retail when it differs from the current one, for the owner to
  ///   confirm ([applySuggestion]) or refuse ([dismissSuggestion]); when it
  ///   equals the current price, nothing is pending.
  ///
  /// Running again after the next price change replaces the pending value, so a
  /// refused suggestion only comes back when a price changes again.
  Future<int?> _proposeRetail(String productId) async {
    final product = await (_db.select(
      _db.products,
    )..where((p) => p.id.equals(productId))).getSingle();

    Future<void> setPending(int? value) async {
      if (product.pendingRetail == value) return;
      await (_db.update(_db.products)..where((p) => p.id.equals(productId)))
          .write(ProductsCompanion(pendingRetail: Value(value)));
    }

    if (product.retailIsOverride == 1) {
      await setPending(null);
      return product.retailPrice;
    }
    final supply = await _basisSupply(productId, await _settings());
    if (supply == null) {
      await setPending(null); // no supply price left to base a suggestion on
      return product.retailPrice;
    }
    final proper = await _calc(supply);

    if (product.retailPrice == null) {
      await (_db.update(_db.products)..where((p) => p.id.equals(productId)))
          .write(
            ProductsCompanion(
              retailPrice: Value(proper),
              pendingRetail: const Value(null),
            ),
          );
      return proper;
    }
    await setPending(proper == product.retailPrice ? null : proper);
    return product.retailPrice;
  }

  /// Retail price suggestions waiting for the owner, most urgent first (those
  /// that now sell below the margin limit), then by name.
  Future<List<PriceSuggestion>> pendingSuggestions() async {
    final rows =
        await (_db.select(_db.products)..where(
              (p) =>
                  p.deletedAt.isNull() &
                  p.pendingRetail.isNotNull() &
                  p.retailPrice.isNotNull() &
                  p.retailIsOverride.equals(0),
            ))
            .get();
    if (rows.isEmpty) return const [];
    final ranges = await marginThresholds();
    final supply = await marginSupplyPrices();
    return [
      for (final p in rows)
        PriceSuggestion(
          productId: p.id!,
          name: p.name,
          currentRetail: p.retailPrice!,
          suggestedRetail: p.pendingRetail!,
          marginSupply: supply[p.id],
          belowMargin:
              supply[p.id] != null &&
              isBelowMargin(supply[p.id]!, p.retailPrice, ranges),
        ),
    ]..sort((a, b) {
      if (a.belowMargin != b.belowMargin) return a.belowMargin ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  /// A recommended retail price for a product that sells below its margin
  /// limit, or null when it does not (or has no price or no limit to compare).
  ///
  /// It is the waiting suggestion when that already reaches the limit,
  /// otherwise the smallest rounded price that does, never below the normal
  /// calculated price. Works for manual prices too.
  Future<PriceRecommendation?> recommendation(String productId) async {
    final product =
        await (_db.select(_db.products)..where(
              (p) => p.id.equals(productId) & p.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    final retail = product?.retailPrice;
    if (product == null || retail == null) return null;

    final supply = (await marginSupplyPrices(productId: productId))[productId];
    if (supply == null) return null;
    final limit = minMarginFor(supply, await marginThresholds());
    if (limit == null || (marginPct(supply, retail) ?? 100) >= limit) {
      return null;
    }

    final pending = product.pendingRetail;
    final int price;
    if (pending != null &&
        product.retailIsOverride == 0 &&
        (marginPct(supply, pending) ?? 0) >= limit) {
      price = pending;
    } else {
      final config = await pricingConfig();
      price = recommendedRetail(
        supply: supply,
        minMarginPct: limit,
        calculated: config.calc(supply),
        roundTo: config.roundTo,
      );
    }
    return PriceRecommendation(
      productId: productId,
      currentRetail: retail,
      recommendedRetail: price,
      marginSupply: supply,
      minMarginPct: limit,
    );
  }

  /// The owner confirmed the recommended price. The product keeps its kind: a
  /// manual price stays manual, a calculated one stays calculated. Any waiting
  /// suggestion is cleared, since the price was just decided. Does nothing if
  /// the product no longer sells below its limit.
  Future<void> applyRecommendation(String productId) async {
    final r = await recommendation(productId);
    if (r == null) return;
    await (_db.update(_db.products)..where((p) => p.id.equals(productId)))
        .write(
          ProductsCompanion(
            retailPrice: Value(r.recommendedRetail),
            pendingRetail: const Value(null),
          ),
        );
  }

  /// The owner said yes: the suggested price becomes the retail price (still
  /// a calculated one, so later price changes propose again). Does nothing if
  /// there is nothing pending.
  Future<void> applySuggestion(String productId) async {
    final product = await (_db.select(
      _db.products,
    )..where((p) => p.id.equals(productId))).getSingleOrNull();
    final pending = product?.pendingRetail;
    if (product == null || pending == null || product.retailIsOverride == 1) {
      return;
    }
    await (_db.update(_db.products)..where((p) => p.id.equals(productId)))
        .write(
          ProductsCompanion(
            retailPrice: Value(pending),
            pendingRetail: const Value(null),
          ),
        );
  }

  /// The owner said no: the retail price stays and the suggestion goes away.
  /// It only returns after the next supplier price change.
  Future<void> dismissSuggestion(String productId) async {
    await (_db.update(_db.products)..where((p) => p.id.equals(productId)))
        .write(const ProductsCompanion(pendingRetail: Value(null)));
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
      recommendation: await recommendation(productId),
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
              ..orderBy([
                (p) => OrderingTerm.desc(p.observedAt),
                // Same date (for example two POs on one day): the one recorded
                // last comes first.
                (p) => OrderingTerm.desc(const CustomExpression<int>('rowid')),
              ]))
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

  /// Deletes a supplier and everything that only makes sense with it: its
  /// price records (the price history from that supplier) and the names it
  /// used for products. Products are kept, and so are past POs (which just lose
  /// their supplier). Returns how many products had a price from this supplier.
  ///
  /// If the supplier was what drove a product's retail price, the new price is
  /// proposed for the owner to confirm, not applied: removing a supplier is a
  /// supplier price change like any other.
  Future<int> deleteSupplier(String supplierId) {
    return _db.transaction(() async {
      final affected = [
        for (final r in await _db
            .customSelect(
              'SELECT DISTINCT sp.product_id AS id FROM supplier_prices sp '
              'JOIN products p ON p.id = sp.product_id '
              'WHERE sp.supplier_id = ? AND p.deleted_at IS NULL',
              variables: [Variable.withString(supplierId)],
            )
            .get())
          r.read<String>('id'),
      ];

      await _db.customUpdate(
        'DELETE FROM supplier_prices WHERE supplier_id = ?',
        variables: [Variable.withString(supplierId)],
        updates: {_db.supplierPrices},
        updateKind: UpdateKind.delete,
      );
      await _db.customUpdate(
        'DELETE FROM product_aliases WHERE supplier_id = ?',
        variables: [Variable.withString(supplierId)],
        updates: {_db.productAliases},
        updateKind: UpdateKind.delete,
      );
      // Child rows are cleaned explicitly: SQLite only cascades with foreign
      // keys switched on, and they are not.
      await _db.customUpdate(
        'UPDATE purchase_orders SET supplier_id = NULL WHERE supplier_id = ?',
        variables: [Variable.withString(supplierId)],
        updates: {_db.purchaseOrders},
      );
      await _db.customUpdate(
        'DELETE FROM suppliers WHERE id = ?',
        variables: [Variable.withString(supplierId)],
        updates: {_db.suppliers},
        updateKind: UpdateKind.delete,
      );

      for (final id in affected) {
        await _proposeRetail(id);
      }
      return affected.length;
    });
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
        pendingRetail: const Value(null), // a manual price needs no suggestion
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

  /// Undoes [deleteProduct]: the product comes back exactly as it was, prices
  /// and any waiting (or already refused) retail suggestion included. Restoring
  /// is not a supplier price change, so it never asks anything new.
  Future<void> restoreProduct(String productId) async {
    await (_db.update(_db.products)..where((p) => p.id.equals(productId)))
        .write(const ProductsCompanion(deletedAt: Value(null)));
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
