/// Chat repository — conversations + real-time messages (Supabase Realtime).
library;

import '../../../core/supabase_client.dart';
import '../domain/chat_models.dart';

class ChatRepository {
  final _client = SupabaseClientHelper.client;

  String? get _uid => _client.auth.currentUser?.id;

  /// Conversations where the current user is buyer or seller, newest first.
  Future<List<Conversation>> getMyConversations() async {
    final uid = _uid;
    if (uid == null) return [];

    final data = await _client
        .from('conversations')
        .select(
          '*, products:product_id ( title, product_images ( image_path, is_primary ) ), '
          'buyer:buyer_id ( id, full_name, avatar_path ), '
          'seller:seller_id ( id, full_name, avatar_path )',
        )
        .order('last_message_at', ascending: false);

    return (data as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((row) => Conversation.fromJson(row, uid))
        .toList();
  }

  /// Find an existing conversation for (product, buyer=me, seller) or create it.
  Future<String> getOrCreateConversation({
    required String productId,
    required String sellerId,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Inicia sesión para chatear.');
    if (uid == sellerId) {
      throw Exception('No puedes chatear contigo mismo.');
    }

    final existing = await _client
        .from('conversations')
        .select('id')
        .eq('product_id', productId)
        .eq('buyer_id', uid)
        .eq('seller_id', sellerId)
        .maybeSingle();

    if (existing != null) return existing['id'] as String;

    final row = await _client
        .from('conversations')
        .insert({
          'product_id': productId,
          'buyer_id': uid,
          'seller_id': sellerId,
        })
        .select('id')
        .single();

    return row['id'] as String;
  }

  /// Cambios en vivo de las conversaciones del usuario (sin joins).
  /// RLS limita las filas a las conversaciones donde participa, así que
  /// no hace falta filtro: cualquier evento indica que hay algo nuevo.
  Stream<List<Map<String, dynamic>>> streamConversationChanges() {
    return _client
        .from('conversations')
        .stream(primaryKey: ['id']).order('last_message_at');
  }

  /// Real-time stream of messages in a conversation (oldest → newest).
  Stream<List<Message>> streamMessages(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('sent_at')
        .map((rows) => rows.map(Message.fromJson).toList());
  }

  Future<void> sendMessage(String conversationId, String content) async {
    final uid = _uid;
    if (uid == null) return;
    final text = content.trim();
    if (text.isEmpty) return;

    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': uid,
      'content': text,
    });
  }

  /// Mark the other party's messages as read.
  Future<void> markRead(String conversationId) async {
    final uid = _uid;
    if (uid == null) return;
    await _client
        .from('messages')
        .update({
          'is_read': true,
          'read_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('conversation_id', conversationId)
        .neq('sender_id', uid)
        .eq('is_read', false);
  }
}
