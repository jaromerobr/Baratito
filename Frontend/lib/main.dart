/// Baratito — App entry point.
///
/// Initializes Supabase, sets up Riverpod and GoRouter,
/// applies the Baratito theme.
///
/// Run with:
/// ```
/// flutter run \
///   --dart-define=SUPABASE_URL=https://ddygpqkuxgfrjdipdvek.supabase.co\
///   --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRkeWdwcWt1eGdmcmpkaXBkdmVrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzMjUwNjEsImV4cCI6MjA5NDkwMTA2MX0.63PViWP91iqrC2r4r6WX-SMcVehwRE-2IbZvwkNOVzY
/// ```
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/supabase_client.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';
import 'core/network/dio_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Supabase (guarded so missing dart-defines don't crash the app)
  var supabaseReady = false;
  try {
    await SupabaseClientHelper.initialize();
    supabaseReady = true;
  } catch (e, st) {
    // Keep app alive and show a friendly error UI below. Also log for debugging.
    // In most cases you should run the app with the --dart-define flags
    // shown in the file header comment.
    // Example:
    // flutter run \
    //   --dart-define=SUPABASE_URL=https://your.supabase.co \
    //   --dart-define=SUPABASE_ANON_KEY=your_anon_key
    //
    // We intentionally do not rethrow so the developer sees a clear message
    // in the emulator instead of a blank/white screen.
    // ignore: avoid_print
    print('Supabase initialization failed: $e');
  }

  // Initialize Dio client for network requests
  DioClient.instance.initialize();

  if (!supabaseReady) {
    runApp(
      ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            appBar: AppBar(title: const Text('Baratito - Error')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'No se pudo inicializar Supabase.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Ejecuta la app con las variables de entorno necesarias:\n--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  runApp(
    ProviderScope(
      child: BaratitoApp(),
    ),
  );
}

class BaratitoApp extends ConsumerWidget {
  const BaratitoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Baratito',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
