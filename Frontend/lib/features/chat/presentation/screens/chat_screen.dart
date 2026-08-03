/// Chat screen — real-time conversation between buyer and seller.
library;

import 'package:flutter/material.dart';
import 'package:baratito/widgets/baratito_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/supabase_client.dart';
import '../../domain/chat_models.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_media.dart';
import '../../../offers/presentation/providers/offers_provider.dart';
import '../../../moderation/presentation/providers/moderation_providers.dart';
import '../../../moderation/presentation/widgets/user_moderation_actions.dart';

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
  final _recorder = AudioRecorder();
  bool _recording = false;

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
    _recorder.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating, content: Text(msg)));
  }

  String _extOf(String name, String fallback) {
    final i = name.lastIndexOf('.');
    if (i == -1 || i == name.length - 1) return fallback;
    return name.substring(i + 1).toLowerCase();
  }

  String _imgContentType(String ext) => ext == 'png'
      ? 'image/png'
      : (ext == 'webp' ? 'image/webp' : 'image/jpeg');

  Future<void> _pickAndSend({required bool isVideo}) async {
    try {
      final picker = ImagePicker();
      final XFile? file = isVideo
          ? await picker.pickVideo(source: ImageSource.gallery)
          : await picker.pickImage(
              source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
      if (file == null) return;
      setState(() => _sending = true);
      final bytes = await file.readAsBytes();
      final ext = _extOf(file.name, isVideo ? 'mp4' : 'jpg');
      await ref.read(chatRepositoryProvider).sendMedia(
            conversationId: widget.conversationId,
            bytes: bytes,
            type: isVideo ? 'video' : 'image',
            ext: ext,
            contentType: isVideo ? 'video/mp4' : _imgContentType(ext),
          );
    } catch (e) {
      _snack('No se pudo enviar: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _openAttach() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined, color: AppColors.primary),
              title: const Text('Enviar imagen'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndSend(isVideo: false);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.videocam_outlined, color: AppColors.primary),
              title: const Text('Enviar video'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndSend(isVideo: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        _snack('Necesitas dar permiso de micrófono');
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(), path: path);
      if (mounted) setState(() => _recording = true);
    } catch (e) {
      _snack('No se pudo grabar: $e');
    }
  }

  Future<void> _stopAndSendRecording() async {
    try {
      final path = await _recorder.stop();
      if (mounted) setState(() => _recording = false);
      if (path == null) return;
      setState(() => _sending = true);
      final bytes = await File(path).readAsBytes();
      await ref.read(chatRepositoryProvider).sendMedia(
            conversationId: widget.conversationId,
            bytes: bytes,
            type: 'audio',
            ext: 'm4a',
            contentType: 'audio/mp4',
          );
    } catch (e) {
      _snack('No se pudo enviar el audio: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _cancelRecording() async {
    try {
      await _recorder.stop();
    } catch (_) {}
    if (mounted) setState(() => _recording = false);
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
    final conv = widget.conversation;
    final title = conv?.otherUserName ?? 'Chat';
    final otherId = conv?.otherUserId ?? '';
    final canModerate = conv != null && !conv.isSupport && otherId.isNotEmpty;
    final blocked = canModerate
        ? (ref.watch(isBlockedProvider(otherId)).asData?.value ?? false)
        : false;

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: BaratitoAppBar(
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
                      fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: canModerate
            ? [
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'report') {
                      reportUserFlow(context, ref,
                          reportedId: otherId, reportedName: conv.otherUserName);
                    } else if (v == 'block') {
                      toggleBlockFlow(context, ref,
                          userId: otherId,
                          currentlyBlocked: blocked,
                          name: conv.otherUserName);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'report', child: Text('Reportar usuario')),
                    PopupMenuItem(
                        value: 'block',
                        child:
                            Text(blocked ? 'Desbloquear' : 'Bloquear usuario')),
                  ],
                ),
              ]
            : null,
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
          if (widget.conversation?.productId != null &&
              !(widget.conversation?.isSupport ?? false))
            _OfferBar(
              conversationId: widget.conversationId,
              productId: widget.conversation!.productId!,
              otherUserId: widget.conversation!.otherUserId,
            ),
          _Composer(
            controller: _msgCtrl,
            sending: _sending,
            recording: _recording,
            onSend: _send,
            onAttach: _openAttach,
            onStartRecord: _startRecording,
            onStopRecord: _stopAndSendRecording,
            onCancelRecord: _cancelRecording,
          ),
        ],
      ),
    );
  }
}

/// Barra de negociación: solo aparece en productos negociables. El comprador
/// hace una oferta; el vendedor la acepta o rechaza.
class _OfferBar extends ConsumerStatefulWidget {
  final String conversationId;
  final String productId;
  final String otherUserId;

  const _OfferBar({
    required this.conversationId,
    required this.productId,
    required this.otherUserId,
  });

  @override
  ConsumerState<_OfferBar> createState() => _OfferBarState();
}

class _OfferBarState extends ConsumerState<_OfferBar> {
  bool _working = false;

