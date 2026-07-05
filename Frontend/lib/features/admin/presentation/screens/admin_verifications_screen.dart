/// Admin — verification review queue.
///
/// Filter by status, open a request to see the cédula (front/back) + selfie
/// (private images via signed URLs) and approve / reject.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';
import '../../../verification/domain/verification_model.dart';
import '../../data/admin_repository.dart';
import '../providers/admin_provider.dart';

class AdminVerificationsScreen extends ConsumerWidget {
  const AdminVerificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(verificationFilterProvider);
    final async = ref.watch(adminVerificationsProvider);

    return Column(
      children: [
        // ── Status filter (desplazable para evitar overflow) ──
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              _FilterChip(
                label: 'Pendientes',
                selected: filter == VerifyStatus.pending,
                onTap: () => ref.read(verificationFilterProvider.notifier).state =
                    VerifyStatus.pending,
              ),
              const Gap(8),
              _FilterChip(
                label: 'Aprobadas',
                selected: filter == VerifyStatus.approved,
                onTap: () => ref.read(verificationFilterProvider.notifier).state =
                    VerifyStatus.approved,
              ),
              const Gap(8),
              _FilterChip(
                label: 'Rechazadas',
                selected: filter == VerifyStatus.rejected,
                onTap: () => ref.read(verificationFilterProvider.notifier).state =
                    VerifyStatus.rejected,
              ),
            ],
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Text('No hay verificaciones aquí',
                      style: GoogleFonts.poppins(
                          color: context.palette.textSecondary)),
                );
              }
              return RefreshIndicator(
                onRefresh: () async =>
                    ref.refresh(adminVerificationsProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Gap(10),
                  itemBuilder: (context, i) => _VerificationTile(item: items[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : context.palette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.primary : context.palette.divider),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : context.palette.textPrimary)),
      ),
    );
  }
}

// ── List tile ───────────────────────────────────────────
class _VerificationTile extends StatelessWidget {
  final AdminVerificationItem item;
  const _VerificationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final v = item.verification;
    final score = v.faceMatchScore;
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(v.createdAt.toLocal());

    return Material(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AdminVerificationDetailScreen(item: item),
        )),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withAlpha(30),
                child: const Icon(Icons.person, color: AppColors.primary),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(item.userEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: context.palette.textSecondary)),
                    Text(dateStr,
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: context.palette.textHint)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ScoreBadge(score: score),
                  const Gap(6),
                  _StatusBadge(status: v.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final double? score;
  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    if (score == null) {
      return Text('Sin score',
          style: GoogleFonts.poppins(
              fontSize: 11, color: context.palette.textHint));
    }
    final pct = (score! * 100).toStringAsFixed(0);
    final color = score! > 0.80
        ? AppColors.success
        : (score! >= 0.5 ? AppColors.warning : AppColors.error);
    return Text('Match $pct%',
        style: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w700, color: color));
  }
}

class _StatusBadge extends StatelessWidget {
  final VerifyStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (String text, Color color) = switch (status) {
      VerifyStatus.approved => ('Aprobada', AppColors.success),
      VerifyStatus.rejected => ('Rechazada', AppColors.error),
      _ => ('Pendiente', AppColors.warning),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: GoogleFonts.poppins(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ── Detail screen ───────────────────────────────────────
class AdminVerificationDetailScreen extends ConsumerStatefulWidget {
  final AdminVerificationItem item;
  const AdminVerificationDetailScreen({super.key, required this.item});

  @override
  ConsumerState<AdminVerificationDetailScreen> createState() =>
      _AdminVerificationDetailScreenState();
}

class _AdminVerificationDetailScreenState
    extends ConsumerState<AdminVerificationDetailScreen> {
  bool _working = false;

  Future<void> _approve() async {
    setState(() => _working = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .approveVerification(widget.item.verification.id);
      _afterAction('Verificación aprobada ✓');
    } catch (e) {
      _onError(e);
    }
  }

  Future<void> _reject() async {
    final reason = await _askReason();
    if (reason == null) return;
    setState(() => _working = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .rejectVerification(widget.item.verification.id, reason);
      _afterAction('Verificación rechazada');
    } catch (e) {
      _onError(e);
    }
  }

  void _afterAction(String msg) {
    ref.invalidate(adminVerificationsProvider);
    ref.invalidate(adminOverviewProvider);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _onError(Object e) {
    if (!mounted) return;
    setState(() => _working = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Error: $e')));
  }

  Future<String?> _askReason() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Motivo del rechazo'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
              hintText: 'Ej. La cédula no es legible'),
          maxLines: 2,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.item.verification;
    final repo = ref.read(adminRepositoryProvider);
    final isPending = v.status == VerifyStatus.pending;

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: const Text('Revisar verificación')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(widget.item.userName,
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            Text(widget.item.userEmail,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: context.palette.textSecondary)),
            const Gap(8),
            Row(
              children: [
                _ScoreBadge(score: v.faceMatchScore),
                const Gap(10),
                _StatusBadge(status: v.status),
              ],
            ),
            if (v.cedulaNumber != null) ...[
              const Gap(8),
              Text('Cédula (OCR): ${v.cedulaNumber}',
                  style: GoogleFonts.poppins(fontSize: 13)),
            ],
            if (v.ocrExtractedName != null)
              Text('Nombre (OCR): ${v.ocrExtractedName}',
                  style: GoogleFonts.poppins(fontSize: 13)),
            if (v.rejectionReason != null && v.rejectionReason!.isNotEmpty) ...[
              const Gap(6),
              Text('Nota: ${v.rejectionReason}',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.error)),
            ],
            const Gap(20),
            _ImageBlock(
                title: 'Cédula — frontal',
                future: repo.signedImageUrl(v.cedulaFrontPath)),
            const Gap(14),
            _ImageBlock(
                title: 'Cédula — posterior',
                future: repo.signedImageUrl(v.cedulaBackPath)),
            const Gap(14),
            _ImageBlock(
                title: 'Selfie',
                future: repo.signedImageUrl(v.selfiePath)),
            const Gap(24),
            if (isPending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _working ? null : _reject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      icon: const Icon(Icons.close),
                      label: const Text('Rechazar'),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _working ? null : _approve,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text('Aprobar'),
                    ),
                  ),
                ],
              ),
            if (_working) ...[
              const Gap(16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}

class _ImageBlock extends StatelessWidget {
  final String title;
  final Future<String?> future;
  const _ImageBlock({required this.title, required this.future});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w700)),
        const Gap(6),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: FutureBuilder<String?>(
            future: future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Container(
                  height: 200,
                  color: context.palette.inputFill,
                  child: const Center(child: CircularProgressIndicator()),
                );
              }
              final url = snap.data;
              if (url == null) {
                return Container(
                  height: 120,
                  color: context.palette.inputFill,
                  alignment: Alignment.center,
                  child: const Text('Sin imagen'),
                );
              }
              return Image.network(
                url,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 120,
                  color: context.palette.inputFill,
                  alignment: Alignment.center,
                  child: const Text('No se pudo cargar'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
