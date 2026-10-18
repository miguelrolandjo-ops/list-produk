import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_application_1/data/owner_database.dart';
import 'package:flutter_application_1/inbox/po_import_service.dart';
import 'package:flutter_application_1/products/product_service.dart';
import 'package:flutter_application_1/review/review_draft.dart';
import 'package:flutter_application_1/review/review_draft_loader.dart';
import 'package:flutter_application_1/review/review_service.dart';
import 'package:flutter_test/flutter_test.dart';

DraftLine line(
  String id, {
  DraftKind kind = DraftKind.isNew,
  int? price = 9500,
  double priceConf = 0.95,
  double nameConf = 0.95,
  String? productId,
}) => DraftLine(
  poLineId: id,
  rawName: 'Raw $id',
  kind: kind,
  newName: 'Raw $id',
  productId: productId,
  productName: productId == null ? null : 'Produk $productId',
  unit: 'pcs',
  unitPrice: price,
  unitPriceConfidence: priceConf,
  nameConfidence: nameConf,
);

ReviewDraft draft(List<DraftLine> lines, {String supplier = 'CV Maju'}) =>
    ReviewDraft(
      poId: 'po1',
      supplierName: supplier,
      supplierMatched: true,
      supplierConfidence: 0.96,
      knownSuppliers: {'cv maju'},
      lines: lines,
    );

