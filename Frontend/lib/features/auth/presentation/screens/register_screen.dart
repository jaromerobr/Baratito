// Register screen — Baratito branded style.
//
// Green header strip + card with registration fields + role selector.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:email_validator/email_validator.dart';
import 'package:provider/provider.dart';
import 'package:gap/gap.dart';
import '../../../../core/router.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../domain/user_model.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  UserRole _selectedRole = UserRole.buyer;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(authControllerProvider.notifier).clearMessages();

    final success = await ref.read(authControllerProvider.notifier).register(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _fullNameController.text,
          role: _selectedRole,
        );

    if (success && mounted) {
      context.go(AppRoutes.verifyEmail);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          // Header bar
          _buildHeaderBar(cs),

          // Scrollable form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Crear cuenta',
                              style: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                              ),
                            ),
                            const Gap(4),
                            Text(
                              'Únete a la comunidad Baratito',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(28),

                      // Error
                      if (authState.errorMessage != null) ...[
                        _buildErrorBanner(authState.errorMessage!, cs),
                        const Gap(16),
                      ],

                      // Full name
                      _buildLabel('Nombre completo', cs),
                      const Gap(8),
                      TextFormField(
                        controller: _fullNameController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: 'Ingresa tu nombre completo',
                          prefixIcon: Icon(Icons.person_outline_rounded,
                              color: cs.outline, size: 22),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Ingresa tu nombre completo';
                          }
                          if (v.trim().length < 3) {
                            return 'Mínimo 3 caracteres';
                          }
                          return null;
                        },
                      ),
                      const Gap(18),

                      // Email
                      _buildLabel('Correo electrónico', cs),
                      const Gap(8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
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
                      const Gap(18),

                      // Password
                      _buildLabel('Contraseña', cs),
                      const Gap(8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: 'Mínimo 8 caracteres',
                          prefixIcon: Icon(Icons.lock_outline_rounded,
                              color: cs.outline, size: 22),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: cs.outline, size: 22,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Ingresa una contraseña';
                          }
                          if (v.length < 8) {
                            return 'Mínimo 8 caracteres';
                          }
                          if (!RegExp(r'[A-Z]').hasMatch(v)) {
                            return 'Debe contener al menos una mayúscula';
                          }
                          if (!RegExp(r'[a-z]').hasMatch(v)) {
                            return 'Debe contener al menos una minúscula';
                          }
                          if (!RegExp(r'[0-9]').hasMatch(v)) {
                            return 'Debe contener al menos un número';
                          }
                          if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(v)) {
                            return 'Debe contener al menos un carácter especial';
                          }
                          return null;
                        },
                      ),
                      const Gap(18),

                      // Confirm password
                      _buildLabel('Confirmar contraseña', cs),
                      const Gap(8),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          hintText: 'Repite tu contraseña',
                          prefixIcon: Icon(Icons.lock_outline_rounded,
                              color: cs.outline, size: 22),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: cs.outline, size: 22,
                            ),
                            onPressed: () => setState(() =>
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Confirma tu contraseña';
                          }
                          if (v != _passwordController.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                      const Gap(24),

                      // Role selector
                      _buildLabel('¿Qué quieres hacer en Baratito?', cs),
                      const Gap(12),
                      _buildRoleSelector(cs),
                      const Gap(32),

                      // Register button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed:
                              authState.isLoading ? null : _handleRegister,
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
                                  'Crear cuenta',
                                  style: GoogleFonts.poppins(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const Gap(20),

                      // Login link
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '¿Ya tienes cuenta? ',
                              style: GoogleFonts.poppins(
                                color: cs.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Text(
                                'Inicia sesión',
                                style: GoogleFonts.poppins(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header bar ─────────────────────────────────────────
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

  // ── Label ──────────────────────────────────────────────
  Widget _buildLabel(String text, ColorScheme cs) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
    );
  }

  // ── Role selector chips ────────────────────────────────
  Widget _buildRoleSelector(ColorScheme cs) {
    return Row(
      children: UserRole.values.map((role) {
        final isSelected = _selectedRole == role;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: role != UserRole.values.last ? 6 : 0,
              left: role != UserRole.values.first ? 6 : 0,
            ),
            child: GestureDetector(
              onTap: () => setState(() => _selectedRole = role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? cs.primary : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? cs.primary : cs.outline,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: cs.primary.withAlpha(40),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  children: [
                    Icon(
                      _roleIcon(role),
                      size: 22,
                      color: isSelected
                          ? cs.onPrimary
                          : cs.onSurfaceVariant,
                    ),
                    const Gap(6),
                    Text(
                      role.label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? cs.onPrimary
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _roleIcon(UserRole role) {
    return switch (role) {
      UserRole.buyer => Icons.shopping_bag_outlined,
      UserRole.seller => Icons.storefront_outlined,
      UserRole.both => Icons.swap_horiz_rounded,
    };
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
