/// Repositorio de reseñas MUTUAS entre usuarios (vendedor ↔ comprador).
/// La escritura pasa por el RPC `submit_review`, que valida que haya un pedido
/// ENTREGADO entre las dos personas.
library;

import '../../../core/supabase_client.dart';

/// Contraparte pendiente de calificar (de un pedido entregado).
typedef PendingReview = ({String revieweeId, String revieweeName, String role});

class UserReview {
  final String id;
  final String revieweeId;
  final String reviewerId;
  final int rating;
  final String? comment;

  /// Rol del calificado en la transacción: 'seller' | 'buyer'.
  final String role;
  final DateTime createdAt;
  final String reviewerName;
  final String? reviewerAvatarPath;

  const UserReview({
    required this.id,
    required this.revieweeId,
    required this.reviewerId,
    required this.rating,
    required this.comment,
    required this.role,
    required this.createdAt,
    required this.reviewerName,
    required this.reviewerAvatarPath,
  });

  factory UserReview.fromJson(Map<String, dynamic> json) {
    final reviewer = json['reviewer'] as Map<String, dynamic>?;
    return UserReview(
      id: json['id'] as String,
      revieweeId: json['reviewee_id'] as String,
      reviewerId: json['reviewer_id'] as String,
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
      role: json['role'] as String? ?? 'seller',
      createdAt: DateTime.parse(json['created_at'] as String),
      reviewerName: (reviewer?['full_name'] as String?) ?? 'Usuario',
      reviewerAvatarPath: reviewer?['avatar_path'] as String?,
    );
  }
}

class ReviewRepository {
  final _client = SupabaseClientHelper.client;

  /// Crea o actualiza la reseña del usuario actual hacia [revieweeId].
  /// El RPC valida que exista un pedido entregado entre ambos.
  Future<void> submitReview({
    required String revieweeId,
    required int rating,
    String? comment,
    String? orderId,
  }) async {
    await _client.rpc('submit_review', params: {
      'p_reviewee': revieweeId,
      'p_rating': rating,
      'p_comment': comment,
      'p_order': orderId,
    });
  }

  /// La calificación que el usuario actual ya dejó a [revieweeId], o null.
  Future<int?> myReviewFor(String revieweeId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final data = await _client
        .from('user_reviews')
        .select('rating')
        .eq('reviewee_id', revieweeId)
        .eq('reviewer_id', uid)
        .maybeSingle();
    return (data?['rating'] as num?)?.toInt();
  }

  /// Contrapartes de pedidos entregados a las que el usuario aún NO ha
  /// calificado (para mostrar el aviso automático de valoración).
  Future<List<PendingReview>> getPendingReviews() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final data = await _client.rpc('pending_reviews');
    return (data as List<dynamic>).cast<Map<String, dynamic>>().map((r) {
      return (
        revieweeId: r['reviewee_id'] as String,
        revieweeName: (r['reviewee_name'] as String?) ?? 'Usuario',
        role: (r['role'] as String?) ?? 'seller',
      );
    }).toList();
  }

  /// Reseñas recibidas por [userId] (con nombre del que calificó).
  Future<List<UserReview>> getUserReviews(String userId) async {
    final data = await _client
        .from('user_reviews')
        .select('*, reviewer:reviewer_id ( full_name, avatar_path )')
        .eq('reviewee_id', userId)
        .order('created_at', ascending: false);
    return (data as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(UserReview.fromJson)
        .toList();
  }
}
