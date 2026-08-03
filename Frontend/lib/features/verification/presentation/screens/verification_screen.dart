/// Identity verification flow.
///
/// Shows a different body depending on the user's status:
/// - verified  → success
/// - pending   → "en revisión"
/// - rejected / not submitted → capture form (cédula front+back, live selfie)
library;

import 'package:flutter/material.dart';
import 'package:baratito/widgets/baratito_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:camera/camera.dart' show XFile;
import 'dart:typed_data';
import '../../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/verification_provider.dart';
import 'guided_camera_screen.dart';

class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gate = ref.watch(verifyGateProvider);

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: BaratitoAppBar(
        title: Text('Verificación de identidad',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: switch (gate) {
          VerifyGate.loading => const Center(child: CircularProgressIndicator()),
          VerifyGate.verified => const _StatusView(
              icon: Icons.verified_rounded,
              color: AppColors.success,
              title: '¡Estás verificado!',
              message:
                  'Tu identidad fue confirmada. Ya puedes publicar y comprar con confianza.',
            ),
          VerifyGate.pending => const _StatusView(
              icon: Icons.hourglass_top_rounded,
              color: AppColors.warning,
              title: 'Verificación en revisión',
              message:
                  'Una persona de nuestro equipo revisará tu cédula y tu selfie para confirmar tu identidad.\n\nLa revisión tarda máximo 2 horas, dentro del horario de atención (8:00 a.m. – 12:00 a.m.). Si la envías fuera de ese horario, se revisará al día siguiente.\n\nTe avisaremos cuando esté lista.',
              showRefresh: true,
            ),
          VerifyGate.notLoggedIn => _StatusView(
              icon: Icons.lock_outline_rounded,
              color: context.palette.textHint,
              title: 'Inicia sesión',
              message: 'Necesitas una cuenta para verificarte.',
            ),
          VerifyGate.rejected ||
          VerifyGate.notSubmitted =>
            const _CaptureForm(),
        },
      ),
    );
  }
}

// ── Status view (verified / pending / etc.) ─────────────
class _StatusView extends ConsumerWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final bool showRefresh;

  const _StatusView({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.showRefresh = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 52, color: color),
            ),
            const Gap(20),
            Text(title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: context.palette.textPrimary)),
            const Gap(10),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 14, height: 1.5, color: context.palette.textSecondary)),
            if (showRefresh) ...[
              const Gap(24),
              OutlinedButton.icon(
                onPressed: () {
                  ref.invalidate(myVerificationProvider);
                  ref.invalidate(currentUserProfileProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar estado'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Capture form ────────────────────────────────────────
class _CaptureForm extends ConsumerStatefulWidget {
  const _CaptureForm();

  @override
  ConsumerState<_CaptureForm> createState() => _CaptureFormState();
}

class _CaptureFormState extends ConsumerState<_CaptureForm> {
  Uint8List? _front;
  Uint8List? _back;
  Uint8List? _selfie;
  bool _loading = false;

  /// Abre la cámara guiada (cuadrícula para cédula, óvalo para rostro)
  /// y devuelve los bytes de la foto capturada.
  Future<Uint8List?> _capture({
    required GuidedCaptureMode mode,
    required String title,
    required String instruction,
  }) async {
    final file = await Navigator.of(context).push<XFile?>(
      MaterialPageRoute(
        builder: (_) => GuidedCameraScreen(
          mode: mode,
          title: title,
          instruction: instruction,
        ),
      ),
    );
    if (file == null) return null;
    return file.readAsBytes();
  }

  Future<void> _submit() async {
    if (_front == null || _back == null || _selfie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa las 3 fotos para continuar')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(verificationRepositoryProvider).submit(
            cedulaFront: _front!,
            cedulaBack: _back!,
            selfie: _selfie!,
          );
      ref.invalidate(myVerificationProvider);
      ref.invalidate(currentUserProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Enviado! Tu verificación está en revisión.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo enviar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rejected = ref.watch(verifyGateProvider) == VerifyGate.rejected;
    final reason = ref.watch(myVerificationProvider).maybeWhen(
          data: (v) => v?.rejectionReason,
          orElse: () => null,
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (rejected)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.error.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withAlpha(80)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cancel_outlined, color: AppColors.error),
                const Gap(10),
                Expanded(
                  child: Text(
                    reason == null || reason.isEmpty
                        ? 'Tu verificación anterior fue rechazada. Vuelve a intentarlo.'
                        : 'Rechazada: $reason',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: context.palette.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        Text(
          'Para comprar o vender necesitas verificar tu identidad. Es rápido y seguro 🔒',
          style: GoogleFonts.poppins(
              fontSize: 14, height: 1.5, color: context.palette.textSecondary),
        ),
        const Gap(14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withAlpha(60)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.schedule_rounded,
                  size: 20, color: AppColors.primary),
              const Gap(10),
              Expanded(
                child: Text(
                  'Validamos tu identidad de forma automática. Si hace falta '
                  'una revisión manual, una persona de nuestro equipo la revisa '
                  'en máximo 2 horas, dentro del horario de atención '
                  '(8:00 a.m. – 12:00 a.m.). Fuera de ese horario, se revisa '
                  'al día siguiente.',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    height: 1.45,
                    color: context.palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Gap(20),
        _CaptureTile(
          label: 'Cédula — parte frontal',
          hint: 'Ubícala dentro del marco con cuadrícula',
          icon: Icons.badge_outlined,
          bytes: _front,
          onTap: () async {
            final b = await _capture(
              mode: GuidedCaptureMode.document,
              title: 'Cédula — parte frontal',
              instruction:
                  'Ubica el frente de tu cédula dentro del marco, sin brillos',
            );
            if (b != null) setState(() => _front = b);
          },
        ),
        const Gap(12),
        _CaptureTile(
          label: 'Cédula — parte posterior',
          hint: 'Ubícala dentro del marco con cuadrícula',
          icon: Icons.badge_outlined,
          bytes: _back,
          onTap: () async {
            final b = await _capture(
              mode: GuidedCaptureMode.document,
              title: 'Cédula — parte posterior',
              instruction:
                  'Ubica el reverso de tu cédula dentro del marco, sin brillos',
            );
            if (b != null) setState(() => _back = b);
          },
        ),
        const Gap(12),
        _CaptureTile(
          label: 'Selfie en vivo',
          hint: 'Ubica tu rostro dentro del óvalo',
          icon: Icons.face_retouching_natural,
          bytes: _selfie,
          onTap: () async {
            final b = await _capture(
              mode: GuidedCaptureMode.face,
              title: 'Selfie',
              instruction:
                  'Ubica tu rostro dentro del óvalo, con buena luz y sin gorra',
            );
            if (b != null) setState(() => _selfie = b);
          },
        ),
        const Gap(24),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text('Enviar verificación',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

class _CaptureTile extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final Uint8List? bytes;
  final VoidCallback onTap;

  const _CaptureTile({
    required this.label,
    required this.hint,
    required this.icon,
    required this.bytes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final done = bytes != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: done ? AppColors.success : context.palette.divider,
            width: done ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: done
                  ? Image.memory(bytes!, width: 56, height: 56, fit: BoxFit.cover)
                  : Container(
                      width: 56,
                      height: 56,
                      color: context.palette.inputFill,
                      child: Icon(icon, color: AppColors.primary),
                    ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.palette.textPrimary)),
                  const Gap(2),
                  Text(hint,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: context.palette.textSecondary)),
                ],
              ),
            ),
            Icon(
              done ? Icons.check_circle : Icons.camera_alt_outlined,
              color: done ? AppColors.success : AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
