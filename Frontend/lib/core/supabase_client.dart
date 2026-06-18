/// Supabase client initialization and access helpers.
///
/// Uses `--dart-define` environment variables for URL and anon key,
/// ensuring secrets are never hard-coded.
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart' show rootBundle;

class SupabaseClientHelper {
  SupabaseClientHelper._();

  /// Initialize Supabase. Call once in `main()`.
  static Future<void> initialize() async {
    // Try loading a local .env file for development. If it does not exist
    // we silently continue — production should provide values via
    // `--dart-define`.
    var envMap = <String, String>{};

    try {
      await dotenv.load(fileName: '.env');
      envMap = Map<String, String>.from(dotenv.env);
    } catch (e) {
      // ignore: avoid_print
      print('No .env file found or failed to load via filesystem: $e');

      // Try loading the .env bundled as an asset (useful for mobile dev builds).
      try {
        final contents = await rootBundle.loadString('assets/.env');
        // Parse simple KEY=VALUE lines into a map.
        final lines = contents.split(RegExp(r"\r?\n"));
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
          final idx = trimmed.indexOf('=');
          if (idx <= 0) continue;
          final key = trimmed.substring(0, idx).trim();
          final value = trimmed.substring(idx + 1).trim();
          envMap[key] = value;
        }
        // ignore: avoid_print
        print('Loaded .env from assets (parsed ${envMap.length} entries).');
      } catch (e2) {
        // ignore: avoid_print
        print('Failed to load .env from assets: $e2');
      }
    }

    final supabaseUrlFromDefine =
        const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    final supabaseAnonFromDefine =
        const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

    final supabaseUrl = supabaseUrlFromDefine.isNotEmpty
        ? supabaseUrlFromDefine
        : (envMap['SUPABASE_URL'] ?? '');
    final supabaseAnonKey = supabaseAnonFromDefine.isNotEmpty
        ? supabaseAnonFromDefine
        : (envMap['SUPABASE_ANON_KEY'] ?? '');

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception(
          'SUPABASE_URL and SUPABASE_ANON_KEY are required. Provide them via --dart-define or a .env file.');
    }

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
