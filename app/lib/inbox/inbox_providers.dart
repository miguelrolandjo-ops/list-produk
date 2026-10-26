import 'dart:convert';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../core/providers.dart';
import '../core/server_providers.dart';
import 'inbox_runner.dart';
import 'po_intake_service.dart';
import 'po_sync_service.dart';

final poIntakeServiceProvider = Provider<PoIntakeService>(
  (ref) => PoIntakeService(
    ref.watch(ownerDbProvider),
    getApplicationDocumentsDirectory,
  ),
);

final poSyncServiceProvider = Provider<PoSyncService>(
  (ref) => PoSyncService(
    ref.watch(ownerDbProvider),
    ref.watch(serverApiProvider),
    ref.watch(poImportServiceProvider),
  ),
);

/// Runs while the owner side of the app runs (watched in App).
final inboxRunnerProvider = Provider<InboxRunner>((ref) {
  final runner = InboxRunner(ref.watch(poSyncServiceProvider))..start();
  ref.listen(serverUserProvider, (_, _) => runner.kick());
  ref.listen(ownerStoreIdProvider, (_, _) => runner.kick());
  ref.onDispose(runner.dispose);
  return runner;
});

/// One PO in the Inbox list.
class InboxItem {
  const InboxItem({
    required this.id,
    required this.status,
    required this.source,
    required this.createdAt,
    required this.pages,
    this.supplierName,
    this.firstPage,
    this.lineCount = 0,
  });

  final String id;

  /// queued, uploading, processing, needs_review, saved, failed.
  final String status;

  /// camera, gallery, share, whatsapp.
  final String source;
  final DateTime createdAt;
  final int pages;

  /// The known supplier, else the name printed on the PO (if read).
  final String? supplierName;

  /// The first photo on this phone, for the thumbnail.
  final String? firstPage;
  final int lineCount;
}

/// Newest first. Updates whenever a PO changes.
final inboxItemsProvider = StreamProvider<List<InboxItem>>((ref) async* {
  final db = ref.watch(ownerDbProvider);

  Future<List<InboxItem>> load() async {
    final rows = await db
        .customSelect(
          'SELECT po.id, po.status, po.source, po.created_at, po.raw_result, '
          's.name AS supplier, '
          '(SELECT COUNT(*) FROM po_pages pg WHERE pg.po_id = po.id) AS pages, '
          '(SELECT local_path FROM po_pages pg WHERE pg.po_id = po.id '
          ' ORDER BY page_no LIMIT 1) AS first_page, '
          "(SELECT COUNT(*) FROM po_lines l WHERE l.po_id = po.id "
          " AND l.match_status != 'ignored') AS lines "
          'FROM purchase_orders po '
          'LEFT JOIN suppliers s ON s.id = po.supplier_id '
          'ORDER BY po.created_at DESC',
        )
        .get();
    return [
      for (final r in rows)
        InboxItem(
          id: r.read<String>('id'),
          status: r.read<String>('status'),
          source: r.read<String>('source'),
          createdAt:
              DateTime.tryParse(r.read<String>('created_at'))?.toLocal() ??
              DateTime.now(),
          pages: r.read<int>('pages'),
          supplierName:
              r.readNullable<String>('supplier') ??
              _printedSupplier(r.readNullable<String>('raw_result')),
          firstPage: r.readNullable<String>('first_page'),
          lineCount: r.read<int>('lines'),
        ),
    ];
  }

  yield await load();
  final changes = db.tableUpdates(
    TableUpdateQuery.onAllTables([
      db.purchaseOrders,
      db.poPages,
      db.poLines,
      db.suppliers,
    ]),
  );
  await for (final _ in changes) {
    yield await load();
  }
});

String? _printedSupplier(String? raw) {
  if (raw == null) return null;
  try {
    final name = (jsonDecode(raw) as Map)['supplier']?['name'];
    return name is String && name.trim().isNotEmpty ? name.trim() : null;
  } on Object {
    return null;
  }
}

/// "Perlu dicek": the badge on the Inbox tab.
final needsReviewCountProvider = Provider<int>(
  (ref) =>
      (ref.watch(inboxItemsProvider).value ?? const [])
          .where((i) => i.status == 'needs_review')
          .length,
);
