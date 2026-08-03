/// Providers de reseñas mutuas.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/review_repository.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository();
});

/// La calificación que el usuario actual ya dejó a otro usuario (null si no).
final myReviewForProvider =
    FutureProvider.family<int?, String>((ref, revieweeId) async {
  return ref.watch(reviewRepositoryProvider).myReviewFor(revieweeId);
});

/// Reseñas recibidas por un usuario.
final userReviewsProvider =
    FutureProvider.family<List<UserReview>, String>((ref, userId) async {
  return ref.watch(reviewRepositoryProvider).getUserReviews(userId);
});

/// Contrapartes de pedidos entregados que el usuario aún no ha calificado.
final pendingReviewsProvider = FutureProvider<List<PendingReview>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(reviewRepositoryProvider).getPendingReviews();
});
