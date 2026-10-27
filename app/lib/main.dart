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
import 'inbox/inbox_providers.dart';
import 'inbox/po_intake_service.dart';
import 'inbox/share_intake.dart';
import 'onboarding/shop_profile.dart';
import 'welcome/invite_link.dart';

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

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  final _share = ShareIntake();
  final _invites = InviteLinkIntake();

  @override
  void initState() {
    super.initState();
    _share.listen(_takeShared);
    _invites.listen(_takeInvite);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _takeShared();
      _takeInvite();
    });
  }

  /// An invite link was tapped: on a new phone it opens "Gabung sebagai
  /// karyawan" with the code filled in. It never joins by itself; the
  /// employee still types a name and taps Gabung.
  Future<void> _takeInvite() async {
    final link = await _invites.take();
    if (link == null || !mounted) return;
    final code = InviteLink.codeFrom(link);
    void say(String text) => _messenger.currentState?.showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 6)),
    );
    if (code == null) {
      say('Tautan undangan tidak lengkap. Minta kode undangan ke pemilik toko.');
      return;
    }
    switch (ref.read(appModeProvider)) {
      case null:
        ref.read(routerProvider).go('/mulai?kode=$code');
      case AppMode.employee:
        say(
          'HP ini sudah tergabung dengan toko. Untuk memakai undangan baru, '
          'pilih Keluar dari toko di menu, lalu buka tautannya lagi.',
        );
      case AppMode.owner:
        say(
          'Ini HP pemilik toko. Buka tautan undangan di HP karyawan.',
        );
    }
  }

  /// Photos shared from WhatsApp and other apps become a PO in the Inbox.
  /// Only on the owner's phone; elsewhere they stay with Android until then.
  Future<void> _takeShared() async {
    if (ref.read(appModeProvider) != AppMode.owner) return;
    final paths = await _share.take();
    if (paths.isEmpty) return;
    try {
      await ref.read(poIntakeServiceProvider).create(paths, PoSource.share);
      ref.read(inboxRunnerProvider).kick();
      ref.read(routerProvider).go('/inbox');
      _messenger.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            paths.length == 1
                ? 'Foto PO diterima'
                : 'PO dengan ${paths.length} halaman diterima',
          ),
        ),
      );
    } on Object catch (e) {
      _messenger.currentState?.showSnackBar(
        SnackBar(content: Text('Foto tidak bisa disimpan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // The owner's phone publishes to the employee catalog and moves PO photos
    // along in the background.
    if (ref.watch(appModeProvider) == AppMode.owner) {
      ref.watch(autoPublisherProvider);
      if (ref.watch(serverApiProvider) != null) ref.watch(inboxRunnerProvider);
    }
    // Becoming the owner (after onboarding or restore) picks up a share that
    // arrived before.
    ref.listen(appModeProvider, (_, mode) {
      if (mode == AppMode.owner) _takeShared();
    });
    return MaterialApp.router(
      title: 'Harga Toko',
      theme: buildAppTheme(),
      scaffoldMessengerKey: _messenger,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
