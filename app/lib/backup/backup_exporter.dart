import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'backup_service.dart' show backupFilePrefix;

/// What the owner picks in "Cadangkan sekarang".
enum BackupDestination { drive, local }

/// A backup this app saved earlier in the Download folder.
class SavedBackup {
  const SavedBackup({
    required this.id,
    required this.name,
    required this.size,
    required this.modified,
  });

  /// Opaque handle for [BackupExporter.fetch] (a content URI on Android, a
  /// file path elsewhere).
  final String id;
  final String name;

  /// Bytes.
  final int size;
  final DateTime modified;
}

/// Newest first; the name (which holds the backup's timestamp) breaks ties.
List<SavedBackup> newestFirst(Iterable<SavedBackup> backups) =>
    backups.toList()..sort((a, b) {
      final byTime = b.modified.compareTo(a.modified);
      return byTime != 0 ? byTime : b.name.compareTo(a.name);
    });

/// Where backups go and where restore looks for them. Behind an interface so
/// the screen can be tested without the platform.
abstract class BackupExporter {
  /// Opens the system share sheet (Google Drive is one of its targets).
  /// Returns false if the owner closed the sheet without choosing anything.
  Future<bool> shareFile(File zip);

  /// Copies the zip into the phone's public Download folder, without asking
  /// where. Returns true if it was saved.
  Future<bool> saveToDownloads(File zip);

  /// Backups this app saved in the Download folder, newest first. Empty when
  /// there are none or they cannot be listed (restore then just opens the file
  /// picker).
  Future<List<SavedBackup>> savedBackups();

  /// Makes [backup] available as a normal file that can be inspected.
  Future<File> fetch(SavedBackup backup);

  /// The general file picker, for a backup that is somewhere else. Null if the
  /// owner cancelled.
  Future<File?> pickFile();
}

/// The real thing.
///
/// Android: a small MediaStore channel in `MainActivity.kt`. MediaStore needs
/// no permission or folder prompt for files this app saved itself, and picks a
/// free name instead of overwriting. It is our own code rather than a plugin
/// because plugins that apply the Kotlin Gradle plugin will stop building in
/// future Flutter versions. Android 9 and older are not supported.
///
/// Other platforms (the Windows development machine): the user's Downloads
/// folder, directly.
///
/// Google Drive: the share sheet. The real Drive API needs a Google Cloud
/// project and sign-in, which is more than a backup file warrants.
class PlatformBackupExporter implements BackupExporter {
  PlatformBackupExporter({
    MethodChannel? channel,
    bool? isAndroid,
    this.downloadsDir,
    this.tempDir,
  }) : _channel = channel ?? const MethodChannel(channelName),
       _isAndroid = isAndroid ?? Platform.isAndroid;

  static const channelName = 'harga_toko/backup_files';

  final MethodChannel _channel;
  final bool _isAndroid;

  /// Overrides for tests: where "Download" and the temp folder are.
  final Directory? downloadsDir;
  final Directory? tempDir;

  @override
  Future<bool> shareFile(File zip) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(zip.path, mimeType: 'application/zip')],
        subject: 'Cadangan Harga Toko',
      ),
    );
    return result.status != ShareResultStatus.dismissed;
  }

  @override
  Future<bool> saveToDownloads(File zip) async {
    if (_isAndroid) {
      try {
        final saved = await _channel.invokeMethod<String>('saveToDownloads', {
          'sourcePath': zip.path,
          'name': p.basename(zip.path),
        });
        return saved != null; // null: Android 9 or older
      } on PlatformException {
        return false;
      } on MissingPluginException {
        return false;
      }
    }
    final dir = await _desktopDownloads();
    if (dir == null) return false;
    await zip.copy(_freeName(dir, p.basename(zip.path)));
    return true;
  }

  @override
  Future<List<SavedBackup>> savedBackups() async {
    try {
      if (_isAndroid) {
        final rows = await _channel.invokeListMethod<Map<Object?, Object?>>(
          'listBackups',
          {'prefix': backupFilePrefix},
        );
        return newestFirst([
          for (final r in rows ?? const <Map<Object?, Object?>>[])
            if ((r['name'] as String).endsWith('.zip'))
              SavedBackup(
                id: r['uri'] as String,
                name: r['name'] as String,
                size: (r['size'] as num).toInt(),
                modified: DateTime.fromMillisecondsSinceEpoch(
                  (r['modified'] as num).toInt(),
                ),
              ),
        ]);
      }
      final dir = await _desktopDownloads();
      if (dir == null || !dir.existsSync()) return const [];
      return newestFirst([
        for (final f in dir.listSync().whereType<File>())
          if (p.basename(f.path).startsWith(backupFilePrefix) &&
              f.path.endsWith('.zip'))
            SavedBackup(
              id: f.path,
              name: p.basename(f.path),
              size: f.lengthSync(),
              modified: f.lastModifiedSync(),
            ),
      ]);
    } on PlatformException {
      return const []; // restore falls back to the file picker
    } on MissingPluginException {
      return const [];
    }
  }

  @override
  Future<File> fetch(SavedBackup backup) async {
    final temp = tempDir ?? await getTemporaryDirectory();
    final dest = Directory(p.join(temp.path, 'restore'));
    await dest.create(recursive: true);
    final file = File(p.join(dest.path, backup.name));
    if (_isAndroid) {
      await _channel.invokeMethod<bool>('copyToFile', {
        'uri': backup.id,
        'destPath': file.path,
      });
      return file;
    }
    return File(backup.id).copy(file.path);
  }

  @override
  Future<File?> pickFile() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    final path = picked?.path;
    return path == null ? null : File(path);
  }

  Future<Directory?> _desktopDownloads() async =>
      downloadsDir ?? await getDownloadsDirectory();

  /// `name`, or `name (1).zip`, `name (2).zip`... so nothing is overwritten.
  String _freeName(Directory dir, String name) {
    var candidate = p.join(dir.path, name);
    for (var i = 1; File(candidate).existsSync(); i++) {
      candidate = p.join(
        dir.path,
        '${p.basenameWithoutExtension(name)} ($i)${p.extension(name)}',
      );
    }
    return candidate;
  }
}
