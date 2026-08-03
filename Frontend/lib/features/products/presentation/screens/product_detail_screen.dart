/// Product detail screen — full info for a single listing.
///
/// Image carousel, price/condition, description, seller card and a
/// contact CTA. Reads from [productDetailProvider].
library;

import 'package:flutter/material.dart';
import 'package:baratito/widgets/minio_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';
import '../../../../core/supabase_client.dart';
import '../../../admin/presentation/providers/admin_provider.dart';
import '../../../chat/domain/chat_models.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../favorites/presentation/widgets/favorite_button.dart';
import '../../domain/product_model.dart';
import '../providers/products_provider.dart';
import '../widgets/product_location_map.dart';
import '../../../reviews/presentation/widgets/star_rating.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));

    return Scaffold(
      backgroundColor: context.palette.background,
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorView(
          onBack: () => Navigator.of(context).maybePop(),
        ),
        data: (product) => _DetailBody(product: product),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final Product product;
  const _DetailBody({required this.product});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // ── Image carousel ──────────────────────────
            SliverToBoxAdapter(child: _ImageCarousel(keys: product.imageKeys)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price + negotiable
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        Text(
                          product.priceLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        if (product.isNegotiable)
                          _Tag('Negociable', AppColors.accent),
                      ],
                    ),
                    const Gap(8),
                    Text(
                      product.title,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: context.palette.textPrimary,
                      ),
                    ),
                    const Gap(12),
                    // Meta chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaChip(Icons.verified_outlined, product.conditionLabel),
                        _MetaChip(Icons.place_outlined, product.locationCity),
                        if (product.brand != null && product.brand!.isNotEmpty)
                          _MetaChip(Icons.sell_outlined, product.brand!),
                        _MetaChip(Icons.favorite_border, '${product.likesCount}'),
                      ],
                    ),
                    const Gap(20),
                    // Description
                    if (product.description != null &&
                        product.description!.isNotEmpty) ...[
                      Text(
                        'Descripción',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.palette.textPrimary,
                        ),
                      ),
                      const Gap(6),
                      Text(
                        product.description!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          height: 1.5,
                          color: context.palette.textSecondary,
                        ),
                      ),
                      const Gap(20),
                    ],
                    // Seller card
                    _SellerCard(product: product),
                    const Gap(20),
                    // Mapa de ubicación (OpenStreetMap)
                    ProductLocationMap(city: product.locationCity),
                  ],
                ),
              ),
            ),
          ],
        ),

        // ── Back button overlay ─────────────────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          child: _CircleButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),

        // ── Bottom CTA ──────────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _BottomCta(product: product),
        ),
      ],
    );
  }
}

// ── Image carousel ──────────────────────────────────────
class _ImageCarousel extends StatefulWidget {
  final List<String> keys;
  const _ImageCarousel({required this.keys});

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.keys.isEmpty) {
      return Container(
        height: 320,
        color: context.palette.inputFill,
        child: Icon(Icons.image_outlined,
            size: 60, color: context.palette.textHint),
      );
    }
    return SizedBox(
      height: 340,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            itemCount: widget.keys.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => MinioImage(
              objectKey: widget.keys[i],
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          if (widget.keys.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.keys.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _page ? Colors.white : Colors.white70,
                      borderRadius: BorderRadius.circular(4),
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

// ── Seller card ─────────────────────────────────────────
class _SellerCard extends ConsumerWidget {
  final Product product;
  const _SellerCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/user/${product.sellerId}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.palette.divider),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.sellerName ?? 'Vendedor',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.palette.textPrimary,
                    ),
                  ),
                  const Gap(3),
                  _SellerRatingLine(product: product),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.palette.textHint),
          ],
        ),
      ),
    );
  }
}

