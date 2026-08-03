/// Admin — moderación de usuarios: reportes recibidos y apelaciones de cuentas
/// bloqueadas. Permite banear/desbanear.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';
import '../../data/admin_repository.dart';
import '../providers/admin_provider.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: context.palette.surface,
            child: TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: context.palette.textSecondary,
              indicatorColor: AppColors.primary,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              tabs: const [
                Tab(text: 'Reportes'),
                Tab(text: 'Apelaciones'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [_ReportsList(), _AppealsList()],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reportes ─────────────────────────────────────────────
class _ReportsList extends ConsumerWidget {
  const _ReportsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminReportsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        if (items.isEmpty) {
          return Center(
              child: Text('Sin reportes',
                  style: GoogleFonts.poppins(
                      color: context.palette.textSecondary)));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.refresh(adminReportsProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Gap(10),
            itemBuilder: (context, i) => _ReportTile(report: items[i]),
          ),
        );
      },
    );
  }
}

class _ReportTile extends ConsumerStatefulWidget {
  final AdminReport report;
  const _ReportTile({required this.report});

  @override
  ConsumerState<_ReportTile> createState() => _ReportTileState();
}

class _ReportTileState extends ConsumerState<_ReportTile> {
  bool _working = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _working = true);
    try {
      await action();
      ref.invalidate(adminReportsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.palette.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${r.reporterName} reportó a ${r.reportedName}',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700)),
          Text('${r.reason} · ${DateFormat('dd/MM/yyyy').format(r.createdAt.toLocal())}',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: context.palette.textSecondary)),
          if (r.details != null && r.details!.isNotEmpty) ...[
            const Gap(4),
            Text(r.details!,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: context.palette.textPrimary)),
          ],
          const Gap(10),
          if (_working)
            const Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => context.push('/user/${r.reportedId}'),
                  child: const Text('Ver perfil'),
                ),
                if (r.reportedBanned)
                  OutlinedButton(
                    onPressed: () => _run(() => ref
                        .read(adminRepositoryProvider)
                        .unbanUser(r.reportedId)),
                    child: const Text('Desbanear'),
                  )
                else
                  FilledButton(
                    style:
                        FilledButton.styleFrom(backgroundColor: AppColors.error),
                    onPressed: () => _run(() => ref
                        .read(adminRepositoryProvider)
                        .banUser(r.reportedId, r.reason)),
                    child: const Text('Banear'),
                  ),
                if (r.status == 'open')
                  TextButton(
                    onPressed: () => _run(() => ref
                        .read(adminRepositoryProvider)
                        .setReportStatus(r.id, 'dismissed')),
                    child: const Text('Descartar'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Apelaciones ──────────────────────────────────────────
class _AppealsList extends ConsumerWidget {
  const _AppealsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminAppealsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        if (items.isEmpty) {
          return Center(
              child: Text('Sin apelaciones',
                  style: GoogleFonts.poppins(
                      color: context.palette.textSecondary)));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.refresh(adminAppealsProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Gap(10),
            itemBuilder: (context, i) => _AppealTile(appeal: items[i]),
          ),
        );
      },
    );
  }
}

class _AppealTile extends ConsumerStatefulWidget {
  final AdminAppeal appeal;
  const _AppealTile({required this.appeal});

  @override
  ConsumerState<_AppealTile> createState() => _AppealTileState();
}

class _AppealTileState extends ConsumerState<_AppealTile> {
  bool _working = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _working = true);
    try {
      await action();
      ref.invalidate(adminAppealsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.appeal;
    final pending = a.status == 'pending';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.palette.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(a.userName,
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              Text(a.status,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: pending
                          ? AppColors.warning
                          : context.palette.textHint)),
            ],
          ),
          const Gap(4),
          Text(a.message,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: context.palette.textPrimary)),
          const Gap(10),
          if (_working)
            const Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)))
          else if (pending)
            Row(
              children: [
                FilledButton(
                  onPressed: () => _run(() => ref
                      .read(adminRepositoryProvider)
                      .resolveAppeal(a.id, a.userId, true)),
                  child: const Text('Aceptar (desbanear)'),
                ),
                const Gap(8),
                OutlinedButton(
                  style:
                      OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                  onPressed: () => _run(() => ref
                      .read(adminRepositoryProvider)
                      .resolveAppeal(a.id, a.userId, false)),
                  child: const Text('Rechazar'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
