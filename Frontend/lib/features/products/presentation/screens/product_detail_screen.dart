/// ProductDetailScreen — Full product detail with photo gallery,
/// negotiable badge, seller info and action buttons.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/product_repository.dart';
import '../../domain/product_model.dart';
import '../providers/product_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'home_feed_screen.dart' show ProductCard;

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _currentPhotoIndex = 0;

  @override
  Widget build(BuildContext context) {
    final product = ref.watch(productDetailProvider(widget.productId));
    final authState = ref.watch(authStateProvider);
    final currentUserId = authState.whenOrNull(
      data: (s) => s.session?.user.id,
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: product.when(
        data: (p) {
          if (p == null) {
            return const Center(child: Text('Producto no encontrado.'));
          }
          return _ProductDetailBody(
            product: p,
            currentUserId: currentUserId,
            currentPhotoIndex: _currentPhotoIndex,
            onPhotoChanged: (i) => setState(() => _currentPhotoIndex = i),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error al cargar el producto.',
            style: GoogleFonts.poppins(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _ProductDetailBody extends ConsumerWidget {
  final Product product;
  final String? currentUserId;
  final int currentPhotoIndex;
  final void Function(int) onPhotoChanged;

  const _ProductDetailBody({
    required this.product,
    required this.currentUserId,
    required this.currentPhotoIndex,
    required this.onPhotoChanged,
  });

  bool get isOwner => currentUserId == product.sellerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ProductRepository();
    final cs = Theme.of(context).colorScheme;
    final isFavAsync = ref.watch(isFavoriteProvider(product.id));
    final isFav = isFavAsync.whenOrNull(data: (v) => v) ?? false;

    return Stack(
      children: [
        CustomScrollView(
      slivers: [
        // ── Photo gallery ──────────────────────────────
        SliverToBoxAdapter(
          child: _PhotoGallery(
            product: product,
            repo: repo,
            currentIndex: currentPhotoIndex,
            onPageChanged: onPhotoChanged,
            isFav: isFav,
            currentUserId: currentUserId,
            onFavToggle: () async {
              if (currentUserId == null) return;
              await repo.toggleFavorite(
                currentUserId!,
                product.id,
                isFav,
              );
              ref.invalidate(isFavoriteProvider(product.id));
              ref.invalidate(favoritesProvider);
            },
          ),
        ),

        // ── Content ────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Title + price row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      product.title,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(8),

              // Price + negotiable
              Row(
                children: [
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  if (product.isNegotiable) ...[
                    const Gap(10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Negociable',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const Gap(16),

              // Condition + category + brand chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.star_rounded,
                    label: product.condition.label,
                    color: AppColors.accent,
                  ),
                  if (product.categoryName != null)
                    _InfoChip(
                      icon: Icons.category_rounded,
                      label: product.categoryName!,
                      color: AppColors.primaryLight,
                    ),
                  if (product.brand != null)
                    _InfoChip(
                      icon: Icons.label_rounded,
                      label: product.brand!,
                      color: AppColors.textSecondary,
                    ),
                ],
              ),
              const Gap(24),

              // Description
              if (product.description != null &&
                  product.description!.isNotEmpty) ...[
                Text(
                  'Descripción',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Gap(8),
                Text(
                  product.description!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const Gap(24),
              ],

              // Seller card
              _SellerCard(product: product),
              const Gap(16),

              // Negotiation hint
              if (product.isNegotiable)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.accent.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: AppColors.accentDark,
                        size: 20,
                      ),
                      const Gap(10),
                      Expanded(
                        child: Text(
                          'El precio es negociable. Puedes chatear con el vendedor para acordar el monto final.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.accentDark,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ]),
          ),
        ),
      ],
        ),

        // ── Sticky bottom action bar ────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: cs.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Price summary
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: cs.primary,
                      ),
                    ),
                    if (product.isNegotiable)
                      Text(
                        'Precio negociable',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.accentDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                const Gap(16),
                // Contact button
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    label: Text(
                      'Contactar vendedor',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Chat próximamente 🚀',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: cs.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Photo gallery ─────────────────────────────────────────

class _PhotoGallery extends StatelessWidget {
  final Product product;
  final ProductRepository repo;
  final int currentIndex;
  final void Function(int) onPageChanged;
  final bool isFav;
  final String? currentUserId;
  final VoidCallback onFavToggle;

  const _PhotoGallery({
    required this.product,
    required this.repo,
    required this.currentIndex,
    required this.onPageChanged,
    required this.isFav,
    required this.currentUserId,
    required this.onFavToggle,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final images = product.images;

    return SizedBox(
      height: 340,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Photos
          images.isEmpty
              ? Container(
                  color: AppColors.inputFill,
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 48,
                      color: AppColors.textHint,
                    ),
                  ),
                )
              : PageView.builder(
                  onPageChanged: onPageChanged,
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final url = ProductCard.resolveImageUrl(images[index].imagePath) ?? '';
                    return CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.inputFill),
                      errorWidget: (_, __, ___) =>
                          Container(color: AppColors.inputFill),
                    );
                  },
                ),

          // Gradient overlay bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 80,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(100),
                  ],
                ),
              ),
            ),
          ),

          // Back button
          Positioned(
            top: topPad + 8,
            left: 12,
            child: _CircleButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),

          // Favorite button
          if (currentUserId != null)
            Positioned(
              top: topPad + 8,
              right: 12,
              child: _CircleButton(
                icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                iconColor: isFav ? Colors.red : Colors.white,
                onTap: onFavToggle,
              ),
            ),

          // Photo dots indicator
          if (images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i == currentIndex ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i == currentIndex
                          ? Colors.white
                          : Colors.white.withAlpha(120),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withAlpha(80),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }
}

// ── Info chip ─────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const Gap(4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Seller card ───────────────────────────────────────────

class _SellerCard extends StatelessWidget {
  final Product product;

  const _SellerCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final name = product.sellerName ?? 'Vendedor';
    final score = product.sellerTrustScore ?? 50;
    final stars = (score / 20).clamp(0.0, 5.0);
    final isTrusted = score >= 85;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withAlpha(30),
            backgroundImage: product.sellerAvatarUrl != null
                ? NetworkImage(product.sellerAvatarUrl!)
                : null,
            child: product.sellerAvatarUrl == null
                ? Text(
                    name.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isTrusted) ...[
                      const Gap(6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              color: Colors.white,
                              size: 10,
                            ),
                            const Gap(2),
                            Text(
                              'Confiable',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const Gap(2),
                Row(
                  children: [
                    ...List.generate(5, (i) {
                      return Icon(
                        i < stars.floor()
                            ? Icons.star_rounded
                            : i < stars
                                ? Icons.star_half_rounded
                                : Icons.star_border_rounded,
                        color: AppColors.accent,
                        size: 14,
                      );
                    }),
                    const Gap(4),
                    Text(
                      stars.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
