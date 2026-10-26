/// Where the Supabase project lives. Both values come from the build, never
/// from the code: `flutter run --dart-define-from-file=config.json` (see
/// `config.example.json`).
///
/// Only the anon (publishable) key may ever be passed here. The service role
/// (secret) key belongs to the Go worker and must never be in the app.
class ServerConfig {
  const ServerConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Without both values the app runs fully offline: the owner works alone and
  /// the online screens say the server isn't set up.
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
