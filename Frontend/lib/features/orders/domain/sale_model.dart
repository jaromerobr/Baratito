/// Una venta del vendedor (agrupada por pedido/checkout) con el comprador y el
/// estado de entrega, para que el vendedor califique al comprador al entregar.
library;

import 'order_status.dart';
import 'order_tracking_model.dart';

class SaleLine {
  final String title;
  final String? imageKey;
  final double price;
  const SaleLine({required this.title, required this.imageKey, required this.price});
}

/// El cálculo de estado (`currentStep`, `isRejected`, `needsProof`,
/// `isDelivered`) vive en [OrderStatusFlow], compartido con `PedidoTracking`
/// (vista comprador) — antes estaba duplicado línea por línea en ambas
/// clases.
class SaleGroup with OrderStatusFlow {
  final String checkoutId;
  final String buyerId;
  final String buyerName;
  @override
  final String paymentStatus;
  @override
  final String fulfillmentStatus;
  final DateTime createdAt;
  final List<SaleLine> items;

  const SaleGroup({
    required this.checkoutId,
    required this.buyerId,
    required this.buyerName,
    required this.paymentStatus,
    required this.fulfillmentStatus,
    required this.createdAt,
    required this.items,
  });

  /// Etiqueta corta del estado (texto dirigido al vendedor: a diferencia de
  /// `PedidoTracking.statusLabel`, NO dice "tu comprobante" — el vendedor no
  /// es quien lo sube, solo está esperando a que el comprador pague).
  String get statusLabel {
    if (isRejected) return 'Rechazado';
    if (needsProof) return 'Esperando pago';
    return OrderStages.labels[currentStep];
  }

  double get total => items.fold(0, (a, i) => a + i.price);
  String get totalLabel => '\$${total.toStringAsFixed(2)}';
  String? get coverImageKey => items.isNotEmpty ? items.first.imageKey : null;
  int get itemCount => items.length;
}
