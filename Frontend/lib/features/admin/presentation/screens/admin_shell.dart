/// Admin panel shell — tabs for dashboard, verifications and (later) products.
library;

import 'package:flutter/material.dart';
import 'package:baratito/widgets/baratito_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';
import '../providers/admin_provider.dart';
import 'admin_dashboard_screen.dart';
import 'admin_verifications_screen.dart';
import 'admin_payments_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_reports_screen.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);

    return isAdmin.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: BaratitoAppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (admin) {
        if (!admin) {
          return Scaffold(
            appBar: BaratitoAppBar(title: const Text('Panel de administración')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline,
                        size: 56, color: context.palette.textHint),
                    const SizedBox(height: 12),
                    Text('Acceso restringido',
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('Esta sección es solo para administradores.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: context.palette.textSecondary)),
                  ],
                ),
              ),
            ),
          );
        }

        return DefaultTabController(
          length: 5,
          child: Scaffold(
            backgroundColor: context.palette.background,
            appBar: BaratitoAppBar(
              title: Text('Administración',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              bottom: TabBar(
                isScrollable: true,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: AppColors.accent,
                tabs: [
                  Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Resumen'),
                  Tab(
                      icon: Icon(Icons.verified_user_rounded),
                      text: 'Verificaciones'),
                  Tab(icon: Icon(Icons.payments_rounded), text: 'Pagos'),
                  Tab(
                      icon: Icon(Icons.local_shipping_rounded),
                      text: 'Pedidos'),
                  Tab(icon: Icon(Icons.flag_rounded), text: 'Reportes'),
                ],
              ),
            ),
            body: const TabBarView(
              children: [
                AdminDashboardScreen(),
                AdminVerificationsScreen(),
                AdminPaymentsScreen(),
                AdminOrdersScreen(),
                AdminReportsScreen(),
              ],
            ),
          ),
        );
      },
    );
  }
}
