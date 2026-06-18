/// Dashboard screen — Main hub after login.
///
/// Shows a branded greeting, user info, quick action cards,
/// and a "Dio + FutureBuilder" demo button.
/// Logout usa AuthProvider.logout() — GoRouter redirige automáticamente.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.currentUser?.name ?? 'Usuario';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // ── Branded header ────────────────────────────
          SliverToBoxAdapter(
            child: _DashboardHeader(
              userName: userName,
              onLogout: () {
                Provider.of<AuthProvider>(context, listen: false).logout();
                // GoRouter redirige a /login vía refreshListenable
              },
            ),
          ),

          // ── Content ───────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick stats row
                _buildQuickStats(),
                const Gap(24),

                // Section title
                Text(
                  'Acciones rápidas',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Gap(14),

                // Action cards grid
                _buildActionCards(context),
                const Gap(24),

                // Maintenance banner
                _buildMaintenanceBanner(),
                const Gap(24),

                // Dio demo button
                _buildDioDemo(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick stats ───────────────────────────────────────
  Widget _buildQuickStats() {
    return Row(
      children: [
        _StatCard(
          icon: Icons.shopping_bag_rounded,
          label: 'Compras',
          value: '0',
          color: AppColors.primary,
        ),
        const Gap(12),
        _StatCard(
          icon: Icons.sell_rounded,
          label: 'Ventas',
          value: '0',
          color: AppColors.accent,
        ),
        const Gap(12),
        _StatCard(
          icon: Icons.star_rounded,
          label: 'Rating',
          value: '—',
          color: const Color(0xFFE67E22),
        ),
      ],
    );
  }

  // ── Action cards ──────────────────────────────────────
  Widget _buildActionCards(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.search_rounded,
                title: 'Explorar',
                subtitle: 'Buscar productos',
                gradient: const [Color(0xFF2ECC71), Color(0xFF27AE60)],
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
                gradient: const [Color(0xFFF39C12), Color(0xFFE67E22)],
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
                gradient: const [Color(0xFF3498DB), Color(0xFF2980B9)],
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
                gradient: const [Color(0xFF9B59B6), Color(0xFF8E44AD)],
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
  Widget _buildMaintenanceBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withAlpha(30),
            AppColors.primary.withAlpha(20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withAlpha(80),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(50),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.construction_rounded,
              color: AppColors.accentDark,
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
                    color: AppColors.textPrimary,
                  ),
                ),
                const Gap(2),
                Text(
                  'Los módulos de compra, venta y chat estarán disponibles en las próximas semanas.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
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
  Widget _buildDioDemo(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(60),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/posts'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.cloud_download_rounded,
                    color: Colors.white,
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
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Petición async con 3 estados reactivos',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withAlpha(200),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
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
  final String userName;
  final VoidCallback onLogout;

  const _DashboardHeader({
    required this.userName,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final firstName = userName.split(' ').first;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent, AppColors.headerYellow],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: logo + logout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(15),
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
                          color: AppColors.primary,
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
                      color: AppColors.primaryDark,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              // Logout button — no context.go(), GoRouter redirige solo
              Material(
                color: Colors.white.withAlpha(80),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: onLogout,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.logout_rounded,
                      color: AppColors.primaryDark,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Gap(24),

          // Greeting
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Hola, $firstName! 👋',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              const Gap(4),
              Text(
                '¿Qué quieres hacer hoy?',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryDark.withAlpha(180),
                ),
              ),
            ],
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
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
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.textSecondary,
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
        color: Colors.transparent,
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
                    Icon(icon, color: Colors.white, size: 28),
                    if (comingSoon)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Pronto',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white.withAlpha(200),
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
