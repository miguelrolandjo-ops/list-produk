import 'package:flutter/services.dart';

import '../catalog/join_service.dart';

/// Invite links for "Gabung sebagai karyawan".
///
/// The owner shares a message with both a link and the 8-character code:
///
///   https://<host>/j/?kode=7KQ2M9XA
///
/// Tapping the link opens the app (when Android has verified the site) on the
/// join screen with the code filled in. Otherwise it opens the landing page
/// (invite-site/j/index.html), whose "Buka aplikasi" button uses
/// hargatoko://join?kode=7KQ2M9XA. Typing the code by hand always works too.
///
/// The parameter is "kode", not "code": Supabase reads a "code" parameter on
/// incoming links as a login callback.
abstract final class InviteLink {
  /// The link for [code], or null when no INVITE_LINK_BASE is configured.
  static String? forCode(String code, {required String base}) {
    final b = base.trim();
    if (b.isEmpty) return null;
    final uri = Uri.parse(b.endsWith('/') ? b : '$b/');
    return uri
        .replace(
          queryParameters: {
            ...uri.queryParameters,
            'kode': JoinService.normalizeCode(code),
          },
        )
        .toString();
  }

  /// The invite code in [link], or null when it isn't an invite link or the
  /// code isn't 8 characters. Accepts the https link (…/j/?kode=, …/j?kode=,
  /// …/j/KODE) and hargatoko://join?kode=… .
  static String? codeFrom(String link) {
    final uri = Uri.tryParse(link.trim());
    if (uri == null) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    final isApp = uri.scheme == 'hargatoko' && uri.host == 'join';
    final isWeb =
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        segments.isNotEmpty &&
        segments.first == 'j';
    if (!isApp && !isWeb) return null;

    final raw =
        uri.queryParameters['kode'] ??
        (isWeb && segments.length > 1 ? segments[1] : null) ??
        (isApp && segments.isNotEmpty ? segments.first : null);
    if (raw == null || !JoinService.isValidCode(raw)) return null;
    return JoinService.normalizeCode(raw);
  }
}

/// Invite links handed over by MainActivity.kt (our own code, no plugin).
class InviteLinkIntake {
  InviteLinkIntake({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'harga_toko/invite';
  final MethodChannel _channel;

  /// [onAvailable] runs when a link was opened while the app runs.
  void listen(void Function() onAvailable) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'inviteAvailable') onAvailable();
    });
  }

  /// The link that opened the app, once; null if none.
  Future<String?> take() async {
    try {
      return await _channel.invokeMethod<String>('takeInvite');
    } on MissingPluginException {
      return null;
    }
  }
}
