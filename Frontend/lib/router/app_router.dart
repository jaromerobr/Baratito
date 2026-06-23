import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/email_confirmation_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/reset_password_screen.dart';

const _authRoutes = [
  '/login',
  '/register',
  '/confirm-email',
  '/forgot-password',
  '/reset-password',
];

GoRouter buildRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final loggedIn = authProvider.status == AuthStatus.authenticated;
      final goingToAuth = _authRoutes.contains(state.matchedLocation);

      if (!loggedIn && !goingToAuth) return '/login';
      if (loggedIn && goingToAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      GoRoute(
        path: '/confirm-email',
        builder: (c, s) => EmailConfirmationScreen(email: s.extra as String? ?? ''),
      ),
      GoRoute(path: '/forgot-password', builder: (c, s) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/reset-password',
        builder: (c, s) => ResetPasswordScreen(email: s.extra as String? ?? ''),
      ),
      GoRoute(
        path: '/home', 
        builder: (c, s) => Scaffold(
          appBar: AppBar(
            title: const Text('Home'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  authProvider.signOut();
                },
              )
            ]
          ),
          body: const Center(child: Text('Bienvenido a Baratito!')),
        )
      ),
    ],
  );
}
