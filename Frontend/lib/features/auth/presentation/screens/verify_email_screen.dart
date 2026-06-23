// Email verification screen — Baratito branded.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:gap/gap.dart';
import '../../../../core/router.dart';
import '../../../../core/theme/theme_provider.dart';
import '../providers/auth_provider.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkVerification() async {
    final verified = await ref
        .read(authControllerProvider.notifier)
        .checkEmailVerified();
    if (verified && mounted) {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _resendEmail() async {
    await ref.read(authControllerProvider.notifier).resendVerification();
  }

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          // Header
          _buildHeader(cs),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Animated email icon
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [cs.primary, cs.primaryContainer],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withAlpha(50),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.mark_email_unread_rounded,
                        color: cs.onPrimary,
                        size: 48,
                      ),
                    ),
                  ),
                  const Gap(28),

                  Text(
                    'Revisa tu correo',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  const Gap(12),
                  Text(
                    'Te enviamos un enlace de verificación.\nRevisa tu bandeja de entrada (y spam)\npara activar tu cuenta.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                  const Gap(14),

                  // Messages
                  if (authState.errorMessage != null)
                    _buildMessage(authState.errorMessage!, isError: true, cs: cs),
                  if (authState.successMessage != null)
                    _buildMessage(authState.successMessage!, isError: false, cs: cs),

                  const Gap(32),

                  // "Already verified" button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed:
                          authState.isLoading ? null : _checkVerification,
                      child: authState.isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: cs.onPrimary,
                              ),
                            )
                          : Text(
                              'Ya verifiqué, continuar',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const Gap(12),

                  // Resend
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: authState.isLoading ? null : _resendEmail,
                      child: Text(
                        'Reenviar correo de verificación',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Sign out
                  TextButton(
                    onPressed: _signOut,
                    child: Text(
                      'Cerrar sesión',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Gap(24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────
  Widget _buildHeader(ColorScheme cs) {
    final themeModel = context.watch<ThemeModel>();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 16,
        left: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primaryContainer],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          const Spacer(),
          Text(
            'BARATITO',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: cs.onPrimary,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          // Theme toggle
          IconButton(
            icon: Icon(
              themeModel.isDarkMode ? Icons.wb_sunny : Icons.nights_stay,
              color: cs.onPrimary,
              size: 22,
            ),
            onPressed: () => context.read<ThemeModel>().toggleTheme(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(String message, {required bool isError, required ColorScheme cs}) {
    final color = isError ? cs.error : cs.primary;
    final icon = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const Gap(10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                color: color,
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
