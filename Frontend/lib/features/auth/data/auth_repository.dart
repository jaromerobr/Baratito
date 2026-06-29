/// Authentication repository.
///
/// Wraps Supabase Auth calls with a [Result] pattern for consistent
/// error handling across the app. Also reads/writes to `public.profiles`.
library;

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/user_model.dart';
import '../../../core/supabase_client.dart';

// ── Result pattern ──────────────────────────────────────
/// Sealed result type for safe error handling without exceptions.
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final String message;
  final String? code;
  const Failure(this.message, {this.code});
}

// ── Auth Failure messages (Spanish) ─────────────────────
class AuthFailureMessages {
  AuthFailureMessages._();

  static const invalidCredentials = 'Correo o contraseña incorrectos.';
  static const emailNotConfirmed =
      'Tu correo aún no está verificado. Revisa tu bandeja de entrada.';
  static const userDisabled = 'Tu cuenta ha sido desactivada.';
  static const emailInUse = 'Ya existe una cuenta con este correo.';
  static const weakPassword = 'La contraseña es demasiado débil.';
  static const strictPasswordPolicy =
      'La contraseña debe tener al menos: 1 mayúscula, 1 minúscula, 1 número y 1 carácter especial (!@#\$...).';
  static const networkError = 'Error de conexión. Verifica tu internet.';
  static const generic = 'Ocurrió un error inesperado. Intenta de nuevo.';
  static const resetEmailSent =
      'Te enviamos un correo para restablecer tu contraseña.';
}

// ── Repository ──────────────────────────────────────────
class AuthRepository {
  final SupabaseClient _client = SupabaseClientHelper.client;
  GoTrueClient get _auth => _client.auth;

  /// Sign in with email and password.
  Future<Result<User>> signInWithEmail(String email, String password) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      if (user == null) {
        return const Failure(AuthFailureMessages.invalidCredentials);
      }

      // Check if the user's account is active
      final profile = await _getProfileById(user.id);
      if (profile != null && !profile.isActive) {
        await _auth.signOut();
        return const Failure(AuthFailureMessages.userDisabled);
      }

      return Success(user);
    } on AuthException catch (e) {
      return Failure(_mapAuthError(e));
    } catch (e) {
      return Failure(AuthFailureMessages.generic, code: e.toString());
    }
  }

  /// Register a new user with email, password, full name, and role.
  Future<Result<User>> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    try {
      final response = await _auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim(), 'role': role.value},
      );

      final user = response.user;
      if (user == null) {
        return const Failure(AuthFailureMessages.generic);
      }

      return Success(user);
    } on AuthException catch (e) {
      return Failure(_mapAuthError(e));
    } catch (e) {
      return Failure(AuthFailureMessages.generic, code: e.toString());
    }
  }

  /// Sign out the current user.
  Future<Result<void>> signOut() async {
    try {
      await _auth.signOut();
      return const Success(null);
    } catch (e) {
      return Failure(AuthFailureMessages.generic, code: e.toString());
    }
  }

  /// Send a password reset email.
  Future<Result<void>> resetPassword(String email) async {
    try {
      await _auth.resetPasswordForEmail(email.trim());
      return const Success(null);
    } on AuthException catch (e) {
      return Failure(_mapAuthError(e));
    } catch (e) {
      return Failure(AuthFailureMessages.generic, code: e.toString());
    }
  }

  /// Get the currently authenticated Supabase user (from cache/session).
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Stream of auth state changes.
  Stream<AuthState> listenAuthState() {
    return _auth.onAuthStateChange;
  }

  /// Fetch the extended profile from `public.profiles`.
  Future<Result<UserProfile>> getUserProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return Success(UserProfile.fromJson(data));
    } catch (e) {
      return Failure('No se pudo cargar el perfil.', code: e.toString());
    }
  }

  /// Resend the verification email for the current user.
  Future<Result<void>> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        return const Failure('No hay una sesión activa.');
      }
      await _auth.resend(type: OtpType.email, email: user.email!);
      return const Success(null);
    } on AuthException catch (e) {
      return Failure(_mapAuthError(e));
    } catch (e) {
      return Failure(AuthFailureMessages.generic, code: e.toString());
    }
  }

  /// Refresh the current session to pick up email verification changes.
  Future<Result<User>> refreshSession() async {
    try {
      final response = await _auth.refreshSession();
      final user = response.user;
      if (user == null) {
        return const Failure('No se pudo actualizar la sesión.');
      }
      return Success(user);
    } catch (e) {
      return Failure(AuthFailureMessages.generic, code: e.toString());
    }
  }

  // ── Helpers ─────────────────────────────────────────────

  /// Fetch a profile to check `is_active`. Returns null on error.
  Future<UserProfile?> _getProfileById(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return UserProfile.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// Map Supabase [AuthException] to a user-friendly message in Spanish.
  String _mapAuthError(AuthException e) {
    final message = e.message.toLowerCase();

    if (message.contains('invalid login credentials') ||
        message.contains('invalid_credentials')) {
      return AuthFailureMessages.invalidCredentials;
    }
    if (message.contains('email not confirmed') ||
        message.contains('email_not_confirmed')) {
      return AuthFailureMessages.emailNotConfirmed;
    }
    if (message.contains('user already registered') ||
        message.contains('already registered')) {
      return AuthFailureMessages.emailInUse;
    }
    if (message.contains('weak password') ||
        message.contains('weak_password')) {
      return AuthFailureMessages.weakPassword;
    }
    if (message.contains(
      'password should contain at least one character of each',
    )) {
      return AuthFailureMessages.strictPasswordPolicy;
    }
    if (message.contains('network') || message.contains('socket')) {
      return AuthFailureMessages.networkError;
    }

    return e.message;
  }
}
