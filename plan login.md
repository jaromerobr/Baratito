Plan de Implementación — Login, Registro y Recuperación de Contraseña

Proyecto Baratito (Flutter + Supabase)


Este documento es una guía de ejecución para implementar en Antigravity. Sigue el orden de las secciones — cada una depende de la anterior. No implementes nada de la sección "Fuera de alcance" en esta tarea.




0. Decisiones de diseño clave (leer antes de empezar)


Identidad visual nueva: se reemplaza la paleta naranja/navy usada en presentaciones anteriores por la paleta oficial de marca definida en la sección 1.
Sin deep links: tanto la confirmación de cuenta como la recuperación de contraseña se resuelven con un código de 6 dígitos enviado por correo, ingresado directamente en la app. Esto evita configurar Associated Domains (iOS) o intent-filters (Android), que son la fuente más común de bugs en este tipo de flujo.
Email confirmation obligatorio: ya está activado en Supabase (Confirm email: ON). Un usuario no puede iniciar sesión hasta confirmar su correo con el código.
Reglas de contraseña: mínimo 8 caracteres y al menos 1 número. No se exige símbolo especial para no frustrar al usuario en el MVP.
Arquitectura: AuthService (llamadas a Supabase) → AuthProvider (estado global con ChangeNotifier) → pantallas (consumen el provider). El enrutamiento con go_router redirige automáticamente según el estado de sesión.



1. Identidad visual

1.1 Logo

Ya tienes el archivo aprobado: fondo amarillo con una "B" verde oscuro que integra una etiqueta de precio.

Acción: copia ese archivo a:

assets/images/logo.png

No se regenera el logo — se usa tal cual.

1.2 Paleta de colores oficial

TokenHexUso principalprimary (Amarillo)#FBBF24Fondo del logo, acentos, loaders, badgessecondary (Verde oscuro)#064E3BBotones principales, enlaces, ícono de marcatertiary (Crema)#FDFCF0Fondo general de todas las pantallas (scaffold)neutral (Gris oscuro)#1F2937Texto principal, títulos

Colores derivados que vas a necesitar (no vinieron en la paleta original, pero son indispensables):

TokenHexUsoerror#DC2626Mensajes de error, bordes de campos inválidossuccess#16A34AConfirmaciones exitosasborder#E5E0D0Bordes sutiles de inputs sobre fondo crematextMuted#6B7280Subtítulos, placeholders, texto secundario


2. Dependencias (pubspec.yaml)

PaqueteVersión¿Ya estaba?Para qué se usa aquísupabase_flutter^2.3.0SíAuth, sesiones, verificación OTPprovider^6.1.1SíEstado global de autenticacióngo_router^13.0.0SíNavegación y redirección según sesióncupertino_icons^1.0.6SíIconos (mostrar/ocultar contraseña, etc.)pin_code_fields^8.0.1Nuevo (recomendado)UI elegante de casillas para el código de 6 dígitos

Agrega esto a tu pubspec.yaml:

yamldependencies:
  pin_code_fields: ^8.0.1

pin_code_fields es opcional pero recomendado — si no lo instalas, usa un TextFormField simple con maxLength: 6 (incluido como alternativa en la sección 9.5).

Confirma que esto ya existe en tu pubspec.yaml (declaración de assets):

yamlflutter:
  uses-material-design: true
  assets:
    - assets/images/


3. Estructura de archivos a crear

lib/
├── config/
│   ├── app_colors.dart          [NUEVO]
│   ├── app_theme.dart           [NUEVO]
│   └── supabase_config.dart     [ya existe]
├── services/
│   └── auth_service.dart        [NUEVO]
├── providers/
│   └── auth_provider.dart       [NUEVO]
├── utils/
│   ├── validators.dart          [NUEVO]
│   └── auth_error_mapper.dart   [NUEVO]
├── router/
│   └── app_router.dart          [NUEVO]
├── widgets/
│   └── auth/
│       ├── baratito_logo.dart   [NUEVO]
│       ├── auth_text_field.dart [NUEVO]
│       └── primary_button.dart  [NUEVO]
├── screens/
│   └── auth/
│       ├── login_screen.dart              [NUEVO]
│       ├── register_screen.dart           [NUEVO]
│       ├── email_confirmation_screen.dart [NUEVO]
│       ├── forgot_password_screen.dart    [NUEVO]
│       └── reset_password_screen.dart     [NUEVO]
└── main.dart                     [MODIFICAR]

assets/
└── images/
    └── logo.png                 [COPIAR del archivo ya aprobado]


