/// Product card used in the marketplace grid.
///
/// Shows the primary image with small color dots for condition (and
/// "negociable"), then the title and price below.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';
import 'package:baratito/widgets/minio_image.dart';
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
      borderRadius: BorderRadius.zero,
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
                  MinioImage(objectKey: product.primaryImageKey),
                  // Indicadores discretos: un punto de color por condición y,
                  // si aplica, otro para "negociable". Ocupan poco y dejan ver
                  // mejor el producto que las antiguas etiquetas de texto.
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Row(
                      children: [
                        _ConditionDot(
                          color: conditionColor(product.condition),
                          tooltip: product.conditionLabel,
                        ),
                        if (product.isNegotiable) ...[
                          const SizedBox(width: 6),
                          const _ConditionDot(
                            color: Color(0xFF8E5BF2),
                            tooltip: 'Negociable',
                          ),
                        ],
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
                  // Altura fija = 2 líneas: así el bloque de texto mide igual
                  // en toda tarjeta y la imagen (Expanded) queda del mismo
                  // tamaño, con o sin título de una sola línea.
                  SizedBox(
                    height: 36,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
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

/// Color que representa cada condición del producto.
/// Público para reusarlo en la leyenda del home.
Color conditionColor(String raw) {
  switch (raw.toLowerCase()) {
    case 'new':
    case 'nuevo':
      return const Color(0xFF27AE60); // verde — nuevo
    case 'like_new':
    case 'como_nuevo':
    case 'como nuevo':
      return const Color(0xFF2D9CDB); // azul — como nuevo
    case 'good':
    case 'buen_estado':
    case 'buen estado':
      return const Color(0xFFF2B01D); // ámbar — buen estado
    case 'fair':
    case 'aceptable':
      return const Color(0xFFE67E22); // naranja — aceptable
    case 'used':
    case 'usado':
    default:
      return const Color(0xFF9AA0A6); // gris — usado
  }
}

/// Punto de color sobre la foto con borde blanco para verse en cualquier fondo.
/// El [tooltip] muestra el significado al mantener presionado.
class _ConditionDot extends StatelessWidget {
  final Color color;
  final String tooltip;

  const _ConditionDot({required this.color, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 13,
        height: 13,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(60),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}
