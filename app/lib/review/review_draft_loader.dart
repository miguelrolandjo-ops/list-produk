import 'dart:convert';

import 'package:drift/drift.dart';

import '../data/owner_database.dart';
import '../inbox/extraction_result.dart';
import '../matching/normalize.dart';
import 'review_draft.dart';

/// Reads a PO that is waiting for review into a [ReviewDraft].
class ReviewDraftLoader {
  ReviewDraftLoader(this._db);

  final OwnerDatabase _db;

  /// Throws [StateError] if the PO is missing or not in 'needs_review'.
  Future<ReviewDraft> load(String poId) async {
    final po = await _db
        .customSelect(
          'SELECT p.status, p.supplier_id, p.po_date, p.raw_result, s.name AS supplier_name '
          'FROM purchase_orders p LEFT JOIN suppliers s ON s.id = p.supplier_id '
          'WHERE p.id = ?',
          variables: [Variable.withString(poId)],
        )
        .getSingleOrNull();
    if (po == null || po.read<String>('status') != 'needs_review') {
      throw StateError('PO ini tidak menunggu review');
    }

    // The printed supplier (for a PO the import could not link to anyone).
    final raw = po.readNullable<String>('raw_result');
    final printed = raw == null
        ? null
        : ExtractionResult.fromJson(jsonDecode(raw)).supplier;
    final matchedName = po.readNullable<String>('supplier_name');

    final suppliers = await _db.customSelect('SELECT name FROM suppliers').get();

    final lineRows = await _db
        .customSelect(
          'SELECT l.id, l.raw_name, l.qty, l.unit, l.unit_price, l.confidence, '
          'l.matched_product_id, l.match_status, pr.name AS product_name '
          'FROM po_lines l LEFT JOIN products pr ON pr.id = l.matched_product_id '
          'WHERE l.po_id = ? ORDER BY l.line_no',
          variables: [Variable.withString(poId)],
        )
        .get();

    // What this supplier last charged for each product, to fill in prices the
    // model could not read.
    final supplierId = po.readNullable<String>('supplier_id');
    final known = <String, int>{};
    if (supplierId != null) {
      final rows = await _db
          .customSelect(
            'SELECT product_id, unit_price FROM current_supplier_prices '
            'WHERE supplier_id = ?',
            variables: [Variable.withString(supplierId)],
          )
          .get();
      for (final r in rows) {
        known[r.read<String>('product_id')] = r.read<int>('unit_price');
      }
    }

    final date = po.readNullable<String>('po_date');
    return ReviewDraft(
      poId: poId,
      supplierName: matchedName ?? printed?.name ?? '',
      supplierMatched: matchedName != null,
      supplierConfidence: printed?.confidence ?? 0,
      knownSuppliers: {
        for (final s in suppliers) normalizeName(s.read<String>('name')),
      },
      poDate: date == null ? null : DateTime.parse('${date}T00:00:00Z'),
      lines: [for (final r in lineRows) _line(r, known)],
    );
  }

  DraftLine _line(QueryRow r, Map<String, int> known) {
    final conf = r.readNullable<String>('confidence');
    final c = conf == null
        ? const <String, Object?>{}
        : (jsonDecode(conf) as Map).cast<String, Object?>();
    final productId = r.readNullable<String>('matched_product_id');
    final status = r.read<String>('match_status');
    final kind = productId == null
        ? DraftKind.isNew
        : switch (status) {
            'auto' => DraftKind.auto,
            'suggested' => DraftKind.suggestion,
            _ => DraftKind.isNew,
          };
    final name = r.read<String>('raw_name');
    final previous = kind == DraftKind.isNew ? null : known[productId];
    final read = r.readNullable<int>('unit_price');
    return DraftLine(
      poLineId: r.read<String>('id'),
      rawName: name,
      kind: kind,
      newName: name,
      productId: kind == DraftKind.isNew ? null : productId,
      productName: kind == DraftKind.isNew
          ? null
          : r.readNullable<String>('product_name'),
      qty: r.readNullable<double>('qty'),
      unit: r.readNullable<String>('unit'),
      unitPrice: read ?? previous,
      previousPrice: previous,
      priceFromCatalog: read == null && previous != null,
      nameConfidence: (c['name'] as num?)?.toDouble() ?? 0,
      unitPriceConfidence: (c['unit_price'] as num?)?.toDouble() ?? 0,
    );
  }
}
