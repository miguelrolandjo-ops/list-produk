import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;

import '../core/server_api.dart';
import '../data/owner_database.dart';
import 'po_import_service.dart';

enum PoSyncOutcome {
  /// No server, nobody signed in as owner, or no store: POs stay queued.
  notConnected,
  done,

  /// Signal lost: queued POs wait, nothing is lost.
  offline,
}

class PoSyncResult {
  const PoSyncResult(
    this.outcome, {
    this.processing = 0,
    this.queued = 0,
    this.readyForReview = 0,
  });

  final PoSyncOutcome outcome;

  /// POs the server is still reading (poll again soon).
  final int processing;

  /// POs still waiting to upload.
  final int queued;

  /// POs that became "Perlu dicek" in this run.
  final int readyForReview;
}

/// Steps 2 to 5 of build guide section 9, for every PO that needs it:
///
/// 2. upload the pages to po-images/{store_id}/{po_id}/{n}.jpg ('uploading')
/// 3. submit_extraction, save the job id ('processing')
/// 4. poll the job
/// 5. when done: import the result (matching runs on the phone, the PO becomes
///    'needs_review'), then mark_extraction_fetched so the server deletes it.
///
/// Safe to call any time; without signal POs simply stay where they are.
class PoSyncService {
  PoSyncService(this._db, this._api, this._importer);

  final OwnerDatabase _db;
  final ServerApi? _api;
  final PoImportService _importer;

  /// Pages uploaded so far per PO, for "1 dari 2 halaman".
  final uploadProgress = ValueNotifier<Map<String, int>>(const {});

  Future<PoSyncResult>? _running;

  Future<PoSyncResult> run() =>
      _running ??= _run().whenComplete(() => _running = null);

  Future<String?> _storeId() async => (await _db
          .customSelect('SELECT store_id FROM settings WHERE id = 1')
          .getSingle())
      .readNullable<String>('store_id');

  Future<PoSyncResult> _run() async {
    final api = _api;
    final user = api?.currentUser;
    final store = await _storeId();
    if (api == null || user == null || user.isAnonymous || store == null) {
      return PoSyncResult(
        PoSyncOutcome.notConnected,
        queued: await _count("status IN ('queued', 'uploading')"),
      );
    }

    var outcome = PoSyncOutcome.done;
    try {
      final waiting = await _db
          .customSelect(
            "SELECT id FROM purchase_orders WHERE status IN ('queued', 'uploading') "
            'AND server_job_id IS NULL ORDER BY created_at',
          )
          .get();
      for (final r in waiting) {
        await _upload(api, store, r.read<String>('id'));
      }
    } on ServerException catch (e) {
      // No signal: stop here, everything waits for the next run. Refused
      // (not this store's owner): uploads stop, already running jobs are
      // still checked below.
      if (e.kind == ServerErrorKind.offline) {
        return PoSyncResult(
          PoSyncOutcome.offline,
          processing: await _count("status = 'processing'"),
          queued: await _count("status IN ('queued', 'uploading')"),
        );
      }
    }

    var ready = 0;
    try {
      final processing = await _db
          .customSelect(
            "SELECT id, server_job_id FROM purchase_orders "
            "WHERE status = 'processing' AND server_job_id IS NOT NULL "
            'ORDER BY created_at',
          )
          .get();
      for (final r in processing) {
        if (await _poll(
          api,
          r.read<String>('id'),
          r.read<String>('server_job_id'),
        )) {
          ready++;
        }
      }
    } on ServerException catch (e) {
      if (e.kind == ServerErrorKind.offline) outcome = PoSyncOutcome.offline;
    }

    return PoSyncResult(
      outcome,
      processing: await _count("status = 'processing'"),
      queued: await _count("status IN ('queued', 'uploading')"),
      readyForReview: ready,
    );
  }

  Future<int> _count(String where) async => (await _db
          .customSelect('SELECT COUNT(*) AS n FROM purchase_orders WHERE $where')
          .getSingle())
      .read<int>('n');

