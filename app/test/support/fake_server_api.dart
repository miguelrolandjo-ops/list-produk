import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_application_1/core/server_api.dart';

/// In-memory stand-in for the Supabase server, following the rules of
/// supabase/migrations/0001_init.sql: publish_catalog keeps only the
/// whitelisted fields and stamps rows with one server time per call,
/// employee_catalog returns rows after a cursor, oldest first, at most
/// [maxRows] (like PostgREST's row limit), and revoked members are refused.
class FakeServerApi implements ServerApi {
  FakeServerApi({this.maxRows = 1000});

  final int maxRows;

  ServerUser? user;
  bool offline = false;

  /// Called inside publishCatalog, to simulate an edit during the upload.
  Future<void> Function()? duringPublish;

  final payloads = <List<Map<String, Object?>>>[];
  final stores = <String, String>{}; // id -> name
  final owners = <String, String>{}; // store id -> user id
  final memberships = <String, Map<String, StoreMember>>{};
  final catalog = <String, Map<String, Map<String, Object?>>>{};
  final invites = <String, (String store, bool revoked)>{};
  final _changes = StreamController<ServerUser?>.broadcast();
  var _clock = 0;
  var _ids = 0;

  static const whitelist = {
    'id',
    'name',
    'model',
    'category',
    'unit',
    'photo_path',
    'retail_price',
    'is_deleted',
  };

  String _now() =>
      DateTime.utc(2026, 10, 26, 8).add(Duration(seconds: _clock++)).toIso8601String();

  void _check() {
    if (offline) throw const ServerException(ServerErrorKind.offline);
  }

  void _requireUser() {
    if (user == null) throw const ServerException(ServerErrorKind.notAllowed);
  }

  bool _isMember(String store) {
    final u = user;
    if (u == null) return false;
    if (owners[store] == u.id) return true;
    final m = memberships[store]?[u.id];
    return m != null && m.isActive;
  }

  @override
  ServerUser? get currentUser => user;

  @override
  Stream<ServerUser?> get userChanges => _changes.stream;

  @override
  Future<bool> signUp(String email, String password) async {
    _check();
    user = ServerUser(id: 'owner-$email', email: email, isAnonymous: false);
    _changes.add(user);
    return true;
  }

  @override
  Future<void> signIn(String email, String password) async {
    _check();
    if (password != 'rahasia123') {
      throw const ServerException(ServerErrorKind.invalidLogin);
    }
    user = ServerUser(id: 'owner-$email', email: email, isAnonymous: false);
    _changes.add(user);
  }

  @override
  Future<void> signInAnonymously() async {
    _check();
    user = ServerUser(id: 'anon-${_ids++}', isAnonymous: true);
    _changes.add(user);
  }

  @override
  Future<void> signOut() async {
    user = null;
    _changes.add(null);
  }

  @override
  Future<String> createStore(String name) async {
    _check();
    _requireUser();
    final id = '00000000-0000-4000-8000-${(_ids++).toString().padLeft(12, '0')}';
    stores[id] = name;
    owners[id] = user!.id;
    return id;
  }

  @override
  Future<String?> storeName(String storeId) async {
    _check();
    return _isMember(storeId) ? stores[storeId] : null;
  }

  @override
  Future<bool> isOwnerOf(String storeId) async {
    _check();
    return user != null && owners[storeId] == user!.id;
  }

  @override
  Future<int> publishCatalog(
    String storeId,
    List<Map<String, Object?>> items,
  ) async {
    _check();
    if (user == null || owners[storeId] != user!.id) {
      throw const ServerException(ServerErrorKind.notAllowed);
    }
    payloads.add(items);
    await duringPublish?.call();
    final at = _now();
    final rows = catalog.putIfAbsent(storeId, () => {});
    for (final i in items) {
      rows[i['id'] as String] = {
        for (final k in whitelist) k: i[k],
        'unit': i['unit'] ?? 'pcs',
        'is_deleted': i['is_deleted'] ?? false,
        'updated_at': at,
      };
    }
    return items.length;
  }

