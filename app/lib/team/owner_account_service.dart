import 'package:drift/drift.dart';

import '../core/server_api.dart';
import '../data/owner_database.dart';

enum OwnerLinkState {
  /// The app was built without the server settings.
  notConfigured,
  signedOut,

  /// Signed in, but this phone has no store on the server yet.
  noStore,
  linked,

  /// The store saved on this phone (for example from a backup) belongs to a
  /// different account.
  notOwner,
}

class OwnerLink {
  const OwnerLink(
    this.state, {
    this.email,
    this.storeId,
    this.storeName,
    this.offline = false,
  });

  final OwnerLinkState state;
  final String? email;
  final String? storeId;
  final String? storeName;

  /// Couldn't reach the server to check; shown as linked from local data.
  final bool offline;
}

/// The owner's account and the link between this phone and its store on the
/// server (settings.store_id). The phone stays the source of truth; the
/// account only exists so employees can get the catalog.
class OwnerAccountService {
  OwnerAccountService(this._db, this._api);

  final OwnerDatabase _db;
  final ServerApi? _api;

  Future<String?> storeId() async => (await _db
          .customSelect('SELECT store_id FROM settings WHERE id = 1')
          .getSingle())
      .readNullable<String>('store_id');

  Future<OwnerLink> check() async {
    final api = _api;
    if (api == null) return const OwnerLink(OwnerLinkState.notConfigured);
    final user = api.currentUser;
    if (user == null || user.isAnonymous) {
      return const OwnerLink(OwnerLinkState.signedOut);
    }
    final id = await storeId();
    if (id == null) return OwnerLink(OwnerLinkState.noStore, email: user.email);
    try {
      if (!await api.isOwnerOf(id)) {
        return OwnerLink(OwnerLinkState.notOwner, email: user.email, storeId: id);
      }
      return OwnerLink(
        OwnerLinkState.linked,
        email: user.email,
        storeId: id,
        storeName: await api.storeName(id),
      );
    } on ServerException catch (e) {
      if (e.kind != ServerErrorKind.offline) rethrow;
      return OwnerLink(
        OwnerLinkState.linked,
        email: user.email,
        storeId: id,
        offline: true,
      );
    }
  }

  /// Signs up. Returns false when the email must be confirmed first.
  Future<bool> signUp(String email, String password) =>
      _require().signUp(email.trim(), password);

  Future<void> signIn(String email, String password) =>
      _require().signIn(email.trim(), password);

  Future<void> signOut() => _require().signOut();

  /// Creates the store on the server and links this phone to it. Every
  /// product is marked unsent, so the whole catalog goes to the new store.
  Future<void> createStore(String name) async {
    final id = await _require().createStore(name.trim());
    await _db.transaction(() async {
      await _db.customUpdate(
        'UPDATE settings SET store_id = ? WHERE id = 1',
        variables: [Variable.withString(id)],
        updates: {_db.settings},
      );
      await _db.customUpdate(
        'UPDATE products SET published_at = NULL',
        updates: {_db.products},
      );
    });
  }

  ServerApi _require() =>
      _api ?? (throw const ServerException(ServerErrorKind.notConfigured));
}

/// Invites and employees of the owner's store ("Tim").
class TeamService {
  TeamService(this._account, this._api);

  final OwnerAccountService _account;
  final ServerApi? _api;

  Future<(ServerApi, String)> _store() async {
    final api = _api;
    if (api == null) throw const ServerException(ServerErrorKind.notConfigured);
    final id = await _account.storeId();
    if (id == null) throw const ServerException(ServerErrorKind.notAllowed);
    return (api, id);
  }

  Future<String> createInvite() async {
    final (api, id) = await _store();
    return api.createInvite(id);
  }

  Future<List<StoreMember>> members() async {
    final (api, id) = await _store();
    return api.members(id);
  }

  Future<List<StoreInvite>> activeInvites() async {
    final (api, id) = await _store();
    return api.activeInvites(id);
  }

  Future<void> revokeMember(String userId) async {
    final (api, id) = await _store();
    await api.revokeMember(id, userId);
  }

  Future<void> revokeInvite(String inviteId) async {
    final (api, _) = await _store();
    await api.revokeInvite(inviteId);
  }

  /// The message sent with the share sheet (WhatsApp etc.).
  static String inviteMessage(String code, {String? storeName}) =>
      'Halo! Ini undangan untuk melihat daftar harga '
      '${storeName == null ? 'toko' : storeName} di aplikasi Harga Toko.\n\n'
      'Kode undangan: $code\n\n'
      'Buka aplikasi Harga Toko, pilih "Gabung sebagai karyawan", lalu '
      'masukkan kode di atas. Kode berlaku 7 hari.';
}
