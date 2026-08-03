import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// "Web client ID" de Google (Google Cloud → Credenciales → cliente OAuth
/// tipo *Web*). NO es secreto (viaja en la app). Reemplázalo por el tuyo o
/// pásalo al compilar: --dart-define=GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com
const String kGoogleWebClientId = String.fromEnvironment(
  'GOOGLE_WEB_CLIENT_ID',
  defaultValue: '758813187933-d5bfmr3fmn6ree2jl3a8f4rdmntk708u.apps.googleusercontent.com',
);

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> resendSignupCode(String email) {
    return _client.auth.resend(type: OtpType.signup, email: email);
  }

  Future<AuthResponse> verifySignupCode({
    required String email,
    required String code,
  }) {
    return _client.auth.verifyOTP(
      type: OtpType.signup,
      email: email,
      token: code,
    );
  }

  Future<void> sendPasswordResetCode(String email) {
    return _client.auth.resetPasswordForEmail(email);
  }

  Future<AuthResponse> verifyResetCode({
    required String email,
    required String code,
  }) {
    return _client.auth.verifyOTP(
      type: OtpType.recovery,
      email: email,
      token: code,
    );
  }

  Future<UserResponse> updatePassword(String newPassword) {
    return _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Inicio de sesión nativo con Google (rápido, sin abrir el navegador).
  /// Obtiene el idToken de Google y crea/inicia la sesión en Supabase.
  /// Devuelve null si el usuario cancela el selector de cuentas.
  Future<AuthResponse?> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(serverClientId: kGoogleWebClientId);
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null; // el usuario canceló

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;
    if (idToken == null) {
      throw const AuthException('No se obtuvo el token de Google.');
    }

    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  Future<void> signOut() async {
    // Cierra también la sesión de Google para que vuelva a preguntar la cuenta.
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _client.auth.signOut();
  }
}
