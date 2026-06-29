/// Checkout payment — the buyer pays the total to Baratito and uploads
/// the transfer proof. Baratito later confirms and pays each seller.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import '../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';
import '../data/payment_repository.dart';

final _paymentRepoProvider = Provider<PaymentRepository>((ref) => PaymentRepository());
final _settingsProvider =
    FutureProvider<PlatformSettings>((ref) => ref.watch(_paymentRepoProvider).getSettings());
final _checkoutProvider = FutureProvider.family<CheckoutInfo, String>(
    (ref, id) => ref.watch(_paymentRepoProvider).getCheckout(id));

class CheckoutPaymentScreen extends ConsumerStatefulWidget {
  final String checkoutId;
  const CheckoutPaymentScreen({super.key, required this.checkoutId});

  @override
  ConsumerState<CheckoutPaymentScreen> createState() =>
      _CheckoutPaymentScreenState();
}

class _CheckoutPaymentScreenState extends ConsumerState<CheckoutPaymentScreen> {
  bool _uploading = false;

  Future<void> _uploadProof() async {
    final file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      await ref
          .read(_paymentRepoProvider)
          .submitProof(widget.checkoutId, bytes);
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('¡Comprobante enviado! 🎉'),
          content: const Text(
            'Estamos verificando tu pago. Cuando lo confirmemos, '
            'tu pedido avanzará y se coordinará la entrega con cada vendedor.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/home');
                context.push('/purchases');
              },
              child: const Text('Ver mis compras'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(_settingsProvider);
    final checkoutAsync = ref.watch(_checkoutProvider(widget.checkoutId));

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        title: Text('Pagar pedido',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: checkoutAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (checkout) => settingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (settings) => ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Total
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Text('Total a pagar',
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: Colors.white70)),
                      Text('\$${checkout.totalAmount.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ],
                  ),
                ),
                const Gap(20),
                Text('Paga con transferencia a Baratito',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const Gap(4),
                Text(
                  'Realiza la transferencia por el total y sube el comprobante. '
                  'Verificamos y coordinamos la entrega con cada vendedor.',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: context.palette.textSecondary),
                ),
                const Gap(16),
                _InfoRow(label: 'Banco', value: settings.bank),
                _InfoRow(label: 'Titular', value: settings.accountName),
                if (settings.accountNumber != null)
                  _InfoRow(
                    label: 'Cuenta',
                    value: settings.accountNumber!,
                    copyable: true,
                  ),
                const Gap(24),
                if (checkout.status == 'pending_payment')
                  _UploadButton(uploading: _uploading, onTap: _uploadProof)
                else
                  _StatusBanner(status: checkout.status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;
  const _InfoRow({
    required this.label,
    required this.value,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: context.palette.textSecondary)),
          const Spacer(),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700)),
          if (copyable) ...[
            const Gap(8),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copiado')),
                );
              },
              child: const Icon(Icons.copy, size: 16, color: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }
}

class _UploadButton extends StatelessWidget {
  final bool uploading;
  final VoidCallback onTap;
  const _UploadButton({required this.uploading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: uploading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: uploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.upload_file),
        label: Text(uploading ? 'Enviando...' : 'Subir comprobante',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final (String text, Color color, IconData icon) = switch (status) {
      'paid' => ('Pago confirmado ✓', AppColors.success, Icons.check_circle),
      'awaiting_confirmation' => (
          'Comprobante en revisión',
          AppColors.warning,
          Icons.hourglass_top
        ),
      _ => ('Pedido cancelado', AppColors.error, Icons.cancel),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const Gap(10),
          Text(text,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, color: context.palette.textPrimary)),
        ],
      ),
    );
  }
}
