import '../core/server_api.dart';
import 'employee_catalog_repository.dart';
import 'employee_session.dart';

/// "Gabung sebagai karyawan": sign in anonymously (no email needed) and
/// accept the invite code.
class JoinService {
  JoinService(this._api, this._session, this._repo);

  final ServerApi? _api;
  final EmployeeSessionStore _session;
  final EmployeeCatalogRepository _repo;

  static const codeLength = 8;

  /// Upper case, without spaces or dashes, so "7kq2 m9xa" works too.
  static String normalizeCode(String typed) =>
      typed.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  static bool isValidCode(String typed) =>
      normalizeCode(typed).length == codeLength;

  /// Joins and returns the store name. Throws [ServerException].
  Future<String> join(
    String code, {
    required String name,
    required String device,
  }) async {
    final api = _api;
    if (api == null) {
      throw const ServerException(ServerErrorKind.notConfigured);
    }
    final user = api.currentUser;
    if (user == null || !user.isAnonymous) {
      if (user != null) await api.signOut();
      await api.signInAnonymously();
    }
    final storeId = await api.acceptInvite(
      normalizeCode(code),
      name: name.trim(),
      device: device,
    );
    final storeName = await api.storeName(storeId) ?? 'Toko';
    await _repo.clear();
    await _session.start(storeId, storeName);
    return storeName;
  }
}