  Future<void> _setStatus(String poId, String status, {String? jobId}) =>
      _db.customUpdate(
        'UPDATE purchase_orders SET status = ?, '
        'server_job_id = COALESCE(?, server_job_id) WHERE id = ?',
        variables: [
          Variable.withString(status),
          Variable<String>(jobId),
          Variable.withString(poId),
        ],
        updates: {_db.purchaseOrders},
      );

  void _progress(String poId, int? pages) {
    final m = Map<String, int>.of(uploadProgress.value);
    if (pages == null) {
      m.remove(poId);
    } else {
      m[poId] = pages;
    }
    uploadProgress.value = m;
  }

  /// Uploads one PO and submits it. Throws [ServerException] for offline and
  /// refused, after putting the PO back in the queue.
  Future<void> _upload(ServerApi api, String store, String poId) async {
    final pages = await _db
        .customSelect(
          'SELECT page_no, local_path FROM po_pages WHERE po_id = ? ORDER BY page_no',
          variables: [Variable.withString(poId)],
        )
        .get();
    if (pages.isEmpty) {
      await _setStatus(poId, 'failed');
      return;
    }
    await _setStatus(poId, 'uploading');
    _progress(poId, 0);
    try {
      final paths = <String>[];
      for (final page in pages) {
        final file = File(page.read<String>('local_path'));
        if (!await file.exists()) {
          // The photo is gone from the phone: nothing to upload, ever.
          await _setStatus(poId, 'failed');
          return;
        }
        final remote = '$store/$poId/${page.read<int>('page_no')}.jpg';
        await api.uploadPoPage(remote, await file.readAsBytes());
        paths.add(remote);
        _progress(poId, paths.length);
      }
      final job = await api.submitExtraction(store, paths);
      await _setStatus(poId, 'processing', jobId: job);
    } on ServerException catch (e) {
      // Back to the queue; pages already uploaded are simply uploaded again
      // (upsert), so there is no half state to clean up.
      await _setStatus(poId, 'queued');
      if (e.kind == ServerErrorKind.offline ||
          e.kind == ServerErrorKind.notAllowed) {
        rethrow;
      }
    } finally {
      _progress(poId, null);
    }
  }

  /// Checks one job. Returns true when the PO became ready for review.
  Future<bool> _poll(ServerApi api, String poId, String jobId) async {
    final job = await api.extractionJob(jobId);
    if (job == null) {
      // The server deleted it (more than 14 days old): read it again.
      await _db.customUpdate(
        "UPDATE purchase_orders SET status = 'queued', server_job_id = NULL "
        'WHERE id = ?',
        variables: [Variable.withString(poId)],
        updates: {_db.purchaseOrders},
      );
      return false;
    }
    switch (job.status) {
      case 'done':
        var ok = true;
        try {
          await _importer.importResult(poId, jsonEncode(job.result));
        } on Object {
          // A result the phone can't use (FormatException) or a PO that
          // changed meanwhile: show it as failed so it can be read again.
          ok = false;
          await _setStatus(poId, 'failed');
        }
        await _markFetched(api, jobId);
        return ok;
      case 'failed':
        await _setStatus(poId, 'failed');
        await _markFetched(api, jobId);
        return false;
      default:
        return false; // pending or running: ask again later
    }
  }

  /// The result is on the phone now. If this call is lost, the server deletes
  /// the job after 14 days anyway.
  Future<void> _markFetched(ServerApi api, String jobId) async {
    try {
      await api.markExtractionFetched(jobId);
    } on ServerException {
      // Ignore: see above.
    }
  }

  /// "Coba lagi" on a failed PO: upload and read it again.
  Future<void> retry(String poId) => _db.customUpdate(
    "UPDATE purchase_orders SET status = 'queued', server_job_id = NULL "
    "WHERE id = ? AND status = 'failed'",
    variables: [Variable.withString(poId)],
    updates: {_db.purchaseOrders},
  );
}
