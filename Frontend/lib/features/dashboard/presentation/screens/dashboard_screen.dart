/// Dashboard screen — Main hub after login.
///
/// Shows a branded greeting, user info, quick action cards,
/// and a "Dio + FutureBuilder" demo button.
/// Adapts the greeting based on the user's role (buyer/seller/both).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:gap/gap.dart';
import '../../../../core/router.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(currentUserProfileProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Branded header ────────────────────────────
          SliverToBoxAdapter(
            child: _DashboardHeader(
              userProfile: userProfile,
              onLogout: () async {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) context.go(AppRoutes.login);
              },
            ),
          ),

          // ── Content ───────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick stats row
                _buildQuickStats(cs),
                const Gap(24),

                // Section title
                Text(
                  'Acciones rápidas',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const Gap(14),

                // Action cards grid
                _buildActionCards(context, cs),
                const Gap(24),

                // Maintenance banner
                _buildMaintenanceBanner(cs),
                const Gap(24),

                // Dio demo button
                _buildDioDemo(context, cs),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick stats ───────────────────────────────────────
  Widget _buildQuickStats(ColorScheme cs) {
    return Row(
      children: [
        _StatCard(
          icon: Icons.shopping_bag_rounded,
          label: 'Compras',
          value: '0',
          color: cs.primary,
        ),
        const Gap(12),
        _StatCard(
          icon: Icons.sell_rounded,
          label: 'Ventas',
          value: '0',
          color: cs.secondary,
        ),
        const Gap(12),
        _StatCard(
          icon: Icons.star_rounded,
          label: 'Rating',
          value: '—',
          color: cs.tertiary,
        ),
      ],
    );
  }

  // ── Action cards ──────────────────────────────────────
  Widget _buildActionCards(BuildContext context, ColorScheme cs) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.search_rounded,
                title: 'Explorar',
                subtitle: 'Buscar productos',
                gradient: [cs.primary, cs.primaryContainer],
                onTap: () {},
                comingSoon: true,
              ),
            ),
            const Gap(12),
            Expanded(
              child: _ActionCard(
                icon: Icons.add_circle_outline_rounded,
                title: 'Publicar',
                subtitle: 'Vender algo',
                gradient: [cs.secondary, cs.secondaryContainer],
                onTap: () {},
                comingSoon: true,
              ),
            ),
          ],
        ),
        const Gap(12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Mensajes',
                subtitle: '0 nuevos',
                gradient: [cs.tertiary, cs.tertiaryContainer],
                onTap: () {},
                comingSoon: true,
              ),
            ),
            const Gap(12),
            Expanded(
              child: _ActionCard(
                icon: Icons.person_outline_rounded,
                title: 'Mi Perfil',
                subtitle: 'Editar datos',
                gradient: [cs.inversePrimary, cs.primaryContainer],
                onTap: () {},
                comingSoon: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Maintenance banner ────────────────────────────────
  Widget _buildMaintenanceBanner(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.secondary.withAlpha(30),
            cs.primary.withAlpha(20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.secondary.withAlpha(80),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cs.secondary.withAlpha(50),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.construction_rounded,
              color: cs.secondary,
              size: 26,
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Módulos en construcción',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const Gap(2),
                Text(
                  'Los módulos de compra, venta y chat estarán disponibles en las próximas semanas.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Dio demo button ───────────────────────────────────
  Widget _buildDioDemo(BuildContext context, ColorScheme cs) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primaryContainer],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withAlpha(60),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: cs.surface.withAlpha(0),
        child: InkWell(
          onTap: () => context.push(AppRoutes.posts),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: cs.onPrimary.withAlpha(40),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.cloud_download_rounded,
                    color: cs.onPrimary,
                    size: 24,
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Demo Dio + FutureBuilder',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: cs.onPrimary,
                        ),
                      ),
                      Text(
                        'Petición async con 3 estados reactivos',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: cs.onPrimary.withAlpha(200),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: cs.onPrimary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Dashboard Header ────────────────────────────────────
class _DashboardHeader extends StatelessWidget {
  final AsyncValue userProfile;
  final VoidCallback onLogout;

  const _DashboardHeader({
    required this.userProfile,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final cs = Theme.of(context).colorScheme;
    final themeModel = context.watch<ThemeModel>();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.secondary, cs.secondaryContainer],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: logo + theme toggle + logout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: cs.shadow.withAlpha(15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'B',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: cs.onSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Theme toggle button
                  Material(
                    color: cs.onSecondary.withAlpha(80),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => context.read<ThemeModel>().toggleTheme(),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          themeModel.isDarkMode
                              ? Icons.wb_sunny
                              : Icons.nights_stay,
                          color: cs.onSecondary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const Gap(8),
                  // Logout button
                  Material(
                    color: cs.onSecondary.withAlpha(80),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: onLogout,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.logout_rounded,
                          color: cs.onSecondary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Gap(24),

          // Greeting
          userProfile.when(
            data: (profile) {
              final name = profile?.fullName ?? 'Usuario';
              final firstName = name.split(' ').first;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Hola, $firstName! 👋',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: cs.onSecondary,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    '¿Qué quieres hacer hoy?',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: cs.onSecondary.withAlpha(180),
                    ),
                  ),
                ],
              );
            },
            loading: () => Text(
              '¡Bienvenido! 👋',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: cs.onSecondary,
              ),
            ),
            error: (_, __) => Text(
              '¡Bienvenido! 👋',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: cs.onSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Card ───────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Gap(8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action Card ─────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;
  final bool comingSoon;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: cs.surface.withAlpha(0),
        child: InkWell(
          onTap: comingSoon ? null : onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: cs.onPrimary, size: 28),
                    if (comingSoon)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.onPrimary.withAlpha(40),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Pronto',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: cs.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
                const Gap(14),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: cs.onPrimary.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
