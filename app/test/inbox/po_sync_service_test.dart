import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_application_1/data/owner_database.dart';
import 'package:flutter_application_1/inbox/debug_sample.dart';
import 'package:flutter_application_1/inbox/po_import_service.dart';
import 'package:flutter_application_1/inbox/po_intake_service.dart';
import 'package:flutter_application_1/inbox/po_sync_service.dart';
import 'package:flutter_application_1/team/owner_account_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../support/fake_server_api.dart';

void main() {
  late OwnerDatabase db;
  late Directory tmp;
  late PoIntakeService intake;
  late FakeServerApi api;
  late PoSyncService sync;
  late String store;

  setUp(() async {
    db = OwnerDatabase(NativeDatabase.memory());
    tmp = await Directory.systemTemp.createTemp('po_test');
    intake = PoIntakeService(db, () async => tmp);
    api = FakeServerApi();
    sync = PoSyncService(db, api, PoImportService(db));
    await api.signUp('budi@email.com', 'rahasia123');
    await OwnerAccountService(db, api).createStore('Toko Berkah');
    store = api.stores.keys.single;
  });
  tearDown(() async {
    await db.close();
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  /// Photos as image_picker or the share handler would hand them over.
  Future<List<String>> photos(int n) async => [
    for (var i = 1; i <= n; i++)
      (await File(p.join(tmp.path, 'src_$i.jpg')).writeAsBytes([0xFF, 0xD8, i])).path,
  ];

  Future<Map<String, Object?>> po(String id) async {
    final r = await db
        .customSelect(
          'SELECT status, server_job_id FROM purchase_orders WHERE id = ?',
          variables: [Variable.withString(id)],
        )
        .getSingle();
    return {'status': r.read<String>('status'), 'job': r.readNullable<String>('server_job_id')};
  }

  test('intake: a queued PO with its pages copied in order', () async {
    final id = await intake.create(await photos(2), PoSource.share);
    expect((await po(id))['status'], 'queued');
    final pages = await db
        .customSelect(
          'SELECT page_no, local_path FROM po_pages WHERE po_id = ? ORDER BY page_no',
          variables: [Variable.withString(id)],
        )
        .get();
    expect(pages.map((r) => r.read<int>('page_no')), [1, 2]);
    final second = File(pages[1].read<String>('local_path'));
    expect(second.path, endsWith(p.join('po_pages', id, '2.jpg')));
    expect(await second.readAsBytes(), [0xFF, 0xD8, 2]);
  });

  test('upload: pages go to {store}/{po}/{n}.jpg and the job is submitted', () async {
    final id = await intake.create(await photos(2), PoSource.camera);
    final r = await sync.run();

    expect(r.outcome, PoSyncOutcome.done);
    expect(r.processing, 1);
    expect(api.uploads.keys, ['$store/$id/1.jpg', '$store/$id/2.jpg']);
    final state = await po(id);
    expect(state['status'], 'processing');
    expect(api.jobPaths[state['job']], ['$store/$id/1.jpg', '$store/$id/2.jpg']);
  });

  test('done: result imported for review, then marked fetched', () async {
    final id = await intake.create(await photos(1), PoSource.gallery);
    await sync.run();
    final job = (await po(id))['job'] as String;

    // Still being read: nothing changes.
    await sync.run();
    expect((await po(id))['status'], 'processing');

    api.finishJob(job, result: Map<String, dynamic>.from(debugSampleExtraction));
    final r = await sync.run();
    expect(r.readyForReview, 1);
    expect((await po(id))['status'], 'needs_review');
    expect(api.fetched, {job});
    final lines = await db
        .customSelect(
          'SELECT COUNT(*) AS n FROM po_lines WHERE po_id = ?',
          variables: [Variable.withString(id)],
        )
        .getSingle();
    expect(lines.read<int>('n'), 5);
  });

  test('failed on the server: Gagal, fetched, and Coba lagi reads it again', () async {
    final id = await intake.create(await photos(1), PoSource.camera);
    await sync.run();
    final job = (await po(id))['job'] as String;
    api.finishJob(job, error: 'model busy');
    await sync.run();
    expect((await po(id))['status'], 'failed');
    expect(api.fetched, {job});

    await sync.retry(id);
    expect(await po(id), {'status': 'queued', 'job': null});
    await sync.run();
    final again = await po(id);
    expect(again['status'], 'processing');
    expect(again['job'], isNot(job));
  });

  test('a result the phone cannot use is Gagal, not a broken review', () async {
    final id = await intake.create(await photos(1), PoSource.camera);
    await sync.run();
    final job = (await po(id))['job'] as String;
    api.finishJob(job, result: {'lines': 'not a list'});
    await sync.run();
    expect((await po(id))['status'], 'failed');
    expect(api.fetched, {job});
  });

  test('signal lost mid-upload: back to the queue, finished on the next run', () async {
    final id = await intake.create(await photos(3), PoSource.share);
    api.goOfflineAfterUploads = 1;
    final r = await sync.run();
    expect(r.outcome, PoSyncOutcome.offline);
    expect(await po(id), {'status': 'queued', 'job': null});
    expect(sync.uploadProgress.value, isEmpty);

    api.goOfflineAfterUploads = null;
    api.offline = false;
    await sync.run();
    expect((await po(id))['status'], 'processing');
    expect(api.uploads.length, 3);
  });

  test('not connected: photos wait in the queue', () async {
    await api.signOut();
    final id = await intake.create(await photos(1), PoSource.camera);
    final r = await sync.run();
    expect(r.outcome, PoSyncOutcome.notConnected);
    expect(r.queued, 1);
    expect((await po(id))['status'], 'queued');
    expect(api.uploads, isEmpty);

    final none = PoSyncService(db, null, PoImportService(db));
    expect((await none.run()).outcome, PoSyncOutcome.notConnected);
  });

  test('a photo missing from the phone makes the PO fail, not loop', () async {
    final id = await intake.create(await photos(1), PoSource.camera);
    final page = (await db.customSelect('SELECT local_path FROM po_pages').getSingle())
        .read<String>('local_path');
    await File(page).delete();
    await sync.run();
    expect((await po(id))['status'], 'failed');
  });

  test('a job the server no longer has is read again', () async {
    final id = await intake.create(await photos(1), PoSource.camera);
    await sync.run();
    api.jobs.clear();
    await sync.run();
    // Re-queued and, in the same run's next pass or the next run, uploaded.
    expect((await po(id))['status'], anyOf('queued', 'processing'));
  });

  test('delete removes the PO and its photos, but never a saved PO', () async {
    final id = await intake.create(await photos(2), PoSource.camera);
    await intake.delete(id);
    expect(
      await db.customSelect('SELECT * FROM purchase_orders').get(),
      isEmpty,
    );
    // Foreign keys are not enforced here, so the pages must go explicitly.
    expect(await db.customSelect('SELECT * FROM po_pages').get(), isEmpty);
    expect(await Directory(p.join(tmp.path, 'po_pages', id)).exists(), isFalse);

    final saved = await intake.create(await photos(1), PoSource.camera);
    await db.customStatement(
      "UPDATE purchase_orders SET status = 'saved' WHERE id = '$saved'",
    );
    await expectLater(intake.delete(saved), throwsStateError);
  });
}
