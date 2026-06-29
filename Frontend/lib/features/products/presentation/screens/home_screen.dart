/// Marketplace home — "Publicaciones recientes".
///
/// Branded header with greeting + search, category chips, condition
/// filter chips and a 2-column grid of products fetched from Supabase.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../domain/category_model.dart';
import '../../domain/product_model.dart';
import '../providers/products_provider.dart';
import '../widgets/product_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(productsProvider.future),
      child: CustomScrollView(
        slivers: [
          // ── Header (greeting + search + filtros) ────
          const SliverToBoxAdapter(child: _HomeHeader()),

          // ── Filtros activos (solo si hay alguno) ────
          const SliverToBoxAdapter(child: _ActiveFilters()),

          // ── Section title ───────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Publicaciones recientes',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: context.palette.textPrimary,
                ),
              ),
            ),
          ),

          // ── Products grid / states ──────────────────
          productsAsync.when(
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: _ErrorState(
                onRetry: () => ref.invalidate(productsProvider),
              ),
            ),
            data: (products) {
              if (products.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.66,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => ProductCard(
                      product: products[i],
                      onTap: () => context.push('/product/${products[i].id}'),
                    ),
                    childCount: products.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────
class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final firstName = profileAsync.maybeWhen(
      data: (p) => (p?.fullName?.trim().split(' ').first) ?? 'tú',
      orElse: () => 'tú',
    );
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: Text(
                    'B',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDark,
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
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              const _ThemeToggleButton(),
              _CartButton(),
            ],
          ),
          const Gap(18),
          Text(
            '¡Hola, $firstName!',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const Gap(2),
          Text(
            '¿Qué buscas hoy?',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withAlpha(220),
            ),
          ),
          const Gap(16),
          // Search bar + filtros
          Row(
            children: [
              Expanded(child: _SearchBar()),
              const Gap(10),
              const _FilterButton(),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Theme toggle (claro/oscuro) ─────────────────────────
class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeModel>().isDarkMode;
    return IconButton(
      tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
      onPressed: () => context.read<ThemeModel>().toggleTheme(),
      icon: Icon(
        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        color: Colors.white,
      ),
    );
  }
}

// ── Filter button (abre el panel de filtros) ────────────
class _FilterButton extends ConsumerWidget {
  const _FilterButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(productFiltersProvider);
    final hasFilters = filters.categoryId != null || filters.condition != null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _openFilterSheet(context),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Icon(Icons.tune_rounded, color: AppColors.primary),
            ),
          ),
        ),
        if (hasFilters)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

void _openFilterSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _FilterSheet(),
  );
}

class _SearchBar extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      textInputAction: TextInputAction.search,
      onSubmitted: (v) =>
          ref.read(productFiltersProvider.notifier).setSearch(v),
      decoration: InputDecoration(
        hintText: 'Buscar artículos de segunda mano...',
        hintStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: context.palette.textHint,
        ),
        prefixIcon: const Icon(Icons.search, color: AppColors.primary),
        suffixIcon: _ctrl.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.close, color: context.palette.textHint),
                onPressed: () {
                  _ctrl.clear();
                  ref.read(productFiltersProvider.notifier).setSearch('');
                  setState(() {});
                },
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }
}

// ── Cart button with badge ──────────────────────────────
class _CartButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartCountProvider);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () => context.push('/cart'),
          icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 2,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Active filters indicator (solo si hay filtros) ──────
class _ActiveFilters extends ConsumerWidget {
  const _ActiveFilters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(productFiltersProvider);
    final notifier = ref.read(productFiltersProvider.notifier);
    final catName = ref.watch(categoriesProvider).maybeWhen(
          data: (cats) {
            if (filters.categoryId == null) return null;
            for (final c in cats) {
              if (c.id == filters.categoryId) return c.name;
            }
            return null;
          },
          orElse: () => null,
        );

    final chips = <Widget>[];
    if (catName != null) {
      chips.add(_RemovableChip(
          label: catName, onRemove: () => notifier.setCategory(null)));
    }
    if (filters.condition != null) {
      chips.add(_RemovableChip(
          label: filters.condition!,
          onRemove: () => notifier.setCondition(null)));
    }
    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }
}

class _RemovableChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _RemovableChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary)),
          const Gap(4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 16, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ── Filter bottom sheet ─────────────────────────────────
class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(productFiltersProvider);
    final notifier = ref.read(productFiltersProvider.notifier);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Container(
      decoration: BoxDecoration(
        color: context.palette.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: context.palette.divider,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const Gap(16),
          Row(
            children: [
              Text('Filtros',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              TextButton(
                onPressed: () => notifier.clear(),
                child: const Text('Limpiar'),
              ),
            ],
          ),
          const Gap(8),
          Text('Categorías',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700)),
          const Gap(10),
          categoriesAsync.maybeWhen(
            data: (cats) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cats.map((c) {
                final sel = c.id == filters.categoryId;
                return _Chip(
                  label: c.name,
                  icon: _iconForCategory(c),
                  selected: sel,
                  onTap: () => notifier.setCategory(sel ? null : c.id),
                );
              }).toList(),
            ),
            orElse: () => const SizedBox(
                height: 40,
                child: Center(child: CircularProgressIndicator())),
          ),
          const Gap(20),
          Text('Estado del producto',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700)),
          const Gap(10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ProductCondition.filterLabels.map((label) {
              final isAll = label == 'Todos';
              final sel = isAll
                  ? filters.condition == null
                  : filters.condition == label;
              return _Chip(
                label: label,
                selected: sel,
                onTap: () => notifier.setCondition(isAll ? null : label),
              );
            }).toList(),
          ),
          const Gap(24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Ver resultados',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category icon helper ────────────────────────────────
IconData _iconForCategory(Category cat) {
  final key = cat.slug.toLowerCase();
  if (key.contains('electro') || key.contains('tech')) {
    return Icons.devices_other;
  }
  if (key.contains('ropa') || key.contains('cloth') || key.contains('moda')) {
    return Icons.checkroom;
  }
  if (key.contains('deporte') || key.contains('sport')) {
    return Icons.sports_soccer;
  }
  if (key.contains('hogar') || key.contains('home') || key.contains('casa')) {
    return Icons.chair;
  }
  if (key.contains('juguete') || key.contains('toy')) return Icons.toys;
  if (key.contains('libro') || key.contains('book')) return Icons.menu_book;
  return Icons.label_outline;
}

// ── Reusable chip ───────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.primary : context.palette.surface;
    final fg = selected ? Colors.white : context.palette.textPrimary;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? AppColors.primary : context.palette.divider,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const Gap(6),
              ],
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty / error states ────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront_outlined,
              size: 64, color: context.palette.textHint),
          const Gap(12),
          Text(
            'Aún no hay publicaciones',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.palette.textPrimary,
            ),
          ),
          const Gap(4),
          Text(
            'Sé el primero en publicar un artículo',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: context.palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 60, color: context.palette.textHint),
          const Gap(12),
          Text(
            'No pudimos cargar los productos',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.palette.textPrimary,
            ),
          ),
          const Gap(12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
