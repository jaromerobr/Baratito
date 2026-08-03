/// Una venta del vendedor (agrupada por pedido/checkout) con el comprador y el
/// estado de entrega, para que el vendedor califique al comprador al entregar.
library;

import 'order_tracking_model.dart';

class SaleLine {
  final String title;
  final String? imageKey;
  final double price;
  const SaleLine({required this.title, required this.imageKey, required this.price});
}

class SaleGroup {
  final String checkoutId;
  final String buyerId;
  final String buyerName;
  final String paymentStatus;
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

  bool get isRejected =>
      fulfillmentStatus == 'rejected' || paymentStatus == 'cancelled';
  bool get needsProof => paymentStatus == 'pending_payment';
  bool get isDelivered => fulfillmentStatus == 'delivered';

  int get currentStep {
    if (needsProof) return -1;
    if (paymentStatus == 'awaiting_confirmation') return 0;
    switch (fulfillmentStatus) {
      case 'received':
        return 2;
      case 'reviewing':
        return 3;
      case 'delivering':
        return 4;
      case 'delivered':
        return 5;
      default:
        return 1;
    }
  }

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
