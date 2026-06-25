/// GoRouter configuration with auth-based redirection.
///
/// Routes: /splash, /login, /register, /verify-email, /posts,
/// /forgot-password, /home (dashboard), /feed, /products/:id,
/// /product/new, /favorites, /my-listings.
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
import '../features/products/presentation/screens/home_feed_screen.dart';
import '../features/products/presentation/screens/product_detail_screen.dart';
import '../features/products/presentation/screens/product_form_screen.dart';
import '../features/products/presentation/screens/favorites_screen.dart';
import '../features/products/presentation/screens/my_listings_screen.dart';

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

  // ── Products ──────────────────────────────────────────
  static const feed = '/feed';
  static const productForm = '/product/new';
  static const favorites = '/favorites';
  static const myListings = '/my-listings';
  static String productDetail(String id) => '/products/$id';
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

      final publicPages = [
        AppRoutes.home,
        AppRoutes.posts,
        AppRoutes.feed,
        AppRoutes.productForm,
        AppRoutes.favorites,
        AppRoutes.myListings,
      ];

      // Not authenticated → go to login unless on auth/public page or product detail
      if (!isAuthenticated) {
        final isProductDetail = currentPath.startsWith('/products/');
        if (!isOnAuthPage &&
            !publicPages.contains(currentPath) &&
            !isProductDetail) {
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

      // ── Products ────────────────────────────────────
      GoRoute(
        path: AppRoutes.feed,
        builder: (context, state) => const HomeFeedScreen(),
      ),
      GoRoute(
        path: '/products/:id',
        builder: (context, state) => ProductDetailScreen(
          productId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.productForm,
        builder: (context, state) => const ProductFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: AppRoutes.myListings,
        builder: (context, state) => const MyListingsScreen(),
      ),
    ],
  );
});
