/// Baratito — App entry point.
///
/// Initializes Supabase, sets up Riverpod and GoRouter,
/// wraps with ChangeNotifierProvider for ThemeModel,
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
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;
import 'package:provider/provider.dart';
import 'core/supabase_client.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
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
      statusBarColor: const Color.fromRGBO(0, 0, 0, 0), // Transparent, without using Colors.transparent
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Supabase
  await SupabaseClientHelper.initialize();

  // Initialize Dio client for network requests
  DioClient.instance.initialize();

  runApp(
    // ChangeNotifierProvider at the root — above ProviderScope and MaterialApp
    ChangeNotifierProvider(
      create: (_) => ThemeModel(),
      child: const ProviderScope(
        child: BaratitoApp(),
      ),
    ),
  );
}

class BaratitoApp extends ConsumerWidget {
  const BaratitoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // context.watch to rebuild when theme changes
    final themeModel = context.watch<ThemeModel>();

    return MaterialApp.router(
      title: 'Baratito',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeModel.themeMode,
      routerConfig: router,
    );
  }
}
