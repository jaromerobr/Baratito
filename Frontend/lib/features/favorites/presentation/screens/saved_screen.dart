/// "Guardados" — products the user has favorited.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';
import '../../../../core/supabase_client.dart';
import '../../../products/presentation/widgets/product_card.dart';
import '../providers/favorites_provider.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = SupabaseClientHelper.auth.currentUser != null;

    if (!loggedIn) {
      return const _Empty(
        title: 'Inicia sesión',
        subtitle: 'Guarda artículos que te interesen',
      );
    }

    final async = ref.watch(favoriteProductsProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('Guardados',
                style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.w800)),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (products) {
                if (products.isEmpty) {
                  return const _Empty(
                    title: 'Sin favoritos aún',
                    subtitle: 'Toca el corazón en un producto para guardarlo',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.refresh(favoriteProductsProvider.future),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.66,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, i) => ProductCard(
                      product: products[i],
                      onTap: () => context.push('/product/${products[i].id}'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Empty({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: context.palette.divider,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.favorite_border,
                size: 44, color: AppColors.primary),
          ),
          const Gap(20),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const Gap(6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 14, color: context.palette.textSecondary)),
        ],
      ),
    );
  }
}
