/// "Mis productos" — listings owned by the current user, split into
/// En venta (active) and Vendidos (sold).
library;

import 'package:flutter/material.dart';
import 'package:baratito/widgets/baratito_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';
import '../providers/products_provider.dart';
import '../widgets/product_card.dart';

class MyProductsScreen extends StatelessWidget {
  const MyProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.palette.background,
        appBar: BaratitoAppBar(
          title: Text('Mis productos',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: AppColors.accent,
            tabs: [
              Tab(text: 'En venta'),
              Tab(text: 'Vendidos'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MyProductsList(status: 'active', emptyText: 'No tienes productos en venta'),
            _MyProductsList(status: 'sold', emptyText: 'Aún no has vendido nada'),
          ],
        ),
      ),
    );
  }
}

class _MyProductsList extends ConsumerWidget {
  final String status;
  final String emptyText;
  const _MyProductsList({required this.status, required this.emptyText});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myProductsProvider(status));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (products) {
        if (products.isEmpty) {
          return _Empty(text: emptyText);
        }
        return RefreshIndicator(
          onRefresh: () async => ref.refresh(myProductsProvider(status).future),
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
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 56, color: context.palette.textHint),
          const Gap(12),
          Text(text,
              style: GoogleFonts.poppins(
                  fontSize: 14, color: context.palette.textSecondary)),
        ],
      ),
    );
  }
}
