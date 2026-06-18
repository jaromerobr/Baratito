// Login screen — Baratito brand.
// Usa Provider + mock AuthProvider (Semana 7).
// El redirect de GoRouter maneja la navegación automáticamente tras login.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:email_validator/email_validator.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _floatController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _floatController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (!success) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Correo o contraseña incorrectos.';
      });
    }
    // Si success == true, GoRouter (refreshListenable) redirige automáticamente
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(size),
            Transform.translate(
              offset: const Offset(0, -40),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildFormCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────
  Widget _buildHeader(Size size) {
    return SizedBox(
      height: size.height * 0.42,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(color: AppColors.accent),
          ),
          Positioned(
            top: -30,
            right: -60,
            child: Transform.rotate(
              angle: -math.pi / 6,
              child: Container(
                width: 250,
                height: 350,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(180),
                  borderRadius: BorderRadius.circular(60),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: -80,
            child: Transform.rotate(
              angle: math.pi / 5,
              child: Container(
                width: 200,
                height: 300,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(140),
                  borderRadius: BorderRadius.circular(60),
                ),
              ),
            ),
          ),
          _buildFloatingIcon(
            icon: Icons.checkroom_outlined,
            top: size.height * 0.10,
            left: 24,
            delay: 0.0,
          ),
          _buildFloatingIcon(
            icon: Icons.local_offer_outlined,
            top: size.height * 0.06,
            right: 30,
            delay: 0.3,
          ),
          _buildFloatingIcon(
            icon: Icons.favorite_outline_rounded,
            top: size.height * 0.15,
            right: 20,
            delay: 0.6,
          ),
          _buildFloatingIcon(
            icon: Icons.sync_outlined,
            top: size.height * 0.22,
            left: 16,
            delay: 0.9,
          ),
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Gap(20),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'B',
                      style: GoogleFonts.poppins(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
                const Gap(12),
                Text(
                  'BARATITO',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDark,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'Segunda mano, nueva oportunidad.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingIcon({
    required IconData icon,
    double? top,
    double? left,
    double? right,
    required double delay,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) {
          final value = math.sin(
            (_floatController.value + delay) * math.pi * 2,
          );
          return Transform.translate(
            offset: Offset(0, value * 8),
            child: child,
          );
        },
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(60),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white.withAlpha(200), size: 22),
        ),
      ),
    );
  }

  // ── FORM CARD ──────────────────────────────────────────
  Widget _buildFormCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Iniciar sesión',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const Gap(4),
            Text(
              'Qué bueno verte de nuevo. Inicia sesión para\nseguir encontrando grandes oportunidades.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const Gap(24),

            // Error inline
            if (_errorMessage != null) ...[
              _buildErrorBanner(_errorMessage!),
              const Gap(16),
            ],

            // Email
            _buildFieldLabel('Correo electrónico'),
            const Gap(8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Ingresa tu correo',
                prefixIcon: Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.textHint,
                  size: 22,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa tu correo electrónico';
                }
                if (!EmailValidator.validate(value.trim())) {
                  return 'Ingresa un correo válido';
                }
                return null;
              },
            ),
            const Gap(20),

            // Password
            _buildFieldLabel('Contraseña'),
            const Gap(8),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleLogin(),
              decoration: InputDecoration(
                hintText: 'Ingresa tu contraseña',
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.textHint,
                  size: 22,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textHint,
                    size: 22,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa tu contraseña';
                }
                return null;
              },
            ),
            const Gap(14),

            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => context.push('/forgot-password'),
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const Gap(24),

            // Login button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Entrar',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const Gap(12),

            // Register button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: () => context.push('/register'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: const BorderSide(color: AppColors.primary, width: 2),
                ),
                child: Text(
                  'Crear cuenta',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 20),
          const Gap(10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
