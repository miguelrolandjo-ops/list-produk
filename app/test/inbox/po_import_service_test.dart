import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_application_1/data/owner_database.dart';
import 'package:flutter_application_1/inbox/po_import_service.dart';
import 'package:flutter_application_1/products/product_service.dart';
import 'package:flutter_application_1/review/review_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late OwnerDatabase db;
  late ProductService products;
  late PoImportService importer;
  final sampleJson = File('../shared/extraction_sample.json').readAsStringSync();

  setUp(() {
    db = OwnerDatabase(NativeDatabase.memory());
    products = ProductService(db);
    importer = PoImportService(db);
  });
  tearDown(() => db.close());

  Future<List<QueryRow>> q(String sql, [List<String> args = const []]) => db
      .customSelect(sql, variables: [for (final a in args) Variable.withString(a)])
      .get();

  Future<void> insertPo(String id, {String status = 'processing'}) =>
      db.customStatement(
        "INSERT INTO purchase_orders (id, status, source) VALUES (?, ?, 'gallery')",
        [id, status],
      );

  Future<Map<String, String>> statuses(String poId) async => {
    for (final r in await q(
      'SELECT raw_name, match_status FROM po_lines WHERE po_id = ?',
      [poId],
    ))
      r.read<String>('raw_name'): r.read<String>('match_status'),
  };

  test('imports the sample into an empty catalog: every line is new', () async {
    await insertPo('po1');
    await importer.importResult('po1', sampleJson);

    final po = (await q('SELECT * FROM purchase_orders')).single;
    expect(po.read<String>('status'), 'needs_review');
    expect(po.read<String>('po_date'), '2026-10-04');
    expect(po.read<String?>('supplier_id'), isNull); // propose a new supplier
    expect(jsonDecode(po.read<String>('raw_result')), isA<Map>());

    final lines = await q('SELECT * FROM po_lines ORDER BY line_no');
    expect(lines, hasLength(5));
    expect(lines.every((l) => l.read<String>('match_status') == 'new'), isTrue);
    expect(lines[0].read<String>('raw_name'), 'Kbl Type C 100cm');
    expect(lines[0].read<double>('qty'), 20);
    expect(lines[0].read<int>('unit_price'), 9500);
    expect(lines[3].read<int?>('unit_price'), isNull);
    expect(jsonDecode(lines[2].read<String>('confidence'))['unit_price'], 0.62);
  });

  test('a known supplier (by name) enables auto and suggested matches', () async {
    final pid = await products.addManual(
      const NewProductInput(
        name: 'Kabel Micro USB 1M',
        supplierName: 'cv  maju elektrik',
        supplyPrice: 7000,
      ),
    );
    await insertPo('po1');
    await importer.importResult('po1', sampleJson);

    final po = (await q('SELECT supplier_id FROM purchase_orders')).single;
    expect(po.read<String?>('supplier_id'), isNotNull);
    final s = await statuses('po1');
    expect(s['Kabel Micro USB 1M'], 'suggested'); // same name, no alias yet
    expect(s['Sarung HP Silikon'], 'new');
    final matched = (await q(
      "SELECT matched_product_id FROM po_lines WHERE raw_name = 'Kabel Micro USB 1M'",
    )).single;
    expect(matched.read<String>('matched_product_id'), pid);
  });

  test('supplier is found by phone even when the printed name differs', () async {
    await db.customStatement(
      "INSERT INTO suppliers (id, name, phone) VALUES ('s1', 'Maju', '+62 812-3456-7890')",
    );
    await insertPo('po1');
    final j = jsonDecode(sampleJson) as Map<String, Object?>;
    (j['supplier'] as Map)['name'] = 'Toko Lain';
    (j['supplier'] as Map)['phone'] = '0812 3456 7890';
    await importer.importResult('po1', jsonEncode(j));
    expect((await q('SELECT supplier_id FROM purchase_orders')).single.read<String>('supplier_id'),
        's1');
  });

  test('the loop closes: review one PO, the same lines auto-match on the next', () async {
    await insertPo('po1');
    await importer.importResult('po1', sampleJson);

    // Owner creates the three product lines as new products, ignores the rest.
    final lines = await q('SELECT id, raw_name FROM po_lines ORDER BY line_no');
    final reviewed = [
      for (final l in lines)
        switch (l.read<String>('raw_name')) {
          'Kbl Type C 100cm' => ReviewedLine.createNew(
            poLineId: l.read<String>('id'),
            rawName: 'Kbl Type C 100cm',
            newName: 'Kabel USB-C 1M',
            unitPrice: 9500,
          ),
          'Kabel Micro USB 1M' => ReviewedLine.createNew(
            poLineId: l.read<String>('id'),
            rawName: 'Kabel Micro USB 1M',
            newName: 'Kabel Micro USB 1M',
            unitPrice: 7000,
          ),
          'Chrgr Fast 20W' => ReviewedLine.createNew(
            poLineId: l.read<String>('id'),
            rawName: 'Chrgr Fast 20W',
            newName: 'Charger Fast 20W',
            unitPrice: 38500,
          ),
          _ => ReviewedLine.ignore(poLineId: l.read<String>('id')),
        },
    ];
    await ReviewService(db, products).save(
      ReviewedPo(poId: 'po1', supplierName: 'CV Maju Elektrik', lines: reviewed),
    );

    // Same supplier sends the same items again, slightly re-typed.
    await insertPo('po2');
    final j = jsonDecode(sampleJson) as Map<String, Object?>;
    ((j['lines'] as List)[0] as Map)['name'] = 'KBL type c 100CM';
    await importer.importResult('po2', jsonEncode(j));

    final s = await statuses('po2');
    expect(s['KBL type c 100CM'], 'auto');
    expect(s['Kabel Micro USB 1M'], 'auto');
    expect(s['Chrgr Fast 20W'], 'auto');
    expect(s['Sarung HP Silikon'], 'new');
  });

  test('a malformed result leaves the PO untouched', () async {
    await insertPo('po1');
    final j = jsonDecode(sampleJson) as Map<String, Object?>;
    ((j['lines'] as List).first as Map)['unit_price'] = 9500.5;
    await expectLater(
      importer.importResult('po1', jsonEncode(j)),
      throwsFormatException,
    );
    await expectLater(importer.importResult('po1', 'not json'), throwsFormatException);
    expect((await q('SELECT status FROM purchase_orders')).single.read<String>('status'),
        'processing');
    expect(await q('SELECT * FROM po_lines'), isEmpty);
  });

  test('only a processing PO can be imported, and only once', () async {
    await insertPo('po1', status: 'queued');
    await expectLater(importer.importResult('po1', sampleJson), throwsStateError);

    await insertPo('po2');
    await importer.importResult('po2', sampleJson);
    await expectLater(importer.importResult('po2', sampleJson), throwsStateError);
    expect(await q('SELECT * FROM po_lines WHERE po_id = ?', ['po2']), hasLength(5));

    await expectLater(importer.importResult('missing', sampleJson), throwsArgumentError);
  });

  test('normalizePhone', () {
    expect(normalizePhone('+62 812-3456-7890'), '08123456789 0'.replaceAll(' ', ''));
    expect(normalizePhone('0812 3456 7890'), '081234567890');
    expect(normalizePhone('0812xxxx'), isNull);
    expect(normalizePhone('123'), isNull);
    expect(normalizePhone(null), isNull);
  });
}
