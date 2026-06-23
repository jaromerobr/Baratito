import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../utils/auth_error_mapper.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus status = AuthStatus.unknown;
  User? user;

  AuthProvider() {
    _init();
  }

  void _init() {
    final session = _authService.currentSession;
    status = session != null
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
    user = session?.user;

    _authService.authStateChanges.listen((data) {
      final newSession = data.session;
      status = newSession != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
      user = newSession?.user;
      notifyListeners();
    });
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _authService.signIn(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return mapAuthError(e);
    } catch (_) {
      return 'No pudimos conectar con el servidor. Revisa tu internet.';
    }
  }

  Future<String?> signUp(String email, String password, String fullName) async {
    try {
      await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      return null;
    } on AuthException catch (e) {
      return mapAuthError(e);
    } catch (_) {
      return 'No pudimos conectar con el servidor. Revisa tu internet.';
    }
  }

  Future<String?> verifySignupCode(String email, String code) async {
    try {
      await _authService.verifySignupCode(email: email, code: code);
      return null;
    } on AuthException catch (e) {
      return mapAuthError(e);
    } catch (_) {
      return 'Ocurrió un error. Intenta de nuevo';
    }
  }

  Future<String?> resendSignupCode(String email) async {
    try {
      await _authService.resendSignupCode(email);
      return null;
    } on AuthException catch (e) {
      return mapAuthError(e);
    } catch (_) {
      return 'Ocurrió un error. Intenta de nuevo';
    }
  }

  Future<String?> sendPasswordResetCode(String email) async {
    try {
      await _authService.sendPasswordResetCode(email);
      return null;
    } on AuthException catch (e) {
      return mapAuthError(e);
    } catch (_) {
      return 'Ocurrió un error. Intenta de nuevo';
    }
  }

  Future<String?> verifyResetCode(String email, String code) async {
    try {
      await _authService.verifyResetCode(email: email, code: code);
      return null;
    } on AuthException catch (e) {
      return mapAuthError(e);
    } catch (_) {
      return 'Ocurrió un error. Intenta de nuevo';
    }
  }

  Future<String?> updatePassword(String newPassword) async {
    try {
      await _authService.updatePassword(newPassword);
      return null;
    } on AuthException catch (e) {
      return mapAuthError(e);
    } catch (_) {
      return 'Ocurrió un error. Intenta de nuevo';
    }
  }

  Future<void> signOut() => _authService.signOut();
}