void main() {
  group('ReviewDraft', () {
    test('a suggestion blocks saving until answered', () {
      var d = draft([line('a', kind: DraftKind.suggestion, productId: 'p1')]);
      expect(d.canSave, isFalse);
      expect(d.blocker, 'Jawab 1 saran produk dulu');
      d = d.accept(0);
      expect(d.lines[0].kind, DraftKind.linked);
      expect(d.canSave, isTrue);
    });

    test('rejecting a suggestion makes a new product and drops the link', () {
      final d = draft([
        line('a', kind: DraftKind.suggestion, productId: 'p1'),
      ]).makeNew(0);
      expect(d.lines[0].kind, DraftKind.isNew);
      expect(d.lines[0].productId, isNull);
    });

    test('accept only applies to suggestions', () {
      final d = draft([line('a')]).accept(0);
      expect(d.lines[0].kind, DraftKind.isNew);
    });

    test('a new product needs a price and a name', () {
      var d = draft([line('a', price: null)]);
      expect(d.blocker, 'Isi harga untuk 1 produk baru');
      d = d.setPrice(0, 12000);
      expect(d.canSave, isTrue);
      d = d.rename(0, '  ');
      expect(d.blocker, 'Isi nama untuk produk baru');
    });

    test('a linked line may have no price', () {
      final d = draft([
        line('a', kind: DraftKind.auto, price: null, productId: 'p1'),
      ]);
      expect(d.canSave, isTrue);
      expect(d.lines[0].hint, LineHint.priceMissing);
    });

    test('ignored lines are skipped by every check and the count', () {
      var d = draft([
        line('a', kind: DraftKind.suggestion, productId: 'p1'),
        line('b', price: null),
        line('c', kind: DraftKind.auto, productId: 'p2'),
      ]);
      d = d.toggleIgnore(0).toggleIgnore(1);
      expect(d.canSave, isTrue);
      expect(d.saveCount, 1);
      d = d.toggleIgnore(0);
      expect(d.saveCount, 2);
      expect(d.canSave, isFalse);
    });

    test('all lines ignored cannot be saved', () {
      final d = draft([line('a')]).toggleIgnore(0);
      expect(d.blocker, 'Semua baris diabaikan');
    });

    test('empty supplier blocks saving', () {
      expect(draft([line('a')], supplier: '').blocker, 'Isi nama supplier');
      expect(
        draft([line('a')]).setSupplierName('  Toko X ').supplierName,
        'Toko X',
      );
    });

    test('price hints clear once the owner edits the price', () {
      var d = draft([line('a', priceConf: 0.62)]);
      expect(d.lines[0].hint, LineHint.priceUnclear);
      d = d.setPrice(0, 38500);
      expect(d.lines[0].hint, LineHint.none);
      expect(
        () => d.setPrice(0, 0),
        throwsArgumentError,
        reason: 'Rupiah prices must be positive',
      );
    });

    test('an unclear name is flagged only on new products, cleared by rename', () {
      var d = draft([
        line('a', nameConf: 0.5),
        line('b', kind: DraftKind.auto, productId: 'p1', nameConf: 0.5),
      ]);
      expect(d.lines[0].hint, LineHint.nameUnclear);
      expect(d.lines[1].hint, LineHint.none);
      d = d.rename(0, 'Nama bagus');
      expect(d.lines[0].hint, LineHint.none);
    });

    test('supplier pill: known name, confidence only while unchanged', () {
      var d = draft([line('a')]);
      expect(d.supplierIsKnown, isTrue);
      expect(d.showSupplierConfidence, isTrue);
      d = d.setSupplierName('cv  MAJU');
      expect(d.supplierIsKnown, isTrue);
      expect(d.showSupplierConfidence, isFalse);
      expect(d.setSupplierName('Toko Baru').supplierIsKnown, isFalse);
    });

    test('toReviewedPo maps every decision', () {
      final d = draft([
        line('auto', kind: DraftKind.auto, productId: 'p1'),
        line('sug', kind: DraftKind.linked, productId: 'p2'),
        line('new'),
        line('skip'),
      ]).toggleIgnore(3);
      final po = d.toReviewedPo();
      expect(po.poId, 'po1');
      expect(po.lines.map((l) => l.decision), [
        LineDecision.link,
        LineDecision.link,
        LineDecision.createNew,
        LineDecision.ignore,
      ]);
      expect(po.lines[0].productId, 'p1');
      expect(po.lines[2].newName, 'Raw new');
      expect(po.lines[2].unitPrice, 9500);
    });

    test('toReviewedPo refuses while blocked', () {
      expect(
        () => draft([line('a', kind: DraftKind.suggestion, productId: 'p')])
            .toReviewedPo(),
        throwsStateError,
      );
    });
  });

  group('ReviewDraftLoader', () {
    late OwnerDatabase db;
    late ProductService products;
    final sample = File('../shared/extraction_sample.json').readAsStringSync();

    setUp(() {
      db = OwnerDatabase(NativeDatabase.memory());
      products = ProductService(db);
    });
    tearDown(() => db.close());

    Future<void> insertPo(String id, String status) => db.customStatement(
      "INSERT INTO purchase_orders (id, status, source) VALUES (?, ?, 'gallery')",
      [id, status],
    );

    test('loads an imported PO with a proposed new supplier', () async {
      await insertPo('po1', 'processing');
      await PoImportService(db).importResult('po1', sample);

      final d = await ReviewDraftLoader(db).load('po1');
      expect(d.supplierName, 'CV Maju Elektrik');
      expect(d.supplierMatched, isFalse);
      expect(d.supplierIsKnown, isFalse);
      expect(d.supplierConfidence, 0.96);
      expect(d.poDate, DateTime.utc(2026, 10, 4));
      expect(d.lines, hasLength(5));
      expect(d.lines.every((l) => l.kind == DraftKind.isNew), isTrue);
      expect(d.lines[2].unitPrice, 38500);
      expect(d.lines[2].hint, LineHint.priceUnclear); // 0.62
      expect(d.lines[3].hint, LineHint.priceMissing);
      expect(d.pendingSuggestions, 0);
    });

    test('loads suggestions with the product name', () async {
      await products.addManual(
        const NewProductInput(
          name: 'Kabel Micro USB 1M',
          supplierName: 'CV Maju Elektrik',
          supplyPrice: 7000,
        ),
      );
      await insertPo('po1', 'processing');
      await PoImportService(db).importResult('po1', sample);

      final d = await ReviewDraftLoader(db).load('po1');
      expect(d.supplierMatched, isTrue);
      expect(d.supplierIsKnown, isTrue);
      final l = d.lines.firstWhere((l) => l.rawName == 'Kabel Micro USB 1M');
      expect(l.kind, DraftKind.suggestion);
      expect(l.productName, 'Kabel Micro USB 1M');
      expect(d.blocker, 'Jawab 1 saran produk dulu');
    });

    test('a PO that is not waiting for review cannot be loaded', () async {
      await insertPo('po1', 'processing');
      await expectLater(ReviewDraftLoader(db).load('po1'), throwsStateError);
      await expectLater(ReviewDraftLoader(db).load('nope'), throwsStateError);
    });

    test('draft to save: the loaded draft saves through ReviewService', () async {
      await insertPo('po1', 'processing');
      await PoImportService(db).importResult('po1', sample);
      var d = await ReviewDraftLoader(db).load('po1');
      d = d.setPrice(3, 20000).toggleIgnore(4); // price the "Sarung", skip shipping
      await ReviewService(db, products).save(d.toReviewedPo());

      final names = await db
          .customSelect('SELECT name FROM products ORDER BY name')
          .get();
      expect(names, hasLength(4));
      expect(
        (await db.customSelect('SELECT status FROM purchase_orders').getSingle())
            .read<String>('status'),
        'saved',
      );
    });
  });
}
