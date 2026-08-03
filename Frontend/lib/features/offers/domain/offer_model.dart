/// Oferta de precio sobre un producto negociable.
library;

class Offer {
  final String id;
  final String productId;
  final String buyerId;
  final String sellerId;
  final double amount;

  /// pending | accepted | rejected | cancelled
  final String status;
  final DateTime createdAt;

  const Offer({
    required this.id,
    required this.productId,
    required this.buyerId,
    required this.sellerId,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';

  String get amountLabel => '\$${amount.toStringAsFixed(2)}';

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      buyerId: json['buyer_id'] as String,
      sellerId: json['seller_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Contexto de negociación de una conversación de producto.
class OfferContext {
  final String productId;
  final String sellerId;
  final String buyerId;
  final bool isNegotiable;
  final double listPrice;

  /// Última oferta entre este comprador y este producto (si existe).
  final Offer? latestOffer;

  const OfferContext({
    required this.productId,
    required this.sellerId,
    required this.buyerId,
    required this.isNegotiable,
    required this.listPrice,
    required this.latestOffer,
  });

  bool amISeller(String uid) => uid == sellerId;
}
