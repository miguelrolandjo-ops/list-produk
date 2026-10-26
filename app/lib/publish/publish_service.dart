import 'dart:math';

import 'package:drift/drift.dart';

import '../core/server_api.dart';
import '../data/owner_database.dart';

enum PublishOutcome {
  /// No server, nobody signed in, or no store yet. Nothing was attempted.
  notConnected,
  nothingToSend,
  sent,

  /// No signal. The products stay unsent and go out next time.
  offline,

  /// The server refused (this account isn't the store's owner).
  notAllowed,
  failed,
}

class PublishResult {
  const PublishResult(this.outcome, {this.sent = 0, this.error});

  final PublishOutcome outcome;

  /// Products the server accepted, including batches sent before a failure.
  final int sent;
  final ServerException? error;
}

/// Sends changed products to the employee catalog (build guide section 7).
///
/// 1. Read `products_to_publish` and remember each row's `updated_at`.
/// 2. Send them with publish_catalog() in batches of [batchSize].
/// 3. Per accepted batch, set `published_at` to the `updated_at` read in step
///    1, never to "now": a product edited while the batch was on its way stays
///    unsent and goes out next time.
///
/// Only the fields in [allowedFields] are ever put in the payload. Supplier
/// names, supply prices, margins and aliases are not even read.
/// (Product photos: the app has no photo feature yet, so `photo_path` is just
/// `photo_remote_path`, which stays empty until photos are added.)
class PublishService {
  PublishService(this._db, this._api);

  final OwnerDatabase _db;
  final ServerApi? _api;

  static const batchSize = 200;

  static const allowedFields = {
    'id',
    'name',
    'model',
    'category',
    'unit',
    'photo_path',
    'retail_price',
    'is_deleted',
  };

  Future<PublishResult>? _running;

  /// Runs one publish. A call while one is running joins it instead of
  /// sending the same products twice.
  Future<PublishResult> publish() =>
      _running ??= _publish().whenComplete(() => _running = null);

  Future<String?> _storeId() async => (await _db
          .customSelect('SELECT store_id FROM settings WHERE id = 1')
          .getSingle())
      .readNullable<String>('store_id');

  /// The payload for one product: exactly [allowedFields], nothing else.
  static Map<String, Object?> itemFor(QueryRow r) => {
    'id': r.read<String>('id'),
    'name': r.read<String>('name'),
    'model': r.readNullable<String>('model'),
    'category': r.readNullable<String>('category'),
    'unit': r.read<String>('unit'),
    'photo_path': r.readNullable<String>('photo_path'),
    'retail_price': r.readNullable<int>('retail_price'),
    'is_deleted': r.read<int>('is_deleted') != 0,
  };

  Future<PublishResult> _publish() async {
    final api = _api;
    final user = api?.currentUser;
    if (api == null || user == null || user.isAnonymous) {
      return const PublishResult(PublishOutcome.notConnected);
    }
    final store = await _storeId();
    if (store == null) return const PublishResult(PublishOutcome.notConnected);

    final rows = await _db
        .customSelect(
          'SELECT v.id, v.name, v.model, v.category, v.unit, v.photo_path, '
          'v.retail_price, v.is_deleted, p.updated_at AS sent_updated_at '
          'FROM products_to_publish v JOIN products p ON p.id = v.id '
          'ORDER BY p.updated_at, v.id',
        )
        .get();
    if (rows.isEmpty) return const PublishResult(PublishOutcome.nothingToSend);

    var sent = 0;
    try {
      for (var i = 0; i < rows.length; i += batchSize) {
        final batch = rows.sublist(i, min(i + batchSize, rows.length));
        await api.publishCatalog(store, [for (final r in batch) itemFor(r)]);
        await _db.transaction(() async {
          for (final r in batch) {
            await _db.customUpdate(
              'UPDATE products SET published_at = ? WHERE id = ?',
              variables: [
                Variable.withString(r.read<String>('sent_updated_at')),
                Variable.withString(r.read<String>('id')),
              ],
              updates: {_db.products},
            );
          }
        });
        sent += batch.length;
      }
    } on ServerException catch (e) {
      final outcome = switch (e.kind) {
        ServerErrorKind.offline => PublishOutcome.offline,
        ServerErrorKind.notAllowed => PublishOutcome.notAllowed,
        _ => PublishOutcome.failed,
      };
      return PublishResult(outcome, sent: sent, error: e);
    }
    return PublishResult(PublishOutcome.sent, sent: sent);
  }
}
