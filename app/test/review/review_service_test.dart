import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_application_1/data/owner_database.dart';
import 'package:flutter_application_1/matching/match_repository.dart';
import 'package:flutter_application_1/matching/product_matcher.dart';
import 'package:flutter_application_1/products/product_service.dart';
import 'package:flutter_application_1/review/review_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late OwnerDatabase db;
  late ProductService products;
  late ReviewService review;
  var tick = 0;

  setUp(() {
    db = OwnerDatabase(NativeDatabase.memory());
    tick = 0;
    DateTime now() => DateTime.utc(2026, 10, 4, 8, tick++);
    products = ProductService(db, now: now);
    review = ReviewService(db, products, now: now);
  });
  tearDown(() => db.close());

  Future<List<QueryRow>> q(String sql, [List<Object?> args = const []]) => db
      .customSelect(
        sql,
        variables: [
          for (final a in args)
            a is int ? Variable.withInt(a) : Variable.withString(a as String),
        ],
      )
      .get();

  Future<void> insertPo(String poId, List<(String id, String raw, String status, String? product)> lines,
      {String status = 'needs_review'}) async {
    await db.customStatement(
      "INSERT INTO purchase_orders (id, status, source) VALUES (?, ?, 'gallery')",
      [poId, status],
    );
    var n = 1;
    for (final (id, raw, st, product) in lines) {
      await db.customStatement(
        'INSERT INTO po_lines (id, po_id, line_no, raw_name, match_status, matched_product_id) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        [id, poId, n++, raw, st, product],
      );
    }
  }

  Future<String> existingProduct({String supplier = 'CV Maju', int supply = 9500}) =>
      products.addManual(
        NewProductInput(
          name: 'Kabel USB-C',
          model: '1M',
          supplierName: supplier,
          supplyPrice: supply,
        ),
      );

  Future<String> supplierId(String name) async =>
      (await q('SELECT id FROM suppliers WHERE name = ?', [name])).single.read<String>('id');

  test('link: remembers alias, records price on PO date, updates retail and statuses', () async {
    final pid = await existingProduct(supply: 9500);
    await insertPo('po1', [('l1', 'Kbl Type C 100cm', 'suggested', pid)]);

    await review.save(
      ReviewedPo(
        poId: 'po1',
        supplierName: 'CV Maju',
        poDate: DateTime.utc(2026, 10, 10),
        lines: [
          ReviewedLine.link(
            poLineId: 'l1',
            rawName: ' Kbl Type C 100cm ',
            productId: pid,
            unitPrice: 12000,
          ),
        ],
      ),
    );

    final sup = await supplierId('CV Maju');
    final alias = (await q('SELECT * FROM product_aliases')).single;
    expect(alias.read<String>('product_id'), pid);
    expect(alias.read<String>('supplier_id'), sup);
    expect(alias.read<String>('alias'), 'Kbl Type C 100cm');
    expect(alias.read<String>('alias_norm'), 'kbl type c 100cm');

    final price = (await q(
      'SELECT * FROM supplier_prices WHERE po_line_id = ?',
      ['l1'],
    )).single;
    expect(price.read<int>('unit_price'), 12000);
    expect(price.read<String>('observed_at'), startsWith('2026-10-10'));

    // basis 'highest' by default: 12.000 is now the basis supply, so a new
    // retail price is proposed, but the current one stays until it is confirmed.
    final prices = (await q('SELECT retail_price, pending_retail FROM products WHERE id = ?', [pid])).single;
    expect(prices.read<int>('retail_price'), 15000);
    expect(prices.read<int>('pending_retail'), (await products.preview(12000)).retail);

    final line = (await q('SELECT * FROM po_lines WHERE id = ?', ['l1'])).single;
    expect(line.read<String>('match_status'), 'confirmed');
    expect(line.read<String>('matched_product_id'), pid);

    final po = (await q('SELECT * FROM purchase_orders WHERE id = ?', ['po1'])).single;
    expect(po.read<String>('status'), 'saved');
    expect(po.read<String>('supplier_id'), sup);
    expect(po.read<String>('po_date'), '2026-10-10');
    expect(po.read<String?>('reviewed_at'), isNotNull);
  });

  test('createNew: creates product, alias, price and retail', () async {
    await insertPo('po1', [('l1', 'Sarung HP Silikon', 'new', null)]);

    await review.save(
      ReviewedPo(
        poId: 'po1',
        supplierName: 'Toko Baru',
        lines: [
          const ReviewedLine.createNew(
            poLineId: 'l1',
            rawName: 'Sarung HP Silikon',
            newName: 'Casing HP Silikon',
            newCategory: 'Aksesoris',
            unitPrice: 9500,
          ),
        ],
      ),
    );

    final p = (await q('SELECT * FROM products WHERE name = ?', ['Casing HP Silikon'])).single;
    expect(p.read<int>('retail_price'), 15000); // pricing vector: 9.500 -> 15.000
    expect(p.read<String?>('category_id'), isNotNull);
    expect((await q('SELECT * FROM product_aliases')).single.read<String>('product_id'),
        p.read<String>('id'));
    final line = (await q('SELECT * FROM po_lines')).single;
    expect(line.read<String>('match_status'), 'new');
    expect(line.read<String>('matched_product_id'), p.read<String>('id'));
  });

  test('ignore: nothing is created and the line is marked ignored', () async {
    await insertPo('po1', [('l1', 'Ongkir', 'new', null)]);
    await review.save(
      const ReviewedPo(
        poId: 'po1',
        supplierName: 'CV Maju',
        lines: [ReviewedLine.ignore(poLineId: 'l1')],
      ),
    );
    expect(await q('SELECT * FROM products'), isEmpty);
    expect(await q('SELECT * FROM product_aliases'), isEmpty);
    expect(await q('SELECT * FROM supplier_prices'), isEmpty);
    expect((await q('SELECT match_status FROM po_lines')).single.read<String>('match_status'),
        'ignored');
  });

  test('an untouched auto-match keeps its auto status', () async {
    final pid = await existingProduct();
    await insertPo('po1', [('l1', 'Kabel USB-C 1M', 'auto', pid)]);
    await review.save(
      ReviewedPo(
        poId: 'po1',
        supplierName: 'CV Maju',
        lines: [
          ReviewedLine.link(
            poLineId: 'l1',
            rawName: 'Kabel USB-C 1M',
            productId: pid,
            unitPrice: 9500,
          ),
        ],
      ),
    );
    expect((await q('SELECT match_status FROM po_lines')).single.read<String>('match_status'),
        'auto');
  });

  test('a manual retail price (override) is never recalculated', () async {
    final pid = await existingProduct(supply: 9500);
    await products.setRetailOverride(pid, 17500);
    await insertPo('po1', [('l1', 'Kabel', 'suggested', pid)]);
    await review.save(
      ReviewedPo(
        poId: 'po1',
        supplierName: 'CV Maju',
        lines: [
          ReviewedLine.link(
            poLineId: 'l1',
            rawName: 'Kabel',
            productId: pid,
            unitPrice: 30000,
          ),
        ],
      ),
    );
    final p = (await q('SELECT retail_price, retail_is_override FROM products')).single;
    expect(p.read<int>('retail_price'), 17500);
    expect(p.read<int>('retail_is_override'), 1);
    expect((await q('SELECT * FROM supplier_prices')).length, 2);
  });

  test('an older PO does not become the latest price', () async {
    await db.customStatement("UPDATE settings SET basis = 'latest' WHERE id = 1");
    final pid = await existingProduct(supply: 9500); // observed 2026-10-04
    final before = (await q('SELECT retail_price FROM products')).single.read<int>('retail_price');
    await insertPo('po1', [('l1', 'Kabel', 'suggested', pid)]);
    await review.save(
      ReviewedPo(
        poId: 'po1',
        supplierName: 'CV Maju',
        poDate: DateTime.utc(2026, 9, 1),
        lines: [
          ReviewedLine.link(
            poLineId: 'l1',
            rawName: 'Kabel',
            productId: pid,
            unitPrice: 30000,
          ),
        ],
      ),
    );
    expect((await q('SELECT retail_price FROM products')).single.read<int>('retail_price'), before);
    expect((await q('SELECT * FROM supplier_prices')).length, 2);
  });

  test('an unreadable price still links but records no price', () async {
    final pid = await existingProduct();
    await insertPo('po1', [('l1', 'Kabel', 'suggested', pid)]);
    await review.save(
      ReviewedPo(
        poId: 'po1',
        supplierName: 'CV Maju',
        lines: [ReviewedLine.link(poLineId: 'l1', rawName: 'Kabel', productId: pid)],
      ),
    );
    expect((await q('SELECT * FROM supplier_prices')).length, 1);
    expect((await q('SELECT * FROM product_aliases')).length, 1);
  });

  test('relinking an existing alias moves it to the new product', () async {
    final a = await existingProduct();
    final b = await products.addManual(
      const NewProductInput(name: 'Kabel Lain', supplierName: 'CV Maju', supplyPrice: 5000),
    );
    for (final (po, target) in [('po1', a), ('po2', b)]) {
      await insertPo(po, [('l-$po', 'Kabel X', 'suggested', null)]);
      await review.save(
        ReviewedPo(
          poId: po,
          supplierName: 'CV Maju',
          lines: [ReviewedLine.link(poLineId: 'l-$po', rawName: 'Kabel X', productId: target)],
        ),
      );
    }
    expect((await q('SELECT product_id FROM product_aliases')).single.read<String>('product_id'), b);
  });

  test('rejects a second save and writes nothing the second time', () async {
    final pid = await existingProduct();
    await insertPo('po1', [('l1', 'Kabel', 'suggested', pid)]);
    final po = ReviewedPo(
      poId: 'po1',
      supplierName: 'CV Maju',
      lines: [
        ReviewedLine.link(poLineId: 'l1', rawName: 'Kabel', productId: pid, unitPrice: 9000),
      ],
    );
    await review.save(po);
    await expectLater(review.save(po), throwsStateError);
    expect((await q('SELECT * FROM supplier_prices')).length, 2);
  });

  test('rejects lines that differ from the PO lines, writing nothing', () async {
    final pid = await existingProduct();
    await insertPo('po1', [
      ('l1', 'Kabel', 'suggested', pid),
      ('l2', 'Charger', 'new', null),
    ]);
    await expectLater(
      review.save(
        ReviewedPo(
          poId: 'po1',
          supplierName: 'CV Maju',
          lines: [
            ReviewedLine.link(poLineId: 'l1', rawName: 'Kabel', productId: pid, unitPrice: 9000),
          ],
        ),
      ),
      throwsArgumentError,
    );
    expect((await q('SELECT status FROM purchase_orders')).single.read<String>('status'),
        'needs_review');
    expect((await q('SELECT * FROM product_aliases')), isEmpty);
    expect((await q('SELECT * FROM supplier_prices')).length, 1);
  });

  test('a PO that is not waiting for review cannot be saved', () async {
    await insertPo('po1', [('l1', 'Kabel', 'new', null)], status: 'processing');
    await expectLater(
      review.save(
        const ReviewedPo(
          poId: 'po1',
          supplierName: 'CV Maju',
          lines: [ReviewedLine.ignore(poLineId: 'l1')],
        ),
      ),
      throwsStateError,
    );
  });

  test('learning loop: the next PO auto-links the saved name', () async {
    await insertPo('po1', [('l1', 'Kbl Type C 100cm', 'new', null)]);
    await review.save(
      const ReviewedPo(
        poId: 'po1',
        supplierName: 'CV Maju',
        lines: [
          ReviewedLine.createNew(
            poLineId: 'l1',
            rawName: 'Kbl Type C 100cm',
            newName: 'Kabel USB-C 1M',
            unitPrice: 9500,
          ),
        ],
      ),
    );

    final sup = await supplierId('CV Maju');
    final matcher = await MatchRepository(db).buildMatcher();
    final r = matcher.match(rawName: 'KBL  type c 100CM', supplierId: sup, unitPrice: 9600);
    expect(r.status, MatchStatus.auto);
    // And the dictionary learned the abbreviation from the saved pair.
    expect(matcher.dictionary.entries['kbl'], 'kabel');
  });
}
