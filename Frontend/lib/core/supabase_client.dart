/// Supabase client initialization and access helpers.
///
/// Uses `--dart-define` environment variables for URL and anon key,
/// ensuring secrets are never hard-coded.
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientHelper {
  SupabaseClientHelper._();

  /// Initialize Supabase. Call once in `main()`.
  static Future<void> initialize() async {
    final supabaseUrl = const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://ddygpqkuxgfrjdipdvek.supabase.co',
    );
    final supabaseAnonKey = const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRkeWdwcWt1eGdmcmpkaXBkdmVrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzMjUwNjEsImV4cCI6MjA5NDkwMTA2MX0.63PViWP91iqrC2r4r6WX-SMcVehwRE-2IbZvwkNOVzY',
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
