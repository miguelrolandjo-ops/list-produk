import 'dart:async';

import 'package:flutter/widgets.dart';

import 'po_sync_service.dart';

/// Moves POs along without the owner doing anything: right after a photo is
/// added, when the app comes back to the foreground, and after signing in.
/// While the server is reading a PO it asks every [pollEvery]; without signal
/// it tries again every [retryEvery]. Nothing runs while the app is in the
/// background.
class InboxRunner with WidgetsBindingObserver {
  InboxRunner(
    this._sync, {
    this.pollEvery = const Duration(seconds: 5),
    this.retryEvery = const Duration(seconds: 30),
  });

  final PoSyncService _sync;
  final Duration pollEvery;
  final Duration retryEvery;

  Timer? _timer;
  bool _foreground = true;
  bool _disposed = false;

  /// Called with the result of every run (the Inbox shows a snackbar when a
  /// PO is ready for review).
  void Function(PoSyncResult)? onResult;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    kick();
  }

  /// Run now (new photos, "Coba lagi", signed in, pull to refresh).
  Future<PoSyncResult?> kick() async {
    _timer?.cancel();
    if (_disposed) return null;
    final result = await _sync.run();
    if (_disposed) return result;
    onResult?.call(result);
    _scheduleAfter(result);
    return result;
  }

  void _scheduleAfter(PoSyncResult r) {
    _timer?.cancel();
    if (!_foreground) return;
    final Duration? next;
    if (r.outcome == PoSyncOutcome.offline) {
      next = retryEvery;
    } else if (r.outcome == PoSyncOutcome.done && r.processing > 0) {
      next = pollEvery;
    } else if (r.outcome == PoSyncOutcome.done && r.queued > 0) {
      next = retryEvery; // an upload failed for another reason
    } else {
      next = null; // nothing to do, or not connected (signing in kicks)
    }
    if (next != null) _timer = Timer(next, kick);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      kick();
    } else {
      _timer?.cancel();
    }
  }

  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
  }
}
