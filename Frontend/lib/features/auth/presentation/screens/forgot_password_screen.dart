// Forgot password screen — Baratito branded.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:email_validator/email_validator.dart';
import 'package:provider/provider.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/theme_provider.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(authControllerProvider.notifier).clearMessages();

    final success = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(_emailController.text);

    if (success && mounted) {
      setState(() => _emailSent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          // Header
          _buildHeaderBar(cs),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _emailSent
                  ? _buildSuccessView(cs)
                  : _buildFormView(authState, cs),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────
  Widget _buildHeaderBar(ColorScheme cs) {
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
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: cs.onPrimary, size: 20),
            onPressed: () => context.pop(),
          ),
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

  // ── Success view ───────────────────────────────────────
  Widget _buildSuccessView(ColorScheme cs) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Gap(60),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: cs.primary.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mark_email_read_outlined,
            color: cs.primary,
            size: 40,
          ),
        ),
        const Gap(24),
        Text(
          '¡Correo enviado!',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        const Gap(12),
        Text(
          'Revisa tu bandeja de entrada en\n${_emailController.text}\ny sigue las instrucciones para\nrestablecer tu contraseña.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: cs.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const Gap(40),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => context.pop(),
            child: Text(
              'Volver al inicio de sesión',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Form view ──────────────────────────────────────────
  Widget _buildFormView(AuthControllerState authState, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Gap(40),
        Center(
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: cs.secondary.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_reset_rounded,
              color: cs.primary,
              size: 36,
            ),
          ),
        ),
        const Gap(24),
        Center(
          child: Text(
            'Recuperar contraseña',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
        ),
        const Gap(8),
        Center(
          child: Text(
            'Ingresa tu correo y te enviaremos\nun enlace para restablecerla.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
        const Gap(32),

        if (authState.errorMessage != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: cs.error.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.error.withAlpha(60)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded,
                    color: cs.error, size: 20),
                const Gap(10),
                Expanded(
                  child: Text(
                    authState.errorMessage!,
                    style: GoogleFonts.poppins(
                      color: cs.error, fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(16),
        ],

        Text(
          'Correo electrónico',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const Gap(8),
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleReset(),
            decoration: InputDecoration(
              hintText: 'tucorreo@ejemplo.com',
              prefixIcon: Icon(Icons.email_outlined,
                  color: cs.outline, size: 22),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Ingresa tu correo';
              }
              if (!EmailValidator.validate(v.trim())) {
                return 'Correo no válido';
              }
              return null;
            },
          ),
        ),
        const Gap(28),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: authState.isLoading ? null : _handleReset,
            child: authState.isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: cs.onPrimary,
                    ),
                  )
                : Text(
                    'Enviar enlace',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
