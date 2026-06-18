import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/verify_email_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/posts/presentation/screens/posts_screen.dart';

class AppRouter {
  final AuthProvider authProvider;
  late final GoRouter router;

  AppRouter({required this.authProvider}) {
    router = GoRouter(
      initialLocation: '/login',
      refreshListenable: authProvider,
      debugLogDiagnostics: true,
      redirect: (context, state) {
        final path = state.uri.path;
        final loggedIn = authProvider.isLoggedIn;

        if (!loggedIn && path != '/login') return '/login';
        if (loggedIn && path == '/login') return '/home';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/verify-email',
          builder: (context, state) => const VerifyEmailScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/posts',
          builder: (context, state) => const PostsScreen(),
        ),
      ],
    );
  }
}