4. Colores y Tema

4.1 lib/config/app_colors.dart

dartimport 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Paleta oficial Baratito
  static const Color primary   = Color(0xFFFBBF24); // Amarillo
  static const Color secondary = Color(0xFF064E3B); // Verde oscuro
  static const Color tertiary  = Color(0xFFFDFCF0); // Crema
  static const Color neutral   = Color(0xFF1F2937); // Gris oscuro

  // Derivados necesarios
  static const Color error     = Color(0xFFDC2626);
  static const Color success   = Color(0xFF16A34A);
  static const Color border    = Color(0xFFE5E0D0);
  static const Color textMuted = Color(0xFF6B7280);
}

4.2 lib/config/app_theme.dart

dartimport 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.tertiary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.secondary,
        primary: AppColors.secondary,
        secondary: AppColors.primary,
        surface: AppColors.tertiary,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.tertiary,
        foregroundColor: AppColors.neutral,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: const TextTheme().apply(
        bodyColor: AppColors.neutral,
        displayColor: AppColors.neutral,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.secondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.neutral,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}


5. Capa de servicio — lib/services/auth_service.dart

Envuelve todas las llamadas a Supabase Auth. Ninguna pantalla debe llamar a Supabase.instance.client.auth directamente — siempre a través de este servicio.

dartimport 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Registro de nuevo usuario. No inicia sesión todavía
  /// (Confirm email está activado, así que no hay sesión hasta confirmar).
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

  /// Inicio de sesión normal.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Reenvía el código de 6 dígitos para confirmar la cuenta.
  Future<void> resendSignupCode(String email) {
    return _client.auth.resend(type: OtpType.signup, email: email);
  }

  /// Verifica el código de 6 dígitos de confirmación de cuenta.
  /// Si es correcto, deja al usuario con sesión iniciada.
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

  /// Paso 1 de recuperación de contraseña: envía el código por correo.
  Future<void> sendPasswordResetCode(String email) {
    return _client.auth.resetPasswordForEmail(email);
  }

  /// Paso 2: valida el código recibido. Deja una sesión temporal activa.
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

  /// Paso 3: define la nueva contraseña.
  /// Debe llamarse justo después de verifyResetCode.
  Future<UserResponse> updatePassword(String newPassword) {
    return _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> signOut() => _client.auth.signOut();
}


6. Estado global — lib/providers/auth_provider.dart

dartimport 'package:flutter/foundation.dart';
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

  /// Devuelve null si todo salió bien, o un mensaje de error en español.
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
    }
  }

  Future<String?> resendSignupCode(String email) async {
    try {
      await _authService.resendSignupCode(email);
      return null;
    } on AuthException catch (e) {
      return mapAuthError(e);
    }
  }

  Future<String?> sendPasswordResetCode(String email) async {
    try {
      await _authService.sendPasswordResetCode(email);
      return null;
    } on AuthException catch (e) {
      return mapAuthError(e);
    }
  }

  Future<String?> verifyResetCode(String email, String code) async {
    try {
      await _authService.verifyResetCode(email: email, code: code);
      return null;
    } on AuthException catch (e) {
      return mapAuthError(e);
    }
  }

  Future<String?> updatePassword(String newPassword) async {
    try {
      await _authService.updatePassword(newPassword);
      return null;
    } on AuthException catch (e) {
      return mapAuthError(e);
    }
  }

  Future<void> signOut() => _authService.signOut();
}


7. Utilidades

7.1 lib/utils/validators.dart

dartclass Validators {
  Validators._();

  static final RegExp _emailRegex =
      RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu correo electrónico';
    if (!_emailRegex.hasMatch(v)) return 'Ingresa un correo válido';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Ingresa tu contraseña';
    if (v.length < 8) return 'Debe tener al menos 8 caracteres';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Debe incluir al menos un número';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value != original) return 'Las contraseñas no coinciden';
    return null;
  }

  static String? fullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu nombre completo';
    if (v.length < 3) return 'El nombre es muy corto';
    return null;
  }

  static String? otpCode(String? value) {
    final v = value?.trim() ?? '';
    if (v.length != 6) return 'El código debe tener 6 dígitos';
    if (!RegExp(r'^\d{6}$').hasMatch(v)) return 'El código solo debe tener números';
    return null;
  }
}

7.2 lib/utils/auth_error_mapper.dart

dartimport 'package:supabase_flutter/supabase_flutter.dart';

