import 'package:drift/native.dart';
import 'package:flutter_application_1/catalog/employee_catalog_repository.dart';
import 'package:flutter_application_1/catalog/employee_session.dart';
import 'package:flutter_application_1/catalog/employee_sync_service.dart';
import 'package:flutter_application_1/catalog/join_service.dart';
import 'package:flutter_application_1/core/app_mode.dart';
import 'package:flutter_application_1/core/server_api.dart';
import 'package:flutter_application_1/data/employee_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_server_api.dart';

CatalogRow row(
  String id,
  String name, {
  String? category,
  int? price,
  bool deleted = false,
  String at = '2026-10-26T08:00:00Z',
}) => CatalogRow(
  id: id,
  name: name,
  category: category,
  retailPrice: price,
  isDeleted: deleted,
  updatedAt: at,
);

void main() {
  late EmployeeDatabase db;
  late EmployeeCatalogRepository repo;

  setUp(() {
    db = EmployeeDatabase(NativeDatabase.memory());
    repo = EmployeeCatalogRepository(db);
  });
  tearDown(() => db.close());

  group('search (FTS5, offline)', () {
    setUp(() => repo.apply([
      row('1', 'Kabel Type C 100cm', category: 'Kabel', price: 15000),
      row('2', 'Kabel Lightning', category: 'Kabel', price: 20000),
      row('3', 'Charger USB-C 20W', category: 'Charger', price: 45000),
      row('4', 'Wajan anti lengket', price: 85000),
    ]));

    Future<List<String>> names(String q, {String? category}) async => [
      for (final e in await repo.search(q, category: category)) e.name,
    ];

    test('partial words: "kab" finds Kabel', () async {
      expect(await names('kab'), ['Kabel Lightning', 'Kabel Type C 100cm']);
    });

    test('every word must match', () async {
      expect(await names('kab ty'), ['Kabel Type C 100cm']);
    });

    test('punctuation splits words like the index does', () async {
      expect(await names('usb-c'), ['Charger USB-C 20W']);
    });

    test('quotes and symbols cannot break the query', () async {
      expect(await names('"kab*'), ['Kabel Lightning', 'Kabel Type C 100cm']);
      expect(await names('***'), hasLength(4)); // nothing searchable = all
    });

    test('category filter, and products without a category', () async {
      expect(await names('', category: 'Charger'), ['Charger USB-C 20W']);
      expect(await names('', category: noCategoryFilter), ['Wajan anti lengket']);
      expect(await names('kabel', category: 'Charger'), isEmpty);
    });

    test('updated rows are found by their new name only', () async {
      await repo.apply([row('2', 'Kabel Micro USB', category: 'Kabel')]);
      expect(await names('lightning'), isEmpty);
      expect(await names('micro'), ['Kabel Micro USB']);
    });

    test('deleted rows disappear from the catalog and the index', () async {
      await repo.apply([row('1', 'Kabel Type C 100cm', deleted: true)]);
      expect(await names('type'), isEmpty);
      expect(await repo.count(), 3);
    });
  });

  group('sync', () {
    late FakeServerApi api;
    late EmployeeSessionStore session;
    late String store;

    Future<void> ownerPublishes(List<(String, String)> items) async {
      final employee = api.user;
      api.user = const ServerUser(id: 'owner', isAnonymous: false);
      await api.publishCatalog(store, [
        for (final (id, name) in items)
          {'id': id, 'name': name, 'unit': 'pcs', 'retail_price': 10000},
      ]);
      api.user = employee;
    }

    setUp(() async {
      api = FakeServerApi(maxRows: 3);
      session = EmployeeSessionStore(MemoryKeyValueStore());
      api.user = const ServerUser(id: 'owner', isAnonymous: false);
      store = await api.createStore('Toko Berkah');
      final code = await api.createInvite(store);
      await JoinService(api, session, repo).join(code, name: 'Sari', device: 'Android');
    });

    test('downloads changes after the cursor and saves the cursor', () async {
      final sync = EmployeeSyncService(repo, api, session, pageSize: 3);
      await ownerPublishes([('a', 'Kabel'), ('b', 'Charger')]);
      expect(await sync.sync(), SyncOutcome.synced);
      expect(await repo.count(), 2);
      final cursor = session.read()!.cursor;
      expect(cursor, isNotNull);

      await ownerPublishes([('c', 'Lampu')]);
      expect(await sync.sync(), SyncOutcome.synced);
      expect(await repo.count(), 3);
      expect(session.read()!.cursor!.compareTo(cursor!), greaterThan(0));
      expect(session.read()!.syncedAt, isNotNull);
    });

    test('a full page that ends inside one publish batch skips nothing', () async {
      // Batch 1: two rows with one timestamp; batch 2: three rows with
      // another. Pages hold 3 rows, so the first page ends inside batch 2.
      await ownerPublishes([('a', 'A'), ('b', 'B')]);
      await ownerPublishes([('c', 'C'), ('d', 'D'), ('e', 'E')]);
      final sync = EmployeeSyncService(repo, api, session, pageSize: 3);
      expect(await sync.sync(), SyncOutcome.synced);
      expect(await repo.count(), 5);
    });

    test('nextCursor steps back to before the last timestamp of a full page', () {
      final rows = [
        row('a', 'A', at: 't1'),
        row('b', 'B', at: 't2'),
        row('c', 'C', at: 't2'),
      ];
      expect(EmployeeSyncService.nextCursor(rows, fullPage: false), 't2');
      expect(EmployeeSyncService.nextCursor(rows, fullPage: true), 't1');
      // Would not move forward: take the last timestamp instead.
      expect(
        EmployeeSyncService.nextCursor(rows, fullPage: true, previous: 't1'),
        't2',
      );
    });

    test('offline keeps the catalog', () async {
      await ownerPublishes([('a', 'Kabel')]);
      final sync = EmployeeSyncService(repo, api, session);
      await sync.sync();
      api.offline = true;
      expect(await sync.sync(), SyncOutcome.offline);
      expect(await repo.count(), 1);
    });

    test('revoked: catalog and session are deleted', () async {
      await ownerPublishes([('a', 'Kabel')]);
      final sync = EmployeeSyncService(repo, api, session);
      await sync.sync();
      await api.revokeMember(store, api.user!.id);

      expect(await sync.sync(), SyncOutcome.revoked);
      expect(await repo.count(), 0);
      expect(session.read(), isNull);
      expect(api.user, isNull); // signed out
    });
  });

  group('join', () {
    late FakeServerApi api;
    late EmployeeSessionStore session;

    setUp(() {
      api = FakeServerApi();
      session = EmployeeSessionStore(MemoryKeyValueStore());
    });

    test('code is cleaned up and checked for 8 characters', () {
      expect(JoinService.normalizeCode(' 7kq2-m9xa '), '7KQ2M9XA');
      expect(JoinService.isValidCode('7kq2 m9xa'), isTrue);
      expect(JoinService.isValidCode('7KQ2M9'), isFalse);
    });

    test('signs in anonymously and saves the store', () async {
      api.user = const ServerUser(id: 'owner', isAnonymous: false);
      final store = await api.createStore('Toko Berkah');
      final code = await api.createInvite(store);
      await api.signOut();

      final name = await JoinService(api, session, repo).join(
        code.toLowerCase(),
        name: ' Sari ',
        device: 'Android',
      );
      expect(name, 'Toko Berkah');
      expect(api.user!.isAnonymous, isTrue);
      expect(session.read()!.storeId, store);
      expect(api.memberships[store]!.values.single.displayName, 'Sari');
    });

    test('a wrong code throws inviteInvalid and saves nothing', () async {
      await expectLater(
        JoinService(api, session, repo).join('SALAHKOD', name: 'Sari', device: 'x'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.kind,
            'kind',
            ServerErrorKind.inviteInvalid,
          ),
        ),
      );
      expect(session.read(), isNull);
    });

    test('without a server it says so', () async {
      await expectLater(
        JoinService(null, session, repo).join('KODE0001', name: 'S', device: 'x'),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
