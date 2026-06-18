/// Baratito — App entry point.
///
/// Initializes Supabase (opcional), configura MultiProvider con AuthProvider
/// y usa AppRouter con GoRouter + refreshListenable para protección de rutas.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;
import 'package:provider/provider.dart';
import 'core/supabase_client.dart';
import 'core/theme/app_theme.dart';
import 'core/network/dio_client.dart';
import 'providers/auth_provider.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Supabase es opcional — la app funciona con mock login sin él
  try {
    await SupabaseClientHelper.initialize();
  } catch (e) {
    // ignore: avoid_print
    print('Supabase no disponible (modo mock): $e');
  }

  DioClient.instance.initialize();

  final authProvider = AuthProvider();
  final appRouter = AppRouter(authProvider: authProvider);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
      ],
      child: ProviderScope(
        child: BaratitoApp(appRouter: appRouter),
      ),
    ),
  );
}

class BaratitoApp extends StatelessWidget {
  final AppRouter appRouter;
  const BaratitoApp({required this.appRouter, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Baratito',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: appRouter.router,
    );
  }
}
