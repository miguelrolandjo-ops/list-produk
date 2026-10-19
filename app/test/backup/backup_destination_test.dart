import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/backup/backup_exporter.dart';
import 'package:flutter_application_1/backup/backup_screen.dart';
import 'package:flutter_application_1/backup/backup_service.dart';
import 'package:flutter_application_1/core/display_prefs.dart';
import 'package:flutter_application_1/core/providers.dart';
import 'package:flutter_application_1/data/owner_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' as p;

class _FakeExporter implements BackupExporter {
  _FakeExporter({
    this.shared = true,
    this.saved = true,
    this.backups = const [],
  });

  final bool shared;
  final bool saved;

  /// What "found in Download" returns (the screen expects newest first).
  final List<SavedBackup> backups;

  /// What the file picker returns, and what [fetch] returns.
  File? picked;
  File? fetchResult;

  final sharedFiles = <String>[];
  final savedFiles = <String>[];
  final fetched = <String>[];
  var pickCalls = 0;

  @override
  Future<bool> shareFile(File zip) async {
    expect(zip.existsSync(), isTrue); // a real zip was made first
    sharedFiles.add(p.basename(zip.path));
    return shared;
  }

  @override
  Future<bool> saveToDownloads(File zip) async {
    expect(zip.existsSync(), isTrue);
    savedFiles.add(p.basename(zip.path));
    return saved;
  }

  @override
  Future<List<SavedBackup>> savedBackups() async => backups;

  @override
  Future<File> fetch(SavedBackup backup) async {
    fetched.add(backup.id);
    return fetchResult!;
  }

  @override
  Future<File?> pickFile() async {
    pickCalls++;
    return picked;
  }
}

class _FakeDisplayPrefs extends DisplayPrefsNotifier {
  @override
  DisplayPrefs build() => const DisplayPrefs(
    showMarginWarning: true,
    showOverrideIcon: true,
    backupReminder: true,
  );
}

