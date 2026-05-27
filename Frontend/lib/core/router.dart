/// GoRouter configuration with auth-based redirection.
///
/// Routes: /splash, /login, /register, /verify-email, /posts,
/// /forgot-password, /home (dashboard).
///
/// Guards:
/// - No session → /login
/// - Authenticated → /home (dashboard)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/verify_email_screen.dart';
import '../features/posts/presentation/screens/posts_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';

// ── Route paths ─────────────────────────────────────────
class AppRoutes {
  AppRoutes._();
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const verifyEmail = '/verify-email';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const posts = '/posts';
}

// ── Router provider ─────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final currentPath = state.uri.path;

      // Don't redirect from splash — it handles its own logic
      if (currentPath == AppRoutes.splash) return null;

      // Determine auth status from the stream
      final isAuthenticated = authState.whenOrNull(
        data: (authData) => authData.session != null,
      );

      // Auth state is still loading
      if (isAuthenticated == null) return null;

      final authPages = [
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
      ];
      final isOnAuthPage = authPages.contains(currentPath);

      // Not authenticated → go to login (unless already on an auth page or home as guest)
      if (!isAuthenticated) {
        if (!isOnAuthPage && currentPath != AppRoutes.home) {
          return AppRoutes.login;
        }
        return null;
      }

      // Authenticated → redirect away from auth pages to dashboard
      if (isOnAuthPage) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.posts,
        builder: (context, state) => const PostsScreen(),
      ),
    ],
  );
});
