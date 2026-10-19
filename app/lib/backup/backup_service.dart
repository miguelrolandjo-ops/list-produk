import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../data/owner_database.dart';

/// Written into every backup so a random zip is never mistaken for one.
const backupAppId = 'harga-toko-owner';

/// Backup files are named `<prefix>YYYYMMDD-HHMM.zip`; restore looks for this
/// prefix in the Download folder.
const backupFilePrefix = 'harga-toko-cadangan-';
const backupFormat = 1;

const _manifestName = 'manifest.json';
const _databaseName = 'owner.sqlite';

/// Tables a real backup must contain.
const _requiredTables = [
  'settings',
  'pricing_anchors',
  'margin_thresholds',
  'products',
  'suppliers',
  'supplier_prices',
];

/// Whether to show the "back up now" banner: the owner has data worth
/// protecting and the last backup is missing or more than 7 days old.
bool backupReminderDue({
  required DateTime? lastBackup,
  required int productCount,
  required DateTime now,
  bool enabled = true,
}) {
  if (!enabled || productCount == 0) return false;
  return lastBackup == null ||
      now.difference(lastBackup) > const Duration(days: 7);
}

/// A problem with a backup file, in words the owner can read.
class BackupException implements Exception {
  const BackupException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// A backup file that passed all checks and is ready to replace the data.
class BackupCandidate {
  const BackupCandidate({
    required this.file,
    required this.createdAt,
    required this.schemaVersion,
    required this.productCount,
  });

