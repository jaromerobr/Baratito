/// Detalle de seguimiento de un pedido: animación del paquete + línea de tiempo
/// de estados + productos. El comprador entra desde "Mis compras".
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';
import 'package:baratito/widgets/baratito_app_bar.dart';
import 'package:baratito/widgets/minio_image.dart';
import '../../reviews/presentation/widgets/rate_user_sheet.dart';
import '../domain/order_tracking_model.dart';
import 'widgets/package_tracker.dart';
import 'widgets/delivery_info.dart';

class OrderTrackingScreen extends ConsumerWidget {
  final PedidoTracking pedido;
  const OrderTrackingScreen({super.key, required this.pedido});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: const BaratitoAppBar(title: Text('Seguimiento del pedido')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── Animación del paquete ──
          Container(
            padding: const EdgeInsets.fromLTRB(8, 18, 8, 14),
            decoration: BoxDecoration(
              color: context.palette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.palette.divider),
            ),
            child: PackageTracker(
              currentStep: pedido.currentStep,
              rejected: pedido.isRejected,
            ),
          ),
          const Gap(14),

          if (pedido.isRejected) _RejectedBanner(reason: pedido.rejectedReason),
          if (pedido.needsProof) ...[
            _InfoBanner(
              color: AppColors.warning,
              icon: Icons.receipt_long_rounded,
              text: 'Aún no recibimos tu comprobante de pago.',
              actionLabel: 'Subir comprobante',
              onAction: () => context.push('/checkout/${pedido.id}'),
            ),
            const Gap(14),
          ],

          // ── Línea de tiempo de estados ──
          Text('Estado del pedido',
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w800)),
          const Gap(10),
          _Timeline(pedido: pedido),
          const Gap(20),

          // ── Productos ──
          Text('Productos (${pedido.itemCount})',
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w800)),
          const Gap(10),
          ...pedido.lines.map((l) => _LineTile(line: l)),
          const Gap(16),

          // ── Datos de entrega ──
          DeliveryInfoCard(pedido: pedido),
          const Gap(16),

          // ── Total ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.palette.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.palette.divider),
            ),
            child: Column(
              children: [
                _row(context, 'Envío', '\$${pedido.shippingFee.toStringAsFixed(2)}'),
                const Gap(6),
                _row(context, 'Total pagado', pedido.priceLabel, bold: true),
              ],
            ),
          ),

          // ── Calificar vendedores (al entregar) ──
          if (pedido.isDelivered) ...[
            const Gap(20),
            Text('Califica a los vendedores',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w800)),
            const Gap(4),
            Text('Tu opinión ayuda a otros compradores.',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: context.palette.textSecondary)),
            const Gap(8),
            ...pedido.sellers.map((s) => Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => showRateUserSheet(
                      context: context,
                      revieweeId: s.sellerId,
                      revieweeName: s.sellerName,
                      orderId: s.orderId,
                    ),
                    icon: const Icon(Icons.star_rounded, size: 18),
                    label: Text('Calificar a ${s.sellerName}',
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13, color: context.palette.textSecondary)),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: bold ? 16 : 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: bold ? AppColors.primary : context.palette.textPrimary)),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  final PedidoTracking pedido;
  const _Timeline({required this.pedido});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(OrderStages.count, (i) {
        final reached = !pedido.isRejected && i <= pedido.currentStep;
        final isCurrent = !pedido.isRejected && i == pedido.currentStep;
        final isLast = i == OrderStages.count - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: reached
                          ? AppColors.primary
                          : context.palette.inputFill,
                    ),
                    child: Icon(
                      reached ? Icons.check_rounded : OrderStages.icons[i],
                      size: 16,
                      color:
                          reached ? Colors.white : context.palette.textHint,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: (reached && i < pedido.currentStep)
                            ? AppColors.primary
                            : context.palette.divider,
                      ),
                    ),
                ],
              ),
              const Gap(12),
              Padding(
                padding: const EdgeInsets.only(bottom: 18, top: 4),
                child: Text(
                  OrderStages.labels[i],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                    color: reached
                        ? context.palette.textPrimary
                        : context.palette.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _LineTile extends StatelessWidget {
  final PedidoLine line;
  const _LineTile({required this.line});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          MinioImage(
            objectKey: line.imageKey,
            width: 52,
            height: 52,
            borderRadius: BorderRadius.circular(10),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.productTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Text('Vendedor: ${line.sellerName}',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: context.palette.textSecondary)),
              ],
            ),
          ),
          Text('\$${line.price.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
        ],
      ),
    );
  }
}

class _RejectedBanner extends StatelessWidget {
  final String? reason;
  const _RejectedBanner({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cancel_rounded, color: AppColors.error),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pedido rechazado',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error)),
                if (reason != null && reason!.isNotEmpty) ...[
                  const Gap(2),
                  Text(reason!,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: context.palette.textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  final String actionLabel;
  final VoidCallback onAction;
  const _InfoBanner({
    required this.color,
    required this.icon,
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const Gap(10),
          Expanded(
            child: Text(text,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: context.palette.textPrimary)),
          ),
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }
}
