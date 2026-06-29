/// Chat screen — real-time conversation between buyer and seller.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';
import '../../../../core/supabase_client.dart';
import '../../domain/chat_models.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final Conversation? conversation;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.conversation,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  final _uid = SupabaseClientHelper.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    // Marca como leídos los mensajes del otro al abrir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatRepositoryProvider).markRead(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _msgCtrl.clear();
    try {
      await ref
          .read(chatRepositoryProvider)
          .sendMessage(widget.conversationId, text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('No se envió: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final title = widget.conversation?.otherUserName ?? 'Chat';

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            if (widget.conversation?.productTitle != null)
              Text(widget.conversation!.productTitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: context.palette.textSecondary)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text('Escribe el primer mensaje 👋',
                        style: GoogleFonts.poppins(
                            color: context.palette.textSecondary)),
                  );
                }
                _scrollToBottom();
                // Marca leídos cuando llegan nuevos del otro.
                ref
                    .read(chatRepositoryProvider)
                    .markRead(widget.conversationId);

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    return _Bubble(message: m, isMine: m.senderId == _uid);
                  },
                );
              },
            ),
          ),
          _Composer(
            controller: _msgCtrl,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final Message message;
  final bool isMine;
  const _Bubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(message.sentAt.toLocal());
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : context.palette.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.content,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isMine ? Colors.white : context.palette.textPrimary)),
            const Gap(2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(time,
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: isMine
                            ? Colors.white.withAlpha(200)
                            : context.palette.textHint)),
                if (isMine) ...[
                  const Gap(4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: Colors.white.withAlpha(200),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
      color: context.palette.surface,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                filled: true,
                fillColor: context.palette.inputFill,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Gap(8),
          Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: sending ? null : onSend,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  sending ? Icons.hourglass_top : Icons.send_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
