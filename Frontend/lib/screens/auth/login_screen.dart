import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/theme_provider.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeModel>().isDarkMode;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            color: AppColors.neutral,
            onPressed: () => context.read<ThemeModel>().toggleTheme(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
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
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.go('/home'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.neutral,
                    side: const BorderSide(color: AppColors.border),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Ver como invitado'),
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
