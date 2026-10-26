import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'display_prefs.dart';

/// Which side of the app this phone is: the owner's (all data, all screens) or
/// an employee's (the read-only catalog). Null until chosen on the first
/// launch screen. An employee phone can never open an owner screen; the router
/// enforces it.
enum AppMode { owner, employee }

const appModeKey = 'app_mode';
const employeeStoreIdKey = 'employee_store_id';
const employeeStoreNameKey = 'employee_store_name';
const employeeCursorKey = 'employee_cursor';
const employeeSyncedAtKey = 'employee_synced_at';

/// Preference keys besides the display ones; main() adds them to the
/// SharedPreferences allow list.
const appPrefKeys = {
  appModeKey,
  employeeStoreIdKey,
  employeeStoreNameKey,
  employeeCursorKey,
  employeeSyncedAtKey,
};

/// The few string values the app keeps outside the databases. An interface so
/// tests can use a plain map.
abstract class KeyValueStore {
  String? getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

class PrefsKeyValueStore implements KeyValueStore {
  PrefsKeyValueStore(this._prefs);
  final SharedPreferencesWithCache _prefs;

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

class MemoryKeyValueStore implements KeyValueStore {
  final values = <String, String>{};

  @override
  String? getString(String key) => values[key];

  @override
  Future<void> setString(String key, String value) async => values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);
}

final keyValueStoreProvider = Provider<KeyValueStore>(
  (ref) => PrefsKeyValueStore(ref.watch(sharedPrefsProvider)),
);

class AppModeNotifier extends Notifier<AppMode?> {
  @override
  AppMode? build() => switch (ref.watch(keyValueStoreProvider).getString(
    appModeKey,
  )) {
    'owner' => AppMode.owner,
    'employee' => AppMode.employee,
    _ => null,
  };

  Future<void> set(AppMode? mode) async {
    final store = ref.read(keyValueStoreProvider);
    if (mode == null) {
      await store.remove(appModeKey);
    } else {
      await store.setString(appModeKey, mode.name);
    }
    state = mode;
  }
}

final appModeProvider = NotifierProvider<AppModeNotifier, AppMode?>(
  AppModeNotifier.new,
);
