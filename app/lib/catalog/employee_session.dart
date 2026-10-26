import '../core/app_mode.dart';

/// The store this employee phone belongs to and how far it has synced.
class EmployeeSession {
  const EmployeeSession({
    required this.storeId,
    required this.storeName,
    this.cursor,
    this.syncedAt,
  });

  final String storeId;
  final String storeName;

  /// The largest server `updated_at` received so far (as the server sent it).
  final String? cursor;

  /// When the last sync finished, on this phone's clock (for "Diperbarui ...").
  final DateTime? syncedAt;
}

class EmployeeSessionStore {
  EmployeeSessionStore(this._kv);

  final KeyValueStore _kv;

  EmployeeSession? read() {
    final id = _kv.getString(employeeStoreIdKey);
    if (id == null) return null;
    return EmployeeSession(
      storeId: id,
      storeName: _kv.getString(employeeStoreNameKey) ?? 'Toko',
      cursor: _kv.getString(employeeCursorKey),
      syncedAt: DateTime.tryParse(_kv.getString(employeeSyncedAtKey) ?? ''),
    );
  }

  Future<void> start(String storeId, String storeName) async {
    await clear();
    await _kv.setString(employeeStoreIdKey, storeId);
    await _kv.setString(employeeStoreNameKey, storeName);
  }

  Future<void> setCursor(String cursor) =>
      _kv.setString(employeeCursorKey, cursor);

  Future<void> setSyncedAt(DateTime at) =>
      _kv.setString(employeeSyncedAtKey, at.toIso8601String());

  Future<void> clear() async {
    for (final k in [
      employeeStoreIdKey,
      employeeStoreNameKey,
      employeeCursorKey,
      employeeSyncedAtKey,
    ]) {
      await _kv.remove(k);
    }
  }
}
