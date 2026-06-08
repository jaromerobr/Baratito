/// Riverpod providers for authentication state management.
///
/// - [authRepositoryProvider]: Singleton repository instance.
/// - [authStateProvider]: StreamProvider that mirrors Supabase auth changes.
/// - [currentUserProfileProvider]: FutureProvider for the public.users profile.
/// - [authControllerProvider]: StateNotifier for login/register/signOut actions.
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/auth_repository.dart';
import '../../domain/user_model.dart';

// ── Repository provider ─────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// ── Auth state stream ───────────────────────────────────
/// Emits every time the Supabase auth state changes
/// (sign in, sign out, token refresh, etc.).
final authStateProvider = StreamProvider<AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.listenAuthState();
});

// ── Current user profile from public.users ──────────────
/// Fetches the extended profile for the currently signed-in user.
/// Returns null if not authenticated.
final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (state) async {
      final user = state.session?.user;
      if (user == null) return null;

      final repo = ref.read(authRepositoryProvider);
      final result = await repo.getUserProfile(user.id);

      return switch (result) {
        Success(data: final profile) => profile,
        Failure() => null,
      };
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// ── Auth controller state ───────────────────────────────
class AuthControllerState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const AuthControllerState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  AuthControllerState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return AuthControllerState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

// ── Auth controller ─────────────────────────────────────
class AuthController extends StateNotifier<AuthControllerState> {
  final AuthRepository _repo;

  AuthController(this._repo) : super(const AuthControllerState());

  /// Sign in with email and password.
  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );

    final result = await _repo.signInWithEmail(email, password);

    return switch (result) {
      Success() => () {
          state = state.copyWith(isLoading: false);
          return true;
        }(),
      Failure(message: final msg) => () {
          state = state.copyWith(isLoading: false, errorMessage: msg);
          return false;
        }(),
    };
  }

  /// Register a new user.
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );

    final result = await _repo.signUpWithEmail(
      email: email,
      password: password,
      fullName: fullName,
      role: role,
    );

    return switch (result) {
      Success() => () {
          state = state.copyWith(isLoading: false);
          return true;
        }(),
      Failure(message: final msg) => () {
          state = state.copyWith(isLoading: false, errorMessage: msg);
          return false;
        }(),
    };
  }

  /// Reset password for an email.
  Future<bool> resetPassword(String email) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );

    final result = await _repo.resetPassword(email);

    return switch (result) {
      Success() => () {
          state = state.copyWith(
            isLoading: false,
            successMessage: AuthFailureMessages.resetEmailSent,
          );
          return true;
        }(),
      Failure(message: final msg) => () {
          state = state.copyWith(isLoading: false, errorMessage: msg);
          return false;
        }(),
    };
  }

  /// Sign out.
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await _repo.signOut();
    state = state.copyWith(isLoading: false);
  }

  /// Resend verification email.
  Future<bool> resendVerification() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );

    final result = await _repo.resendVerificationEmail();

    return switch (result) {
      Success() => () {
          state = state.copyWith(
            isLoading: false,
            successMessage: 'Correo de verificación reenviado.',
          );
          return true;
        }(),
      Failure(message: final msg) => () {
          state = state.copyWith(isLoading: false, errorMessage: msg);
          return false;
        }(),
    };
  }

  /// Refresh session to check email verification.
  Future<bool> checkEmailVerified() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repo.refreshSession();

    return switch (result) {
      Success(data: final user) => () {
          final verified = user.emailConfirmedAt != null;
          if (!verified) {
            state = state.copyWith(
              isLoading: false,
              errorMessage: 'Tu correo aún no ha sido verificado.',
            );
          } else {
            state = state.copyWith(isLoading: false);
          }
          return verified;
        }(),
      Failure(message: final msg) => () {
          state = state.copyWith(isLoading: false, errorMessage: msg);
          return false;
        }(),
    };
  }

  /// Clear error/success messages.
  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}

// ── Controller provider ─────────────────────────────────
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthControllerState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo);
});
