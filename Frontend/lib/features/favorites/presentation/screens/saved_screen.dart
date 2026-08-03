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
import 'package:baratito/widgets/baratito_app_bar.dart';
import '../../../products/presentation/widgets/product_card.dart';
import '../providers/favorites_provider.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = SupabaseClientHelper.auth.currentUser != null;

    final Widget body;
    if (!loggedIn) {
      body = const _Empty(
        title: 'Inicia sesión',
        subtitle: 'Guarda artículos que te interesen',
        showLogin: true,
      );
    } else {
      final async = ref.watch(favoriteProductsProvider);
      body = async.when(
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
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
      );
    }

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: const BaratitoAppBar(title: Text('Guardados')),
      body: body,
    );
  }
}

class _Empty extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showLogin;
  const _Empty({
    required this.title,
    required this.subtitle,
    this.showLogin = false,
  });

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
          if (showLogin) ...[
            const Gap(20),
            FilledButton(
              onPressed: () => context.go('/login'),
              child: const Text('Iniciar sesión'),
            ),
          ],
        ],
      ),
    );
  }
}
