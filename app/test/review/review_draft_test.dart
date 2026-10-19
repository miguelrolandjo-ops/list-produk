import 'dart:io';

import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Variable;
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

  group('default price from the catalog', () {
    late OwnerDatabase db;
    late ProductService products;
    final sample = File('../shared/extraction_sample.json').readAsStringSync();

    setUp(() {
      db = OwnerDatabase(NativeDatabase.memory());
      products = ProductService(db);
    });
    tearDown(() => db.close());

    Future<ReviewDraft> importSample({int sarungPrice = 18000}) async {
      await products.addManual(
        NewProductInput(
          name: 'Sarung HP Silikon',
          supplierName: 'CV Maju Elektrik',
          supplyPrice: sarungPrice,
        ),
      );
      await products.addManual(
        const NewProductInput(
          name: 'Charger Fast 20W',
          supplierName: 'CV Maju Elektrik',
          supplyPrice: 36000,
        ),
      );
      await db.customStatement(
        "INSERT INTO purchase_orders (id, status, source) VALUES ('po1', 'processing', 'gallery')",
      );
      await PoImportService(db).importResult('po1', sample);
      return ReviewDraftLoader(db).load('po1');
    }

    DraftLine byName(ReviewDraft d, String raw) =>
        d.lines.firstWhere((l) => l.rawName == raw);

    test('an unreadable price defaults to what this supplier charged before', () async {
      final d = await importSample();
      final l = byName(d, 'Sarung HP Silikon');
      expect(l.kind, DraftKind.suggestion);
      expect(l.unitPrice, 18000);
      expect(l.priceFromCatalog, isTrue);
      expect(l.hint, LineHint.priceFromCatalog); // still highlighted
    });

    test('a low-confidence price is kept, with the previous one for reference', () async {
      final d = await importSample();
      final l = byName(d, 'Chrgr Fast 20W');
      expect(l.kind, DraftKind.suggestion);
      expect(l.unitPrice, 38500); // as read, not replaced
      expect(l.previousPrice, 36000);
      expect(l.priceFromCatalog, isFalse);
      expect(l.hint, LineHint.priceUnclear);
    });

    test('a line with no match has no default', () async {
      final d = await importSample();
      final l = byName(d, 'Ongkos kirim');
      expect(l.previousPrice, isNull);
      expect(l.priceFromCatalog, isFalse);
    });

    test('no default when the PO supplier is not known yet', () async {
      await products.addManual(
        const NewProductInput(
          name: 'Sarung HP Silikon',
          supplierName: 'Toko Lain',
          supplyPrice: 18000,
        ),
      );
      await db.customStatement(
        "INSERT INTO purchase_orders (id, status, source) VALUES ('po1', 'processing', 'gallery')",
      );
      await PoImportService(db).importResult('po1', sample);
      final d = await ReviewDraftLoader(db).load('po1');
      expect(byName(d, 'Sarung HP Silikon').unitPrice, isNull);
    });

    test('rejecting the match drops the borrowed price', () async {
      var d = await importSample();
      final i = d.lines.indexWhere((l) => l.rawName == 'Sarung HP Silikon');
      d = d.makeNew(i);
      expect(d.lines[i].unitPrice, isNull);
      expect(d.lines[i].priceFromCatalog, isFalse);
      expect(d.lines[i].hint, LineHint.priceMissing);
    });

    test('an unchecked default is not saved as a new price; a checked one is', () async {
      var d = await importSample();
      final i = d.lines.indexWhere((l) => l.rawName == 'Sarung HP Silikon');
      // Keep only the Sarung line: link it, ignore the others.
      d = d.accept(i);
      for (var k = 0; k < d.lines.length; k++) {
        if (k != i) d = d.toggleIgnore(k);
      }
      ReviewedLine linked(ReviewedPo po) =>
          po.lines.singleWhere((l) => l.decision == LineDecision.link);

      expect(linked(d.toReviewedPo()).unitPrice, isNull);
      expect(linked(d.setPrice(i, 18000).toReviewedPo()).unitPrice, 18000);

      Future<int> priceRows() async => (await db
              .customSelect('SELECT COUNT(*) AS n FROM supplier_prices')
              .getSingle())
          .read<int>('n');
      final before = await priceRows();
      await ReviewService(db, products).save(d.toReviewedPo());
      expect(await priceRows(), before); // nothing new was observed
    });
  });

  group('category on new products', () {
    late OwnerDatabase db;
    late ProductService products;
    final sample = File('../shared/extraction_sample.json').readAsStringSync();

    setUp(() {
      db = OwnerDatabase(NativeDatabase.memory());
      products = ProductService(db);
    });
    tearDown(() => db.close());

    /// A catalog the owner already filed, none of it close enough to the
    /// sample lines to be offered as a match, so those lines stay new.
    Future<ReviewDraft> importWithCatalog() async {
      for (final (name, category) in [
        ('Kabel Roll 10M', 'Kabel'),
        ('Kabel Listrik 5M', 'Kabel'),
        ('Kabel HDMI 3M', 'Kabel'),
        ('Charger Mobil 2 Port', 'Charger'),
        ('Charger Laptop 65W', 'Charger'),
        ('Charger Adaptor 12V', 'Charger'),
      ]) {
        await products.addManual(
          NewProductInput(
            name: name,
            categoryName: category,
            supplierName: 'Toko Lama',
            supplyPrice: 9500,
          ),
        );
      }
      await db.customStatement(
        "INSERT INTO purchase_orders (id, status, source) VALUES ('po1', 'processing', 'gallery')",
      );
      await PoImportService(db).importResult('po1', sample);
      return ReviewDraftLoader(db).load('po1');
    }

    DraftLine byName(ReviewDraft d, String raw) =>
        d.lines.firstWhere((l) => l.rawName == raw);

    test('a new line starts with the category the catalog suggests', () async {
      final d = await importWithCatalog();
      final cable = byName(d, 'Kabel Micro USB 1M');
      expect(cable.kind, DraftKind.isNew);
      expect(cable.newCategory, 'Kabel');
      expect(cable.categoryChecked, isFalse); // still a guess
      expect(byName(d, 'Ongkos kirim').newCategory, isNull); // nothing similar
      expect(d.categoryOptions, ['Charger', 'Kabel']);
    });

    test('the owner can change or clear it; it is then a decision, not a guess', () async {
      var d = await importWithCatalog();
      final i = d.lines.indexWhere((l) => l.rawName == 'Kabel Micro USB 1M');
      d = d.setCategory(i, '  Aksesoris ');
      expect(d.lines[i].newCategory, 'Aksesoris');
      expect(d.lines[i].categoryChecked, isTrue);
      d = d.setCategory(i, '');
      expect(d.lines[i].newCategory, isNull);
      expect(d.lines[i].categoryChecked, isTrue);
    });

    test('rejecting a match gives the line its suggested category', () {
      const matched = DraftLine(
        poLineId: 'a',
        rawName: 'Kabel Data',
        kind: DraftKind.suggestion,
        newName: 'Kabel Data',
        productId: 'p1',
        productName: 'Kabel X',
        suggestedCategory: 'Kabel',
        unitPrice: 5000,
      );
      var d = draft([matched]);
      expect(d.lines[0].newCategory, isNull); // not a new product yet
      d = d.makeNew(0);
      expect(d.lines[0].newCategory, 'Kabel');
    });

    test('a category the owner chose survives rejecting and re-rejecting', () {
      var d = draft([
        const DraftLine(
          poLineId: 'a',
          rawName: 'Kabel Data',
          kind: DraftKind.isNew,
          newName: 'Kabel Data',
          suggestedCategory: 'Kabel',
          newCategory: 'Kabel',
          unitPrice: 5000,
        ),
      ]);
      d = d.setCategory(0, 'Aksesoris').makeNew(0);
      expect(d.lines[0].newCategory, 'Aksesoris');
    });

    test('the category is saved with the new product', () async {
      var d = await importWithCatalog();
      final sarung = d.lines.indexWhere((l) => l.rawName == 'Sarung HP Silikon');
      d = d.setPrice(sarung, 20000).setCategory(sarung, 'Casing');
      d = d.toggleIgnore(d.lines.indexWhere((l) => l.rawName == 'Ongkos kirim'));
      d = d.setPrice(d.lines.indexWhere((l) => l.rawName == 'Kbl Type C 100cm'), 9500);
      await ReviewService(db, products).save(d.toReviewedPo());

      Future<String?> categoryOf(String name) async => (await db
              .customSelect(
                'SELECT c.name AS n FROM products p '
                'LEFT JOIN categories c ON c.id = p.category_id WHERE p.name = ?',
                variables: [Variable.withString(name)],
              )
              .getSingle())
          .readNullable<String>('n');
      expect(await categoryOf('Kabel Micro USB 1M'), 'Kabel'); // suggestion kept
      expect(await categoryOf('Sarung HP Silikon'), 'Casing'); // owner's choice
      expect(await categoryOf('Kbl Type C 100cm'), isNull); // no suggestion
    });
  });

  group('link a line to a product by hand', () {
    const kabel = ProductOption(id: 'p1', name: 'Kabel USB-C', model: '1M', supplierPrice: 9500);
    const charger = ProductOption(id: 'p2', name: 'Charger Fast 20W');

    test('ProductOption.matches needs every word, in name or model', () {
      expect(kabel.matches(''), isTrue);
      expect(kabel.matches('kabel c'), isTrue);
      expect(kabel.matches('usb 1m'), isTrue); // 1M is the model
      expect(kabel.matches('kabel lightning'), isFalse);
    });

    test('a new line becomes linked to the picked product', () {
      final d = draft([line('a')]).linkTo(0, kabel);
      final l = d.lines[0];
      expect(l.kind, DraftKind.linked);
      expect(l.productId, 'p1');
      expect(l.productName, 'Kabel USB-C');
      expect(l.previousPrice, 9500);
      expect(l.unitPrice, 9500); // the PO price is kept (9500 here)
    });

    test('a suggestion can be pointed at a different product', () {
      final d = draft([line('a', kind: DraftKind.suggestion, productId: 'p9')])
          .linkTo(0, charger);
      expect(d.lines[0].kind, DraftKind.linked);
      expect(d.lines[0].productId, 'p2');
      expect(d.pendingSuggestions, 0);
      expect(d.canSave, isTrue);
    });

    test('a price read from the PO is kept, the product price is only a reference', () {
      final d = draft([line('a', price: 12000)]).linkTo(0, kabel);
      expect(d.lines[0].unitPrice, 12000);
      expect(d.lines[0].previousPrice, 9500);
      expect(d.lines[0].priceFromCatalog, isFalse);
    });

    test('a missing price defaults to the product price, still highlighted', () {
      final d = draft([line('a', price: null)]).linkTo(0, kabel);
      expect(d.lines[0].unitPrice, 9500);
      expect(d.lines[0].priceFromCatalog, isTrue);
      expect(d.lines[0].hint, LineHint.priceFromCatalog);
    });

    test('a price borrowed from the old match follows the new product', () {
      var d = draft([
        const DraftLine(
          poLineId: 'a',
          rawName: 'Kabel',
          kind: DraftKind.suggestion,
          newName: 'Kabel',
          productId: 'p9',
          productName: 'Old',
          unitPrice: 7000, // borrowed from p9's catalog price
          priceFromCatalog: true,
          previousPrice: 7000,
        ),
      ]);
      d = d.linkTo(0, kabel);
      expect(d.lines[0].unitPrice, 9500);
      expect(d.lines[0].priceFromCatalog, isTrue);

      // The new product has no known price for this supplier: nothing to borrow.
      d = d.linkTo(0, charger);
      expect(d.lines[0].unitPrice, isNull);
      expect(d.lines[0].priceFromCatalog, isFalse);
      expect(d.lines[0].hint, LineHint.priceMissing);
    });

    test('an ignored line stays ignored when linked', () {
      final d = draft([line('a')]).toggleIgnore(0).linkTo(0, kabel);
      expect(d.lines[0].ignored, isTrue);
      expect(d.lines[0].kind, DraftKind.linked);
    });

    test('the link is what gets saved', () {
      final po = draft([line('a')]).linkTo(0, kabel).toReviewedPo();
      expect(po.lines.single.decision, LineDecision.link);
      expect(po.lines.single.productId, 'p1');
    });
  });

  group('link by hand with the database', () {
    late OwnerDatabase db;
    late ProductService products;
    final sample = File('../shared/extraction_sample.json').readAsStringSync();

    setUp(() {
      db = OwnerDatabase(NativeDatabase.memory());
      products = ProductService(db);
    });
    tearDown(() => db.close());

    test('the loader offers every product with the price from this PO supplier', () async {
      await products.addManual(
        const NewProductInput(name: 'Kabel Roll', supplierName: 'CV Maju Elektrik', supplyPrice: 9500),
      );
      await products.addManual(
        const NewProductInput(name: 'Adaptor', supplierName: 'Toko Lain', supplyPrice: 5000),
      );
      final gone = await products.addManual(
        const NewProductInput(name: 'Dihapus', supplierName: 'CV Maju Elektrik', supplyPrice: 1000),
      );
      await products.deleteProduct(gone);
      await db.customStatement(
        "INSERT INTO purchase_orders (id, status, source) VALUES ('po1', 'processing', 'gallery')",
      );
      await PoImportService(db).importResult('po1', sample);

      final d = await ReviewDraftLoader(db).load('po1');
      expect(d.productOptions.map((o) => o.name), ['Adaptor', 'Kabel Roll']); // no deleted
      final byName = {for (final o in d.productOptions) o.name: o.supplierPrice};
      expect(byName['Kabel Roll'], 9500); // charged by this PO's supplier
      expect(byName['Adaptor'], isNull); // another supplier's product
    });

    test('saving teaches the alias, so the next PO links by itself', () async {
      final pid = await products.addManual(
        const NewProductInput(name: 'Casing Silikon Premium', supplierName: 'CV Maju Elektrik', supplyPrice: 18000),
      );
      await db.customStatement(
        "INSERT INTO purchase_orders (id, status, source) VALUES ('po1', 'processing', 'gallery')",
      );
      await PoImportService(db).importResult('po1', sample);
      var d = await ReviewDraftLoader(db).load('po1');

      // The matcher knew nothing about this line; the owner picks the product.
      final i = d.lines.indexWhere((l) => l.rawName == 'Sarung HP Silikon');
      expect(d.lines[i].kind, DraftKind.isNew);
      final option = d.productOptions.singleWhere((o) => o.id == pid);
      d = d.linkTo(i, option);
      for (var k = 0; k < d.lines.length; k++) {
        if (k != i) d = d.toggleIgnore(k);
      }
      await ReviewService(db, products).save(d.toReviewedPo());

      await db.customStatement(
        "INSERT INTO purchase_orders (id, status, source) VALUES ('po2', 'processing', 'gallery')",
      );
      await PoImportService(db).importResult('po2', sample);
      final line = (await db
              .customSelect(
                "SELECT match_status, matched_product_id FROM po_lines "
                "WHERE po_id = 'po2' AND raw_name = 'Sarung HP Silikon'",
              )
              .getSingle());
      expect(line.read<String>('match_status'), 'auto');
      expect(line.read<String>('matched_product_id'), pid);
    });
  });
}