String mapAuthError(AuthException e) {
  final msg = e.message.toLowerCase();

  if (msg.contains('invalid login credentials')) {
    return 'Correo o contraseña incorrectos';
  }
  if (msg.contains('user already registered')) {
    return 'Ya existe una cuenta registrada con este correo';
  }
  if (msg.contains('email not confirmed')) {
    return 'Debes confirmar tu correo antes de iniciar sesión';
  }
  if (msg.contains('token has expired') || msg.contains('invalid token') ||
      msg.contains('otp_expired')) {
    return 'El código ingresado no es válido o ya expiró';
  }
  if (msg.contains('password should be at least')) {
    return 'La contraseña es demasiado corta';
  }
  if (msg.contains('rate limit') || msg.contains('over_email_send_rate_limit')) {
    return 'Demasiados intentos. Espera unos minutos e intenta de nuevo';
  }
  return 'Ocurrió un error. Intenta de nuevo';
}


8. Enrutamiento — lib/router/app_router.dart

dartimport 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/email_confirmation_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/reset_password_screen.dart';
// import '../screens/home/home_screen.dart'; // Pantalla principal, fuera de este plan

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
      // GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
    ],
  );
}


Nota: la ruta /home está comentada porque la pantalla principal no es parte de este plan. Antigravity debe descomentarla cuando esa pantalla exista — de lo contrario el redirect fallará al intentar navegar ahí tras un login exitoso.




9. Widgets reutilizables

9.1 lib/widgets/auth/baratito_logo.dart

dartimport 'package:flutter/material.dart';

class BaratitoLogo extends StatelessWidget {
  final double size;
  const BaratitoLogo({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/images/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

9.2 lib/widgets/auth/auth_text_field.dart

dartimport 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final int? maxLength;
  final String? Function(String?)? validator;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.maxLength,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: suffixIcon,
        counterText: '', // oculta el contador de caracteres
      ),
    );
  }
}

9.3 lib/widgets/auth/primary_button.dart

dartimport 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool loading;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(label),
    );
  }
}


10. Pantallas

10.1 LoginScreen — implementación de referencia completa

Usa este patrón exacto para las demás pantallas (mismos imports, misma estructura de Form + Column + manejo de _loading).

dartimport 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/auth/baratito_logo.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../../widgets/auth/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final auth = context.read<AuthProvider>();
    final error = await auth.signIn(_emailCtrl.text.trim(), _passwordCtrl.text);

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    // El redirect de go_router se encarga de navegar a /home automáticamente
    // al detectar la sesión activa (ver app_router.dart).
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Center(child: BaratitoLogo(size: 96)),
                const SizedBox(height: 16),
                Text(
                  'Bienvenido de nuevo',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.neutral,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Inicia sesión para comprar y vender en Loja',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 32),
                AuthTextField(
                  controller: _emailCtrl,
                  label: 'Correo electrónico',
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _passwordCtrl,
                  label: 'Contraseña',
                  obscureText: _obscure,
                  validator: Validators.password,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Iniciar sesión',
                  loading: _loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('¿No tienes cuenta? '),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: const Text('Regístrate'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


10.2 RegisterScreen — especificación

Sigue el mismo patrón estructural que LoginScreen. Campos y comportamiento:

CampoValidadorNotasNombre completoValidators.fullNameTextInputType.nameCorreo electrónicoValidators.emailTextInputType.emailAddressContraseñaValidators.passwordobscure + botón de ojo (igual que Login)Confirmar contraseñaValidators.confirmPassword(value, _passwordCtrl.text)obscure + botón de ojo

Checkbox obligatorio: "Acepto los términos y condiciones" — booleano en estado local. Si el botón se presiona sin marcarlo, muestra un SnackBar: "Debes aceptar los términos para continuar" (no llames a Supabase si no está marcado).

Botón "Crear cuenta":

dartfinal error = await context.read<AuthProvider>().signUp(
  _emailCtrl.text.trim(),
  _passwordCtrl.text,
  _nameCtrl.text.trim(),
);

if (error != null) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  return;
}

if (!mounted) return;
context.go('/confirm-email', extra: _emailCtrl.text.trim());

Pie de pantalla: "¿Ya tienes cuenta?" + botón "Inicia sesión" → context.go('/login').


10.3 EmailConfirmationScreen — especificación

Constructor recibe final String email; (requerido).

Contenido visual:


Ícono grande de correo (Icons.mark_email_unread_outlined, color AppColors.secondary)
Título: "Confirma tu cuenta"
Texto: "Enviamos un código de 6 dígitos a {email}. Ingrésalo aquí para activar tu cuenta."
Campo de código: AuthTextField con keyboardType: TextInputType.number, maxLength: 6, validator: Validators.otpCode (o pin_code_fields si se instaló — ver sección 2).


Botón principal "Confirmar cuenta":

dartfinal error = await context.read<AuthProvider>().verifySignupCode(
  widget.email,
  _codeCtrl.text.trim(),
);

if (error != null) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  return;
}
// Al verificar correctamente, Supabase crea la sesión.
// El listener de AuthProvider + el redirect de go_router
// se encargan de navegar a /home automáticamente.

Botón secundario "Reenviar código":


Al presionarlo, llama context.read<AuthProvider>().resendSignupCode(widget.email).
Debe quedar deshabilitado 30 segundos con un contador visible ("Reenviar en 28s") para no disparar el rate limit de Supabase. Usa un Timer.periodic simple en un StatefulWidget.



10.4 ForgotPasswordScreen — especificación

Contenido:


Título: "Recupera tu contraseña"
Subtítulo: "Te enviaremos un código de 6 dígitos a tu correo"
Campo: Correo electrónico (Validators.email)


Botón "Enviar código":

dartfinal error = await context.read<AuthProvider>().sendPasswordResetCode(
  _emailCtrl.text.trim(),
);

if (error != null) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  return;
}

