/// Riverpod providers for chat.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/chat_repository.dart';
import '../../domain/chat_models.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) => ChatRepository());

/// The current user's conversation list.
final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(chatRepositoryProvider).getMyConversations();
});

/// Cambios en vivo sobre `conversations` (RLS limita a las del usuario).
/// Cada evento (mensaje nuevo actualiza last_message_at, conversación nueva)
/// sirve para refrescar la lista de chats sin que el usuario haga nada.
final conversationChangesProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(chatRepositoryProvider).streamConversationChanges();
});

/// Real-time messages stream for a conversation.
final messagesProvider =
    StreamProvider.family<List<Message>, String>((ref, conversationId) {
  return ref.watch(chatRepositoryProvider).streamMessages(conversationId);
});
