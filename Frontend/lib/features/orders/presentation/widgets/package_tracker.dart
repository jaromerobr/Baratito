/// Animación de seguimiento: un paquete que avanza sobre la línea de progreso
/// según la etapa del pedido, con un balanceo continuo. Flutter puro.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:baratito/core/theme/app_palette.dart';
import '../../domain/order_tracking_model.dart';

class PackageTracker extends StatefulWidget {
  /// Etapa alcanzada (0..5). Si es -1 (falta comprobante) se dibuja en el inicio.
  final int currentStep;
  final bool rejected;

  const PackageTracker({
    super.key,
    required this.currentStep,
    this.rejected = false,
  });

  @override
  State<PackageTracker> createState() => _PackageTrackerState();
}

class _PackageTrackerState extends State<PackageTracker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const steps = OrderStages.count; // 6
    final step = widget.currentStep.clamp(0, steps - 1);
    final frac = widget.rejected ? 0.0 : step / (steps - 1);
    final done = widget.rejected ? -1 : widget.currentStep;

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        const pad = 22.0;
        final track = w - pad * 2;
        final lineY = 46.0;
        final fillColor = widget.rejected ? AppColors.error : AppColors.primary;

        return SizedBox(
          height: 72,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Línea base
              Positioned(
                left: pad,
                right: pad,
                top: lineY,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.palette.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Línea de progreso (se rellena al avanzar)
              Positioned(
                left: pad,
                top: lineY,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOut,
                  width: track * frac,
                  height: 4,
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Puntos de cada etapa
              for (var i = 0; i < steps; i++)
                Positioned(
                  left: pad + track * (i / (steps - 1)) - 5,
                  top: lineY - 4,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (!widget.rejected && i <= done)
                          ? AppColors.primary
                          : context.palette.surface,
                      border: Border.all(
                        color: (!widget.rejected && i <= done)
                            ? AppColors.primary
                            : context.palette.divider,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              // El paquete que se desliza a la etapa actual y se balancea.
              AnimatedPositioned(
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
                left: pad + track * frac - 18,
                top: 0,
                child: AnimatedBuilder(
                  animation: _bob,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, -3 + _bob.value * 6),
                    child: child,
                  ),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: fillColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: fillColor.withAlpha(70),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.rejected
                          ? Icons.close_rounded
                          : (widget.currentStep >= steps - 1
                              ? Icons.check_rounded
                              : Icons.inventory_2_rounded),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              // Etiqueta de la etapa actual, bajo la línea.
              Positioned(
                left: 0,
                right: 0,
                top: lineY + 12,
                child: Center(
                  child: Text(
                    widget.rejected
                        ? 'Pedido rechazado'
                        : (widget.currentStep < 0
                            ? 'Falta tu comprobante'
                            : OrderStages.labels[step]),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: fillColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
