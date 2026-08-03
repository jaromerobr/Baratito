/// Acciones de moderación sobre otro usuario: reportar y bloquear/desbloquear.
/// Reutilizable desde el perfil público y el chat.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/moderation_providers.dart';

const List<String> kReportReasons = [
  'Spam o publicidad',
  'Contenido inapropiado',
  'Fraude o estafa',
  'Acoso o insultos',
  'Otro',
];

void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating, content: Text(msg)));
}

/// Muestra el diálogo de reporte y lo envía.
Future<void> reportUserFlow(
  BuildContext context,
  WidgetRef ref, {
  required String reportedId,
  String? reportedName,
}) async {
  var reason = kReportReasons.first;
  final detailsCtrl = TextEditingController();

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: Text('Reportar a ${reportedName ?? 'este usuario'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final r in kReportReasons)
              ListTile(
                onTap: () => setLocal(() => reason = r),
                title: Text(r),
                dense: true,
                contentPadding: EdgeInsets.zero,
                trailing: reason == r
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : const Icon(Icons.radio_button_unchecked),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: detailsCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Detalles (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enviar reporte')),
        ],
      ),
    ),
  );

  if (ok != true) return;
  try {
    await ref.read(moderationRepositoryProvider).reportUser(
          reportedId: reportedId,
          reason: reason,
          details: detailsCtrl.text,
        );
    if (context.mounted) {
      _snack(context, 'Reporte enviado. Gracias, lo revisaremos.');
    }
  } catch (e) {
    if (context.mounted) _snack(context, 'No se pudo reportar: $e');
  }
}

/// Bloquea o desbloquea al usuario. Devuelve el nuevo estado (true = bloqueado).
Future<bool?> toggleBlockFlow(
  BuildContext context,
  WidgetRef ref, {
  required String userId,
  required bool currentlyBlocked,
  String? name,
}) async {
  if (!currentlyBlocked) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Bloquear a ${name ?? 'este usuario'}?'),
        content: const Text(
            'Dejarás de ver sus productos y sus mensajes. Puedes desbloquearlo cuando quieras.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Bloquear')),
        ],
      ),
    );
    if (ok != true) return null;
  }

  try {
    final repo = ref.read(moderationRepositoryProvider);
    if (currentlyBlocked) {
      await repo.unblockUser(userId);
    } else {
      await repo.blockUser(userId);
    }
    ref.invalidate(blockedIdsProvider);
    ref.invalidate(isBlockedProvider(userId));
    if (context.mounted) {
      _snack(context, currentlyBlocked ? 'Usuario desbloqueado' : 'Usuario bloqueado');
    }
    return !currentlyBlocked;
  } catch (e) {
    if (context.mounted) _snack(context, 'Error: $e');
    return null;
  }
}
