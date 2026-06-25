/// MyListingsScreen — Shows the current seller's active, paused and sold listings.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router.dart';
import '../../data/product_repository.dart';
import '../../domain/product_model.dart';
import '../providers/product_provider.dart';

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(myListingsProvider);
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const Gap(14),
                  Expanded(
                    child: Text(
                      'Mis publicaciones',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => context.push(AppRoutes.productForm),
                      borderRadius: BorderRadius.circular(10),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          listings.when(
            data: (products) {
              if (products.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sell_outlined,
                          size: 64,
                          color: AppColors.textSecondary.withAlpha(80),
                        ),
                        const Gap(16),
                        Text(
                          'Aún no tienes publicaciones',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Gap(8),
                        Text(
                          'Publica tu primer artículo',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.textHint,
                          ),
                        ),
                        const Gap(20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text(
                            'Publicar artículo',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () => context.push(AppRoutes.productForm),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ListingRow(
                      product: products[index],
                      ref: ref,
                    ),
                    childCount: products.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(
                child:
                    CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (_, __) => SliverFillRemaining(
              child: Center(
                child: Text(
                  'Error al cargar tus publicaciones.',
                  style:
                      GoogleFonts.poppins(color: AppColors.textSecondary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Listing row ───────────────────────────────────────────

class _ListingRow extends StatelessWidget {
  final Product product;
  final WidgetRef ref;

  const _ListingRow({required this.product, required this.ref});

  String get _statusLabel {
    switch (product.status) {
      case ProductStatus.active:
        return 'Activo';
      case ProductStatus.sold:
        return 'Vendido';
      case ProductStatus.paused:
        return 'Pausado';
      case ProductStatus.deleted:
        return 'Eliminado';
    }
  }

  Color get _statusColor {
    switch (product.status) {
      case ProductStatus.active:
        return AppColors.success;
      case ProductStatus.sold:
        return AppColors.textSecondary;
      case ProductStatus.paused:
        return AppColors.warning;
      case ProductStatus.deleted:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ProductRepository();
    final imageUrl = product.primaryImagePath != null
        ? repo.getImageUrl(product.primaryImagePath!)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push(
          AppRoutes.productDetail(product.id),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppColors.inputFill),
                          errorWidget: (_, __, ___) =>
                              Container(color: AppColors.inputFill),
                        )
                      : Container(
                          color: AppColors.inputFill,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.textHint,
                          ),
                        ),
                ),
              ),
              const Gap(12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(4),
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const Gap(4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _statusColor.withAlpha(80),
                            ),
                          ),
                          child: Text(
                            _statusLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: _statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (product.isNegotiable) ...[
                          const Gap(6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Negociable',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: AppColors.accentDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Actions menu
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textSecondary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'detail',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.visibility_outlined,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const Gap(8),
                        Text(
                          'Ver publicación',
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (product.status == ProductStatus.active)
                    PopupMenuItem(
                      value: 'pause',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.pause_circle_outline_rounded,
                            size: 18,
                            color: AppColors.warning,
                          ),
                          const Gap(8),
                          Text(
                            'Pausar',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  if (product.status == ProductStatus.paused)
                    PopupMenuItem(
                      value: 'activate',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.play_circle_outline_rounded,
                            size: 18,
                            color: AppColors.success,
                          ),
                          const Gap(8),
                          Text(
                            'Activar',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AppColors.error,
                        ),
                        const Gap(8),
                        Text(
                          'Eliminar',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  final repo = ProductRepository();
                  switch (value) {
                    case 'detail':
                      context.push(AppRoutes.productDetail(product.id));
                    case 'pause':
                      await repo.updateProduct(product.id, {'status': 'paused'});
                      ref.invalidate(myListingsProvider);
                    case 'activate':
                      await repo.updateProduct(product.id, {'status': 'active'});
                      ref.invalidate(myListingsProvider);
                    case 'delete':
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Text(
                            '¿Eliminar artículo?',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          content: Text(
                            'Esta acción no se puede deshacer.',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(
                                'Cancelar',
                                style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(
                                'Eliminar',
                                style: GoogleFonts.poppins(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await repo.deleteProduct(product.id);
                        ref.invalidate(myListingsProvider);
                      }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
