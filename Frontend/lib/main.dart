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
import 'package:provider/provider.dart';
import 'core/supabase_client.dart'; // We use the existing supabase config initialized via SupabaseClientHelper
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseClientHelper.initialize(); // Using the existing helper which has the fallbacks

  runApp(const BaratitoApp());
}

class BaratitoApp extends StatelessWidget {
  const BaratitoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final router = buildRouter(authProvider);

          return MaterialApp.router(
            title: 'Baratito',
            theme: AppTheme.light,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
