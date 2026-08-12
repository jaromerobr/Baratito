/// Publishing permission — pure domain rule for "who may publish".
///
/// Lives in `domain` (no Riverpod, no Supabase) so the rule can be unit
/// tested without a session, a network call or a widget tree.
library;

/// Whether the user can publish/buy, and why not.
enum VerifyGate {
  loading,
  notLoggedIn,
  notSubmitted,
  pending,
  rejected,
  verified,
}

/// Business rule: a seller must have an **approved** identity verification
/// before publishing an article.
class PublishPermission {
  PublishPermission._();

  /// Resolves whether the current user may open the publish form.
  ///
  /// - Admins are exempt from identity verification (they moderate the
  ///   marketplace and are trusted by definition).
  /// - A signed-out user can never publish, whatever the other flags say.
  /// - Any non-conclusive state (loading, pending, rejected, not submitted)
  ///   denies publishing: the gate is deliberately fail-closed.
  static bool canPublish({required VerifyGate gate, required bool isAdmin}) {
    if (gate == VerifyGate.notLoggedIn) return false;
    if (isAdmin) return true;
    return gate == VerifyGate.verified;
  }
}