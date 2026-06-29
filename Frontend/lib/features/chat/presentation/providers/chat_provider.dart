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

/// Real-time messages stream for a conversation.
final messagesProvider =
    StreamProvider.family<List<Message>, String>((ref, conversationId) {
  return ref.watch(chatRepositoryProvider).streamMessages(conversationId);
});
