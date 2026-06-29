/// Heart toggle button — saves/removes a product from favorites.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';
import '../../../../core/supabase_client.dart';
import '../providers/favorites_provider.dart';

class FavoriteButton extends ConsumerWidget {
  final String productId;
  final double size;
  final bool withCircle;

  const FavoriteButton({
    super.key,
    required this.productId,
    this.size = 22,
    this.withCircle = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(favoriteIdsProvider).maybeWhen(
          data: (ids) => ids.contains(productId),
          orElse: () => false,
        );

    final icon = Icon(
      isFav ? Icons.favorite : Icons.favorite_border,
      color: isFav ? AppColors.error : (withCircle ? context.palette.textPrimary : Colors.white),
      size: size,
    );

    void onTap() {
      if (SupabaseClientHelper.auth.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inicia sesión para guardar')),
        );
        return;
      }
      ref.read(favoritesControllerProvider).toggle(productId, isFav);
    }

    if (!withCircle) {
      return GestureDetector(onTap: onTap, child: icon);
    }

    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(8), child: icon),
      ),
    );
  }
}
