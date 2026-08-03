/// Admin — control de entrega de cada pedido: avanzar de etapa o rechazar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';
import '../../../orders/domain/order_tracking_model.dart';
import '../../../orders/presentation/widgets/delivery_info.dart';
import '../providers/admin_provider.dart';

class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminPedidosProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Text('No hay pedidos todavía',
                style: GoogleFonts.poppins(
                    color: context.palette.textSecondary)),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.refresh(adminPedidosProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Gap(10),
            itemBuilder: (context, i) => _AdminPedidoTile(pedido: items[i]),
          ),
        );
      },
    );
  }
}

class _AdminPedidoTile extends ConsumerStatefulWidget {
  final PedidoTracking pedido;
  const _AdminPedidoTile({required this.pedido});

  @override
  ConsumerState<_AdminPedidoTile> createState() => _AdminPedidoTileState();
}

class _AdminPedidoTileState extends ConsumerState<_AdminPedidoTile> {
  bool _working = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _working = true);
    try {
      await action();
      ref.invalidate(adminPedidosProvider);
      ref.invalidate(adminCheckoutsProvider);
      ref.invalidate(commissionSummaryProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _reject() async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar pedido'),
        content: TextField(
          controller: ctrl,
          maxLines: 2,
          decoration: const InputDecoration(hintText: 'Motivo (opcional)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
    if (reason == null) return; // canceló
    await _run(() => ref
        .read(adminRepositoryProvider)
        .rejectOrder(widget.pedido.id, reason));
  }

  Color _statusColor(PedidoTracking p) {
    if (p.isRejected) return AppColors.error;
    if (p.isDelivered) return AppColors.success;
    if (p.needsProof) return AppColors.warning;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pedido;
    final color = _statusColor(p);
    final terminal = p.isRejected || p.isDelivered;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.palette.divider),
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
                    Text(p.buyerName ?? 'Comprador',
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(
                        '${p.itemCount} producto(s) · '
                        '${DateFormat('dd/MM/yyyy').format(p.createdAt.toLocal())}',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: context.palette.textSecondary)),
                  ],
                ),
              ),
              Text(p.priceLabel,
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
            ],
          ),
          const Gap(8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha(22),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(p.statusLabel,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ),
          const Gap(10),
          DeliveryInfoCard(pedido: p),
          if (!terminal) ...[
            const Gap(12),
            if (_working)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(6),
                  child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              )
            else
              _actions(p),
          ],
        ],
      ),
    );
  }

  Widget _actions(PedidoTracking p) {
    final buttons = <Widget>[];

    if (p.needsProof) {
      buttons.add(Text('Esperando comprobante del comprador',
          style: GoogleFonts.poppins(
              fontSize: 12, color: context.palette.textSecondary)));
    } else if (p.paymentStatus == 'awaiting_confirmation') {
      buttons.add(FilledButton.icon(
        onPressed: () => _run(() =>
            ref.read(adminRepositoryProvider).confirmCheckout(p.id)),
        icon: const Icon(Icons.check_rounded, size: 18),
        label: const Text('Aceptar pago'),
      ));
    } else if (p.paymentStatus == 'paid') {
      final next = nextFulfillmentStatus(p.fulfillmentStatus);
      final label = advanceLabel(p.fulfillmentStatus);
      if (next != null && label != null) {
        buttons.add(FilledButton.icon(
          onPressed: () => _run(
              () => ref.read(adminRepositoryProvider).setFulfillment(p.id, next)),
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: Text(label),
        ));
      }
    }

    // Rechazar disponible en cualquier etapa no terminal.
    buttons.add(OutlinedButton.icon(
      onPressed: _reject,
      style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
      icon: const Icon(Icons.close_rounded, size: 18),
      label: const Text('Rechazar'),
    ));

    return Wrap(spacing: 8, runSpacing: 8, children: buttons);
  }
}
