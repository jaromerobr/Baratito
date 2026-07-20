/// Chat domain models: Conversation + Message.
library;

import '../../products/domain/product_model.dart' show kProductImagesBucket;
import '../../../core/supabase_client.dart';
import '../../profile/data/profile_repository.dart';

class Conversation {
  final String id;
  final String? productId;
  final String? productTitle;
  final String? productImageUrl;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatarUrl;
  final DateTime? lastMessageAt;

  /// 'product' (comprador↔vendedor) o 'support' (usuario↔equipo Baratito).
  final String kind;

  const Conversation({
    required this.id,
    this.productId,
    this.productTitle,
    this.productImageUrl,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatarUrl,
    this.lastMessageAt,
    this.kind = 'product',
  });

  bool get isSupport => kind == 'support';

  /// Build from a row that embeds product, buyer and seller, picking the
  /// "other" participant relative to [currentUid].
  factory Conversation.fromJson(Map<String, dynamic> json, String currentUid) {
    final buyer = json['buyer'] as Map<String, dynamic>?;
    final seller = json['seller'] as Map<String, dynamic>?;
    final buyerId = json['buyer_id'] as String?;
    final kind = json['kind'] as String? ?? 'product';

    // Determinar el "otro" participante y su nombre.
    final Map<String, dynamic>? other;
    final String otherName;
    if (kind == 'support' && buyerId == currentUid) {
      // El usuario que reporta ve al equipo de soporte.
      other = null;
      otherName = 'Soporte Baratito';
    } else if (kind == 'support') {
      // El admin ve a la persona que reportó.
      other = buyer;
      otherName = (buyer?['full_name'] as String?) ?? 'Usuario';
    } else {
      other = (buyerId == currentUid) ? seller : buyer;
      otherName = (other?['full_name'] as String?) ?? 'Usuario';
    }

    final product = json['products'] as Map<String, dynamic>?;

    return Conversation(
      id: json['id'] as String,
      kind: kind,
      productId: json['product_id'] as String?,
      productTitle: product?['title'] as String?,
      productImageUrl: _firstImage(product),
      otherUserId: (other?['id'] as String?) ?? '',
      otherUserName: otherName,
      otherUserAvatarUrl:
          ProfileRepository.avatarUrl(other?['avatar_path'] as String?),
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
    );
  }

  static String? _firstImage(Map<String, dynamic>? product) {
    final images = (product?['product_images'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    if (images.isEmpty) return null;
    final path = images.first['image_path'] as String?;
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return SupabaseClientHelper.client.storage
        .from(kProductImagesBucket)
        .getPublicUrl(path);
  }
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime sentAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.isRead,
    required this.sentAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        conversationId: json['conversation_id'] as String,
        senderId: json['sender_id'] as String,
        content: json['content'] as String? ?? '',
        isRead: json['is_read'] as bool? ?? false,
        sentAt: DateTime.parse(json['sent_at'] as String),
      );
}
