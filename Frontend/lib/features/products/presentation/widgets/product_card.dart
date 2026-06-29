/// Product card used in the marketplace grid.
///
/// Shows the primary image with "Negociable" + condition badges overlaid,
/// then the title and price below — matching the Baratito home design.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';
import '../../../favorites/presentation/widgets/favorite_button.dart';
import '../../domain/product_model.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image + badges ──────────────────────────
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _ProductImage(url: product.primaryImageUrl),
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (product.isNegotiable)
                          Flexible(
                            child: _Badge(
                              text: 'Negociable',
                              color: AppColors.accent,
                              textColor: Colors.white,
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        Flexible(
                          child: _Badge(
                            text: product.conditionLabel,
                            color: Colors.black.withAlpha(140),
                            textColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: FavoriteButton(productId: product.id, size: 18),
                  ),
                ],
              ),
            ),

            // ── Title + price ───────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: context.palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.priceLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? url;
  const _ProductImage({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return Container(
        color: context.palette.inputFill,
        child: Icon(
          Icons.image_outlined,
          color: context.palette.textHint,
          size: 40,
        ),
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: context.palette.inputFill,
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stack) => Container(
        color: context.palette.inputFill,
        child: Icon(
          Icons.broken_image_outlined,
          color: context.palette.textHint,
          size: 40,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;

  const _Badge({
    required this.text,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