  @override
  Future<List<CatalogRow>> employeeCatalog(
    String storeId, {
    String? since,
  }) async {
    _check();
    if (!_isMember(storeId)) {
      throw const ServerException(ServerErrorKind.notAllowed);
    }
    final rows =
        (catalog[storeId]?.values.toList() ?? [])
            .where(
              (r) =>
                  since == null ||
                  (r['updated_at'] as String).compareTo(since) > 0,
            )
            .toList()
          ..sort(
            (a, b) =>
                (a['updated_at'] as String).compareTo(b['updated_at'] as String),
          );
    return [
      for (final r in rows.take(maxRows))
        CatalogRow.fromJson(Map<String, dynamic>.from(r)),
    ];
  }

  @override
  Future<String> createInvite(String storeId) async {
    _check();
    final code = 'KODE${(_ids++).toString().padLeft(4, '0')}';
    invites[code] = (storeId, false);
    return code;
  }

  @override
  Future<String> acceptInvite(
    String code, {
    required String name,
    required String device,
  }) async {
    _check();
    _requireUser();
    final inv = invites[code.toUpperCase()];
    if (inv == null || inv.$2) {
      throw const ServerException(ServerErrorKind.inviteInvalid);
    }
    memberships.putIfAbsent(inv.$1, () => {})[user!.id] = StoreMember(
      userId: user!.id,
      displayName: name,
      deviceLabel: device,
      joinedAt: DateTime.utc(2026, 10, 26),
    );
    return inv.$1;
  }

  @override
  Future<List<StoreMember>> members(String storeId) async =>
      memberships[storeId]?.values.toList() ?? [];

  @override
  Future<void> revokeMember(String storeId, String userId) async {
    final m = memberships[storeId]![userId]!;
    memberships[storeId]![userId] = StoreMember(
      userId: m.userId,
      displayName: m.displayName,
      deviceLabel: m.deviceLabel,
      joinedAt: m.joinedAt,
      revokedAt: DateTime.utc(2026, 10, 27),
    );
  }

  @override
  Future<List<StoreInvite>> activeInvites(String storeId) async => [];

  @override
  Future<void> revokeInvite(String inviteId) async {}

  // ------------------------------------------------------------ PO reading

  /// Uploaded objects in 'po-images', by path.
  final uploads = <String, Uint8List>{};

  /// Jobs by id: what the worker would have written.
  final jobs = <String, ExtractionJob>{};
  final jobPaths = <String, List<String>>{};
  final fetched = <String>{};

  /// Fail uploads after this many succeeded (a signal lost mid-PO).
  int? goOfflineAfterUploads;

  @override
  Future<void> uploadPoPage(String path, Uint8List jpeg) async {
    _check();
    if (goOfflineAfterUploads != null &&
        uploads.length >= goOfflineAfterUploads!) {
      offline = true;
      _check();
    }
    final store = path.split('/').first;
    if (user == null || owners[store] != user!.id) {
      throw const ServerException(ServerErrorKind.notAllowed);
    }
    uploads[path] = jpeg;
  }

  @override
  Future<String> submitExtraction(String storeId, List<String> paths) async {
    _check();
    if (user == null || owners[storeId] != user!.id) {
      throw const ServerException(ServerErrorKind.notAllowed);
    }
    if (paths.isEmpty) throw const ServerException(ServerErrorKind.other);
    final id = 'job-${_ids++}';
    jobs[id] = const ExtractionJob(status: 'pending');
    jobPaths[id] = paths;
    return id;
  }

  /// What the Go worker does: store a result (or a failure).
  void finishJob(String id, {Map<String, dynamic>? result, String? error}) {
    jobs[id] = result != null
        ? ExtractionJob(status: 'done', result: result)
        : ExtractionJob(status: 'failed', error: error ?? 'gagal');
  }

  @override
  Future<ExtractionJob?> extractionJob(String jobId) async {
    _check();
    return jobs[jobId];
  }

  @override
  Future<void> markExtractionFetched(String jobId) async {
    _check();
    fetched.add(jobId);
  }
}
