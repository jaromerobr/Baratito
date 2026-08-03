/// Bottom sheet para calificar a otro usuario (1-5 estrellas + comentario
/// opcional). Sirve para comprador→vendedor y vendedor→comprador. La escritura
/// pasa por el RPC que valida que el pedido esté entregado.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';
import '../providers/reviews_provider.dart';

/// Abre el sheet de calificación. Devuelve true si se guardó.
Future<bool?> showRateUserSheet({
  required BuildContext context,
  required String revieweeId,
  required String revieweeName,
  String? orderId,
  int? initialRating,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RateUserSheet(
      revieweeId: revieweeId,
      revieweeName: revieweeName,
      orderId: orderId,
      initialRating: initialRating,
    ),
  );
}

class _RateUserSheet extends ConsumerStatefulWidget {
  final String revieweeId;
  final String revieweeName;
  final String? orderId;
  final int? initialRating;

  const _RateUserSheet({
    required this.revieweeId,
    required this.revieweeName,
    this.orderId,
    this.initialRating,
  });

  @override
  ConsumerState<_RateUserSheet> createState() => _RateUserSheetState();
}

class _RateUserSheetState extends ConsumerState<_RateUserSheet> {
  late int _rating = widget.initialRating ?? 0;
  final _commentCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Selecciona de 1 a 5 estrellas')));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(reviewRepositoryProvider).submitReview(
            revieweeId: widget.revieweeId,
            rating: _rating,
            comment: _commentCtrl.text,
            orderId: widget.orderId,
          );
      ref.invalidate(myReviewForProvider(widget.revieweeId));
      ref.invalidate(userReviewsProvider(widget.revieweeId));
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('¡Gracias por tu valoración!')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('No se pudo guardar la reseña: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFFFB300);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.palette.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Gap(16),
            Text('Calificar a ${widget.revieweeName}',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const Gap(4),
            Text('¿Qué tan buena fue tu experiencia?',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: context.palette.textSecondary)),
            const Gap(16),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      onPressed:
                          _saving ? null : () => setState(() => _rating = i),
                      icon: Icon(
                        _rating >= i
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: amber,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ),
            const Gap(12),
            TextField(
              controller: _commentCtrl,
              enabled: !_saving,
              maxLines: 3,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: 'Comentario (opcional)',
                filled: true,
                fillColor: context.palette.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const Gap(8),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('Enviar valoración',
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
