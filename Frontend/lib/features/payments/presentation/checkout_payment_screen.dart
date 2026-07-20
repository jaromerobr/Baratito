/// Checkout payment — el comprador transfiere el total (productos + envío)
/// al Banco de Loja de Baratito (QR/datos), sube el comprobante y la app
/// lo valida con OCR: si el monto coincide, el pago se confirma solo;
/// si no, queda en revisión manual del equipo.
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
import '../data/receipt_ocr_service.dart';

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

  Future<void> _uploadProof(CheckoutInfo checkout) async {
    final file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      // 1. OCR local del comprobante (monto + referencia).
      ReceiptOcrResult? ocr;
      try {
        ocr = await ReceiptOcrService.read(
          file.path,
          expectedTotal: checkout.totalAmount,
        );
      } catch (_) {
        ocr = null; // si el OCR falla, igual se envía a revisión manual
      }

      // 2. Subir + validar en el backend.
      final bytes = await file.readAsBytes();
      final status = await ref.read(_paymentRepoProvider).submitProof(
            widget.checkoutId,
            bytes,
            ocrAmount: ocr?.amount,
            ocrReference: ocr?.reference,
          );

      ref.invalidate(_checkoutProvider(widget.checkoutId));
      if (!mounted) return;

      final validated = status == 'paid';
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(validated
              ? '¡Pago validado! ✅'
              : 'Comprobante en revisión 🕐'),
          content: Text(validated
              ? 'Leímos tu comprobante (\$${ocr?.amount?.toStringAsFixed(2)}) '
                  'y coincide con el total. Tu pedido está confirmado; '
                  'coordinaremos la entrega.'
              : ocr?.amount != null
                  ? 'El monto leído (\$${ocr!.amount!.toStringAsFixed(2)}) no '
                      'coincide con el total (\$${checkout.totalAmount.toStringAsFixed(2)}). '
                      'Una persona del equipo lo revisará en breve.'
                  : 'No pudimos leer el monto del comprobante. '
                      'Una persona del equipo lo revisará en breve.'),
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
                // Total con desglose (productos + envío)
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
                      const Gap(6),
                      Text(
                        'Productos \$${checkout.productsSubtotal.toStringAsFixed(2)}'
                        '  ·  Envío \$${checkout.shippingFee.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const Gap(20),
                Text('Paga con transferencia a Baratito',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const Gap(4),
                Text(
                  'Transfiere el total (Banco de Loja) escaneando el QR o '
                  'usando los datos de la cuenta, y sube el comprobante. '
                  'La app lo valida al instante.',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: context.palette.textSecondary),
                ),
                const Gap(16),
                // ── QR de cobro (si está configurado) ──
                if (PaymentRepository.qrUrl(settings.qrPath) != null) ...[
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(12),
                        child: Image.network(
                          PaymentRepository.qrUrl(settings.qrPath)!,
                          width: 220,
                          height: 220,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const SizedBox(
                            width: 220,
                            height: 100,
                            child: Center(child: Text('QR no disponible')),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Gap(8),
                  Center(
                    child: Text('Escanea con tu app del Banco de Loja',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: context.palette.textSecondary)),
                  ),
                  const Gap(16),
                ],
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
                  _UploadButton(
                    uploading: _uploading,
                    onTap: () => _uploadProof(checkout),
                  )
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
          const Gap(12),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w700)),
          ),
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
