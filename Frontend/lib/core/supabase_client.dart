/// Supabase client initialization and access helpers.
///
/// Uses `--dart-define` environment variables for URL and anon key,
/// ensuring secrets are never hard-coded.
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientHelper {
  SupabaseClientHelper._();

  /// Initialize Supabase. Call once in `main()`.
  static Future<void> initialize() async {
    const supabaseUrl = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: '',
    );
    const supabaseAnonKey = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: '',
    );

    assert(
      supabaseUrl.isNotEmpty,
      'SUPABASE_URL must be provided via --dart-define',
    );
    assert(
      supabaseAnonKey.isNotEmpty,
      'SUPABASE_ANON_KEY must be provided via --dart-define',
    );

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  /// Shortcut to the Supabase client instance.
  static SupabaseClient get client => Supabase.instance.client;

  /// Shortcut to the Auth client.
  static GoTrueClient get auth => client.auth;
}