if (!mounted) return;
context.push('/reset-password', extra: _emailCtrl.text.trim());

Pie: botón de texto "Volver a iniciar sesión" → context.pop().


10.5 ResetPasswordScreen — especificación

Constructor recibe final String email; (requerido).

Campos:

CampoValidadorCódigo de 6 dígitosValidators.otpCodeNueva contraseñaValidators.password (obscure + ojo)Confirmar nueva contraseñaValidators.confirmPassword (obscure + ojo)

Botón "Cambiar contraseña" — son dos llamadas encadenadas:

dartsetState(() => _loading = true);
final auth = context.read<AuthProvider>();

final codeError = await auth.verifyResetCode(widget.email, _codeCtrl.text.trim());
if (codeError != null) {
  setState(() => _loading = false);
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(codeError)));
  return;
}

final passError = await auth.updatePassword(_passwordCtrl.text);
setState(() => _loading = false);
if (!mounted) return;

if (passError != null) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(passError)));
  return;
}

// Cierra la sesión temporal de recuperación para que el usuario
// inicie sesión limpio con su nueva contraseña.
await auth.signOut();
if (!mounted) return;
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Contraseña actualizada. Inicia sesión.')),
);
context.go('/login');

Enlace inferior: "¿No recibiste el código?" + botón "Reenviar" → vuelve a llamar sendPasswordResetCode(widget.email).

Si instalaste pin_code_fields (sección 2), reemplaza el campo de código por:

dartPinCodeTextField(
  appContext: context,
  length: 6,
  controller: _codeCtrl,
  keyboardType: TextInputType.number,
  pinTheme: PinTheme(
    shape: PinCodeFieldShape.box,
    borderRadius: BorderRadius.circular(10),
    fieldHeight: 50,
    fieldWidth: 44,
    activeColor: AppColors.secondary,
    selectedColor: AppColors.primary,
    inactiveColor: AppColors.border,
  ),
  onChanged: (_) {},
)


11. Configuración requerida en el Dashboard de Supabase

Ve a Authentication → Email Templates y cambia dos plantillas para que usen el código de 6 dígitos en vez del link por defecto:

11.1 Plantilla "Confirm signup"

Reemplaza el contenido para que muestre {{ .Token }} en vez de {{ .ConfirmationURL }}:

html<h2>Confirma tu cuenta en Baratito</h2>
<p>Tu código de verificación es:</p>
<h1 style="letter-spacing: 4px;">{{ .Token }}</h1>
<p>Este código expira en 1 hora. Ingrésalo en la app para activar tu cuenta.</p>

11.2 Plantilla "Reset Password"

html<h2>Recupera tu contraseña en Baratito</h2>
<p>Tu código de verificación es:</p>
<h1 style="letter-spacing: 4px;">{{ .Token }}</h1>
<p>Este código expira en 1 hora. Si no solicitaste este cambio, ignora este correo.</p>


No necesitas tocar Site URL ni Redirect URLs para este flujo — al ser 100% por código, no hay ningún link que abrir ni deep link que interceptar.




12. main.dart — wiring final

dartimport 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const BaratitoApp());
}

class BaratitoApp extends StatelessWidget {
  const BaratitoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final router = buildRouter(authProvider);

          return MaterialApp.router(
            title: 'Baratito',
            theme: AppTheme.light,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}