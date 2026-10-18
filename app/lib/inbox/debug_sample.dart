import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../data/owner_database.dart';
import 'po_import_service.dart';

/// Same content as shared/extraction_sample.json (a test keeps them equal).
const debugSampleExtraction = <String, Object?>{
  'supplier': {
    'name': 'CV Maju Elektrik',
    'phone': '0812xxxx',
    'address': 'Jl. Mangga Dua No. 8, Jakarta',
    'confidence': 0.96,
  },
  'po_date': '2026-10-04',
  'lines': [
    {
      'name': 'Kbl Type C 100cm',
      'qty': 20,
      'unit': 'pcs',
      'unit_price': 9500,
      'confidence': {'name': 0.97, 'qty': 0.99, 'unit_price': 0.95},
    },
    {
      'name': 'Kabel Micro USB 1M',
      'qty': 12,
      'unit': 'pcs',
      'unit_price': 7000,
      'confidence': {'name': 0.98, 'qty': 0.97, 'unit_price': 0.96},
    },
    {
      'name': 'Chrgr Fast 20W',
      'qty': 6,
      'unit': 'pcs',
      'unit_price': 38500,
      'confidence': {'name': 0.9, 'qty': 0.95, 'unit_price': 0.62},
    },
    {
      'name': 'Sarung HP Silikon',
      'qty': 2,
      'unit': 'dus',
      'unit_price': null,
      'confidence': {'name': 0.93, 'qty': 0.9, 'unit_price': 0},
    },
    {
      'name': 'Ongkos kirim',
      'qty': null,
      'unit': null,
      'unit_price': 25000,
      'confidence': {'name': 0.99, 'qty': 0, 'unit_price': 0.9},
    },
  ],
};

/// Creates a PO as if the worker had just answered, so the Review screen can be
/// tried on a phone before the Inbox and the worker exist. Debug builds only
/// (the Settings entry is hidden in release). Returns the PO id.
Future<String> seedSamplePo(OwnerDatabase db, PoImportService importer) async {
  final id = const Uuid().v4();
  await db.customInsert(
    "INSERT INTO purchase_orders (id, status, source) VALUES (?, 'processing', 'gallery')",
    variables: [Variable.withString(id)],
    updates: {db.purchaseOrders},
  );
  await importer.importResult(id, jsonEncode(debugSampleExtraction));
  return id;
}
