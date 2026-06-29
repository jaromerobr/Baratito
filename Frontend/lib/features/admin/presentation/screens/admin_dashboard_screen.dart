/// Admin dashboard — key metrics for Baratito.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/admin_overview.dart';
import '../providers/admin_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminOverviewProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const Gap(12),
              Text('No se pudieron cargar las métricas',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              const Gap(8),
              Text('$e',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textSecondary)),
              const Gap(12),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(adminOverviewProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      data: (m) => RefreshIndicator(
        onRefresh: () async => ref.refresh(adminOverviewProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── KPI grid ────────────────────────────────
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _Kpi(
                  icon: Icons.people_alt_rounded,
                  label: 'Usuarios',
                  value: '${m.usersTotal}',
                  sub: '+${m.usersNew7d} esta semana',
                  color: AppColors.primary,
                ),
                _Kpi(
                  icon: Icons.verified_user_rounded,
                  label: 'Verificados',
                  value: '${m.usersVerified}',
                  sub: '${m.verifiedRate.toStringAsFixed(0)}% del total',
                  color: AppColors.success,
                ),
                _Kpi(
                  icon: Icons.inventory_2_rounded,
                  label: 'Productos activos',
                  value: '${m.productsActive}',
                  sub: '${m.productsTotal} en total',
                  color: AppColors.accent,
                ),
                _Kpi(
                  icon: Icons.sell_rounded,
                  label: 'Vendidos',
                  value: '${m.productsSold}',
                  sub: '${m.ordersTotal} órdenes',
                  color: const Color(0xFF8E44AD),
                ),
              ],
            ),
            const Gap(16),

            // ── Verification funnel ─────────────────────
            _Section(
              title: 'Verificaciones de identidad',
              child: Column(
                children: [
                  _StatRow(
                    icon: Icons.hourglass_top_rounded,
                    color: AppColors.warning,
                    label: 'Pendientes (por revisar)',
                    value: m.verifPending,
                  ),
                  _StatRow(
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                    label: 'Aprobadas',
                    value: m.verifApproved,
                  ),
                  _StatRow(
                    icon: Icons.cancel_rounded,
                    color: AppColors.error,
                    label: 'Rechazadas',
                    value: m.verifRejected,
                  ),
                ],
              ),
            ),
            const Gap(16),

            // ── Products by category ────────────────────
            _Section(
              title: 'Productos por categoría',
              child: _BarList(
                items: m.byCategory,
                emptyText: 'Aún no hay productos publicados',
                color: AppColors.primary,
              ),
            ),
            const Gap(16),

            // ── Top sellers ─────────────────────────────
            _Section(
              title: 'Top vendedores (más publican)',
              child: _BarList(
                items: m.topSellers,
                emptyText: 'Aún no hay vendedores',
                color: AppColors.accent,
              ),
            ),
            const Gap(24),
          ],
        ),
      ),
    );
  }
}

// ── KPI card ────────────────────────────────────────────
class _Kpi extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _Kpi({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withAlpha(28),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const Spacer(),
              Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
            ],
          ),
          const Spacer(),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          Text(sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ── Section wrapper ─────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const Gap(12),
          child,
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int value;

  const _StatRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const Gap(10),
          Expanded(
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textPrimary)),
          ),
          Text('$value',
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

// ── Simple horizontal bar list ──────────────────────────
class _BarList extends StatelessWidget {
  final List<NamedCount> items;
  final String emptyText;
  final Color color;

  const _BarList({
    required this.items,
    required this.emptyText,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(emptyText,
          style: GoogleFonts.poppins(
              fontSize: 13, color: AppColors.textSecondary));
    }
    final maxValue =
        items.map((e) => e.total).reduce((a, b) => a > b ? a : b).toDouble();

    return Column(
      children: items.map((item) {
        final fraction = maxValue == 0 ? 0.0 : item.total / maxValue;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.textPrimary)),
                  ),
                  Text('${item.total}',
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
              const Gap(4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 7,
                  backgroundColor: color.withAlpha(25),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
