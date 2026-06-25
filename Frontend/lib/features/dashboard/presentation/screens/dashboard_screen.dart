/// DashboardScreen — Main shell with bottom nav.
///
/// Layout: login-style header + BottomAppBar with notched FAB.
/// Tabs: Inicio (feed), Favoritos, Compras, Perfil.
/// Colors: only cs.primary (forest green) + cs.secondary (mustard yellow).
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../products/domain/product_model.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../../../products/presentation/screens/home_feed_screen.dart'
    show ProductCard;

// ── Shell ─────────────────────────────────────────────────

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _index = 0;

  static const _tabs = [
    _FeedTab(),
    _FavoritesTab(),
    _OrdersTab(),
    _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: _tabs,
      ),

      // ── Centered FAB: Publicar ────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.productForm),
        backgroundColor: cs.secondary,
        foregroundColor: cs.onSecondary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ── Bottom nav ────────────────────────────────────
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        color: cs.surface,
        elevation: 8,
        shadowColor: Colors.black26,
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Inicio',
              index: 0,
              current: _index,
              onTap: (i) => setState(() => _index = i),
            ),
            _NavItem(
              icon: Icons.favorite_rounded,
              label: 'Guardados',
              index: 1,
              current: _index,
              onTap: (i) => setState(() => _index = i),
            ),
            const SizedBox(width: 56), // notch gap
            _NavItem(
              icon: Icons.shopping_bag_rounded,
              label: 'Compras',
              index: 2,
              current: _index,
              onTap: (i) => setState(() => _index = i),
            ),
            _NavItem(
              icon: Icons.person_rounded,
              label: 'Perfil',
              index: 3,
              current: _index,
              onTap: (i) => setState(() => _index = i),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom nav item ───────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final void Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selected = index == current;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: selected ? cs.primary : cs.onSurfaceVariant.withAlpha(120),
            ),
            const Gap(2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected
                    ? cs.primary
                    : cs.onSurfaceVariant.withAlpha(120),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 0 — FEED
// ════════════════════════════════════════════════════════════

class _FeedTab extends ConsumerStatefulWidget {
  const _FeedTab();

  @override
  ConsumerState<_FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends ConsumerState<_FeedTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final topPad = MediaQuery.of(context).padding.top;
    final categories = ref.watch(categoriesProvider);
    final filters = ref.watch(feedFiltersProvider);
    final feed = ref.watch(productFeedProvider);
    final userProfile = ref.watch(currentUserProfileProvider);

    final firstName = userProfile.whenOrNull(
      data: (p) => (p?.fullName ?? 'tú').split(' ').first,
    ) ?? 'tú';

    return CustomScrollView(
      slivers: [
        // ── Branded header ──────────────────────────────
        SliverToBoxAdapter(
          child: _FeedHeader(
            topPad: topPad,
            cs: cs,
            firstName: firstName,
          ),
        ),

        // ── Search bar (overlaps header) ────────────────
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(18),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) =>
                      ref.read(feedFiltersProvider.notifier).setSearch(v),
                  onSubmitted: (v) =>
                      ref.read(feedFiltersProvider.notifier).setSearch(v),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Buscar artículos de segunda mano...',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textHint,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: cs.primary,
                      size: 22,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(feedFiltersProvider.notifier)
                                  .setSearch(null);
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Spacer to compensate for the -24 translate ──
        const SliverToBoxAdapter(child: SizedBox(height: 0)),

        // ── Category pills ──────────────────────────────
        SliverToBoxAdapter(
          child: categories.when(
            data: (cats) => _CategoryPills(
              categories: cats,
              selectedId: filters.categoryId,
              onSelected: (id) =>
                  ref.read(feedFiltersProvider.notifier).setCategory(id),
            ),
            loading: () => const _ShimmerPills(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ),

        // ── Condition pills ─────────────────────────────
        SliverToBoxAdapter(
          child: _ConditionPills(
            selected: filters.condition,
            onSelected: (c) =>
                ref.read(feedFiltersProvider.notifier).setCondition(c),
          ),
        ),

        // ── Active filters row ──────────────────────────
        if (filters.search != null ||
            filters.categoryId != null ||
            filters.condition != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Row(
                children: [
                  if (filters.search != null)
                    _ActiveChip(
                      label: '"${filters.search}"',
                      onRemove: () => ref
                          .read(feedFiltersProvider.notifier)
                          .setSearch(null),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        ref.read(feedFiltersProvider.notifier).clear(),
                    child: Text(
                      'Limpiar',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Section label ───────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text(
              filters.search != null || filters.categoryId != null
                  ? 'Resultados'
                  : 'Publicaciones recientes',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),

        // ── Product grid ────────────────────────────────
        feed.when(
          data: (products) {
            if (products.isEmpty) {
              return SliverFillRemaining(
                child: _EmptyFeed(
                  onClear: () =>
                      ref.read(feedFiltersProvider.notifier).clear(),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => ProductCard(
                    product: products[i],
                    onTap: () =>
                        context.push(AppRoutes.productDetail(products[i].id)),
                  ),
                  childCount: products.length,
                ),
              ),
            );
          },
          loading: () => const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (_, _) => SliverFillRemaining(
            child: Center(
              child: Text(
                'Error al cargar productos.',
                style: GoogleFonts.poppins(color: AppColors.textSecondary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Feed header (login style) ─────────────────────────────

class _FeedHeader extends StatelessWidget {
  final double topPad;
  final ColorScheme cs;
  final String firstName;

  const _FeedHeader({
    required this.topPad,
    required this.cs,
    required this.firstName,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: topPad + 200,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Yellow base
          Positioned.fill(child: Container(color: cs.secondary)),

          // Green diagonal shape — top-right
          Positioned(
            top: -30,
            right: -60,
            child: Transform.rotate(
              angle: -math.pi / 6,
              child: Container(
                width: 220,
                height: 320,
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(190),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ),

          // Green diagonal shape — bottom-left
          Positioned(
            bottom: 30,
            left: -70,
            child: Transform.rotate(
              angle: math.pi / 5,
              child: Container(
                width: 180,
                height: 260,
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(150),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ),

          // Content
          Positioned(
            top: topPad + 16,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo row
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'B',
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: cs.primary,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                    const Gap(10),
                    Text(
                      'BARATITO',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),

                const Gap(20),

                // Greeting
                Text(
                  '¡Hola, $firstName! 👋',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                  ),
                ),
                const Gap(4),
                Text(
                  '¿Qué buscas hoy?',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: cs.primary.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category pills ────────────────────────────────────────

class _CategoryPills extends StatelessWidget {
  final List<ProductCategory> categories;
  final String? selectedId;
  final void Function(String?) onSelected;

  const _CategoryPills({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const Gap(8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final selected = selectedId == cat.id;
          return GestureDetector(
            onTap: () => onSelected(selected ? null : cat.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? cs.primary : cs.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? cs.primary
                      : AppColors.divider,
                ),
              ),
              child: Text(
                cat.name,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ShimmerPills extends StatelessWidget {
  const _ShimmerPills();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        itemCount: 4,
        separatorBuilder: (_, __) => const Gap(8),
        itemBuilder: (_, __) => Container(
          width: 72,
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

// ── Condition pills ───────────────────────────────────────

class _ConditionPills extends StatelessWidget {
  final String? selected;
  final void Function(String?) onSelected;

  const _ConditionPills({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final all = [null, ...ProductCondition.values];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        itemCount: all.length,
        separatorBuilder: (_, __) => const Gap(8),
        itemBuilder: (context, index) {
          final cond = all[index];
          final isSelected = selected == cond?.value;
          final label = cond?.label ?? 'Todos';
          return GestureDetector(
            onTap: () => onSelected(isSelected ? null : cond?.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.secondary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? cs.secondary
                      : AppColors.divider,
                ),
              ),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? cs.primary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Active filter chip ────────────────────────────────────

class _ActiveChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _ActiveChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: cs.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Gap(4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 14, color: cs.primary),
          ),
        ],
      ),
    );
  }
}

// ── Empty feed state ──────────────────────────────────────

class _EmptyFeed extends StatelessWidget {
  final VoidCallback onClear;

  const _EmptyFeed({required this.onClear});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cs.secondary.withAlpha(40),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.storefront_outlined,
              size: 40,
              color: cs.primary,
            ),
          ),
          const Gap(20),
          Text(
            'Aún no hay publicaciones',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Gap(6),
          Text(
            '¡Sé el primero en publicar algo!',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Gap(24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(180, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(
              'Publicar artículo',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            onPressed: () => context.push(AppRoutes.productForm),
          ),
          const Gap(12),
          TextButton(
            onPressed: onClear,
            child: Text(
              'Limpiar filtros',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 1 — FAVORITOS
// ════════════════════════════════════════════════════════════

class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final topPad = MediaQuery.of(context).padding.top;
    final favorites = ref.watch(favoritesProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _TabHeader(
            topPad: topPad,
            cs: cs,
            title: 'Guardados',
            subtitle: 'Tus artículos favoritos',
            icon: Icons.favorite_rounded,
          ),
        ),
        favorites.when(
          data: (products) {
            if (products.isEmpty) {
              return SliverFillRemaining(
                child: _EmptyFavorites(cs: cs),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => ProductCard(
                    product: products[i],
                    onTap: () => context
                        .push(AppRoutes.productDetail(products[i].id)),
                  ),
                  childCount: products.length,
                ),
              ),
            );
          },
          loading: () => const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (_, _) => SliverFillRemaining(
            child: Center(
              child: Text(
                'Error al cargar favoritos.',
                style: GoogleFonts.poppins(color: AppColors.textSecondary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  final ColorScheme cs;
  const _EmptyFavorites({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cs.secondary.withAlpha(40),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.favorite_outline_rounded,
              size: 40,
              color: cs.primary,
            ),
          ),
          const Gap(20),
          Text(
            'Sin favoritos aún',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Gap(6),
          Text(
            'Guarda artículos que te interesen',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 2 — COMPRAS
// ════════════════════════════════════════════════════════════

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final topPad = MediaQuery.of(context).padding.top;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _TabHeader(
            topPad: topPad,
            cs: cs,
            title: 'Mis compras',
            subtitle: 'Historial de pedidos',
            icon: Icons.shopping_bag_rounded,
          ),
        ),
        SliverFillRemaining(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: cs.secondary.withAlpha(40),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 44,
                  color: cs.primary,
                ),
              ),
              const Gap(24),
              Text(
                'Próximamente',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Gap(8),
              Text(
                'Sistema de compras en desarrollo',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const Gap(4),
              Text(
                'Pagos y chat llegarán pronto 🚀',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 3 — PERFIL
// ════════════════════════════════════════════════════════════

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final topPad = MediaQuery.of(context).padding.top;
    final userProfile = ref.watch(currentUserProfileProvider);

    return CustomScrollView(
      slivers: [
        // Profile header
        SliverToBoxAdapter(
          child: _ProfileHeader(
            topPad: topPad,
            cs: cs,
            userProfile: userProfile,
          ),
        ),

        // Menu options
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Menu card
              Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _ProfileMenuItem(
                      icon: Icons.sell_rounded,
                      label: 'Mis publicaciones',
                      color: cs.primary,
                      onTap: () => context.push(AppRoutes.myListings),
                    ),
                    _ProfileDivider(),
                    _ProfileMenuItem(
                      icon: Icons.favorite_rounded,
                      label: 'Guardados',
                      color: cs.primary,
                      onTap: () => context.push(AppRoutes.favorites),
                    ),
                    _ProfileDivider(),
                    _ProfileMenuItem(
                      icon: Icons.star_rounded,
                      label: 'Mis reseñas',
                      color: cs.secondary,
                      onTap: () {},
                      badge: 'Próximamente',
                    ),
                    _ProfileDivider(),
                    _ProfileMenuItem(
                      icon: Icons.settings_rounded,
                      label: 'Configuración',
                      color: AppColors.textSecondary,
                      onTap: () {},
                      badge: 'Próximamente',
                    ),
                  ],
                ),
              ),

              const Gap(16),

              // Logout
              Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _ProfileMenuItem(
                  icon: Icons.logout_rounded,
                  label: 'Cerrar sesión',
                  color: AppColors.error,
                  onTap: () async {
                    await ref
                        .read(authControllerProvider.notifier)
                        .signOut();
                    if (context.mounted) context.go(AppRoutes.login);
                  },
                  textColor: AppColors.error,
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final double topPad;
  final ColorScheme cs;
  final AsyncValue<UserProfile?> userProfile;

  const _ProfileHeader({
    required this.topPad,
    required this.cs,
    required this.userProfile,
  });

  @override
  Widget build(BuildContext context) {
    final name = userProfile.whenOrNull(data: (p) => p?.fullName) ?? 'Usuario';
    final initials = name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return SizedBox(
      height: topPad + 220,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Yellow base
          Positioned.fill(child: Container(color: cs.secondary)),

          // Green diagonal shapes
          Positioned(
            top: -30,
            right: -60,
            child: Transform.rotate(
              angle: -math.pi / 6,
              child: Container(
                width: 220,
                height: 320,
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(190),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: -70,
            child: Transform.rotate(
              angle: math.pi / 5,
              child: Container(
                width: 180,
                height: 260,
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(150),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ),

          // Content
          Positioned(
            top: topPad + 16,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: cs.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initials.isEmpty ? 'U' : initials,
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
                const Gap(14),
                // Name
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Gap(4),
                Text(
                  'Miembro de Baratito',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: cs.primary.withAlpha(200),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? badge;
  final Color? textColor;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: badge != null ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Gap(14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor ?? AppColors.textPrimary,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cs.secondary.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge!,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.accentDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textHint,
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        height: 1,
        color: AppColors.divider,
      ),
    );
  }
}

// ── Shared tab header (mini) ──────────────────────────────

class _TabHeader extends StatelessWidget {
  final double topPad;
  final ColorScheme cs;
  final String title;
  final String subtitle;
  final IconData icon;

  const _TabHeader({
    required this.topPad,
    required this.cs,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: topPad + 130,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: Container(color: cs.secondary)),
          Positioned(
            top: -20,
            right: -50,
            child: Transform.rotate(
              angle: -math.pi / 6,
              child: Container(
                width: 180,
                height: 260,
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(180),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: -60,
            child: Transform.rotate(
              angle: math.pi / 5,
              child: Container(
                width: 140,
                height: 200,
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(130),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ),
          Positioned(
            top: topPad + 16,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: cs.primary, size: 24),
                ),
                const Gap(14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: cs.primary.withAlpha(200),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
