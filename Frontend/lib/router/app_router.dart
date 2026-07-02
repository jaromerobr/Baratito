import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/email_confirmation_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../features/products/presentation/screens/main_shell.dart';
import '../features/products/presentation/screens/product_detail_screen.dart';
import '../features/products/presentation/screens/publish_product_screen.dart';
import '../features/verification/presentation/screens/verification_screen.dart';
import '../features/admin/presentation/screens/admin_shell.dart';
import '../features/profile/presentation/screens/profile_edit_screen.dart';
import '../features/products/presentation/screens/my_products_screen.dart';
import '../features/orders/presentation/purchases_screen.dart';
import '../features/chat/presentation/screens/chat_screen.dart';
import '../features/chat/domain/chat_models.dart';
import '../features/cart/presentation/screens/cart_screen.dart';
import '../features/payments/presentation/checkout_payment_screen.dart';

const _authRoutes = [
  '/login',
  '/register',
  '/confirm-email',
  '/forgot-password',
  '/reset-password',
];

/// Referencia global al router activo, para navegar desde eventos externos
/// (ej. al tocar una notificación push). Se asigna en [buildRouter].
GoRouter? rootRouter;

GoRouter buildRouter(AuthProvider authProvider) {
  final router = GoRouter(
    initialLocation: '/login',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final loggedIn = authProvider.status == AuthStatus.authenticated;
      final loc = state.matchedLocation;
      final goingToAuth = _authRoutes.contains(loc);

      // Rutas que un invitado (sin sesión) también puede ver.
      final isGuestAllowed =
          loc == '/home' || loc.startsWith('/product');

      // Si no hay sesión y va a una ruta protegida → login.
      if (!loggedIn && !goingToAuth && !isGuestAllowed) return '/login';

      // Si hay sesión y va a una pantalla de auth → home.
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
        builder: (c, s) => const MainShell(),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (c, s) => ProductDetailScreen(
          productId: s.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/publish',
        builder: (c, s) => const PublishProductScreen(),
      ),
      GoRoute(
        path: '/verify',
        builder: (c, s) => const VerificationScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (c, s) => const AdminShell(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (c, s) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: '/my-products',
        builder: (c, s) => const MyProductsScreen(),
      ),
      GoRoute(
        path: '/purchases',
        builder: (c, s) => const PurchasesScreen(),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (c, s) => ChatScreen(
          conversationId: s.pathParameters['id']!,
          conversation: s.extra as Conversation?,
        ),
      ),
      GoRoute(
        path: '/cart',
        builder: (c, s) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout/:id',
        builder: (c, s) => CheckoutPaymentScreen(
          checkoutId: s.pathParameters['id']!,
        ),
      ),
    ],
  );
  rootRouter = router;
  return router;
}
