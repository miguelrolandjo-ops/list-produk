import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../data/owner_database.dart';
import '../matching/match_repository.dart';
import '../matching/normalize.dart';
import '../matching/product_matcher.dart';
import 'extraction_result.dart';

/// Turns an extraction result into po_lines ready for the Review screen
/// (build guide section 9, steps 5). No UI, no network.
class PoImportService {
  PoImportService(this._db, {this._uuid = const Uuid()});

  final OwnerDatabase _db;
  final Uuid _uuid;

  /// Stores [rawJson] on the PO, matches every line against the catalog and
  /// moves the PO to 'needs_review'. The PO must be 'processing'.
  ///
  /// Throws [FormatException] for a malformed result and leaves the PO
  /// untouched, so the caller can mark it failed.
  Future<void> importResult(String poId, String rawJson) async {
    final result = ExtractionResult.fromJson(jsonDecode(rawJson));

    // Matching reads the catalog, so build the matcher before the transaction.
    final matcher = await MatchRepository(_db).buildMatcher();

    await _db.transaction(() async {
      final status = await _db
          .customSelect(
            'SELECT status FROM purchase_orders WHERE id = ?',
            variables: [Variable.withString(poId)],
          )
          .getSingleOrNull();
      if (status == null) throw ArgumentError('PO tidak ditemukan');
      if (status.read<String>('status') != 'processing') {
        throw StateError('PO ini tidak sedang diproses');
      }

      final supplierId = await _findSupplier(result.supplier);

      for (var i = 0; i < result.lines.length; i++) {
        final line = result.lines[i];
        final outcome = matcher.match(
          rawName: line.name,
          supplierId: supplierId,
          unitPrice: line.unitPrice,
        );
        await _db.customInsert(
          'INSERT INTO po_lines (id, po_id, line_no, raw_name, qty, unit, '
          'unit_price, confidence, matched_product_id, match_status) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          variables: [
            Variable.withString(_uuid.v4()),
            Variable.withString(poId),
            Variable.withInt(i + 1),
            Variable.withString(line.name),
            Variable<double>(line.qty),
            Variable<String>(line.unit),
            Variable<int>(line.unitPrice),
            Variable.withString(jsonEncode(line.confidenceJson)),
            Variable<String>(outcome.productId),
            Variable.withString(_statusValue(outcome.status)),
          ],
          updates: {_db.poLines},
        );
      }

      await _db.customUpdate(
        'UPDATE purchase_orders SET status = ?, supplier_id = ?, po_date = ?, '
        'raw_result = ? WHERE id = ?',
        variables: [
          Variable.withString('needs_review'),
          Variable<String>(supplierId),
          Variable<String>(result.poDate?.toIso8601String().substring(0, 10)),
          Variable.withString(rawJson),
          Variable.withString(poId),
        ],
        updates: {_db.purchaseOrders},
      );
    });
  }

  /// A known supplier, by phone number first (the most reliable key), then by
  /// exact normalized name. Null means "propose a new supplier": the Review
  /// screen reads the printed name and phone from raw_result.
  Future<String?> _findSupplier(ExtractedSupplier s) async {
    final suppliers = await _db
        .customSelect('SELECT id, name, phone FROM suppliers')
        .get();

    final phone = normalizePhone(s.phone);
    if (phone != null) {
      for (final r in suppliers) {
        if (normalizePhone(r.readNullable<String>('phone')) == phone) {
          return r.read<String>('id');
        }
      }
    }
    final name = s.name == null ? '' : normalizeName(s.name!);
    if (name.isNotEmpty) {
      for (final r in suppliers) {
        if (normalizeName(r.read<String>('name')) == name) {
          return r.read<String>('id');
        }
      }
    }
    return null;
  }

  static String _statusValue(MatchStatus s) => switch (s) {
    MatchStatus.auto => 'auto',
    MatchStatus.suggested => 'suggested',
    MatchStatus.isNew => 'new',
  };
}

/// Digits only, +62 / 62 written as 0, and at least 6 digits to count as a
/// phone number. Returns null otherwise ("0812xxxx" is not a usable number).
String? normalizePhone(String? raw) {
  if (raw == null) return null;
  var d = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (d.startsWith('62')) d = '0${d.substring(2)}';
  return d.length >= 6 && !RegExp(r'[a-zA-Z]').hasMatch(raw) ? d : null;
}