  OfferArgs get _args =>
      (productId: widget.productId, otherUserId: widget.otherUserId);

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _working = true);
    try {
      await action();
      ref.invalidate(offerContextProvider(_args));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
              behavior: SnackBarBehavior.floating, content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _makeOffer(double listPrice) async {
    final ctrl = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hacer una oferta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Precio publicado: \$${listPrice.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: context.palette.textSecondary)),
            const Gap(8),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                prefixText: '\$ ',
                hintText: 'Tu oferta',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim().replaceAll(',', '.'));
              Navigator.pop(ctx, (v != null && v > 0) ? v : null);
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (amount == null) return;
    await _run(() => ref.read(offerRepositoryProvider).makeOffer(
          productId: widget.productId,
          amount: amount,
          conversationId: widget.conversationId,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final uid = SupabaseClientHelper.auth.currentUser?.id;
    final async = ref.watch(offerContextProvider(_args));

    return async.maybeWhen(
      data: (ctx) {
        if (ctx == null || !ctx.isNegotiable || uid == null) {
          return const SizedBox.shrink();
        }
        final amISeller = ctx.amISeller(uid);
        final offer = ctx.latestOffer;

        Widget content;
        if (amISeller) {
          if (offer != null && offer.isPending) {
            content = _bar(
              icon: Icons.local_offer_rounded,
              color: AppColors.accentDark,
              text: 'Oferta recibida: ${offer.amountLabel}',
              trailing: _working
                  ? _spinner()
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      TextButton(
                        onPressed: () => _run(() => ref
                            .read(offerRepositoryProvider)
                            .respondOffer(offer.id, false)),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.error),
                        child: const Text('Rechazar'),
                      ),
                      FilledButton(
                        onPressed: () => _run(() => ref
                            .read(offerRepositoryProvider)
                            .respondOffer(offer.id, true)),
                        child: const Text('Aceptar'),
                      ),
                    ]),
            );
          } else if (offer != null && offer.isAccepted) {
            content = _bar(
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
              text: 'Precio acordado: ${offer.amountLabel}',
            );
          } else {
            content = _bar(
              icon: Icons.local_offer_outlined,
              color: context.palette.textSecondary,
              text: 'Producto negociable · espera una oferta del comprador',
            );
          }
        } else {
          // Comprador
          if (offer != null && offer.isPending) {
            content = _bar(
              icon: Icons.hourglass_top_rounded,
              color: AppColors.accentDark,
              text: 'Oferta enviada: ${offer.amountLabel} · esperando respuesta',
            );
          } else if (offer != null && offer.isAccepted) {
            content = _bar(
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
              text: '¡Oferta aceptada! Comprarás a ${offer.amountLabel}',
            );
          } else {
            content = _bar(
              icon: Icons.local_offer_rounded,
              color: AppColors.primary,
              text: offer != null && offer.isRejected
                  ? 'Oferta rechazada · puedes enviar otra'
                  : 'Este producto es negociable',
              trailing: _working
                  ? _spinner()
                  : FilledButton(
                      onPressed: () => _makeOffer(ctx.listPrice),
                      child: const Text('Hacer oferta'),
                    ),
            );
          }
        }

        return content;
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _spinner() => const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2));

  Widget _bar({
    required IconData icon,
    required Color color,
    required String text,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: context.palette.surface,
        border: Border(top: BorderSide(color: context.palette.divider)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const Gap(8),
          Expanded(
            child: Text(text,
                style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ),
          ?trailing,
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
        padding: message.isMedia
            ? const EdgeInsets.fromLTRB(6, 6, 6, 6)
            : const EdgeInsets.fromLTRB(14, 10, 14, 8),
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
            _content(context),
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

  Widget _content(BuildContext context) {
    switch (message.type) {
      case 'image':
        return ChatImageBubble(mediaPath: message.mediaPath!);
      case 'video':
        return ChatVideoBubble(mediaPath: message.mediaPath!);
      case 'audio':
        return ChatAudioBubble(mediaPath: message.mediaPath!, isMine: isMine);
      default:
        return Text(message.content,
            style: GoogleFonts.poppins(
                fontSize: 14,
                color: isMine ? Colors.white : context.palette.textPrimary));
    }
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final bool recording;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onStartRecord;
  final VoidCallback onStopRecord;
  final VoidCallback onCancelRecord;

  const _Composer({
    required this.controller,
    required this.sending,
    required this.recording,
    required this.onSend,
    required this.onAttach,
    required this.onStartRecord,
    required this.onStopRecord,
    required this.onCancelRecord,
  });

  Widget _circleButton(IconData icon, VoidCallback? onTap) {
    return Material(
      color: AppColors.primary,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    // Modo grabación: cancelar · "Grabando…" · enviar.
    if (recording) {
      return Container(
        padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + bottom),
        color: context.palette.surface,
        child: Row(
          children: [
            IconButton(
              onPressed: onCancelRecord,
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
            ),
            const Icon(Icons.fiber_manual_record, color: AppColors.error, size: 14),
            const Gap(8),
            Expanded(
              child: Text('Grabando audio…',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: context.palette.textSecondary)),
            ),
            _circleButton(Icons.send_rounded, sending ? null : onStopRecord),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(6, 8, 12, 8 + bottom),
      color: context.palette.surface,
      child: Row(
        children: [
          IconButton(
            onPressed: sending ? null : onAttach,
            icon: Icon(Icons.add_circle_outline, color: AppColors.primary),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              // Límite real alineado con el CHECK de la base de datos (1–1000).
              maxLength: 1000,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                counterText: '',
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
          // Micrófono si no hay texto; enviar si hay texto.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final hasText = value.text.trim().isNotEmpty;
              if (sending) return _circleButton(Icons.hourglass_top, null);
              return _circleButton(
                hasText ? Icons.send_rounded : Icons.mic_rounded,
                hasText ? onSend : onStartRecord,
              );
            },
          ),
        ],
      ),
    );
  }
}
