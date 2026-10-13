import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _marginWarningKey = 'show_margin_warning_icon';
const _overrideIconKey = 'show_override_icon';
const _backupReminderKey = 'backup_reminder';

/// Only these keys are read or written by the app.
const displayPrefKeys = {
  _marginWarningKey,
  _overrideIconKey,
  _backupReminderKey,
};

/// Created in main() before runApp, so reads are synchronous and the list
/// never flashes the wrong icons on startup.
final sharedPrefsProvider = Provider<SharedPreferencesWithCache>(
  (ref) => throw UnimplementedError('Override sharedPrefsProvider in main()'),
);

/// Per-device display preferences (what the home list shows, whether the
/// backup banner appears). Not business data, so not in the database.
class DisplayPrefs {
  const DisplayPrefs({
    this.showMarginWarning = true,
    this.showOverrideIcon = true,
    this.backupReminder = true,
  });

  final bool showMarginWarning;
  final bool showOverrideIcon;
  final bool backupReminder;

  DisplayPrefs copyWith({
    bool? showMarginWarning,
    bool? showOverrideIcon,
    bool? backupReminder,
  }) => DisplayPrefs(
    showMarginWarning: showMarginWarning ?? this.showMarginWarning,
    showOverrideIcon: showOverrideIcon ?? this.showOverrideIcon,
    backupReminder: backupReminder ?? this.backupReminder,
  );
}

class DisplayPrefsNotifier extends Notifier<DisplayPrefs> {
  @override
  DisplayPrefs build() {
    final prefs = ref.watch(sharedPrefsProvider);
    return DisplayPrefs(
      showMarginWarning: prefs.getBool(_marginWarningKey) ?? true,
      showOverrideIcon: prefs.getBool(_overrideIconKey) ?? true,
      backupReminder: prefs.getBool(_backupReminderKey) ?? true,
    );
  }

  Future<void> setShowMarginWarning(bool value) async {
    state = state.copyWith(showMarginWarning: value);
    await ref.read(sharedPrefsProvider).setBool(_marginWarningKey, value);
  }

  Future<void> setShowOverrideIcon(bool value) async {
    state = state.copyWith(showOverrideIcon: value);
    await ref.read(sharedPrefsProvider).setBool(_overrideIconKey, value);
  }

  Future<void> setBackupReminder(bool value) async {
    state = state.copyWith(backupReminder: value);
    await ref.read(sharedPrefsProvider).setBool(_backupReminderKey, value);
  }
}

final displayPrefsProvider =
    NotifierProvider<DisplayPrefsNotifier, DisplayPrefs>(
      DisplayPrefsNotifier.new,
    );
