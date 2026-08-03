/// Reportar/bloquear usuarios (personal), estado de baneo de cuenta y
/// apelaciones. Ver `Backend/20_reports_blocks.sql`.
library;

import '../../../core/supabase_client.dart';

typedef BanStatus = ({bool banned, String? reason});

class ModerationRepository {
  final _client = SupabaseClientHelper.client;

  String? get _uid => _client.auth.currentUser?.id;

  // ── Bloqueo personal ──────────────────────────────────
  Future<Set<String>> getBlockedIds() async {
    final uid = _uid;
    if (uid == null) return {};
    final data = await _client
        .from('user_blocks')
        .select('blocked_id')
        .eq('blocker_id', uid);
    return (data as List)
        .map((e) => (e as Map<String, dynamic>)['blocked_id'] as String)
        .toSet();
  }

  Future<bool> isBlocked(String userId) async {
    final uid = _uid;
    if (uid == null) return false;
    final data = await _client
        .from('user_blocks')
        .select('blocked_id')
        .eq('blocker_id', uid)
        .eq('blocked_id', userId)
        .maybeSingle();
    return data != null;
  }

  Future<void> blockUser(String userId) async {
    final uid = _uid;
    if (uid == null) return;
    await _client
        .from('user_blocks')
        .upsert({'blocker_id': uid, 'blocked_id': userId});
  }

  Future<void> unblockUser(String userId) async {
    final uid = _uid;
    if (uid == null) return;
    await _client
        .from('user_blocks')
        .delete()
        .eq('blocker_id', uid)
        .eq('blocked_id', userId);
  }

  // ── Reportes ──────────────────────────────────────────
  Future<void> reportUser({
    required String reportedId,
    required String reason,
    String? details,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Inicia sesión para reportar');
    await _client.from('user_reports').insert({
      'reporter_id': uid,
      'reported_id': reportedId,
      'reason': reason,
      'details': (details != null && details.trim().isNotEmpty)
          ? details.trim()
          : null,
    });
  }

  // ── Estado de baneo + apelación ───────────────────────
  Future<BanStatus> myBanStatus() async {
    final uid = _uid;
    if (uid == null) return (banned: false, reason: null);
    final data = await _client
        .from('profiles')
        .select('is_banned, ban_reason')
        .eq('id', uid)
        .maybeSingle();
    return (
      banned: (data?['is_banned'] as bool?) ?? false,
      reason: data?['ban_reason'] as String?,
    );
  }

  Future<void> submitAppeal(String message) async {
    final uid = _uid;
    if (uid == null) return;
    await _client
        .from('account_appeals')
        .insert({'user_id': uid, 'message': message.trim()});
  }
}
