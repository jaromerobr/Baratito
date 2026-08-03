/// Admin repository — metrics, verification review and product moderation.
///
/// All write actions are additionally protected by RLS (admins only).
library;

import '../../../core/supabase_client.dart';
import '../../verification/domain/verification_model.dart';
import '../../orders/domain/order_tracking_model.dart';
import '../domain/admin_overview.dart';

/// A verification request joined with the applicant's profile (admin view).
class AdminVerificationItem {
  final IdentityVerification verification;
  final String userName;
  final String userEmail;

  const AdminVerificationItem({
    required this.verification,
    required this.userName,
    required this.userEmail,
  });
}

/// A checkout payment awaiting/processed (admin view).
class AdminCheckoutItem {
  final String id;
  final String buyerName;
  final String buyerEmail;
  final double total;
  final double platformFee;
  final double shippingFee;
  final double? ocrAmount;
  final bool autoConfirmed;
  final String status;
  final String? proofPath;
  final DateTime createdAt;

  const AdminCheckoutItem({
    required this.id,
    required this.buyerName,
    required this.buyerEmail,
    required this.total,
    required this.platformFee,
    required this.shippingFee,
    required this.ocrAmount,
    required this.autoConfirmed,
    required this.status,
    required this.proofPath,
    required this.createdAt,
  });
}

class AdminRepository {
  final _client = SupabaseClientHelper.client;
  static const _verifBucket = 'verification-docs';

