import '../core/server_api.dart';
import 'employee_catalog_repository.dart';
import 'employee_session.dart';

enum SyncOutcome {
  synced,

  /// No signal: the phone keeps searching the last synced catalog.
  offline,

  /// The owner revoked this phone (or its login is gone). The local catalog
  /// and session have been deleted.
  revoked,
  notJoined,
  failed,
}

/// Downloads catalog changes (build guide section 7, "Employee sync").
///
/// Calls employee_catalog(store, since) with the largest `updated_at` already
/// stored, applies the rows, and saves the new cursor. The cursor is the
/// server's clock, so a phone with the wrong time can't break sync.
///
/// The server returns at most [pageSize] rows per call (Supabase's default
/// row limit). Rows of one publish batch share one `updated_at`, so a full
/// page may stop in the middle of such a group. In that case the cursor is
/// set just before the page's last timestamp and that group is fetched again
/// (re-applying a row is harmless), so no row is skipped.
class EmployeeSyncService {
  EmployeeSyncService(
    this._repo,
    this._api,
    this._session, {
    this.pageSize = 1000,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final EmployeeCatalogRepository _repo;
  final ServerApi? _api;
  final EmployeeSessionStore _session;
  final int pageSize;
  final DateTime Function() _clock;

  Future<SyncOutcome>? _running;

  Future<SyncOutcome> sync() =>
      _running ??= _sync().whenComplete(() => _running = null);

  /// The cursor after a page of rows (oldest first). See the class comment.
  static String nextCursor(
    List<CatalogRow> rows, {
    required bool fullPage,
    String? previous,
  }) {
    final last = rows.last.updatedAt;
    if (!fullPage) return last;
    for (var i = rows.length - 1; i >= 0; i--) {
      final t = rows[i].updatedAt;
      if (t != last) {
        // Must move forward, or the same page would come back forever.
        return t == previous ? last : t;
      }
    }
    return last; // the whole page has one timestamp: nothing better to do
  }

  Future<SyncOutcome> _sync() async {
    final session = _session.read();
    if (session == null) return SyncOutcome.notJoined;
    final api = _api;
    if (api == null) return SyncOutcome.offline;

    var cursor = session.cursor;
    try {
      while (true) {
        final rows = await api.employeeCatalog(session.storeId, since: cursor);
        if (rows.isEmpty) break;
        await _repo.apply(rows);
        final full = rows.length >= pageSize;
        final next = nextCursor(rows, fullPage: full, previous: cursor);
        cursor = next;
        await _session.setCursor(next);
        if (!full) break;
      }
      await _session.setSyncedAt(_clock());
      return SyncOutcome.synced;
    } on ServerException catch (e) {
      switch (e.kind) {
        case ServerErrorKind.notAllowed:
          await leave();
          return SyncOutcome.revoked;
        case ServerErrorKind.offline:
          return SyncOutcome.offline;
        default:
          return SyncOutcome.failed;
      }
    }
  }

  /// Leaves the store on this phone: deletes the local catalog and session,
  /// and signs out. The owner's list still shows the phone until revoked.
  Future<void> leave() async {
    await _repo.clear();
    await _session.clear();
    try {
      await _api?.signOut();
    } on ServerException {
      // Offline: the local data is gone anyway, which is what matters here.
    }
  }
}
