/// Everything the app asks of the server, behind one interface so services can
/// be tested with a fake and the Supabase client stays in one file
/// (`supabase_server_api.dart`).
///
/// The server only knows the employee catalog, store access, and (later) the
/// PO queue. Supplier data never goes through this interface.
library;

import 'dart:typed_data';

class ServerUser {
  const ServerUser({required this.id, this.email, required this.isAnonymous});

  final String id;
  final String? email;

  /// Employees sign in anonymously; the owner signs in with email.
  final bool isAnonymous;
}

enum ServerErrorKind {
  /// No connection, or the server didn't answer.
  offline,

  /// The server refused: not a member, access revoked, not the owner.
  notAllowed,

  /// accept_invite: the code doesn't exist, expired, or was cancelled.
  inviteInvalid,
  invalidLogin,
  emailNotConfirmed,
  emailTaken,
  weakPassword,

  /// Anonymous sign-ins are switched off in the Supabase dashboard.
  anonymousDisabled,

  /// The app was built without SUPABASE_URL / SUPABASE_ANON_KEY.
  notConfigured,
  other,
}

class ServerException implements Exception {
  const ServerException(this.kind, [this.detail]);

  final ServerErrorKind kind;

  /// The server's own message, for logs. Not shown to the user as is.
  final String? detail;

  /// What to tell the user, in the app's language.
  String get message => switch (kind) {
    ServerErrorKind.offline =>
      'Tidak ada koneksi ke server. Periksa internet lalu coba lagi.',
    ServerErrorKind.notAllowed => 'Akses ditolak oleh server.',
    ServerErrorKind.inviteInvalid =>
      'Kode tidak berlaku. Mungkin salah ketik, sudah dibatalkan, atau lewat 7 hari.',
    ServerErrorKind.invalidLogin => 'Email atau kata sandi salah.',
    ServerErrorKind.emailNotConfirmed =>
      'Email belum dikonfirmasi. Buka tautan di email dari Supabase, lalu masuk lagi.',
    ServerErrorKind.emailTaken => 'Email ini sudah terdaftar. Pilih Masuk.',
    ServerErrorKind.weakPassword =>
      'Kata sandi terlalu lemah. Pakai minimal 8 karakter.',
    ServerErrorKind.anonymousDisabled =>
      'Server belum mengizinkan karyawan bergabung. Pemilik perlu '
          'menyalakan "Anonymous sign-ins" di Supabase.',
    ServerErrorKind.notConfigured =>
      'Server belum diatur di aplikasi ini.',
    ServerErrorKind.other => 'Terjadi kesalahan di server. Coba lagi nanti.',
  };

  @override
  String toString() => 'ServerException($kind${detail == null ? '' : ': $detail'})';
}

/// One row of employee_catalog(). [updatedAt] is the server's timestamp exactly
/// as received: it goes back to the server as the next sync cursor, so it is
/// never parsed or reformatted.
class CatalogRow {
  const CatalogRow({
    required this.id,
    required this.name,
    this.model,
    this.category,
    this.unit = 'pcs',
    this.photoPath,
    this.retailPrice,
    this.isDeleted = false,
    required this.updatedAt,
  });

  factory CatalogRow.fromJson(Map<String, dynamic> j) => CatalogRow(
    id: j['id'] as String,
    name: j['name'] as String,
    model: j['model'] as String?,
    category: j['category'] as String?,
    unit: (j['unit'] as String?) ?? 'pcs',
    photoPath: j['photo_path'] as String?,
    retailPrice: (j['retail_price'] as num?)?.toInt(),
    isDeleted: (j['is_deleted'] as bool?) ?? false,
    updatedAt: j['updated_at'] as String,
  );

  final String id;
  final String name;
  final String? model;
  final String? category;
  final String unit;
  final String? photoPath;
  final int? retailPrice;
  final bool isDeleted;
  final String updatedAt;
}

class StoreMember {
  const StoreMember({
    required this.userId,
    this.displayName,
    this.deviceLabel,
    required this.joinedAt,
    this.lastSeenAt,
    this.revokedAt,
  });

  final String userId;
  final String? displayName;
  final String? deviceLabel;
  final DateTime joinedAt;
  final DateTime? lastSeenAt;
  final DateTime? revokedAt;

  bool get isActive => revokedAt == null;
}

class StoreInvite {
  const StoreInvite({
    required this.id,
    required this.code,
    required this.createdAt,
    required this.expiresAt,
  });

  final String id;
  final String code;
  final DateTime createdAt;
  final DateTime expiresAt;
}

/// One PO reading job on the server, as the owner's phone sees it.
class ExtractionJob {
  const ExtractionJob({required this.status, this.result, this.error});

  /// 'pending', 'running', 'done' or 'failed'.
  final String status;

  /// The extraction JSON (build guide section 9), when done.
  final Map<String, dynamic>? result;
  final String? error;
}

abstract class ServerApi {
  ServerUser? get currentUser;

  /// Emits whenever someone signs in or out (not the current value on listen).
  Stream<ServerUser?> get userChanges;

  /// Owner sign-up. Returns false when the project requires email
  /// confirmation first (no session yet).
  Future<bool> signUp(String email, String password);
  Future<void> signIn(String email, String password);
  Future<void> signInAnonymously();
  Future<void> signOut();

  /// create_store(): the store plus the owner's membership. Returns its id.
  Future<String> createStore(String name);

  /// The store's name, or null if this user can't see it.
  Future<String?> storeName(String storeId);

  /// Whether the signed-in user is the (not revoked) owner of [storeId].
  Future<bool> isOwnerOf(String storeId);

  /// publish_catalog(). [items] hold only the whitelisted employee fields.
  Future<int> publishCatalog(String storeId, List<Map<String, Object?>> items);

  /// employee_catalog(): rows changed after [since], oldest first.
  Future<List<CatalogRow>> employeeCatalog(String storeId, {String? since});

  /// create_invite(): an 8-character code, valid 7 days.
  Future<String> createInvite(String storeId);

  /// accept_invite(): joins the store as an employee. Returns the store id.
  Future<String> acceptInvite(
    String code, {
    required String name,
    required String device,
  });

  /// Employees of the store, revoked ones included (newest first).
  Future<List<StoreMember>> members(String storeId);
  Future<void> revokeMember(String storeId, String userId);

  /// Invite codes that can still be used.
  Future<List<StoreInvite>> activeInvites(String storeId);
  Future<void> revokeInvite(String inviteId);

  /// Uploads one PO page to the private 'po-images' bucket at [path]
  /// ({store_id}/{po_id}/{page_no}.jpg). Replaces an earlier upload.
  Future<void> uploadPoPage(String path, Uint8List jpeg);

  /// submit_extraction(): queues uploaded pages for reading. Returns the job id.
  Future<String> submitExtraction(String storeId, List<String> paths);

  /// The job's state, or null if the server no longer has it.
  Future<ExtractionJob?> extractionJob(String jobId);

  /// mark_extraction_fetched(): the result is saved on the phone, so the
  /// server can delete it.
  Future<void> markExtractionFetched(String jobId);
}
