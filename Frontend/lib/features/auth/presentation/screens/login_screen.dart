// Login screen — Matches the Baratito brand mockup.
//
// Gradient header with floating icons, big "B" logo,
// card with email/password fields, remember me, and guest mode.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:email_validator/email_validator.dart';
import 'package:provider/provider.dart';
import 'package:gap/gap.dart';
import 'dart:math' as math;
import '../../../../core/router.dart';
import '../../../../core/theme/theme_provider.dart';
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

    final success = await ref
        .read(authControllerProvider.notifier)
        .signIn(_emailController.text, _passwordController.text);

    if (success && mounted) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final size = MediaQuery.of(context).size;
    final cs = Theme.of(context).colorScheme;
    // context.watch for theme icon reactivity
    final themeModel = context.watch<ThemeModel>();

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header with gradient + logo ────────────
            _buildHeader(size, cs, themeModel),

            // ── Card form ──────────────────────────────
            Transform.translate(
              offset: const Offset(0, -40),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildFormCard(authState, cs),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────
  Widget _buildHeader(Size size, ColorScheme cs, ThemeModel themeModel) {
    return SizedBox(
      height: size.height * 0.42,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Secondary background
          Positioned.fill(child: Container(color: cs.secondary)),

          // Primary diagonal shape (top-right)
          Positioned(
            top: -30,
            right: -60,
            child: Transform.rotate(
              angle: -math.pi / 6,
              child: Container(
                width: 250,
                height: 350,
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(180),
                  borderRadius: BorderRadius.circular(60),
                ),
              ),
            ),
          ),

          // Primary diagonal shape (bottom-left)
          Positioned(
            bottom: 20,
            left: -80,
            child: Transform.rotate(
              angle: math.pi / 5,
              child: Container(
                width: 200,
                height: 300,
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(140),
                  borderRadius: BorderRadius.circular(60),
                ),
              ),
            ),
          ),

          // Theme toggle button (top right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: IconButton(
              icon: Icon(
                themeModel.isDarkMode ? Icons.wb_sunny : Icons.nights_stay,
                color: cs.onPrimary,
              ),
              onPressed: () => context.read<ThemeModel>().toggleTheme(),
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
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withAlpha(30),
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
                        color: cs.primary,
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
                    color: cs.onSecondary,
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
                    color: cs.onSecondary,
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
    final cs = Theme.of(context).colorScheme;
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
            color: cs.onPrimary.withAlpha(60),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: cs.onPrimary.withAlpha(200), size: 22),
        ),
      ),
    );
  }

  // ── FORM CARD ──────────────────────────────────────────
  Widget _buildFormCard(AuthControllerState authState, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withAlpha(18),
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
                color: cs.onSurface,
              ),
            ),
            const Gap(4),
            Text(
              'Qué bueno verte de nuevo. Inicia sesión para\nseguir encontrando grandes oportunidades.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const Gap(24),

            // Error banner
            if (authState.errorMessage != null) ...[
              _buildErrorBanner(authState.errorMessage!, cs),
              const Gap(16),
            ],

            // Email field
            _buildFieldLabel('Correo electrónico o usuario', cs),
            const Gap(8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: 'Ingresa tu correo o usuario',
                prefixIcon: Icon(
                  Icons.person_outline_rounded,
                  color: cs.outline,
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
            _buildFieldLabel('Contraseña', cs),
            const Gap(8),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleLogin(),
              decoration: InputDecoration(
                hintText: 'Ingresa tu contraseña',
                prefixIcon: Icon(
                  Icons.lock_outline_rounded,
                  color: cs.outline,
                  size: 22,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: cs.outline,
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
                Flexible(
                  child: GestureDetector(
                    onTap: () => setState(() => _rememberMe = !_rememberMe),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                        const Gap(6),
                        Flexible(
                          child: Text(
                            'Recordarme',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(8),
                // Forgot password
                Flexible(
                  child: GestureDetector(
                    onTap: () => context.push(AppRoutes.forgotPassword),
                    child: Text(
                      '¿Olvidaste tu contraseña?',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
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
                child: authState.isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: cs.onPrimary,
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
              style: GoogleFonts.poppins(fontSize: 13, color: cs.outline),
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
                    color: cs.primary,
                    size: 20,
                  ),
                  const Gap(6),
                  Text(
                    'Continuar como invitado',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: cs.primary,
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
  Widget _buildFieldLabel(String text, ColorScheme cs) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
    );
  }

  // ── Error banner ───────────────────────────────────────
  Widget _buildErrorBanner(String message, ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.error.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.error.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: cs.error, size: 20),
          const Gap(10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                color: cs.error,
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