void main() {
  late Directory root;
  late OwnerDatabase db;
  late BackupService service;

  Future<void> settle(WidgetTester tester) => tester
      .runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      })
      .then((_) => tester.pump());

  Future<void> frames(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Real time passes while the zip is made and written; wait until the busy
  /// spinner of the screen is gone (or give up after a few seconds).
  Future<void> done(WidgetTester tester, {bool Function()? until}) async {
    for (var i = 0; i < 60; i++) {
      await settle(tester);
      final finished = until != null
          ? until()
          : find.byType(SnackBar).evaluate().isNotEmpty;
      if (finished && find.byType(CircularProgressIndicator).evaluate().isEmpty) {
        break;
      }
    }
    await frames(tester);
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> open(WidgetTester tester, _FakeExporter exporter) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    root = Directory.systemTemp.createTempSync('backup_dest_test');
    addTearDown(() => root.deleteSync(recursive: true));
    final dbFile = File(p.join(root.path, 'owner.sqlite'));
    db = OwnerDatabase(NativeDatabase(dbFile));
    addTearDown(() => tester.runAsync(db.close));
    await tester.runAsync(() => initializeDateFormatting('id_ID'));

    service = BackupService(
      db: db,
      databaseFile: dbFile,
      tempDir: Directory(p.join(root.path, 'tmp')),
      now: () => DateTime.utc(2026, 10, 19, 8, 30),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ownerDbProvider.overrideWithValue(db),
          displayPrefsProvider.overrideWith(_FakeDisplayPrefs.new),
          backupServiceProvider.overrideWith((ref) async => service),
          backupExporterProvider.overrideWithValue(exporter),
        ],
        child: const MaterialApp(home: BackupScreen()),
      ),
    );
    await settle(tester);
  }

  Future<bool> markedBackedUp(WidgetTester tester) async => (await tester
          .runAsync(
            () => db
                .customSelect('SELECT last_backup_at FROM settings')
                .getSingle(),
          ))!
      .readNullable<String>('last_backup_at') !=
      null;

  testWidgets('"Cadangkan sekarang" offers Google Drive or the phone', (tester) async {
    await open(tester, _FakeExporter());
    await tester.tap(find.text('Cadangkan sekarang'));
    await frames(tester);

    expect(find.text('Simpan cadangan ke mana?'), findsOneWidget);
    expect(find.text('Google Drive'), findsOneWidget);
    expect(find.text('Simpan di HP'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('"Simpan di HP" saves straight to Download, with no other prompt', (
    tester,
  ) async {
    final exporter = _FakeExporter();
    await open(tester, exporter);
    await tester.tap(find.text('Cadangkan sekarang'));
    await frames(tester);
    await tester.tap(find.text('Simpan di HP'));
    await done(tester);

    expect(exporter.sharedFiles, isEmpty);
    expect(exporter.savedFiles, hasLength(1));
    expect(exporter.savedFiles.single, startsWith('harga-toko-cadangan-20261019'));
    expect(exporter.savedFiles.single, endsWith('.zip'));
    // No folder picker or confirmation: just the result message.
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);
    expect(
      find.textContaining('Cadangan disimpan di folder Download: harga-toko-cadangan-'),
      findsOneWidget,
    );
    expect(await markedBackedUp(tester), isTrue);
    await finish(tester);
  });

  testWidgets('"Google Drive" opens the share sheet', (tester) async {
    final exporter = _FakeExporter();
    await open(tester, exporter);
    await tester.tap(find.text('Cadangkan sekarang'));
    await frames(tester);
    await tester.tap(find.text('Google Drive'));
    await done(tester);

    expect(exporter.savedFiles, isEmpty);
    expect(exporter.sharedFiles, hasLength(1));
    expect(await markedBackedUp(tester), isTrue);
    await finish(tester);
  });

  testWidgets('closing the share sheet without choosing is not a backup', (tester) async {
    final exporter = _FakeExporter(shared: false);
    await open(tester, exporter);
    await tester.tap(find.text('Cadangkan sekarang'));
    await frames(tester);
    await tester.tap(find.text('Google Drive'));
    // No message is shown in this case, so wait for the share call instead.
    await done(tester, until: () => exporter.sharedFiles.isNotEmpty);

    expect(exporter.sharedFiles, hasLength(1));
    expect(await markedBackedUp(tester), isFalse);
    await finish(tester);
  });

  testWidgets('a failed save to Download says so and is not a backup', (tester) async {
    final exporter = _FakeExporter(saved: false);
    await open(tester, exporter);
    await tester.tap(find.text('Cadangkan sekarang'));
    await frames(tester);
    await tester.tap(find.text('Simpan di HP'));
    await done(tester);

    expect(
      find.text('Gagal menyimpan ke folder Download. Coba lewat Google Drive.'),
      findsOneWidget,
    );
    expect(await markedBackedUp(tester), isFalse);
    await finish(tester);
  });

  testWidgets('dismissing the popup does nothing', (tester) async {
    final exporter = _FakeExporter();
    await open(tester, exporter);
    await tester.tap(find.text('Cadangkan sekarang'));
    await frames(tester);
    // Tap outside the sheet.
    await tester.tapAt(const Offset(400, 50));
    await frames(tester);

    expect(exporter.sharedFiles, isEmpty);
    expect(exporter.savedFiles, isEmpty);
    expect(await markedBackedUp(tester), isFalse);
    await finish(tester);
  });

  group('restore looks in the Download folder first', () {
    SavedBackup saved(String name, DateTime when, {int size = 4096}) =>
        SavedBackup(id: 'id-$name', name: name, size: size, modified: when);

    final newest = saved(
      'harga-toko-cadangan-20261018-0900.zip',
      DateTime(2026, 10, 18, 9, 0),
      size: 3 * 1024 * 1024,
    );
    final older = saved(
      'harga-toko-cadangan-20260901-0800.zip',
      DateTime(2026, 9, 1, 8, 0),
    );

    Future<File> realZip(WidgetTester tester) async =>
        (await tester.runAsync(() => service.createBackup()))!;

    testWidgets('lists what it found, newest first, with the newest marked', (tester) async {
      final exporter = _FakeExporter(backups: [newest, older]);
      await open(tester, exporter);

      await tester.tap(find.text('Pulihkan dari file'));
      await frames(tester);

      expect(find.text('Pilih cadangan'), findsOneWidget);
      expect(find.text('Ditemukan di folder Download'), findsOneWidget);
      expect(find.text('Terbaru'), findsOneWidget); // only the first one
      expect(find.textContaining('3,0 MB'), findsOneWidget);
      expect(find.textContaining('4 KB'), findsOneWidget);
      // Newest above older.
      expect(
        tester.getTopLeft(find.textContaining(newest.name)).dy,
        lessThan(tester.getTopLeft(find.textContaining(older.name)).dy),
      );
      // The general picker is not opened unless asked for.
      expect(exporter.pickCalls, 0);
      await finish(tester);
    });

    testWidgets('choosing one fetches it and asks for confirmation; Batal changes nothing', (
      tester,
    ) async {
      final exporter = _FakeExporter(backups: [newest, older]);
      await open(tester, exporter);
      exporter.fetchResult = await realZip(tester);

      await tester.tap(find.text('Pulihkan dari file'));
      await frames(tester);
      await tester.tap(find.textContaining(newest.name));
      await done(tester, until: () => find.text('Pulihkan data?').evaluate().isNotEmpty);

      expect(exporter.fetched, [newest.id]);
      expect(exporter.pickCalls, 0);
      expect(find.text('Pulihkan data?'), findsOneWidget);
      expect(find.textContaining('berisi 0 produk'), findsOneWidget);

      await tester.tap(find.text('Batal'));
      await frames(tester);
      expect(find.text('Pulihkan data?'), findsNothing);
      await finish(tester);
    });

    testWidgets('no backups found: the file picker opens straight away', (tester) async {
      final exporter = _FakeExporter(); // nothing in Download
      await open(tester, exporter);

      await tester.tap(find.text('Pulihkan dari file'));
      await done(tester, until: () => exporter.pickCalls > 0);

      expect(exporter.pickCalls, 1);
      expect(find.text('Pilih cadangan'), findsNothing); // no list to show
      expect(find.byType(AlertDialog), findsNothing); // cancelled picker: nothing happens
      await finish(tester);
    });

    testWidgets('"Pilih file lain" opens the file picker', (tester) async {
      final exporter = _FakeExporter(backups: [newest]);
      await open(tester, exporter);

      await tester.tap(find.text('Pulihkan dari file'));
      await frames(tester);
      await tester.tap(find.text('Pilih file lain'));
      await done(tester, until: () => exporter.pickCalls > 0);

      expect(exporter.pickCalls, 1);
      expect(exporter.fetched, isEmpty);
      await finish(tester);
    });

    testWidgets('a file from the picker goes through the same checks and confirmation', (
      tester,
    ) async {
      final exporter = _FakeExporter();
      await open(tester, exporter);
      exporter.picked = await realZip(tester);

      await tester.tap(find.text('Pulihkan dari file'));
      await done(tester, until: () => find.text('Pulihkan data?').evaluate().isNotEmpty);
      expect(find.text('Pulihkan data?'), findsOneWidget);
      await tester.tap(find.text('Batal'));
      await frames(tester);
      await finish(tester);
    });

    testWidgets('a file that is not a backup is refused with a message', (tester) async {
      final exporter = _FakeExporter();
      await open(tester, exporter);
      exporter.picked = File(p.join(root.path, 'notes.zip'))
        ..writeAsStringSync('not a zip at all');

      await tester.tap(find.text('Pulihkan dari file'));
      await done(tester);

      expect(find.text('File ini bukan cadangan aplikasi Harga Toko.'), findsOneWidget);
      expect(find.text('Pulihkan data?'), findsNothing);
      await finish(tester);
    });

    testWidgets('dismissing the list does nothing', (tester) async {
      final exporter = _FakeExporter(backups: [newest]);
      await open(tester, exporter);

      await tester.tap(find.text('Pulihkan dari file'));
      await frames(tester);
      await tester.tapAt(const Offset(400, 50));
      await frames(tester);

      expect(exporter.fetched, isEmpty);
      expect(exporter.pickCalls, 0);
      expect(find.text('Pulihkan data?'), findsNothing);
      await finish(tester);
    });
  });
}
