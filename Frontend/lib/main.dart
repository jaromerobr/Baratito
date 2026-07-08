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
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/supabase_client.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/notifications/push_notification_service.dart';
import 'providers/auth_provider.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseClientHelper.initialize();

  // Notificaciones push (FCM). El try/catch da robustez en runtime.
  // OJO: el build de Android requiere Frontend/android/app/google-services.json
  // (el plugin google-services falla la compilación si no está). Ver README S9.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await PushNotificationService.instance.init();
  } catch (e) {
    debugPrint('Firebase/FCM no inicializado (¿falta google-services.json?): $e');
  }

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
          // El router se crea UNA sola vez y se reutiliza: si se
          // reconstruyera en cada cambio de tema, la navegación se
          // reiniciaría y el usuario volvería al inicio.
          final router = rootRouter ?? buildRouter(authProvider);

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
