import 'dart:io';

import 'package:downloadsfolder/downloadsfolder.dart'
    show copyFileIntoDownloadFolder;
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

/// What the owner picks in "Cadangkan sekarang".
enum BackupDestination { drive, local }

/// Where a finished backup zip goes. Behind an interface so the screen can be
/// tested without the platform.
abstract class BackupExporter {
  /// Opens the system share sheet (Google Drive is one of its targets).
  /// Returns false if the owner closed the sheet without choosing anything.
  Future<bool> shareFile(File zip);

  /// Copies the zip into the phone's public Download folder, without asking
  /// where. Returns true if it was saved.
  Future<bool> saveToDownloads(File zip);
}

/// The real thing.
///
/// Download folder: `downloadsfolder` writes through MediaStore on Android 10+
/// (no permission, no folder prompt) and picks a free file name instead of
/// overwriting. Android 9 and older need WRITE_EXTERNAL_STORAGE, declared in
/// the manifest.
///
/// Google Drive: the share sheet. The real Drive API needs a Google Cloud
/// project and sign-in, which is more than a backup file warrants.
class PlatformBackupExporter implements BackupExporter {
  const PlatformBackupExporter();

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
    final saved = await copyFileIntoDownloadFolder(
      zip.path,
      p.basename(zip.path),
    );
    return saved == true;
  }
}
