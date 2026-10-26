import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_application_1/core/server_api.dart';
import 'package:flutter_application_1/data/owner_database.dart';
import 'package:flutter_application_1/products/product_service.dart';
import 'package:flutter_application_1/publish/publish_service.dart';
import 'package:flutter_application_1/team/owner_account_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_server_api.dart';

void main() {
  late OwnerDatabase db;
  late ProductService products;
  late FakeServerApi api;
  late PublishService publish;
  late String store;

  setUp(() async {
    db = OwnerDatabase(NativeDatabase.memory());
    products = ProductService(db);
    api = FakeServerApi();
    publish = PublishService(db, api);
    await api.signUp('budi@email.com', 'rahasia123');
    await OwnerAccountService(db, api).createStore('Toko Berkah');
    store = api.stores.keys.single;
  });
  tearDown(() => db.close());

  Future<String> add(String name, {String? category}) => products.addManual(
    NewProductInput(
      name: name,
      supplierName: 'CV Rahasia Supplier',
      supplyPrice: 9500,
      categoryName: category,
      model: 'TC-100',
    ),
  );

  Future<int> unsent() async => (await db
          .customSelect('SELECT COUNT(*) AS n FROM products_to_publish')
          .getSingle())
      .read<int>('n');

  test('payload has only the whitelisted fields and no supplier data', () async {
    await add('Kabel Type C', category: 'Kabel');
    final result = await publish.publish();

    expect(result.outcome, PublishOutcome.sent);
    expect(result.sent, 1);
    final item = api.payloads.single.single;
    expect(item.keys.toSet(), PublishService.allowedFields);
    final json = jsonEncode(api.payloads);
    expect(json, isNot(contains('Rahasia'))); // supplier name
    expect(json, isNot(contains('9500'))); // supply price
    expect(item['category'], 'Kabel');
    expect(item['is_deleted'], false);
    expect(await unsent(), 0);
  });

  test('published_at is the updated_at that was sent, not now', () async {
    final id = await add('Kabel');
    final before = (await db
            .customSelect(
              'SELECT updated_at FROM products WHERE id = ?',
              variables: [Variable.withString(id)],
            )
            .getSingle())
        .read<String>('updated_at');
    await publish.publish();
    final after = (await db
            .customSelect(
              'SELECT published_at FROM products WHERE id = ?',
              variables: [Variable.withString(id)],
            )
            .getSingle())
        .read<String>('published_at');
    expect(after, before);
  });

  test('a product edited during the upload stays unsent', () async {
    final id = await add('Kabel');
    api.duringPublish = () async {
      api.duringPublish = null;
      // Make sure the new updated_at is later than the one being sent.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await products.setRetailOverride(id, 25000);
    };
    await publish.publish();
    expect(await unsent(), 1);

    final second = await publish.publish();
    expect(second.sent, 1);
    expect(api.payloads.last.single['retail_price'], 25000);
    expect(await unsent(), 0);
  });

  test('sends in batches of 200', () async {
    for (var i = 0; i < 450; i++) {
      await add('Produk $i');
    }
    final result = await publish.publish();
    expect(result.sent, 450);
    expect(api.payloads.map((p) => p.length), [200, 200, 50]);
  });

  test('deleted products go out as is_deleted', () async {
    final id = await add('Kabel');
    await publish.publish();
    await products.deleteProduct(id);
    await publish.publish();
    expect(api.payloads.last.single['is_deleted'], true);
  });

  test('offline: nothing is lost, it goes out next time', () async {
    await add('Kabel');
    api.offline = true;
    final r = await publish.publish();
    expect(r.outcome, PublishOutcome.offline);
    expect(await unsent(), 1);

    api.offline = false;
    expect((await publish.publish()).outcome, PublishOutcome.sent);
    expect(await unsent(), 0);
  });

  test('not connected: no store, signed out, or employee session', () async {
    await add('Kabel');
    await api.signOut();
    expect(
      (await publish.publish()).outcome,
      PublishOutcome.notConnected,
    );
    await api.signInAnonymously();
    expect(
      (await publish.publish()).outcome,
      PublishOutcome.notConnected,
    );
    expect(
      (await PublishService(db, null).publish()).outcome,
      PublishOutcome.notConnected,
    );
  });

  test('another account is refused and nothing is marked sent', () async {
    await add('Kabel');
    await api.signIn('lain@email.com', 'rahasia123');
    final r = await publish.publish();
    expect(r.outcome, PublishOutcome.notAllowed);
    expect(r.error?.kind, ServerErrorKind.notAllowed);
    expect(await unsent(), 1);
    expect(store, isNotEmpty);
  });
}
