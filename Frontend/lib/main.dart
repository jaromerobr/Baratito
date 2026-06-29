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
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;
import 'core/supabase_client.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseClientHelper.initialize();

  runApp(
    const ProviderScope(
      child: BaratitoApp(),
    ),
  );
}

class BaratitoApp extends StatelessWidget {
  const BaratitoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeModel()),
      ],
      child: Consumer2<AuthProvider, ThemeModel>(
        builder: (context, authProvider, themeModel, _) {
          final router = buildRouter(authProvider);

          return MaterialApp.router(
            title: 'Baratito',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeModel.themeMode,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
