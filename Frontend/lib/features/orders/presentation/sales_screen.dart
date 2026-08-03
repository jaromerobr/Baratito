/// "Mis ventas" — pedidos donde el usuario actual es vendedor. Cuando el pedido
/// está entregado, puede calificar al comprador.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baratito/widgets/baratito_app_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';
import 'package:baratito/widgets/minio_image.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../reviews/presentation/providers/reviews_provider.dart';
import '../../reviews/presentation/widgets/rate_user_sheet.dart';
import '../domain/sale_model.dart';
import '../data/order_repository.dart';

final _orderRepoProvider = Provider<OrderRepository>((ref) => OrderRepository());

final mySalesProvider = FutureProvider<List<SaleGroup>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(_orderRepoProvider).getMySales();
});

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(mySalesProvider);
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: BaratitoAppBar(
        title: Text('Mis ventas',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sell_outlined,
                      size: 56, color: context.palette.textHint),
                  const Gap(12),
                  Text('Aún no tienes ventas',
                      style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(mySalesProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Gap(10),
              itemBuilder: (context, i) => _SaleCard(sale: items[i]),
            ),
          );
        },
      ),
    );
  }
}

class _SaleCard extends ConsumerWidget {
  final SaleGroup sale;
  const _SaleCard({required this.sale});

  Color _statusColor() {
    if (sale.isRejected) return AppColors.error;
    if (sale.isDelivered) return AppColors.success;
    if (sale.needsProof) return AppColors.warning;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _statusColor();
    final rated = sale.buyerId.isEmpty
        ? null
        : ref.watch(myReviewForProvider(sale.buyerId)).asData?.value;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MinioImage(
                objectKey: sale.coverImageKey,
                width: 56,
                height: 56,
                borderRadius: BorderRadius.circular(10),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sale.itemCount == 1
                          ? sale.items.first.title
                          : 'Venta · ${sale.itemCount} productos',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    Text('Comprador: ${sale.buyerName}',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: context.palette.textSecondary)),
                    Text(
                        DateFormat('dd/MM/yyyy').format(sale.createdAt.toLocal()),
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: context.palette.textHint)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(sale.totalLabel,
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                  const Gap(4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withAlpha(22),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(sale.statusLabel,
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color)),
                  ),
                ],
              ),
            ],
          ),
          if (sale.isDelivered && sale.buyerId.isNotEmpty) ...[
            const Gap(6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => showRateUserSheet(
                  context: context,
                  revieweeId: sale.buyerId,
                  revieweeName: sale.buyerName,
                  initialRating: rated,
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 34),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(
                    rated != null
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 18),
                label: Text(
                  rated != null ? 'Editar valoración' : 'Calificar comprador',
                  style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