/// Star rating for the seller, or "Primera publicación" / "Sin valoraciones
/// aún" when there are no reviews yet.
class _SellerRatingLine extends ConsumerWidget {
  final Product product;
  const _SellerRatingLine({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (product.sellerRatingCount > 0) {
      return StarRating(
        rating: product.sellerRatingAvg,
        count: product.sellerRatingCount,
        size: 15,
      );
    }
    // No reviews yet: distinguish a brand-new seller (first publication).
    final countAsync = ref.watch(sellerPublishedCountProvider(product.sellerId));
    final isFirst = countAsync.maybeWhen(
      data: (n) => n <= 1,
      orElse: () => false,
    );
    return Row(
      children: [
        Icon(
          isFirst ? Icons.fiber_new_rounded : Icons.star_outline_rounded,
          size: 15,
          color: context.palette.textSecondary,
        ),
        const Gap(4),
        Text(
          isFirst ? 'Primera publicación' : 'Sin valoraciones aún',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: context.palette.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ── Bottom CTA ──────────────────────────────────────────
class _BottomCta extends ConsumerStatefulWidget {
  final Product product;
  const _BottomCta({required this.product});

  @override
  ConsumerState<_BottomCta> createState() => _BottomCtaState();
}

class _BottomCtaState extends ConsumerState<_BottomCta> {
  bool _opening = false;

  Future<void> _contact() async {
    final product = widget.product;
    final uid = SupabaseClientHelper.auth.currentUser?.id;

    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para contactar')),
      );
      return;
    }
    if (uid == product.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este producto es tuyo')),
      );
      return;
    }

    setState(() => _opening = true);
    try {
      final convId =
          await ref.read(chatRepositoryProvider).getOrCreateConversation(
                productId: product.id,
                sellerId: product.sellerId,
              );
      ref.invalidate(conversationsProvider);
      if (!mounted) return;
      final conv = Conversation(
        id: convId,
        productId: product.id,
        productTitle: product.title,
        otherUserId: product.sellerId,
        otherUserName: product.sellerName ?? 'Vendedor',
      );
      context.push('/chat/$convId', extra: conv);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _addToCart() async {
    final product = widget.product;
    final uid = SupabaseClientHelper.auth.currentUser?.id;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para comprar')),
      );
      return;
    }
    if (uid == product.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este producto es tuyo')),
      );
      return;
    }
    final inCart = ref.read(cartIdsProvider).valueOrNull?.contains(product.id) ?? false;
    if (inCart) {
      context.push('/cart');
      return;
    }
    await ref.read(cartControllerProvider).add(product.id);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Agregado al carrito'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
        action: SnackBarAction(
            label: 'Ver carrito', onPressed: () => router.push('/cart')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Las cuentas admin solo miran el catálogo: sin barra de compra/contacto.
    final isAdmin = ref.watch(isAdminProvider).maybeWhen(
          data: (v) => v,
          orElse: () => false,
        );
    if (isAdmin) return const SizedBox.shrink();

    // Si el producto es del propio usuario: sin carrito, sin chat,
    // sin favorito — solo un aviso con acceso a sus publicaciones.
    final uid = SupabaseClientHelper.auth.currentUser?.id;
    final isOwn = uid != null && uid == widget.product.sellerId;
    if (isOwn) {
      return Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: context.palette.surface,
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 12),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.storefront_outlined, color: AppColors.primary),
            const Gap(10),
            Expanded(
              child: Text(
                'Este producto es tuyo',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.palette.textPrimary),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/my-products'),
              child: const Text('Mis productos'),
            ),
          ],
        ),
      );
    }

    final inCart = ref.watch(cartIdsProvider).maybeWhen(
          data: (ids) => ids.contains(widget.product.id),
          orElse: () => false,
        );

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: context.palette.surface,
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 12),
        ],
      ),
      child: Row(
        children: [
          FavoriteButton(productId: widget.product.id),
          const Gap(10),
          _CircleButton(
            icon: Icons.chat_bubble_outline,
            filled: true,
            onTap: _opening ? () {} : _contact,
          ),
          const Gap(10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _addToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: Icon(inCart
                  ? Icons.shopping_cart
                  : Icons.add_shopping_cart_outlined),
              label: Text(
                inCart ? 'En el carrito' : 'Agregar al carrito',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small reusable pieces ───────────────────────────────
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? context.palette.inputFill : Colors.white,
      shape: const CircleBorder(),
      elevation: filled ? 0 : 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: context.palette.textPrimary, size: 22),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaChip(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.palette.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const Gap(5),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onBack;
  const _ErrorView({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 56, color: context.palette.textHint),
            const Gap(12),
            Text('No se pudo cargar el producto',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const Gap(12),
            TextButton(onPressed: onBack, child: const Text('Volver')),
          ],
        ),
      ),
    );
  }
}
