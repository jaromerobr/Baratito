/// Tarjeta con los datos de entrega de un pedido (dirección, referencia,
/// teléfono). Se usa en el seguimiento del comprador y en el panel de admin.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';
import '../../domain/order_tracking_model.dart';

class DeliveryInfoCard extends StatelessWidget {
  final PedidoTracking pedido;
  const DeliveryInfoCard({super.key, required this.pedido});

  @override
  Widget build(BuildContext context) {
    if (!pedido.hasDelivery) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warning.withAlpha(22),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_off_outlined,
                color: AppColors.warning, size: 20),
            const Gap(8),
            Expanded(
              child: Text('Sin datos de entrega registrados.',
                  style: GoogleFonts.poppins(
                      fontSize: 12.5, color: context.palette.textPrimary)),
            ),
          ],
        ),
      );
    }

    final parts = <String>[
      if ((pedido.deliveryAddress ?? '').isNotEmpty) pedido.deliveryAddress!,
      if ((pedido.deliveryCity ?? '').isNotEmpty) pedido.deliveryCity!,
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.palette.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined,
                  color: AppColors.primary, size: 20),
              const Gap(8),
              Text('Datos de entrega',
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const Gap(8),
          if ((pedido.deliveryRecipient ?? '').isNotEmpty)
            _line(context, Icons.person_outline, pedido.deliveryRecipient!),
          if (parts.isNotEmpty)
            _line(context, Icons.place_outlined, parts.join(', ')),
          if ((pedido.deliveryReference ?? '').isNotEmpty)
            _line(context, Icons.home_outlined, pedido.deliveryReference!),
          if ((pedido.deliveryPhone ?? '').isNotEmpty)
            _line(context, Icons.phone_outlined, pedido.deliveryPhone!),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: context.palette.textHint),
          const Gap(8),
          Expanded(
            child: Text(text,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: context.palette.textPrimary)),
          ),
        ],
      ),
    );
  }
}
