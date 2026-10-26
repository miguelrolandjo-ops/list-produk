import 'package:flutter/services.dart';

/// Photos shared to the app (WhatsApp, Gallery, Files...). The Android side is
/// our own code in MainActivity.kt, not a plugin: it receives the share,
/// shrinks each photo to about 1600 px and keeps the files until Dart takes
/// them. Only the owner's phone takes them.
class ShareIntake {
  ShareIntake({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'harga_toko/share';
  final MethodChannel _channel;

  /// [onAvailable] is called when photos were shared while the app runs.
  void listen(void Function() onAvailable) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'sharedAvailable') onAvailable();
    });
  }

  /// Shared photos waiting (file paths, in the order shared). Each call
  /// returns them once. Empty on platforms without the native side.
  Future<List<String>> take() async {
    try {
      return await _channel.invokeListMethod<String>('takeShared') ?? const [];
    } on MissingPluginException {
      return const [];
    }
  }
}
