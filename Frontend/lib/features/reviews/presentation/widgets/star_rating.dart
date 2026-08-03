/// Read-only star rating display (supports half stars).
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:baratito/core/theme/app_palette.dart';

class StarRating extends StatelessWidget {
  /// Average rating 0..5.
  final double rating;

  /// Number of reviews; when > 0 it's shown next to the stars.
  final int count;

  final double size;

  /// Shows the numeric average (e.g. "4.5") before the stars.
  final bool showValue;

  const StarRating({
    super.key,
    required this.rating,
    this.count = 0,
    this.size = 16,
    this.showValue = true,
  });

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFFFB300);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showValue) ...[
          Text(
            rating.toStringAsFixed(1),
            style: GoogleFonts.poppins(
              fontSize: size * 0.8,
              fontWeight: FontWeight.w700,
              color: context.palette.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
        ],
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i
                ? Icons.star_rounded
                : (rating >= i - 0.5
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded),
            size: size,
            color: amber,
          ),
        if (count > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($count)',
            style: GoogleFonts.poppins(
              fontSize: size * 0.75,
              color: context.palette.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
