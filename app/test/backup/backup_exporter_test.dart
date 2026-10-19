import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_application_1/backup/backup_exporter.dart';
import 'package:flutter_application_1/backup/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late Directory downloads;
  late Directory temp;

  setUp(() {
    root = Directory.systemTemp.createTempSync('exporter_test');
    downloads = Directory(p.join(root.path, 'Download'))..createSync();
    temp = Directory(p.join(root.path, 'tmp'))..createSync();
  });
  tearDown(() => root.deleteSync(recursive: true));

  File zip(String name, {String content = 'zip', DateTime? modified}) {
    final f = File(p.join(root.path, name))..writeAsStringSync(content);
    if (modified != null) f.setLastModifiedSync(modified);
    return f;
  }

  File inDownloads(String name, {DateTime? modified, String content = 'x'}) {
    final f = File(p.join(downloads.path, name))..writeAsStringSync(content);
    if (modified != null) f.setLastModifiedSync(modified);
    return f;
  }

  group('newestFirst', () {
    SavedBackup b(String name, DateTime t) =>
        SavedBackup(id: name, name: name, size: 1, modified: t);

    test('sorts by time, newest first; the name breaks a tie', () {
      final old = b('a-old', DateTime(2026, 1, 1));
      final tieA = b('harga-toko-cadangan-20260301-0900.zip', DateTime(2026, 3, 1));
      final tieB = b('harga-toko-cadangan-20260301-1000.zip', DateTime(2026, 3, 1));
      final newest = b('z-new', DateTime(2026, 9, 1));
      expect(
        newestFirst([old, tieA, newest, tieB]).map((e) => e.name),
        [newest.name, tieB.name, tieA.name, old.name],
      );
    });
  });

  group('desktop / non-Android', () {
    PlatformBackupExporter exporter() => PlatformBackupExporter(
      isAndroid: false,
      downloadsDir: downloads,
      tempDir: temp,
    );

    test('saves into the Download folder without asking, never overwriting', () async {
      final file = zip('${backupFilePrefix}20261019-0830.zip');
      final e = exporter();

      expect(await e.saveToDownloads(file), isTrue);
      expect(await e.saveToDownloads(file), isTrue);
      expect(await e.saveToDownloads(file), isTrue);

      final names = downloads.listSync().map((f) => p.basename(f.path)).toList()..sort();
      expect(names, [
        '${backupFilePrefix}20261019-0830 (1).zip',
        '${backupFilePrefix}20261019-0830 (2).zip',
        '${backupFilePrefix}20261019-0830.zip',
      ]);
    });

    test('no Download folder known: saving fails, listing is empty', () async {
      final e = PlatformBackupExporter(
        isAndroid: false,
        downloadsDir: Directory(p.join(root.path, 'nope')),
        tempDir: temp,
      );
      expect(await e.savedBackups(), isEmpty);
    });

    test('lists only this app\'s backups, newest first', () async {
      inDownloads('${backupFilePrefix}20260901-0800.zip', modified: DateTime(2026, 9, 1));
      inDownloads('${backupFilePrefix}20261015-0800.zip', modified: DateTime(2026, 10, 15));
      inDownloads('${backupFilePrefix}20260101-0800.zip', modified: DateTime(2026, 1, 1));
      inDownloads('holiday.zip', modified: DateTime(2026, 10, 18)); // someone else's zip
      inDownloads('${backupFilePrefix}20261016-0800.txt', modified: DateTime(2026, 10, 16)); // not a zip

      final found = await exporter().savedBackups();

      expect(found.map((b) => b.name), [
        '${backupFilePrefix}20261015-0800.zip',
        '${backupFilePrefix}20260901-0800.zip',
        '${backupFilePrefix}20260101-0800.zip',
      ]);
      expect(found.first.size, 1);
      expect(found.first.modified, DateTime(2026, 10, 15));
    });

    test('an empty Download folder lists nothing', () async {
      expect(await exporter().savedBackups(), isEmpty);
    });

    test('fetch copies the backup into a temp folder, leaving the original', () async {
      final original = inDownloads('${backupFilePrefix}20261015-0800.zip', content: 'data');
      final e = exporter();
      final backup = (await e.savedBackups()).single;

      final fetched = await e.fetch(backup);

      expect(fetched.path, startsWith(temp.path));
      expect(fetched.readAsStringSync(), 'data');
      expect(original.existsSync(), isTrue);
    });

    test('what is saved can be found again (the round trip restore relies on)', () async {
      final e = exporter();
      await e.saveToDownloads(zip('${backupFilePrefix}20261019-0830.zip', content: 'abc'));
      final found = await e.savedBackups();
      expect(found.single.name, '${backupFilePrefix}20261019-0830.zip');
      expect((await e.fetch(found.single)).readAsStringSync(), 'abc');
    });
  });

  group('Android channel', () {
    const channel = MethodChannel(PlatformBackupExporter.channelName);
    late List<MethodCall> calls;
    Object? Function(MethodCall) handler = (_) => null;

    PlatformBackupExporter exporter() => PlatformBackupExporter(
      channel: channel,
      isAndroid: true,
      tempDir: temp,
    );

    setUp(() {
      calls = [];
      handler = (_) => null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return handler(call);
          });
    });
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('save sends the file path and name, and succeeds when a name comes back', () async {
      handler = (_) => '${backupFilePrefix}20261019-0830 (1).zip';
      final file = zip('${backupFilePrefix}20261019-0830.zip');

      expect(await exporter().saveToDownloads(file), isTrue);

      expect(calls.single.method, 'saveToDownloads');
      expect(calls.single.arguments, {
        'sourcePath': file.path,
        'name': '${backupFilePrefix}20261019-0830.zip',
      });
    });

    test('save fails (without throwing) on Android 9 and older, and on errors', () async {
      final file = zip('b.zip');
      handler = (_) => null; // the native side returns null below Android 10
      expect(await exporter().saveToDownloads(file), isFalse);

      handler = (_) => throw PlatformException(code: 'backup_files', message: 'penuh');
      expect(await exporter().saveToDownloads(file), isFalse);
    });

    test('lists the saved backups newest first and skips non-zip files', () async {
      handler = (call) => [
        {
          'uri': 'content://media/1',
          'name': '${backupFilePrefix}20260901-0800.zip',
          'size': 2048,
          'modified': DateTime(2026, 9, 1).millisecondsSinceEpoch,
        },
        {
          'uri': 'content://media/2',
          'name': '${backupFilePrefix}20261015-0800.zip',
          'size': 4096,
          'modified': DateTime(2026, 10, 15).millisecondsSinceEpoch,
        },
        {
          'uri': 'content://media/3',
          'name': '${backupFilePrefix}20261016-0800.txt',
          'size': 1,
          'modified': DateTime(2026, 10, 16).millisecondsSinceEpoch,
        },
      ];

      final found = await exporter().savedBackups();

      expect(calls.single.method, 'listBackups');
      expect(calls.single.arguments, {'prefix': backupFilePrefix});
      expect(found.map((b) => b.id), ['content://media/2', 'content://media/1']);
      expect(found.first.size, 4096);
      expect(found.first.modified, DateTime(2026, 10, 15));
    });

    test('a listing error means "none found", so restore opens the file picker', () async {
      handler = (_) => throw PlatformException(code: 'backup_files');
      expect(await exporter().savedBackups(), isEmpty);
    });

    test('nothing registered natively (for example after a hot restart): empty, no crash', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      expect(await exporter().savedBackups(), isEmpty);
      expect(await exporter().saveToDownloads(zip('c.zip')), isFalse);
    });

    test('fetch asks the native side to copy the content URI to a temp file', () async {
      final backup = SavedBackup(
        id: 'content://media/2',
        name: '${backupFilePrefix}20261015-0800.zip',
        size: 1,
        modified: DateTime(2026, 10, 15),
      );
      handler = (_) => true;

      final file = await exporter().fetch(backup);

      expect(calls.single.method, 'copyToFile');
      expect(calls.single.arguments, {'uri': 'content://media/2', 'destPath': file.path});
      expect(file.path, startsWith(temp.path));
      expect(p.basename(file.path), backup.name);
    });
  });
}
