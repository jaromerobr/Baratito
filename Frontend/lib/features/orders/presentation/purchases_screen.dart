/// "Mis compras" — pedidos del comprador con su estado de entrega. Al tocar un
/// pedido se abre el seguimiento con la animación del paquete.
library;

import 'package:flutter/material.dart';
import 'package:baratito/widgets/baratito_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';
import 'package:baratito/widgets/minio_image.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../domain/order_tracking_model.dart';
import '../data/order_repository.dart';
import 'order_tracking_screen.dart';

final _orderRepositoryProvider =
    Provider<OrderRepository>((ref) => OrderRepository());

final myPedidosProvider = FutureProvider<List<PedidoTracking>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(_orderRepositoryProvider).getMyPedidos();
});

class PurchasesScreen extends ConsumerWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myPedidosProvider);

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: BaratitoAppBar(
        title: Text('Mis compras',
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
                  Icon(Icons.shopping_bag_outlined,
                      size: 56, color: context.palette.textHint),
                  const Gap(12),
                  Text('Aún no tienes compras',
                      style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const Gap(4),
                  Text('Cuando compres algo, aparecerá aquí',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: context.palette.textSecondary)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(myPedidosProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Gap(10),
              itemBuilder: (context, i) => _PedidoCard(pedido: items[i]),
            ),
          );
        },
      ),
    );
  }
}

class _PedidoCard extends StatelessWidget {
  final PedidoTracking pedido;
  const _PedidoCard({required this.pedido});

  Color _statusColor() {
    if (pedido.isRejected) return AppColors.error;
    if (pedido.isDelivered) return AppColors.success;
    if (pedido.needsProof) return AppColors.warning;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    return Material(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(pedido: pedido),
        )),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              MinioImage(
                objectKey: pedido.coverImageKey,
                width: 60,
                height: 60,
                borderRadius: BorderRadius.circular(10),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pedido.itemCount == 1
                          ? pedido.lines.first.productTitle
                          : 'Pedido · ${pedido.itemCount} productos',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const Gap(2),
                    Text(
                      DateFormat('dd/MM/yyyy').format(pedido.createdAt.toLocal()),
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: context.palette.textHint),
                    ),
                    const Gap(6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withAlpha(22),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(pedido.statusLabel,
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: color)),
                    ),
                  ],
                ),
              ),
              const Gap(8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(pedido.priceLabel,
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                  const Gap(4),
                  Icon(Icons.chevron_right, color: context.palette.textHint),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
