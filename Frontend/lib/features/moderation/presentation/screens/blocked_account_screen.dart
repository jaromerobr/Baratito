/// Pantalla que ve un usuario cuya CUENTA fue bloqueada por el admin. Muestra el
/// motivo y permite enviar una apelación (o cerrar sesión).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/moderation_providers.dart';

class BlockedAccountScreen extends ConsumerStatefulWidget {
  const BlockedAccountScreen({super.key});

  @override
  ConsumerState<BlockedAccountScreen> createState() =>
      _BlockedAccountScreenState();
}

class _BlockedAccountScreenState extends ConsumerState<BlockedAccountScreen> {
  final _appealCtrl = TextEditingController();
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _appealCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendAppeal() async {
    final msg = _appealCtrl.text.trim();
    if (msg.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(moderationRepositoryProvider).submitAppeal(msg);
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ban = ref.watch(banStatusProvider).asData?.value;

    return Scaffold(
      backgroundColor: context.palette.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Gap(24),
              const Icon(Icons.gpp_bad_rounded, size: 72, color: AppColors.error),
              const Gap(16),
              Text('Tu cuenta está bloqueada',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              const Gap(8),
              Text(
                ban?.reason != null && ban!.reason!.isNotEmpty
                    ? 'Motivo: ${ban.reason}'
                    : 'Un administrador bloqueó tu cuenta.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 14, color: context.palette.textSecondary),
              ),
              const Gap(28),
              if (_sent)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(22),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Recibimos tu apelación. La revisaremos y te avisaremos.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: context.palette.textPrimary),
                  ),
                )
              else ...[
                Text('¿Crees que es un error? Envía una apelación:',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const Gap(10),
                TextField(
                  controller: _appealCtrl,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'Explica por qué deberíamos revisar tu caso…',
                    filled: true,
                    fillColor: context.palette.inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const Gap(8),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _sending ? null : _sendAppeal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text('Enviar apelación',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
              const Spacer(),
              TextButton(
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (context.mounted) context.go('/home');
                },
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
