// Login screen — Matches the Baratito brand mockup.
//
// Yellow/green gradient header with floating icons, big "B" logo,
// white card with email/password fields, remember me, and guest mode.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:email_validator/email_validator.dart';
import 'package:gap/gap.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  late AnimationController _floatController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Floating icons animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Fade-in for the card
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

    ref.read(authControllerProvider.notifier).clearMessages();

    final success = await ref.read(authControllerProvider.notifier).signIn(
          _emailController.text,
          _passwordController.text,
        );

    if (success && mounted) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header with gradient + logo ────────────
            _buildHeader(size),

            // ── White card form ────────────────────────
            Transform.translate(
              offset: const Offset(0, -40),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildFormCard(authState),
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
          // Yellow background
          Positioned.fill(
            child: Container(
              color: AppColors.accent,
            ),
          ),

          // Green diagonal shape (top-right)
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

          // Green diagonal shape (bottom-left)
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

          // Floating icons
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

          // Logo "B" + Title centered
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Gap(20),
                // "B" logo container
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
                // "BARATITO" text
                Text(
                  'BARATITO',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDark,
                    letterSpacing: 2,
                  ),
                ),
                // Tagline
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

  // ── Floating icon with animation ───────────────────────
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
          child: Icon(
            icon,
            color: Colors.white.withAlpha(200),
            size: 22,
          ),
        ),
      ),
    );
  }

  // ── FORM CARD ──────────────────────────────────────────
  Widget _buildFormCard(AuthControllerState authState) {
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
            // Title
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

            // Error banner
            if (authState.errorMessage != null) ...[
              _buildErrorBanner(authState.errorMessage!),
              const Gap(16),
            ],

            // Email field
            _buildFieldLabel('Correo electrónico o usuario'),
            const Gap(8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Ingresa tu correo o usuario',
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

            // Password field
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

            // Remember me + Forgot password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Remember me checkbox
                GestureDetector(
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (v) =>
                              setState(() => _rememberMe = v ?? false),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const Gap(8),
                      Text(
                        'Recordarme',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Forgot password
                GestureDetector(
                  onTap: () => context.push(AppRoutes.forgotPassword),
                  child: Text(
                    '¿Olvidaste tu contraseña?',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(24),

            // Login button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: authState.isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: authState.isLoading
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
                onPressed: () => context.push(AppRoutes.register),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
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
            const Gap(20),

            // Divider
            Text(
              'o',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textHint,
              ),
            ),
            const Gap(12),

            // Guest mode
            GestureDetector(
              onTap: () => context.go(AppRoutes.home),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const Gap(6),
                  Text(
                    'Continuar como invitado',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Field label ────────────────────────────────────────
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

  // ── Error banner ───────────────────────────────────────
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
