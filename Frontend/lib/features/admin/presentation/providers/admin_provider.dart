/// Riverpod providers for the admin panel.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/admin_repository.dart';
import '../../domain/admin_overview.dart';
import '../../../verification/domain/verification_model.dart';

final adminRepositoryProvider =
    Provider<AdminRepository>((ref) => AdminRepository());

/// Whether the current user is an admin (gates the panel entry).
final isAdminProvider = FutureProvider<bool>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(adminRepositoryProvider).isCurrentUserAdmin();
});

/// Dashboard metrics.
final adminOverviewProvider = FutureProvider<AdminOverview>((ref) async {
  return ref.watch(adminRepositoryProvider).getOverview();
});

/// Verification queue, filtered by the selected status.
final verificationFilterProvider =
    StateProvider<VerifyStatus>((ref) => VerifyStatus.pending);

final adminVerificationsProvider =
    FutureProvider<List<AdminVerificationItem>>((ref) async {
  final status = ref.watch(verificationFilterProvider);
  return ref.watch(adminRepositoryProvider).getVerifications(status: status);
});

/// Checkouts pending confirmation (commission collection).
final adminCheckoutsProvider =
    FutureProvider<List<AdminCheckoutItem>>((ref) async {
  return ref.watch(adminRepositoryProvider).getCheckouts(onlyPending: true);
});

/// Commission earned + pending payouts.
final commissionSummaryProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(adminRepositoryProvider).commissionSummary();
});
