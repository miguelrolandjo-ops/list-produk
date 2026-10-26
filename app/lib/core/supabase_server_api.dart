import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'server_api.dart';

/// [ServerApi] on Supabase. The only file that talks to the Supabase client;
/// every error leaves here as a [ServerException].
class SupabaseServerApi implements ServerApi {
  SupabaseServerApi(this._client);

  final SupabaseClient _client;

  static const _timeout = Duration(seconds: 20);

  ServerUser? _user(User? u) => u == null
      ? null
      : ServerUser(id: u.id, email: u.email, isAnonymous: u.isAnonymous);

  @override
  ServerUser? get currentUser => _user(_client.auth.currentUser);

  @override
  Stream<ServerUser?> get userChanges =>
      _client.auth.onAuthStateChange.map((s) => _user(s.session?.user));

  @override
  Future<bool> signUp(String email, String password) => _call(() async {
    final res = await _client.auth.signUp(email: email, password: password);
    return res.session != null;
  });

  @override
  Future<void> signIn(String email, String password) => _call(
    () => _client.auth.signInWithPassword(email: email, password: password),
  );

  @override
  Future<void> signInAnonymously() =>
      _call(() => _client.auth.signInAnonymously());

  @override
  Future<void> signOut() => _call(() => _client.auth.signOut());

  @override
  Future<String> createStore(String name) => _call(
    () async =>
        await _client.rpc('create_store', params: {'p_name': name}) as String,
  );

  @override
  Future<String?> storeName(String storeId) => _call(() async {
    final row = await _client
        .from('stores')
        .select('name')
        .eq('id', storeId)
        .maybeSingle();
    return row?['name'] as String?;
  });

  @override
  Future<bool> isOwnerOf(String storeId) => _call(() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return false;
    final row = await _client
        .from('store_members')
        .select('role, revoked_at')
        .eq('store_id', storeId)
        .eq('user_id', uid)
        .maybeSingle();
    return row != null && row['role'] == 'owner' && row['revoked_at'] == null;
  });

  @override
  Future<int> publishCatalog(
    String storeId,
    List<Map<String, Object?>> items,
  ) => _call(() async {
    final n = await _client.rpc(
      'publish_catalog',
      params: {'p_store': storeId, 'p_items': items},
    );
    return (n as num).toInt();
  });

  @override
  Future<List<CatalogRow>> employeeCatalog(String storeId, {String? since}) =>
      _call(() async {
        final rows = await _client.rpc(
          'employee_catalog',
          params: {'p_store': storeId, 'p_since': since},
        );
        return [
          for (final r in rows as List)
            CatalogRow.fromJson(Map<String, dynamic>.from(r as Map)),
        ];
      });

  @override
  Future<String> createInvite(String storeId) => _call(
    () async =>
        await _client.rpc('create_invite', params: {'p_store': storeId})
            as String,
  );

  @override
  Future<String> acceptInvite(
    String code, {
    required String name,
    required String device,
  }) => _call(
    () async =>
        await _client.rpc(
              'accept_invite',
              params: {'p_code': code, 'p_name': name, 'p_device': device},
            )
            as String,
  );

  @override
  Future<List<StoreMember>> members(String storeId) => _call(() async {
    final rows = await _client
        .from('store_members')
        .select(
          'user_id, display_name, device_label, joined_at, last_seen_at, revoked_at',
        )
        .eq('store_id', storeId)
        .eq('role', 'employee')
        .order('joined_at', ascending: false);
    return [
      for (final r in rows)
        StoreMember(
          userId: r['user_id'] as String,
          displayName: r['display_name'] as String?,
          deviceLabel: r['device_label'] as String?,
          joinedAt: DateTime.parse(r['joined_at'] as String),
          lastSeenAt: _date(r['last_seen_at']),
          revokedAt: _date(r['revoked_at']),
        ),
    ];
  });

  @override
  Future<void> revokeMember(String storeId, String userId) => _call(
    () => _client
        .from('store_members')
        .update({'revoked_at': DateTime.now().toUtc().toIso8601String()})
        .eq('store_id', storeId)
        .eq('user_id', userId),
  );

  @override
  Future<List<StoreInvite>> activeInvites(String storeId) => _call(() async {
    final rows = await _client
        .from('invites')
        .select('id, code, created_at, expires_at')
        .eq('store_id', storeId)
        .isFilter('revoked_at', null)
        .gt('expires_at', DateTime.now().toUtc().toIso8601String())
        .order('created_at', ascending: false);
    return [
      for (final r in rows)
        StoreInvite(
          id: r['id'] as String,
          code: r['code'] as String,
          createdAt: DateTime.parse(r['created_at'] as String),
          expiresAt: DateTime.parse(r['expires_at'] as String),
        ),
    ];
  });

  @override
  Future<void> revokeInvite(String inviteId) => _call(
    () => _client
        .from('invites')
        .update({'revoked_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', inviteId),
  );

  static DateTime? _date(Object? v) =>
      v == null ? null : DateTime.parse(v as String);

  /// Runs [f] and turns every failure into a [ServerException].
  Future<T> _call<T>(Future<T> Function() f) async {
    try {
      return await f().timeout(_timeout);
    } on ServerException {
      rethrow;
    } on AuthRetryableFetchException catch (e) {
      throw ServerException(ServerErrorKind.offline, e.message);
    } on AuthException catch (e) {
      throw ServerException(_authKind(e), e.message);
    } on PostgrestException catch (e) {
      throw ServerException(_postgrestKind(e), e.message);
    } on SocketException catch (e) {
      throw ServerException(ServerErrorKind.offline, e.message);
    } on TimeoutException {
      throw const ServerException(ServerErrorKind.offline, 'timeout');
    } catch (e) {
      // The http client's own exceptions (ClientException) aren't exported
      // here; recognise them by name.
      final text = e.toString();
      if (text.contains('ClientException') ||
          text.contains('SocketException') ||
          text.contains('Failed host lookup') ||
          text.contains('Connection')) {
        throw ServerException(ServerErrorKind.offline, text);
      }
      throw ServerException(ServerErrorKind.other, text);
    }
  }

  static ServerErrorKind _authKind(AuthException e) {
    final code = e.code ?? '';
    final msg = e.message.toLowerCase();
    if (code == 'invalid_credentials' || msg.contains('invalid login')) {
      return ServerErrorKind.invalidLogin;
    }
    if (code == 'email_not_confirmed' || msg.contains('not confirmed')) {
      return ServerErrorKind.emailNotConfirmed;
    }
    if (code == 'user_already_exists' ||
        code == 'email_exists' ||
        msg.contains('already registered')) {
      return ServerErrorKind.emailTaken;
    }
    if (code == 'weak_password' || msg.contains('password should')) {
      return ServerErrorKind.weakPassword;
    }
    if (code == 'anonymous_provider_disabled' ||
        msg.contains('anonymous sign-ins are disabled')) {
      return ServerErrorKind.anonymousDisabled;
    }
    return ServerErrorKind.other;
  }

  static ServerErrorKind _postgrestKind(PostgrestException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invite invalid')) return ServerErrorKind.inviteInvalid;
    if (msg.contains('not allowed') || msg.contains('not signed in')) {
      return ServerErrorKind.notAllowed;
    }
    // Anything else (an expired token after a long time offline, for
    // example) is not a refusal: an employee must not lose the catalog over it.
    return ServerErrorKind.other;
  }
}
