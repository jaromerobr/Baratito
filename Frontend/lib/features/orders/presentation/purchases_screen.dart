/// "Mis compras" — purchase history for the current user.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';
import 'package:baratito/widgets/minio_image.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/order_repository.dart';

final _orderRepositoryProvider = Provider<OrderRepository>((ref) => OrderRepository());

final myPurchasesProvider = FutureProvider<List<PurchaseItem>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(_orderRepositoryProvider).getMyPurchases();
});

class PurchasesScreen extends ConsumerWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myPurchasesProvider);

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
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
            onRefresh: () async => ref.refresh(myPurchasesProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Gap(10),
              itemBuilder: (context, i) => _PurchaseTile(item: items[i]),
            ),
          );
        },
      ),
    );
  }
}

class _PurchaseTile extends StatelessWidget {
  final PurchaseItem item;
  const _PurchaseTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          MinioImage(
            objectKey: item.productImageKey,
            width: 60,
            height: 60,
            borderRadius: BorderRadius.circular(10),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                Text('Vendedor: ${item.sellerName}',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: context.palette.textSecondary)),
                Text(DateFormat('dd/MM/yyyy').format(item.createdAt.toLocal()),
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: context.palette.textHint)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(item.priceLabel,
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
              const Gap(4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(22),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(item.status,
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
