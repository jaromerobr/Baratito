/// Seguimiento de un pedido (checkout) a través de las etapas de pago y entrega.
library;

import 'package:flutter/material.dart';

/// Las 6 etapas visibles de la línea de tiempo del comprador, en orden.
class OrderStages {
  static const List<String> labels = [
    'En revisión de pago',
    'Pago aceptado',
    'Pedido recibido',
    'En revisión por Baratito',
    'En entrega',
    'Entregado',
  ];

  static const List<IconData> icons = [
    Icons.receipt_long_rounded,
    Icons.verified_rounded,
    Icons.inventory_2_rounded,
    Icons.fact_check_rounded,
    Icons.local_shipping_rounded,
    Icons.check_circle_rounded,
  ];

  static const int count = 6;
}

/// Una línea del pedido (un producto de un vendedor).
class PedidoLine {
  final String orderId;
  final String sellerId;
  final String sellerName;
  final String productTitle;
  final String? imageKey;
  final double price;

  const PedidoLine({
    required this.orderId,
    required this.sellerId,
    required this.sellerName,
    required this.productTitle,
    required this.imageKey,
    required this.price,
  });

  /// Construye una línea desde una fila de `orders` con product/seller embebidos.
  factory PedidoLine.fromOrderRow(Map<String, dynamic> row) {
    final product = row['products'] as Map<String, dynamic>?;
    final seller = row['seller'] as Map<String, dynamic>?;
    return PedidoLine(
      orderId: row['id'] as String,
      sellerId: row['seller_id'] as String? ?? '',
      sellerName: (seller?['full_name'] as String?) ?? 'Vendedor',
      productTitle: (product?['title'] as String?) ?? 'Producto',
      imageKey: _firstImageKey(product),
      price: (row['agreed_price'] as num?)?.toDouble() ?? 0,
    );
  }

  static String? _firstImageKey(Map<String, dynamic>? product) {
    final images = (product?['product_images'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    if (images.isEmpty) return null;
    images.sort((a, b) => ((b['is_primary'] as bool? ?? false) ? 1 : 0)
        .compareTo((a['is_primary'] as bool? ?? false) ? 1 : 0));
    final path = images.first['image_path'] as String?;
    return (path == null || path.isEmpty) ? null : path;
  }
}

/// Un pedido completo (checkout) con su estado de pago + entrega.
class PedidoTracking {
  /// Id del checkout.
  final String id;

  /// Estado del pago: pending_payment | awaiting_confirmation | paid | cancelled.
  final String paymentStatus;

  /// Estado de entrega: pending | received | reviewing | delivering | delivered | rejected.
  final String fulfillmentStatus;

  final String? rejectedReason;
  final double total;
  final double shippingFee;
  final DateTime createdAt;
  final DateTime? paidAt;

  /// Nombre del comprador (solo se usa en la vista de admin).
  final String? buyerName;

  // ── Datos de entrega ──
  final String? deliveryRecipient;
  final String? deliveryPhone;
  final String? deliveryAddress;
  final String? deliveryReference;
  final String? deliveryCity;

  final List<PedidoLine> lines;

  const PedidoTracking({
    required this.id,
    required this.paymentStatus,
    required this.fulfillmentStatus,
    required this.rejectedReason,
    required this.total,
    required this.shippingFee,
    required this.createdAt,
    required this.paidAt,
    required this.lines,
    this.buyerName,
    this.deliveryRecipient,
    this.deliveryPhone,
    this.deliveryAddress,
    this.deliveryReference,
    this.deliveryCity,
  });

  bool get hasDelivery =>
      deliveryAddress != null && deliveryAddress!.trim().isNotEmpty;

  /// Construye el pedido desde un mapa con forma de `checkouts` + sus líneas.
  factory PedidoTracking.fromCheckout(
    String id,
    Map<String, dynamic>? c,
    List<PedidoLine> lines, {
    String? buyerName,
  }) {
    DateTime? parse(Object? v) =>
        v is String && v.isNotEmpty ? DateTime.parse(v) : null;
    final lineSum = lines.fold<double>(0, (a, l) => a + l.price);
    return PedidoTracking(
      id: id,
      paymentStatus: (c?['status'] as String?) ?? 'pending_payment',
      fulfillmentStatus: (c?['fulfillment_status'] as String?) ?? 'pending',
      rejectedReason: c?['rejected_reason'] as String?,
      total: (c?['total_amount'] as num?)?.toDouble() ?? lineSum,
      shippingFee: (c?['shipping_fee'] as num?)?.toDouble() ?? 0,
      createdAt: parse(c?['created_at']) ?? DateTime.now(),
      paidAt: parse(c?['paid_at']),
      buyerName: buyerName,
      deliveryRecipient: c?['delivery_recipient'] as String?,
      deliveryPhone: c?['delivery_phone'] as String?,
      deliveryAddress: c?['delivery_address'] as String?,
      deliveryReference: c?['delivery_reference'] as String?,
      deliveryCity: c?['delivery_city'] as String?,
      lines: lines,
    );
  }

  bool get isRejected =>
      fulfillmentStatus == 'rejected' || paymentStatus == 'cancelled';

  /// El comprador aún no ha subido comprobante válido.
  bool get needsProof => paymentStatus == 'pending_payment';

  /// Índice (0..5) de la etapa alcanzada. -1 si falta el comprobante.
  int get currentStep {
    if (needsProof) return -1;
    if (paymentStatus == 'awaiting_confirmation') return 0;
    // paid → depende del fulfillment.
    switch (fulfillmentStatus) {
      case 'received':
        return 2;
      case 'reviewing':
        return 3;
      case 'delivering':
        return 4;
      case 'delivered':
        return 5;
      case 'pending':
      default:
        return 1; // pago aceptado
    }
  }

  bool get isDelivered => fulfillmentStatus == 'delivered';

  /// Etiqueta corta del estado para chips/listas.
  String get statusLabel {
    if (isRejected) return 'Rechazado';
    if (needsProof) return 'Falta tu comprobante';
    return OrderStages.labels[currentStep];
  }

  String get priceLabel => '\$${total.toStringAsFixed(2)}';

  /// Imagen de portada del pedido (primer producto).
  String? get coverImageKey => lines.isNotEmpty ? lines.first.imageKey : null;

  int get itemCount => lines.length;

  /// Vendedores distintos del pedido (para calificar tras la entrega).
  List<PedidoLine> get sellers {
    final seen = <String>{};
    final out = <PedidoLine>[];
    for (final l in lines) {
      if (seen.add(l.sellerId)) out.add(l);
    }
    return out;
  }
}

/// Siguiente estado de entrega al avanzar (null si ya está entregado).
String? nextFulfillmentStatus(String current) {
  const flow = {
    'pending': 'received',
    'received': 'reviewing',
    'reviewing': 'delivering',
    'delivering': 'delivered',
  };
  return flow[current];
}

/// Etiqueta del botón de "avanzar" según el estado actual (admin).
String? advanceLabel(String current) {
  const labels = {
    'pending': 'Marcar recibido',
    'received': 'Pasar a revisión',
    'reviewing': 'Marcar en entrega',
    'delivering': 'Marcar entregado',
  };
  return labels[current];
}
