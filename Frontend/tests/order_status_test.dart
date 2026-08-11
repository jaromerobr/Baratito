// Pruebas unitarias del flujo de estado de un pedido (pago → entrega),
// compartido entre la vista del comprador (PedidoTracking) y la del
// vendedor (SaleGroup) a través del mixin OrderStatusFlow.
//
// PE-S15 — Angel Paladines: este archivo no existía. La lógica de estado
// (currentStep / isRejected / needsProof / isDelivered) era la más repetida
// del dominio de pedidos y no tenía ninguna prueba automatizada.
import 'package:flutter_test/flutter_test.dart';
import 'package:baratito/features/orders/domain/order_tracking_model.dart';
import 'package:baratito/features/orders/domain/sale_model.dart';

PedidoTracking _pedido({
  required String paymentStatus,
  required String fulfillmentStatus,
}) {
  return PedidoTracking.fromCheckout(
    'checkout-1',
    {
      'status': paymentStatus,
      'fulfillment_status': fulfillmentStatus,
      'total_amount': 10.0,
      'shipping_fee': 2.0,
      'created_at': '2026-07-01T00:00:00Z',
    },
    const [],
  );
}

SaleGroup _venta({
  required String paymentStatus,
  required String fulfillmentStatus,
}) {
  return SaleGroup(
    checkoutId: 'checkout-1',
    buyerId: 'buyer-1',
    buyerName: 'Comprador Test',
    paymentStatus: paymentStatus,
    fulfillmentStatus: fulfillmentStatus,
    createdAt: DateTime(2026, 7, 1),
    items: const [],
  );
}

void main() {
  group('OrderStatusFlow.currentStep (comprador y vendedor coinciden)', () {
    final casos = <String, List<String>>{
      'falta comprobante': ['pending_payment', 'pending'],
      'comprobante en revisión': ['awaiting_confirmation', 'pending'],
      'pago aceptado': ['paid', 'pending'],
      'recibido': ['paid', 'received'],
      'en revisión Baratito': ['paid', 'reviewing'],
      'en entrega': ['paid', 'delivering'],
      'entregado': ['paid', 'delivered'],
    };
    final pasoEsperado = <String, int>{
      'falta comprobante': -1,
      'comprobante en revisión': 0,
      'pago aceptado': 1,
      'recibido': 2,
      'en revisión Baratito': 3,
      'en entrega': 4,
      'entregado': 5,
    };

    casos.forEach((nombre, estados) {
      test('$nombre → step ${pasoEsperado[nombre]}', () {
        final pedido = _pedido(
          paymentStatus: estados[0],
          fulfillmentStatus: estados[1],
        );
        final venta = _venta(
          paymentStatus: estados[0],
          fulfillmentStatus: estados[1],
        );
        expect(pedido.currentStep, pasoEsperado[nombre]);
        expect(venta.currentStep, pasoEsperado[nombre]);
      });
    });
  });

  group('needsProof / isRejected / isDelivered', () {
    test('pago cancelado se marca rechazado (comprador y vendedor)', () {
      expect(
        _pedido(paymentStatus: 'cancelled', fulfillmentStatus: 'pending')
            .isRejected,
        isTrue,
      );
      expect(
        _venta(paymentStatus: 'cancelled', fulfillmentStatus: 'pending')
            .isRejected,
        isTrue,
      );
    });

    test('entrega rechazada se marca rechazado aunque el pago esté pagado',
        () {
      expect(
        _pedido(paymentStatus: 'paid', fulfillmentStatus: 'rejected')
            .isRejected,
        isTrue,
      );
    });

    test(
      'REGLA DE NEGOCIO (ESTADO_DEL_PROYECTO.md §3.9.5): si el admin '
      'rechaza el comprobante, el pedido vuelve a pending_payment y NO se '
      'marca isRejected — el comprador puede volver a subir comprobante '
      'las veces que haga falta.',
      () {
        final pedido = _pedido(
          paymentStatus: 'pending_payment',
          fulfillmentStatus: 'pending',
        );
        expect(pedido.needsProof, isTrue);
        expect(pedido.isRejected, isFalse);
      },
    );

    test('entregado', () {
      expect(
        _pedido(paymentStatus: 'paid', fulfillmentStatus: 'delivered')
            .isDelivered,
        isTrue,
      );
      expect(
        _venta(paymentStatus: 'paid', fulfillmentStatus: 'delivered')
            .isDelivered,
        isTrue,
      );
    });
  });

  group('statusLabel — mismo estado, texto distinto según el rol', () {
    test(
      'falta comprobante: el comprador ve "tu comprobante", el vendedor ve '
      '"esperando pago" (el vendedor no es quien sube el comprobante)',
      () {
        final pedido = _pedido(
          paymentStatus: 'pending_payment',
          fulfillmentStatus: 'pending',
        );
        final venta = _venta(
          paymentStatus: 'pending_payment',
          fulfillmentStatus: 'pending',
        );
        expect(pedido.statusLabel, 'Falta tu comprobante');
        expect(venta.statusLabel, 'Esperando pago');
        expect(pedido.statusLabel, isNot(venta.statusLabel));
      },
    );

    test('rechazado: mismo texto para ambos roles', () {
      final pedido =
          _pedido(paymentStatus: 'cancelled', fulfillmentStatus: 'pending');
      final venta =
          _venta(paymentStatus: 'cancelled', fulfillmentStatus: 'pending');
      expect(pedido.statusLabel, 'Rechazado');
      expect(venta.statusLabel, 'Rechazado');
    });

    test('en camino: mismo texto (viene de OrderStages, no hay distinción de rol)',
        () {
      final pedido =
          _pedido(paymentStatus: 'paid', fulfillmentStatus: 'delivering');
      final venta =
          _venta(paymentStatus: 'paid', fulfillmentStatus: 'delivering');
      expect(pedido.statusLabel, 'En entrega');
      expect(venta.statusLabel, 'En entrega');
    });
  });
}
