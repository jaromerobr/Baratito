/// Admin — confirm buyer payments and trigger seller payouts.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';
import '../../data/admin_repository.dart';
import '../providers/admin_provider.dart';

class AdminPaymentsScreen extends ConsumerWidget {
  const AdminPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminCheckoutsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(commissionSummaryProvider);
        ref.invalidate(adminCheckoutsProvider);
        await ref.read(adminCheckoutsProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _CommissionSummary(),
          const Gap(16),
          Text('Pagos por revisar',
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w700)),
          const Gap(8),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Error: $e'),
            data: (items) {
              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text('No hay pagos por revisar',
                        style: GoogleFonts.poppins(
                            color: context.palette.textSecondary)),
                  ),
                );
              }
              return Column(
                children: [
                  for (final it in items) ...[
                    _CheckoutCard(item: it),
                    const Gap(10),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Commission summary header ───────────────────────────
class _CommissionSummary extends ConsumerWidget {
  const _CommissionSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(commissionSummaryProvider);
    return async.maybeWhen(
      data: (m) {
        double d(String k) => (m[k] as num?)?.toDouble() ?? 0;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Comisión ganada por Baratito',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.white70)),
              Text('\$${d('commission_earned').toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const Gap(8),
              Row(
                children: [
                  _MiniStat(
                      label: 'Ventas brutas',
                      value: '\$${d('gross_paid').toStringAsFixed(2)}'),
                  const Gap(16),
                  _MiniStat(
                      label: 'Por pagar a vendedores',
                      value: '\$${d('payouts_pending').toStringAsFixed(2)}'),
                ],
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox(
        height: 90,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ],
    );
  }
}

class _CheckoutCard extends ConsumerStatefulWidget {
  final AdminCheckoutItem item;
  const _CheckoutCard({required this.item});

  @override
  ConsumerState<_CheckoutCard> createState() => _CheckoutCardState();
}

class _CheckoutCardState extends ConsumerState<_CheckoutCard> {
  bool _working = false;

  Future<void> _confirm() async {
    setState(() => _working = true);
    try {
      await ref.read(adminRepositoryProvider).confirmCheckout(widget.item.id);
      ref.invalidate(adminCheckoutsProvider);
      ref.invalidate(adminOverviewProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago confirmado · payouts generados')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _working = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _viewProof() async {
    final url =
        await ref.read(adminRepositoryProvider).proofSignedUrl(widget.item.proofPath);
    if (!mounted || url == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Future<void> _reject() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Rechazar comprobante?'),
        content: const Text(
            'El pedido volverá a "pendiente de pago" y el comprador '
            'podrá subir un comprobante válido de nuevo.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _working = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .rejectCheckoutProof(widget.item.id);
      ref.invalidate(adminCheckoutsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comprobante rechazado')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _working = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    // El vendedor recibe: productos − comisión (el envío es de Baratito).
    final sellerGets = it.total - it.shippingFee - it.platformFee;
    final awaiting = it.status == 'awaiting_confirmation';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(it.buyerName,
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(it.buyerEmail,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: context.palette.textSecondary)),
                    Text(
                        DateFormat('dd/MM/yyyy HH:mm')
                            .format(it.createdAt.toLocal()),
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: context.palette.textHint)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (awaiting ? AppColors.warning : context.palette.textHint)
                      .withAlpha(28),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                    awaiting ? 'Por confirmar' : 'Esperando pago',
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: awaiting
                            ? AppColors.warning
                            : context.palette.textSecondary)),
              ),
            ],
          ),
          const Gap(10),
          _MoneyRow(label: 'Total pagado', value: it.total, bold: true),
          _MoneyRow(label: 'Envío (Baratito)', value: it.shippingFee),
          _MoneyRow(
              label: 'Comisión Baratito (8%)',
              value: it.platformFee,
              color: AppColors.success),
          _MoneyRow(label: 'A pagar a vendedores', value: sellerGets),
          if (it.ocrAmount != null) ...[
            const Gap(6),
            Row(
              children: [
                Icon(
                  (it.ocrAmount! - it.total).abs() <= 0.01
                      ? Icons.check_circle
                      : Icons.warning_amber_rounded,
                  size: 16,
                  color: (it.ocrAmount! - it.total).abs() <= 0.01
                      ? AppColors.success
                      : AppColors.warning,
                ),
                const Gap(6),
                Expanded(
                  child: Text(
                    'OCR leyó: \$${it.ocrAmount!.toStringAsFixed(2)}'
                    '${it.autoConfirmed ? " · validado automáticamente" : ""}',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: context.palette.textSecondary),
                  ),
                ),
              ],
            ),
          ],
          const Gap(12),
          // Wrap: si los dos botones no caben a lo ancho, pasan a dos líneas
          // (evita el "right overflowed" en pantallas angostas).
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 8,
            children: [
              if (it.proofPath != null)
                OutlinedButton.icon(
                  onPressed: _viewProof,
                  icon: const Icon(Icons.receipt_long, size: 18),
                  label: const Text('Ver comprobante'),
                ),
              if (awaiting && it.proofPath != null)
                OutlinedButton.icon(
                  onPressed: _working ? null : _reject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Rechazar'),
                ),
              if (awaiting)
                ElevatedButton.icon(
                  onPressed: _working ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                  icon: _working
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check, size: 18),
                  label: const Text('Confirmar pago'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;
  final Color? color;
  const _MoneyRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: context.palette.textSecondary)),
          const Spacer(),
          Text('\$${value.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: color ?? context.palette.textPrimary)),
        ],
      ),
    );
  }
}
