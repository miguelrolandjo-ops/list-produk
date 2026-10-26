import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_mode.dart';
import 'core/display_prefs.dart';
import 'core/router.dart';
import 'core/server_config.dart';
import 'core/server_providers.dart';
import 'core/ui.dart';
import 'onboarding/shop_profile.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Date names (Okt, Nov, ...) in Indonesian.
  await initializeDateFormatting('id_ID');
  final prefs = await SharedPreferencesWithCache.create(
    cacheOptions: SharedPreferencesWithCacheOptions(
      allowList: {...displayPrefKeys, ...appPrefKeys, ...shopProfileKeys},
    ),
  );

  // Phones that used the app before modes existed already hold the owner's
  // data: they stay the owner's phone and skip the welcome screen.
  if (prefs.getString(appModeKey) == null) {
    final docs = await getApplicationDocumentsDirectory();
    if (await File(p.join(docs.path, 'owner.sqlite')).exists()) {
      await prefs.setString(appModeKey, AppMode.owner.name);
    }
  }

  if (ServerConfig.isConfigured) {
    // Works offline too: the saved session is restored, refreshed when online.
    await Supabase.initialize(
      url: ServerConfig.url,
      anonKey: ServerConfig.anonKey,
    );
  }

  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const App(),
    ),
  );
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The owner's phone publishes to the employee catalog in the background.
    if (ref.watch(appModeProvider) == AppMode.owner) {
      ref.watch(autoPublisherProvider);
    }
    return MaterialApp.router(
      title: 'Harga Toko',
      theme: buildAppTheme(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
