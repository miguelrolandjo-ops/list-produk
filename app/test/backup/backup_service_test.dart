import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter_application_1/backup/backup_service.dart';
import 'package:flutter_application_1/data/owner_database.dart';
import 'package:flutter_application_1/products/product_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late File dbFile;
  late Directory temp;
  late OwnerDatabase db;
  late BackupService backup;
  final fixedNow = DateTime.utc(2026, 10, 6, 8, 30);

  OwnerDatabase open() => OwnerDatabase(NativeDatabase(dbFile));

  setUp(() {
    root = Directory.systemTemp.createTempSync('backup_test');
    dbFile = File(p.join(root.path, 'owner.sqlite'));
    temp = Directory(p.join(root.path, 'tmp'));
    db = open();
    backup = BackupService(
      db: db,
      databaseFile: dbFile,
      tempDir: temp,
      now: () => fixedNow,
    );
  });

  tearDown(() async {
    await db.close();
    root.deleteSync(recursive: true);
  });

  Future<String> addProduct(OwnerDatabase target, String name, int supply) =>
      ProductService(target).addManual(
        NewProductInput(
          name: name,
          supplierName: 'CV Maju',
          supplyPrice: supply,
        ),
      );

  Future<List<String>> productNames(OwnerDatabase target) async => [
    for (final r in await (target.select(target.products)).get()) r.name,
  ];

  File writeZip(Map<String, List<int>> files) {
    final archive = Archive();
    files.forEach(
      (name, bytes) => archive.addFile(ArchiveFile.bytes(name, bytes)),
    );
    final f = File(p.join(root.path, 'x.zip'));
    f.writeAsBytesSync(ZipEncoder().encodeBytes(archive));
    return f;
  }

  List<int> manifest({
    String app = backupAppId,
    int format = backupFormat,
    int schema = 1,
  }) => utf8.encode(
    jsonEncode({
      'app': app,
      'format': format,
      'schemaVersion': schema,
      'createdAt': fixedNow.toIso8601String(),
    }),
  );

  test('a backup restores the data after the database is replaced', () async {
    await addProduct(db, 'Kabel', 9500);
    final zip = await backup.createBackup();
    expect(zip.path, endsWith('.zip'));
    expect(p.basename(zip.path), contains('20261006'));

    // Data changes after the backup was made.
    await addProduct(db, 'Charger', 45000);
    expect(await productNames(db), hasLength(2));

    final candidate = await backup.inspect(zip);
    expect(candidate.productCount, 1);
    expect(candidate.schemaVersion, 1);
    await backup.restore(candidate);

    final restored = open();
    addTearDown(restored.close);
    expect(await productNames(restored), ['Kabel']);
    // Default data is intact too.
    expect(await restored.select(restored.pricingAnchors).get(), hasLength(18));
    // The previous data is kept as a safety copy.
    expect(File('${dbFile.path}.before-restore').existsSync(), isTrue);
  });

  test('restore stamps last_backup_at with the backup time', () async {
    final zip = await backup.createBackup();
    await backup.restore(await backup.inspect(zip));

    final restored = open();
    addTearDown(restored.close);
    final s = await restored.select(restored.settings).getSingle();
    expect(DateTime.parse(s.lastBackupAt!), fixedNow);
  });

  test('markBackedUp stores last_backup_at', () async {
    await backup.markBackedUp();
    final s = await db.select(db.settings).getSingle();
    expect(DateTime.parse(s.lastBackupAt!), fixedNow);
  });

  test(
    'the backup contains no supplier-independent junk, only the two files',
    () async {
      final zip = await backup.createBackup();
      final names = ZipDecoder()
          .decodeBytes(zip.readAsBytesSync())
          .files
          .map((f) => f.name)
          .toSet();
      expect(names, {'manifest.json', 'owner.sqlite'});
      expect(temp.listSync().whereType<File>().map((f) => p.basename(f.path)), [
        p.basename(zip.path),
      ]); // the temporary copy was cleaned up
    },
  );

  group('rejects files that are not a usable backup', () {
    Future<void> expectRejected(File f, [String? text]) async {
      await expectLater(
        backup.inspect(f),
        throwsA(
          isA<BackupException>().having(
            (e) => e.message,
            'message',
            text == null ? isNotEmpty : contains(text),
          ),
        ),
      );
    }

    test('not a zip', () async {
      final f = File(p.join(root.path, 'junk.zip'))..writeAsStringSync('hello');
      await expectRejected(f, 'bukan cadangan');
    });

    test('zip without the manifest', () async {
      await expectRejected(writeZip({'a.txt': utf8.encode('hi')}));
    });

    test('manifest from another app', () async {
      final real = await backup.createBackup();
      final dbBytes = ZipDecoder()
          .decodeBytes(real.readAsBytesSync())
          .find('owner.sqlite')!
          .content;
      await expectRejected(
        writeZip({
          'manifest.json': manifest(app: 'other-app'),
          'owner.sqlite': dbBytes,
        }),
        'bukan cadangan',
      );
    });

    test('made by a newer app version', () async {
      final real = await backup.createBackup();
      final dbBytes = ZipDecoder()
          .decodeBytes(real.readAsBytesSync())
          .find('owner.sqlite')!
          .content;
      await expectRejected(
        writeZip({
          'manifest.json': manifest(schema: 99),
          'owner.sqlite': dbBytes,
        }),
        'lebih baru',
      );
    });

    test('corrupt database bytes', () async {
      await expectRejected(
        writeZip({
          'manifest.json': manifest(),
          'owner.sqlite': List.filled(5000, 7),
        }),
      );
    });

    test('a sqlite file from some other app', () async {
      final other = File(p.join(root.path, 'other.sqlite'));
      final o = OwnerDatabase(NativeDatabase(other));
      await o.customStatement('DROP TABLE supplier_prices');
      await o.close();
      await expectRejected(
        writeZip({
          'manifest.json': manifest(),
          'owner.sqlite': other.readAsBytesSync(),
        }),
        'bukan cadangan',
      );
    });

    test('a rejected file never touches the current data', () async {
      await addProduct(db, 'Kabel', 9500);
      await expectRejected(writeZip({'a.txt': utf8.encode('hi')}));
      expect(await productNames(db), ['Kabel']);
    });
  });
}
