/// Main shell with bottom navigation + center "publish" FAB.
///
/// Tabs: Inicio (marketplace), Guardados (favorites), Compras, Perfil.
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
import '../../../verification/presentation/providers/verification_provider.dart';
import '../../../admin/presentation/providers/admin_provider.dart';
import '../../../chat/presentation/screens/conversations_screen.dart';
import '../../../favorites/presentation/screens/saved_screen.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../../core/router.dart';
import '../../../../core/supabase_client.dart';
import 'home_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          SavedScreen(),
          ConversationsScreen(),
          _ProfileTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onPublishTap(context),
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomBar(
        index: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }

  void _onPublishTap(BuildContext context) {
    final loggedIn = SupabaseClientHelper.auth.currentUser != null;
    if (!loggedIn) {
      // Capturamos el router AHORA (contexto válido); la acción del SnackBar
      // se dispara después, cuando este contexto podría estar desactivado.
      final router = GoRouter.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Inicia sesión para publicar'),
          action: SnackBarAction(
            label: 'Entrar',
            onPressed: () => router.go(AppRoutes.login),
          ),
        ),
      );
      return;
    }

    // Gate: solo usuarios verificados pueden publicar.
    final gate = ref.read(verifyGateProvider);
    if (gate == VerifyGate.verified) {
      context.push('/publish');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Verifica tu identidad para publicar')),
      );
      context.push('/verify');
    }
  }
}

// ── Bottom navigation bar ───────────────────────────────
class _BottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  const _BottomBar({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: context.palette.surface,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      height: 68,
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BarItem(
            icon: Icons.home_rounded,
            label: 'Inicio',
            active: index == 0,
            onTap: () => onTap(0),
          ),
          _BarItem(
            icon: Icons.favorite_rounded,
            label: 'Guardados',
            active: index == 1,
            onTap: () => onTap(1),
          ),
          const SizedBox(width: 40), // space for the FAB notch
          _BarItem(
            icon: Icons.chat_bubble_rounded,
            label: 'Chats',
            active: index == 2,
            onTap: () => onTap(2),
          ),
          _BarItem(
            icon: Icons.person_rounded,
            label: 'Perfil',
            active: index == 3,
            onTap: () => onTap(3),
          ),
        ],
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _BarItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : context.palette.textHint;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const Gap(2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile tab ─────────────────────────────────────────
class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final p = profileAsync.valueOrNull;
    final avatarUrl = ProfileRepository.avatarUrl(p?.avatarPath);
    final loggedIn = SupabaseClientHelper.auth.currentUser != null;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          // Header: avatar + name + edit
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primary,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? const Icon(Icons.person, size: 38, color: Colors.white)
                    : null,
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p?.fullName ?? (loggedIn ? 'Usuario' : 'Invitado'),
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    if (p?.username != null)
                      Text('@${p!.username}',
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: AppColors.primary)),
                    Text(
                      p?.email ?? 'Inicia sesión para ver tu perfil',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: context.palette.textSecondary),
                    ),
                  ],
                ),
              ),
              if (loggedIn)
                IconButton(
                  onPressed: () => context.push('/profile/edit'),
                  icon: const Icon(Icons.edit_outlined,
                      color: AppColors.primary),
                ),
            ],
          ),
          if (p?.bio != null && p!.bio!.isNotEmpty) ...[
            const Gap(10),
            Text(p.bio!,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: context.palette.textSecondary)),
          ],
          const Gap(20),
          const _VerificationCard(),
          const Gap(12),
          const _ThemeMenuItem(),
          const Gap(8),

          // Menú
          if (loggedIn) ...[
            _MenuItem(
              icon: Icons.inventory_2_outlined,
              label: 'Mis productos',
              subtitle: 'En venta y vendidos',
              onTap: () => context.push('/my-products'),
            ),
            _MenuItem(
              icon: Icons.shopping_bag_outlined,
              label: 'Mis compras',
              subtitle: 'Historial de compras',
              onTap: () => context.push('/purchases'),
            ),
            _MenuItem(
              icon: Icons.person_outline,
              label: 'Editar perfil',
              subtitle: 'Foto, nombre, bio y más',
              onTap: () => context.push('/profile/edit'),
            ),
            const Gap(8),
            const _AdminEntry(),
            const Gap(16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (context.mounted) context.go(AppRoutes.login);
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar sesión'),
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Iniciar sesión'),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Profile menu item ───────────────────────────────────
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(22),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 21),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                      Text(subtitle,
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: context.palette.textSecondary)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: context.palette.textHint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Theme toggle row (Perfil) ───────────────────────────
class _ThemeMenuItem extends StatelessWidget {
  const _ThemeMenuItem();

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeModel>().isDarkMode;
    return Material(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(22),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: AppColors.primary,
                  size: 21),
            ),
            const Gap(12),
            Expanded(
              child: Text('Modo oscuro',
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ),
            Switch(
              value: isDark,
              activeThumbColor: AppColors.primary,
              onChanged: (_) => context.read<ThemeModel>().toggleTheme(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Verification status card (Perfil) ───────────────────
class _VerificationCard extends ConsumerWidget {
  const _VerificationCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gate = ref.watch(verifyGateProvider);

    final (IconData icon, Color color, String title, String subtitle, bool action) =
        switch (gate) {
      VerifyGate.verified => (
          Icons.verified_rounded,
          AppColors.success,
          'Identidad verificada',
          'Puedes publicar y comprar',
          false,
        ),
      VerifyGate.pending => (
          Icons.hourglass_top_rounded,
          AppColors.warning,
          'Verificación en revisión',
          'Toca para ver el estado',
          true,
        ),
      VerifyGate.rejected => (
          Icons.cancel_outlined,
          AppColors.error,
          'Verificación rechazada',
          'Toca para reintentar',
          true,
        ),
      _ => (
          Icons.shield_outlined,
          AppColors.primary,
          'Verifica tu identidad',
          'Necesario para comprar y vender',
          true,
        ),
    };

    return Material(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: action ? () => context.push('/verify') : null,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withAlpha(90)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.palette.textPrimary)),
                    Text(subtitle,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: context.palette.textSecondary)),
                  ],
                ),
              ),
              if (action)
                Icon(Icons.chevron_right, color: context.palette.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Admin panel entry (solo admins) ─────────────────────
class _AdminEntry extends ConsumerWidget {
  const _AdminEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider).maybeWhen(
          data: (v) => v,
          orElse: () => false,
        );
    if (!isAdmin) return const SizedBox.shrink();

    return Material(
      color: AppColors.primaryDark,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/admin'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              const Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white, size: 26),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Panel de administración',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    Text('Métricas y verificaciones',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withAlpha(200))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
