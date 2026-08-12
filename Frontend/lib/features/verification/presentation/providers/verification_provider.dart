/// Riverpod providers for identity verification + the publish/buy gate.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/verification_repository.dart';
import '../../domain/publish_permission.dart';
import '../../domain/verification_model.dart';

// The gate enum + the publish rule live in `domain`; re-exported here so the
// existing UI imports keep working.
export '../../domain/publish_permission.dart' show VerifyGate, PublishPermission;

final verificationRepositoryProvider =
    Provider<VerificationRepository>((ref) => VerificationRepository());

/// The current user's latest verification request (refreshes on auth change).
final myVerificationProvider =
    FutureProvider<IdentityVerification?>((ref) async {
  ref.watch(authStateProvider); // re-fetch on login/logout
  return ref.watch(verificationRepositoryProvider).getMyLatest();
});

/// Resolves the gate from the profile flag + the latest request status.
final verifyGateProvider = Provider<VerifyGate>((ref) {
  final profile = ref.watch(currentUserProfileProvider);
  final verification = ref.watch(myVerificationProvider);

  // Not logged in?
  final isLoggedIn = profile.maybeWhen(
    data: (p) => p != null,
    orElse: () => false,
  );

  return profile.when(
    loading: () => VerifyGate.loading,
    error: (_, _) => VerifyGate.notSubmitted,
    data: (p) {
      if (!isLoggedIn) return VerifyGate.notLoggedIn;
      if (p!.isVerified) return VerifyGate.verified;

      return verification.maybeWhen(
        data: (v) {
          if (v == null) return VerifyGate.notSubmitted;
          switch (v.status) {
            case VerifyStatus.approved:
              return VerifyGate.verified;
            case VerifyStatus.pending:
            case VerifyStatus.unknown:
              return VerifyGate.pending;
            case VerifyStatus.rejected:
              return VerifyGate.rejected;
          }
        },
        orElse: () => VerifyGate.loading,
      );
    },
  );
});
