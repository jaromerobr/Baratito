/// PE-S15 — Eduardo — Pruebas de la línea de tiempo de estados del pedido.
///
/// `PedidoTracking` mapea el estado de PAGO + el estado de ENTREGA a una etapa
/// (0..5) de la línea de tiempo del comprador. Ese mapeo es una **regla de
/// negocio propia de Baratito** (no evidente desde el tipo de dato) y no tenía
/// ninguna prueba. Estas pruebas la fijan.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:baratito/features/orders/domain/order_tracking_model.dart';

/// Construye un pedido mínimo con los estados de pago/entrega a probar.
PedidoTracking _pedido(String pago, String entrega) => PedidoTracking(
      id: 'x',
      paymentStatus: pago,
      fulfillmentStatus: entrega,
      rejectedReason: null,
      total: 0,
      shippingFee: 0,
      createdAt: DateTime(2024, 1, 1),
      paidAt: null,
      lines: const [],
    );

void main() {
  group('PedidoTracking — etapas de la línea de tiempo', () {
    test('sin comprobante (pending_payment) → paso -1 y aviso de comprobante',
        () {
      final p = _pedido('pending_payment', 'pending');
      expect(p.needsProof, isTrue);
      expect(p.currentStep, -1);
      expect(p.statusLabel, 'Falta tu comprobante');
    });

    test('comprobante en revisión (awaiting_confirmation) → paso 0', () {
      // Regla Baratito: el comprador ya transfirió, pero el admin AÚN no
      // confirma el pago → es la etapa 0 "En revisión de pago", NO "aceptado".
      final p = _pedido('awaiting_confirmation', 'pending');
      expect(p.currentStep, 0);
      expect(p.statusLabel, 'En revisión de pago');
      expect(p.isDelivered, isFalse);
    });

    test('pagado pero sin avanzar la entrega → paso 1 (Pago aceptado)', () {
      // Regla Baratito: "paid" por sí solo es apenas la etapa 1; el avance real
      // depende del fulfillment (recibido/entregado/etc.), no del pago.
      final p = _pedido('paid', 'pending');
      expect(p.currentStep, 1);
      expect(p.statusLabel, 'Pago aceptado');
    });

    test('etapas de entrega mapean a 2..5', () {
      expect(_pedido('paid', 'received').currentStep, 2);
      expect(_pedido('paid', 'reviewing').currentStep, 3);
      expect(_pedido('paid', 'delivering').currentStep, 4);
      expect(_pedido('paid', 'delivered').currentStep, 5);
    });

    test('entregado → isDelivered y etiqueta "Entregado"', () {
      final p = _pedido('paid', 'delivered');
      expect(p.isDelivered, isTrue);
      expect(p.statusLabel, 'Entregado');
    });

    test('rechazo de entrega → isRejected y etiqueta "Rechazado"', () {
      final p = _pedido('paid', 'rejected');
      expect(p.isRejected, isTrue);
      expect(p.statusLabel, 'Rechazado');
    });

    test(
        'pago cancelado (comprobante rechazado) → isRejected aunque la entrega '
        'siga en pending', () {
      // Regla Baratito (migración 28): rechazar un comprobante CANCELA el
      // pedido (status='cancelled'). Por eso isRejected también debe ser true
      // por el lado del PAGO, no solo por el fulfillment.
      final p = _pedido('cancelled', 'pending');
      expect(p.isRejected, isTrue);
      expect(p.statusLabel, 'Rechazado');
    });
  });
}
