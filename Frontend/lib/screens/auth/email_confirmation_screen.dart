import 'dart:async';
import 'package:baratito/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../../widgets/auth/primary_button.dart';

class EmailConfirmationScreen extends StatefulWidget {
  final String email;
  const EmailConfirmationScreen({super.key, required this.email});

  @override
  State<EmailConfirmationScreen> createState() => _EmailConfirmationScreenState();
}

class _EmailConfirmationScreenState extends State<EmailConfirmationScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  int _resendCooldown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_codeCtrl.text.length != 6) return;
    
    setState(() => _loading = true);
    final error = await context.read<AuthProvider>().verifySignupCode(
      widget.email,
      _codeCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0) return;

    final error = await context.read<AuthProvider>().resendSignupCode(widget.email);
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código reenviado')),
      );
      _startCooldown();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verificación')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: AppColors.secondary,
              ),
              const SizedBox(height: 24),
              Text(
                'Confirma tu cuenta',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Enviamos un código de 6 dígitos a ${widget.email}. Ingrésalo aquí para activar tu cuenta.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.palette.textSecondary),
              ),
              const SizedBox(height: 32),
              AuthTextField(
                controller: _codeCtrl,
                label: 'Código de 6 dígitos',
                keyboardType: TextInputType.number,
                maxLength: 6,
                validator: Validators.otpCode,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Confirmar cuenta',
                loading: _loading,
                onPressed: _verify,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _resendCooldown > 0 ? null : _resend,
                child: Text(
                  _resendCooldown > 0
                      ? 'Reenviar en ${_resendCooldown}s'
                      : 'Reenviar código',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