  /// Extracted copy of the database, not yet in use.
  final File file;
  final DateTime createdAt;
  final int schemaVersion;
  final int productCount;
}

/// Backup and restore of the owner database. No UI dependencies.
///
/// A backup is a zip with `manifest.json` and `owner.sqlite` (a consistent
/// copy made with VACUUM INTO). Photos are not included.
class BackupService {
  BackupService({
    required this._db,
    required this._databaseFile,
    required this._tempDir,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final OwnerDatabase _db;
  final File _databaseFile;
  final Directory _tempDir;
  final DateTime Function() _now;

  /// Creates the backup zip in the temp directory and returns it. Call
  /// [markBackedUp] once the owner has actually saved or shared it.
  Future<File> createBackup() async {
    await _tempDir.create(recursive: true);
    final copy = File(p.join(_tempDir.path, 'backup-copy.sqlite'));
    if (copy.existsSync()) copy.deleteSync();
    // VACUUM INTO writes a consistent snapshot even while the app is using
    // the database.
    await _db.customStatement('VACUUM INTO ?', [copy.path]);

    final createdAt = _now().toUtc();
    final archive = Archive()
      ..addFile(
        ArchiveFile.string(
          _manifestName,
          jsonEncode({
            'app': backupAppId,
            'format': backupFormat,
            'schemaVersion': _db.schemaVersion,
            'createdAt': createdAt.toIso8601String(),
          }),
        ),
      )
      ..addFile(ArchiveFile.bytes(_databaseName, await copy.readAsBytes()));
    copy.deleteSync();

    final local = createdAt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    final name =
        '$backupFilePrefix${local.year}${two(local.month)}${two(local.day)}'
        '-${two(local.hour)}${two(local.minute)}.zip';
    final zip = File(p.join(_tempDir.path, name));
    await zip.writeAsBytes(ZipEncoder().encodeBytes(archive));
    return zip;
  }

  /// Remembers when the owner last backed up (settings.last_backup_at).
  Future<void> markBackedUp([DateTime? when]) async {
    final at = (when ?? _now()).toUtc().toIso8601String();
    await _db.customStatement(
      'UPDATE settings SET last_backup_at = ? WHERE id = 1',
      [at],
    );
  }

  /// Checks that [zip] is a backup of this app that this version can read.
  /// Throws [BackupException] otherwise. Changes nothing that is in use.
  Future<BackupCandidate> inspect(File zip) async {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(await zip.readAsBytes());
    } catch (_) {
      throw const BackupException('File ini bukan file cadangan (bukan zip).');
    }

    final manifestFile = archive.find(_manifestName);
    final dbFile = archive.find(_databaseName);
    if (manifestFile == null || dbFile == null) {
      throw const BackupException(
        'File ini bukan cadangan aplikasi Harga Toko.',
      );
    }

    final Map<String, dynamic> manifest;
    try {
      manifest =
          jsonDecode(utf8.decode(manifestFile.content)) as Map<String, dynamic>;
    } catch (_) {
      throw const BackupException('Data cadangan rusak.');
    }
    if (manifest['app'] != backupAppId) {
      throw const BackupException(
        'File ini bukan cadangan aplikasi Harga Toko.',
      );
    }
    final format = manifest['format'];
    final schema = manifest['schemaVersion'];
    final createdAt = DateTime.tryParse('${manifest['createdAt']}');
    if (format is! int || schema is! int || createdAt == null) {
      throw const BackupException('Data cadangan rusak.');
    }
    if (format > backupFormat || schema > _db.schemaVersion) {
      throw const BackupException(
        'Cadangan ini dibuat oleh versi aplikasi yang lebih baru. '
        'Perbarui aplikasi dulu.',
      );
    }

    await _tempDir.create(recursive: true);
    final candidate = File(p.join(_tempDir.path, 'restore-candidate.sqlite'));
    if (candidate.existsSync()) candidate.deleteSync();
    await candidate.writeAsBytes(dbFile.content);

    final productCount = _verifyDatabase(candidate, schema, createdAt);
    return BackupCandidate(
      file: candidate,
      createdAt: createdAt.toLocal(),
      schemaVersion: schema,
      productCount: productCount,
    );
  }

  /// Opens the extracted database on its own and checks it. Also stamps
  /// last_backup_at with the backup's own time, so the restored phone doesn't
  /// start with a stale value. Returns the number of products.
  int _verifyDatabase(File file, int schemaVersion, DateTime createdAt) {
    final sqlite.Database check;
    try {
      check = sqlite.sqlite3.open(file.path);
    } catch (_) {
      throw const BackupException('Data cadangan rusak.');
    }
    try {
      final integrity = check.select('PRAGMA integrity_check').first.values;
      if (integrity.first != 'ok') {
        throw const BackupException('Data cadangan rusak.');
      }
      final version =
          check.select('PRAGMA user_version').first.values.first as int;
      if (version != schemaVersion) {
        throw const BackupException('Data cadangan rusak.');
      }
      final tables = {
        for (final row in check.select(
          "SELECT name FROM sqlite_master WHERE type = 'table'",
        ))
          row['name'] as String,
      };
      if (!tables.containsAll(_requiredTables)) {
        throw const BackupException(
          'File ini bukan cadangan aplikasi Harga Toko.',
        );
      }
      if (check.select('SELECT 1 FROM settings WHERE id = 1').isEmpty) {
        throw const BackupException('Data cadangan rusak.');
      }
      check.execute('UPDATE settings SET last_backup_at = ? WHERE id = 1', [
        createdAt.toUtc().toIso8601String(),
      ]);
      return check.select('SELECT COUNT(*) AS n FROM products').first['n']
          as int;
    } on sqlite.SqliteException {
      throw const BackupException('Data cadangan rusak.');
    } finally {
      check.close();
    }
  }

  /// Replaces ALL data on this phone with [candidate]. The database is closed
  /// first, so the caller must rebuild everything that uses it afterwards.
  /// The old file is kept as `owner.sqlite.before-restore` in case it is
  /// needed.
  Future<void> restore(BackupCandidate candidate) async {
    await _db.close();

    final dir = _databaseFile.parent.path;
    final name = p.basename(_databaseFile.path);
    // A leftover write-ahead log would be applied to the new file.
    for (final suffix in ['-wal', '-shm', '-journal']) {
      final side = File('${_databaseFile.path}$suffix');
      if (side.existsSync()) side.deleteSync();
    }

    final safety = File(p.join(dir, '$name.before-restore'));
    final hadOld = _databaseFile.existsSync();
    if (hadOld) {
      if (safety.existsSync()) safety.deleteSync();
      await _databaseFile.rename(safety.path);
    }
    try {
      await candidate.file.copy(_databaseFile.path);
    } catch (_) {
      // Put the old data back; nothing is lost if the copy fails.
      if (_databaseFile.existsSync()) _databaseFile.deleteSync();
      if (hadOld) await safety.rename(_databaseFile.path);
      throw const BackupException(
        'Pemulihan gagal. Data di HP ini tidak diubah.',
      );
    }
    if (candidate.file.existsSync()) candidate.file.deleteSync();
  }
}
