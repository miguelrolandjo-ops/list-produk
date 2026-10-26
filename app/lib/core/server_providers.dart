import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../catalog/employee_catalog_repository.dart';
import '../catalog/employee_session.dart';
import '../catalog/employee_sync_service.dart';
import '../catalog/join_service.dart';
import '../data/employee_database.dart';
import '../publish/auto_publisher.dart';
import '../publish/publish_service.dart';
import '../team/owner_account_service.dart';
import 'app_mode.dart';
import 'providers.dart';
import 'server_api.dart';
import 'server_config.dart';
import 'supabase_server_api.dart';

/// The server, or null when the app was built without server settings (and in
/// tests). Everything online checks for null and stays quiet offline.
final serverApiProvider = Provider<ServerApi?>(
  (ref) => ServerConfig.isConfigured
      ? SupabaseServerApi(Supabase.instance.client)
      : null,
);

/// Who is signed in, updated on sign-in and sign-out.
final serverUserProvider = StreamProvider<ServerUser?>((ref) async* {
  final api = ref.watch(serverApiProvider);
  if (api == null) {
    yield null;
    return;
  }
  yield api.currentUser;
  yield* api.userChanges;
});

// ---------------------------------------------------------------- owner side

final publishServiceProvider = Provider<PublishService>(
  (ref) => PublishService(
    ref.watch(ownerDbProvider),
    ref.watch(serverApiProvider),
  ),
);

final ownerAccountServiceProvider = Provider<OwnerAccountService>(
  (ref) => OwnerAccountService(
    ref.watch(ownerDbProvider),
    ref.watch(serverApiProvider),
  ),
);

final teamServiceProvider = Provider<TeamService>(
  (ref) => TeamService(
    ref.watch(ownerAccountServiceProvider),
    ref.watch(serverApiProvider),
  ),
);

/// Account and store status for the account screen and the settings menu.
/// Re-checked on sign-in/out and when the linked store changes.
final ownerLinkProvider = FutureProvider<OwnerLink>((ref) async {
  ref.watch(serverUserProvider);
  ref.watch(ownerStoreIdProvider);
  return ref.watch(ownerAccountServiceProvider).check();
});

final ownerStoreIdProvider = StreamProvider<String?>((ref) {
  final db = ref.watch(ownerDbProvider);
  return db
      .customSelect(
        'SELECT store_id FROM settings WHERE id = 1',
        readsFrom: {db.settings},
      )
      .watchSingle()
      .map((r) => r.readNullable<String>('store_id'));
});

/// "N belum terkirim": products employees don't have yet. Null when the phone
/// isn't connected to a store (then there is nothing to send to).
final unsentCountProvider = StreamProvider<int?>((ref) {
  final user = ref.watch(serverUserProvider).value;
  if (user == null || user.isAnonymous) return Stream.value(null);
  final db = ref.watch(ownerDbProvider);
  return db
      .customSelect(
        'SELECT s.store_id AS store_id, '
        '(SELECT COUNT(*) FROM products_to_publish) AS n '
        'FROM settings s WHERE s.id = 1',
        readsFrom: {db.settings, db.products, db.categories},
      )
      .watchSingle()
      .map(
        (r) => r.readNullable<String>('store_id') == null
            ? null
            : r.read<int>('n'),
      );
});

/// Publishes in the background while the owner side of the app runs.
final autoPublisherProvider = Provider<AutoPublisher?>((ref) {
  if (ref.watch(serverApiProvider) == null) return null;
  final publisher = AutoPublisher(
    ref.watch(ownerDbProvider),
    ref.watch(publishServiceProvider),
  )..start();
  ref.listen(serverUserProvider, (_, _) => publisher.kick());
  ref.onDispose(publisher.dispose);
  return publisher;
});

// ------------------------------------------------------------- employee side

final employeeDbProvider = Provider<EmployeeDatabase>((ref) {
  final db = EmployeeDatabase();
  ref.onDispose(db.close);
  return db;
});

final employeeCatalogRepositoryProvider = Provider<EmployeeCatalogRepository>(
  (ref) => EmployeeCatalogRepository(ref.watch(employeeDbProvider)),
);

final employeeSessionStoreProvider = Provider<EmployeeSessionStore>(
  (ref) => EmployeeSessionStore(ref.watch(keyValueStoreProvider)),
);

final employeeSyncServiceProvider = Provider<EmployeeSyncService>(
  (ref) => EmployeeSyncService(
    ref.watch(employeeCatalogRepositoryProvider),
    ref.watch(serverApiProvider),
    ref.watch(employeeSessionStoreProvider),
  ),
);

final joinServiceProvider = Provider<JoinService>(
  (ref) => JoinService(
    ref.watch(serverApiProvider),
    ref.watch(employeeSessionStoreProvider),
    ref.watch(employeeCatalogRepositoryProvider),
  ),
);
