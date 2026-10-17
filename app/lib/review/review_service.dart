import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../data/owner_database.dart';
import '../matching/normalize.dart';
import '../products/product_service.dart';

enum LineDecision { link, createNew, ignore }

/// The owner's final decision for one PO line on the Review screen.
class ReviewedLine {
  const ReviewedLine.link({
    required this.poLineId,
    required this.rawName,
    required String this.productId,
    this.unitPrice,
  }) : decision = LineDecision.link,
       newName = null,
       newModel = null,
       newCategory = null,
       newUnit = 'pcs';

  const ReviewedLine.createNew({
    required this.poLineId,
    required this.rawName,
    required String this.newName,
    this.newModel,
    this.newCategory,
    this.newUnit = 'pcs',
    this.unitPrice,
  }) : decision = LineDecision.createNew,
       productId = null;

  const ReviewedLine.ignore({required this.poLineId})
    : decision = LineDecision.ignore,
      rawName = '',
      productId = null,
      newName = null,
      newModel = null,
      newCategory = null,
      newUnit = 'pcs',
      unitPrice = null;

  final String poLineId;
  final LineDecision decision;

  /// The name as printed on the PO; remembered as the supplier's alias.
  final String rawName;
  final String? productId;
  final String? newName;
  final String? newModel;
  final String? newCategory;
  final String newUnit;

  /// Whole Rupiah per unit. Null when the PO price was unreadable: the line is
  /// still linked, but no price is recorded.
  final int? unitPrice;
}

class ReviewedPo {
  const ReviewedPo({
    required this.poId,
    required this.supplierName,
    required this.lines,
    this.poDate,
  });

  final String poId;

  /// Supplier as corrected by the owner; created if it doesn't exist yet.
  final String supplierName;
  final DateTime? poDate;
  final List<ReviewedLine> lines;
}

/// Saves a reviewed PO in one local transaction: products, aliases, supplier
/// prices (and the retail recalculation they trigger), and the PO status.
/// Publishing is a separate step, after this commits.
class ReviewService {
  ReviewService(
    this._db,
    this._products, {
    this._uuid = const Uuid(),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final OwnerDatabase _db;
  final ProductService _products;
  final Uuid _uuid;
  final DateTime Function() _now;

  Future<void> save(ReviewedPo po) {
    if (po.supplierName.trim().isEmpty) {
      throw ArgumentError('Supplier wajib diisi');
    }
    for (final l in po.lines) {
      if (l.decision == LineDecision.createNew &&
          (l.newName ?? '').trim().isEmpty) {
        throw ArgumentError('Nama produk wajib diisi');
      }
      if (l.decision != LineDecision.ignore && l.rawName.trim().isEmpty) {
        throw ArgumentError('Nama di PO kosong');
      }
    }

    return _db.transaction(() async {
      await _checkPo(po);
      final supplierId = await _products.findOrCreateSupplier(po.supplierName);
      // PO date, not today, so an old PO never looks like the latest price.
      final observedAt = po.poDate ?? _now();

      for (final line in po.lines) {
        switch (line.decision) {
          case LineDecision.ignore:
            await _setLine(line.poLineId, null, 'ignored');
          case LineDecision.link:
            final productId = line.productId!;
            await _addAlias(productId, supplierId, line.rawName);
            await _recordPrice(productId, supplierId, line, observedAt);
            await _setLine(line.poLineId, productId, 'confirmed');
          case LineDecision.createNew:
            final productId = await _products.insertProduct(
              name: line.newName!,
              model: line.newModel,
              categoryName: line.newCategory,
              unit: line.newUnit,
            );
            await _addAlias(productId, supplierId, line.rawName);
            await _recordPrice(productId, supplierId, line, observedAt);
            await _setLine(line.poLineId, productId, 'new');
        }
      }

      await _db.customUpdate(
        'UPDATE purchase_orders SET status = ?, supplier_id = ?, po_date = ?, '
        'reviewed_at = ? WHERE id = ?',
        variables: [
          Variable.withString('saved'),
          Variable.withString(supplierId),
          Variable<String>(po.poDate == null ? null : _dateOnly(po.poDate!)),
          Variable.withString(_now().toUtc().toIso8601String()),
          Variable.withString(po.poId),
        ],
        updates: {_db.purchaseOrders},
      );
    });
  }

  /// The PO must be waiting for review, and the lines must be exactly its
  /// lines: saving twice would double-record prices, and a skipped line would
  /// silently stay unreviewed.
  Future<void> _checkPo(ReviewedPo po) async {
    final rows = await _db
        .customSelect(
          'SELECT status FROM purchase_orders WHERE id = ?',
          variables: [Variable.withString(po.poId)],
        )
        .get();
    if (rows.isEmpty) throw ArgumentError('PO tidak ditemukan');
    if (rows.single.read<String>('status') != 'needs_review') {
      throw StateError('PO ini tidak menunggu review');
    }
    final lineRows = await _db
        .customSelect(
          'SELECT id FROM po_lines WHERE po_id = ?',
          variables: [Variable.withString(po.poId)],
        )
        .get();
    final expected = {for (final r in lineRows) r.read<String>('id')};
    final given = po.lines.map((l) => l.poLineId).toList();
    if (given.length != given.toSet().length ||
        !given.toSet().containsAll(expected) ||
        given.length != expected.length) {
      throw ArgumentError('Baris review tidak sama dengan baris PO');
    }
  }

  /// Remembers the supplier's name for the product. If the same name was
  /// linked to another product before, the latest confirmation wins.
  Future<void> _addAlias(String productId, String supplierId, String raw) {
    final alias = raw.trim();
    return _db.customInsert(
      'INSERT INTO product_aliases (id, product_id, supplier_id, alias, alias_norm) '
      'VALUES (?, ?, ?, ?, ?) '
      'ON CONFLICT (supplier_id, alias_norm) DO UPDATE SET '
      'product_id = excluded.product_id, alias = excluded.alias',
      variables: [
        Variable.withString(_uuid.v4()),
        Variable.withString(productId),
        Variable.withString(supplierId),
        Variable.withString(alias),
        Variable.withString(normalizeName(alias)),
      ],
      updates: {_db.productAliases},
    );
  }

  Future<void> _recordPrice(
    String productId,
    String supplierId,
    ReviewedLine line,
    DateTime observedAt,
  ) async {
    final price = line.unitPrice;
    if (price == null) return;
    await _products.recordSupplierPrice(
      productId,
      supplierId,
      price,
      observedAt: observedAt,
      poLineId: line.poLineId,
    );
  }

  /// An untouched auto-match keeps its 'auto' status (so the auto-match rate
  /// can be measured later); everything else the owner decided is recorded.
  Future<void> _setLine(String poLineId, String? productId, String status) {
    return _db.customUpdate(
      'UPDATE po_lines SET matched_product_id = ?1, match_status = '
      "CASE WHEN ?2 = 'confirmed' AND match_status = 'auto' "
      'AND matched_product_id IS ?1 THEN \'auto\' ELSE ?2 END WHERE id = ?3',
      variables: [
        Variable<String>(productId),
        Variable.withString(status),
        Variable.withString(poLineId),
      ],
      updates: {_db.poLines},
    );
  }

  String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
