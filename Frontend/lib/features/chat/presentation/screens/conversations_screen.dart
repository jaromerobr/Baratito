/// Chats list — all conversations of the current user.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';
import '../../../../core/supabase_client.dart';
import '../../domain/chat_models.dart';
import '../providers/chat_provider.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = SupabaseClientHelper.auth.currentUser != null;

    if (!loggedIn) {
      return _CenterMessage(
        icon: Icons.lock_outline,
        title: 'Inicia sesión',
        subtitle: 'Necesitas una cuenta para chatear',
      );
    }

    // Refresco en vivo: cualquier cambio en las conversaciones del usuario
    // (mensaje nuevo, conversación nueva) recarga la lista automáticamente.
    ref.listen(conversationChangesProvider, (previous, next) {
      if (previous?.valueOrNull != null || next.valueOrNull != null) {
        ref.invalidate(conversationsProvider);
      }
    });

    final async = ref.watch(conversationsProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        if (items.isEmpty) {
          return const _CenterMessage(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Sin conversaciones',
            subtitle: 'Escríbele a un vendedor desde un producto',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.refresh(conversationsProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, indent: 78),
            itemBuilder: (context, i) => _ConversationTile(conv: items[i]),
          ),
        );
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conv;
  const _ConversationTile({required this.conv});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.primary.withAlpha(30),
        backgroundImage: conv.otherUserAvatarUrl != null
            ? NetworkImage(conv.otherUserAvatarUrl!)
            : null,
        child: conv.otherUserAvatarUrl == null
            ? const Icon(Icons.person, color: AppColors.primary)
            : null,
      ),
      title: Text(conv.otherUserName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w700)),
      subtitle: conv.productTitle != null
          ? Text('Sobre: ${conv.productTitle}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: context.palette.textSecondary))
          : null,
      trailing: conv.lastMessageAt != null
          ? Text(_timeLabel(conv.lastMessageAt!),
              style: GoogleFonts.poppins(
                  fontSize: 11, color: context.palette.textHint))
          : null,
      onTap: () => context.push('/chat/${conv.id}', extra: conv),
    );
  }

  String _timeLabel(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return DateFormat('HH:mm').format(local);
    }
    return DateFormat('dd/MM').format(local);
  }
}

class _CenterMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _CenterMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 60, color: context.palette.textHint),
          const Gap(12),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          const Gap(4),
          Text(subtitle,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: context.palette.textSecondary)),
        ],
      ),
    );
  }
}
