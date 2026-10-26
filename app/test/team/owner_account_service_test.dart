import 'package:drift/native.dart';
import 'package:flutter_application_1/data/owner_database.dart';
import 'package:flutter_application_1/products/product_service.dart';
import 'package:flutter_application_1/team/owner_account_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_server_api.dart';

void main() {
  late OwnerDatabase db;
  late FakeServerApi api;
  late OwnerAccountService account;

  setUp(() {
    db = OwnerDatabase(NativeDatabase.memory());
    api = FakeServerApi();
    account = OwnerAccountService(db, api);
  });
  tearDown(() => db.close());

  test('no server, signed out, no store, linked', () async {
    expect(
      (await OwnerAccountService(db, null).check()).state,
      OwnerLinkState.notConfigured,
    );
    expect((await account.check()).state, OwnerLinkState.signedOut);

    await account.signUp('budi@email.com', 'rahasia123');
    expect((await account.check()).state, OwnerLinkState.noStore);

    await account.createStore('  Toko Berkah ');
    final link = await account.check();
    expect(link.state, OwnerLinkState.linked);
    expect(link.storeName, 'Toko Berkah');
    expect(await account.storeId(), api.stores.keys.single);
  });

  test('an employee (anonymous) session counts as signed out', () async {
    await api.signInAnonymously();
    expect((await account.check()).state, OwnerLinkState.signedOut);
  });

  test('a restored backup from another account is notOwner', () async {
    await account.signUp('budi@email.com', 'rahasia123');
    await account.createStore('Toko Berkah');
    await account.signIn('lain@email.com', 'rahasia123');
    expect((await account.check()).state, OwnerLinkState.notOwner);
  });

  test('offline: shown as linked from local data', () async {
    await account.signUp('budi@email.com', 'rahasia123');
    await account.createStore('Toko Berkah');
    api.offline = true;
    final link = await account.check();
    expect(link.state, OwnerLinkState.linked);
    expect(link.offline, isTrue);
  });

  test('a new store marks every product unsent', () async {
    await ProductService(db).addManual(
      const NewProductInput(name: 'Kabel', supplierName: 'CV', supplyPrice: 9500),
    );
    await db.customStatement(
      "UPDATE products SET published_at = '2099-01-01T00:00:00.000Z'",
    );
    await account.signUp('budi@email.com', 'rahasia123');
    await account.createStore('Toko Berkah');
    final n = (await db
            .customSelect('SELECT COUNT(*) AS n FROM products_to_publish')
            .getSingle())
        .read<int>('n');
    expect(n, 1);
  });
}