  /// Is the current user an admin?
  Future<bool> isCurrentUserAdmin() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return false;
    final row = await _client
        .from('admins')
        .select('id')
        .eq('user_id', uid)
        .maybeSingle();
    return row != null;
  }

  /// Dashboard metrics (admin-only RPC).
  Future<AdminOverview> getOverview() async {
    final data = await _client.rpc('admin_overview');
    return AdminOverview.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Verification requests, optionally filtered by status.
  Future<List<AdminVerificationItem>> getVerifications({
    VerifyStatus? status,
  }) async {
    var query = _client
        .from('identity_verifications')
        .select('*, profiles:user_id ( full_name, email )');

    if (status != null) {
      query = query.eq('status', status.name);
    }

    final data = await query.order('created_at', ascending: false).limit(100);

    return (data as List<dynamic>).cast<Map<String, dynamic>>().map((row) {
      final profile = row['profiles'] as Map<String, dynamic>?;
      return AdminVerificationItem(
        verification: IdentityVerification.fromJson(row),
        userName: (profile?['full_name'] as String?) ?? 'Usuario',
        userEmail: (profile?['email'] as String?) ?? '',
      );
    }).toList();
  }

  /// Signed URL (1h) to view a private verification image.
  Future<String?> signedImageUrl(String? path) async {
    if (path == null || path.isEmpty) return null;
    return _client.storage.from(_verifBucket).createSignedUrl(path, 3600);
  }

  Future<void> approveVerification(String id) async {
    await _client.from('identity_verifications').update({
      'status': 'approved',
      'rejection_reason': null,
      'reviewed_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> rejectVerification(String id, String reason) async {
    await _client.from('identity_verifications').update({
      'status': 'rejected',
      'rejection_reason': reason,
      'reviewed_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  // ── Payments (commission collection) ──────────────────

  /// Checkouts to review (newest first). [onlyPending] limits to those that
  /// still need confirmation.
  Future<List<AdminCheckoutItem>> getCheckouts({bool onlyPending = true}) async {
    var query = _client
        .from('checkouts')
        .select('*, buyer:buyer_id ( full_name, email )');

    if (onlyPending) {
      query = query.inFilter(
          'status', ['awaiting_confirmation', 'pending_payment']);
    }

    // Prioridad para el admin: mayor valor primero.
    final data =
        await query.order('total_amount', ascending: false).limit(100);

    return (data as List<dynamic>).cast<Map<String, dynamic>>().map((row) {
      final buyer = row['buyer'] as Map<String, dynamic>?;
      return AdminCheckoutItem(
        id: row['id'] as String,
        buyerName: (buyer?['full_name'] as String?) ?? 'Comprador',
        buyerEmail: (buyer?['email'] as String?) ?? '',
        total: (row['total_amount'] as num?)?.toDouble() ?? 0,
        platformFee: (row['platform_fee_total'] as num?)?.toDouble() ?? 0,
        shippingFee: (row['shipping_fee'] as num?)?.toDouble() ?? 0,
        ocrAmount: (row['ocr_amount'] as num?)?.toDouble(),
        autoConfirmed: row['auto_confirmed'] as bool? ?? false,
        status: (row['status'] as String?) ?? 'pending_payment',
        proofPath: row['proof_path'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
    }).toList();
  }

  /// Signed URL (1h) for a private payment proof.
  Future<String?> proofSignedUrl(String? path) async {
    if (path == null || path.isEmpty) return null;
    return _client.storage.from('payment-proofs').createSignedUrl(path, 3600);
  }

  /// Confirm a checkout payment → generates seller payouts (admin RPC).
  Future<void> confirmCheckout(String checkoutId) async {
    await _client.rpc('confirm_checkout_payment',
        params: {'p_checkout': checkoutId});
  }

  /// Reject a proof: the checkout goes back to 'pending_payment' so the
  /// buyer can upload a valid receipt again.
  Future<void> rejectCheckoutProof(String checkoutId) async {
    await _client.from('checkouts').update({
      'status': 'pending_payment',
      'proof_path': null,
      'ocr_amount': null,
      'auto_confirmed': false,
    }).eq('id', checkoutId);
  }

  /// Commission earned + pending payouts summary.
  Future<Map<String, dynamic>> commissionSummary() async {
    final res = await _client.rpc('admin_commission_summary');
    return Map<String, dynamic>.from(res as Map);
  }

  /// Remove a product from the marketplace (moderation).
  Future<void> removeProduct(String productId) async {
    await _client
        .from('products')
        .update({'status': 'removed', 'published_at': null})
        .eq('id', productId);
  }

  // ── Seguimiento / entrega de pedidos ──────────────────────
  /// Todos los pedidos (checkouts) con sus líneas, para el control de entrega.
  Future<List<PedidoTracking>> getPedidos() async {
    final data = await _client
        .from('checkouts')
        .select(
          'id, status, fulfillment_status, rejected_reason, total_amount, '
          'shipping_fee, created_at, paid_at, '
          'delivery_recipient, delivery_phone, delivery_address, '
          'delivery_reference, delivery_city, '
          'buyer:buyer_id ( full_name ), '
          'orders:orders!checkout_id ( id, seller_id, agreed_price, '
          'products:product_id ( title, product_images ( image_path, is_primary ) ), '
          'seller:seller_id ( full_name ) )',
        )
        // Prioridad para el admin: los pedidos de mayor valor primero.
        .order('total_amount', ascending: false)
        .limit(100);

    return (data as List<dynamic>).cast<Map<String, dynamic>>().map((row) {
      final buyer = row['buyer'] as Map<String, dynamic>?;
      final orders = (row['orders'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final lines = orders.map(PedidoLine.fromOrderRow).toList();
      return PedidoTracking.fromCheckout(
        row['id'] as String,
        row,
        lines,
        buyerName: (buyer?['full_name'] as String?) ?? 'Comprador',
      );
    }).toList();
  }

  /// Avanza la entrega (received | reviewing | delivering | delivered).
  Future<void> setFulfillment(String checkoutId, String status) async {
    await _client.rpc('set_order_fulfillment',
        params: {'p_checkout': checkoutId, 'p_status': status});
  }

  /// Rechaza el pedido (terminal) con un motivo.
  Future<void> rejectOrder(String checkoutId, String reason) async {
    await _client.rpc('set_order_fulfillment', params: {
      'p_checkout': checkoutId,
      'p_status': 'rejected',
      'p_reason': reason,
    });
  }

  // ── Reportes de usuarios / apelaciones / ban ──────────────
  Future<List<AdminReport>> getUserReports() async {
    final data = await _client
        .from('user_reports')
        .select(
            '*, reporter:reporter_id ( full_name ), reported:reported_id ( full_name, is_banned )')
        .order('created_at', ascending: false)
        .limit(100);
    return (data as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(AdminReport.fromJson)
        .toList();
  }

  Future<List<AdminAppeal>> getAppeals() async {
    final data = await _client
        .from('account_appeals')
        .select('*, user:user_id ( full_name, is_banned )')
        .order('created_at', ascending: false)
        .limit(100);
    return (data as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(AdminAppeal.fromJson)
        .toList();
  }

  Future<void> banUser(String userId, String? reason) async {
    await _client.rpc('set_user_banned',
        params: {'p_user': userId, 'p_banned': true, 'p_reason': reason});
  }

  Future<void> unbanUser(String userId) async {
    await _client.rpc('set_user_banned',
        params: {'p_user': userId, 'p_banned': false});
  }

  Future<void> setReportStatus(String id, String status) async {
    await _client.from('user_reports').update({'status': status}).eq('id', id);
  }

  /// Resuelve una apelación: aceptar desbanea al usuario.
  Future<void> resolveAppeal(String id, String userId, bool accept) async {
    await _client.from('account_appeals').update({
      'status': accept ? 'accepted' : 'rejected',
      'resolved_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
    if (accept) await unbanUser(userId);
  }
}

class AdminReport {
  final String id;
  final String reporterName;
  final String reportedId;
  final String reportedName;
  final bool reportedBanned;
  final String reason;
  final String? details;
  final String status;
  final DateTime createdAt;

  const AdminReport({
    required this.id,
    required this.reporterName,
    required this.reportedId,
    required this.reportedName,
    required this.reportedBanned,
    required this.reason,
    required this.details,
    required this.status,
    required this.createdAt,
  });

  factory AdminReport.fromJson(Map<String, dynamic> j) {
    final reporter = j['reporter'] as Map<String, dynamic>?;
    final reported = j['reported'] as Map<String, dynamic>?;
    return AdminReport(
      id: j['id'] as String,
      reporterName: (reporter?['full_name'] as String?) ?? 'Usuario',
      reportedId: j['reported_id'] as String,
      reportedName: (reported?['full_name'] as String?) ?? 'Usuario',
      reportedBanned: (reported?['is_banned'] as bool?) ?? false,
      reason: j['reason'] as String? ?? '',
      details: j['details'] as String?,
      status: j['status'] as String? ?? 'open',
      createdAt: DateTime.parse(j['created_at'] as String),
    );
  }
}

class AdminAppeal {
  final String id;
  final String userId;
  final String userName;
  final bool userBanned;
  final String message;
  final String status;
  final DateTime createdAt;

  const AdminAppeal({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userBanned,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory AdminAppeal.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>?;
    return AdminAppeal(
      id: j['id'] as String,
      userId: j['user_id'] as String,
      userName: (user?['full_name'] as String?) ?? 'Usuario',
      userBanned: (user?['is_banned'] as bool?) ?? false,
      message: j['message'] as String? ?? '',
      status: j['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(j['created_at'] as String),
    );
  }
}
