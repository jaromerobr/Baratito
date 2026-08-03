/// Providers de moderación: bloqueos personales y estado de baneo.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/moderation_repository.dart';

final moderationRepositoryProvider =
    Provider<ModerationRepository>((ref) => ModerationRepository());

/// Ids de usuarios que el usuario actual ha bloqueado (para ocultar su contenido).
final blockedIdsProvider = FutureProvider<Set<String>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(moderationRepositoryProvider).getBlockedIds();
});

/// ¿Tengo bloqueado a este usuario?
final isBlockedProvider =
    FutureProvider.family<bool, String>((ref, userId) async {
  final ids = await ref.watch(blockedIdsProvider.future);
  return ids.contains(userId);
});

/// Estado de baneo de la cuenta del usuario actual.
final banStatusProvider = FutureProvider<BanStatus>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(moderationRepositoryProvider).myBanStatus();
});
