import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter/widgets.dart';

import '../data/owner_database.dart';
import 'publish_service.dart';

/// Publishes on its own, so the owner never has to think about it: a few
/// seconds after any product or category change, when the app comes back to
/// the foreground, and after signing in. Without signal it tries again every
/// [retryAfter]; nothing is lost meanwhile, the products just stay unsent.
class AutoPublisher with WidgetsBindingObserver {
  AutoPublisher(
    this._db,
    this._service, {
    this.debounce = const Duration(seconds: 3),
    this.retryAfter = const Duration(minutes: 2),
  });

  final OwnerDatabase _db;
  final PublishService _service;
  final Duration debounce;
  final Duration retryAfter;

  StreamSubscription<void>? _changes;
  Timer? _timer;
  Timer? _retry;
  bool _disposed = false;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _changes = _db
        .tableUpdates(
          TableUpdateQuery.onAllTables([
            _db.products,
            _db.categories,
            _db.settings,
          ]),
        )
        .listen((_) => _schedule(debounce));
    _schedule(Duration.zero);
  }

  /// Publish soon (after signing in, or "Kirim sekarang").
  void kick() => _schedule(Duration.zero);

  void _schedule(Duration after) {
    if (_disposed) return;
    _timer?.cancel();
    _timer = Timer(after, _run);
  }

  Future<void> _run() async {
    if (_disposed) return;
    final result = await _service.publish();
    _retry?.cancel();
    if (!_disposed &&
        (result.outcome == PublishOutcome.offline ||
            result.outcome == PublishOutcome.failed)) {
      _retry = Timer(retryAfter, _run);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _schedule(Duration.zero);
  }

  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _changes?.cancel();
    _timer?.cancel();
    _retry?.cancel();
  }
}
