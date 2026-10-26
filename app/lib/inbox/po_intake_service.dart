import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../data/owner_database.dart';

/// Where a PO came from (purchase_orders.source).
enum PoSource { camera, gallery, share }

/// Step 1 of build guide section 9: a new PO ('queued') with its pages copied
/// into the app's own folder. The images are already shrunk to about 1600 px
/// on the long side (image_picker does it for camera and gallery, the share
/// handler in MainActivity.kt for shared photos). Nothing here needs signal.
class PoIntakeService {
  PoIntakeService(
    this._db,
    this._baseDir, {
    Uuid uuid = const Uuid(),
  }) : _uuid = uuid;

  final OwnerDatabase _db;

  /// The app documents folder (a function so it's only looked up when used).
  final Future<Directory> Function() _baseDir;
  final Uuid _uuid;

  /// Creates the PO from [images] in page order and returns its id. The
  /// source files are left alone; shared ones live in the cache anyway.
  Future<String> create(List<String> images, PoSource source) async {
    if (images.isEmpty) throw ArgumentError('Tidak ada foto');
    final id = _uuid.v4();
    final dir = Directory(p.join((await _baseDir()).path, 'po_pages', id));
    await dir.create(recursive: true);

    final pages = <String>[];
    try {
      for (var i = 0; i < images.length; i++) {
        final dest = p.join(dir.path, '${i + 1}.jpg');
        await File(images[i]).copy(dest);
        pages.add(dest);
      }
      await _db.transaction(() async {
        await _db.customInsert(
          "INSERT INTO purchase_orders (id, status, source) VALUES (?, 'queued', ?)",
          variables: [Variable.withString(id), Variable.withString(source.name)],
          updates: {_db.purchaseOrders},
        );
        for (var i = 0; i < pages.length; i++) {
          await _db.customInsert(
            'INSERT INTO po_pages (id, po_id, page_no, local_path) '
            'VALUES (?, ?, ?, ?)',
            variables: [
              Variable.withString(_uuid.v4()),
              Variable.withString(id),
              Variable.withInt(i + 1),
              Variable.withString(pages[i]),
            ],
            updates: {_db.poPages},
          );
        }
      });
    } catch (_) {
      // No half PO: remove the copies if anything failed.
      if (await dir.exists()) await dir.delete(recursive: true);
      rethrow;
    }
    return id;
  }

  /// Deletes a PO that isn't saved, with its photos on this phone. A job
  /// already on the server is left to the server's 14-day cleanup.
  Future<void> delete(String poId) async {
    final pages = await _db
        .customSelect(
          'SELECT local_path FROM po_pages WHERE po_id = ?',
          variables: [Variable.withString(poId)],
        )
        .get();
    // The database doesn't enforce foreign keys, so the PO's pages and lines
    // are deleted explicitly, in one transaction.
    final deleted = await _db.transaction(() async {
      final n = await _db.customUpdate(
        "DELETE FROM purchase_orders WHERE id = ? "
        "AND status NOT IN ('saved', 'uploading')",
        variables: [Variable.withString(poId)],
        updates: {_db.purchaseOrders},
        updateKind: UpdateKind.delete,
      );
      if (n == 0) return 0;
      for (final table in ['po_lines', 'po_pages']) {
        await _db.customUpdate(
          'DELETE FROM $table WHERE po_id = ?',
          variables: [Variable.withString(poId)],
          updates: {table == 'po_lines' ? _db.poLines : _db.poPages},
          updateKind: UpdateKind.delete,
        );
      }
      return n;
    });
    if (deleted == 0) throw StateError('PO ini tidak bisa dihapus');
    for (final r in pages) {
      final f = File(r.read<String>('local_path'));
      if (await f.exists()) await f.delete();
    }
    final dir = Directory(p.join((await _baseDir()).path, 'po_pages', poId));
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}
