/// Orders repository — pedidos (checkouts) del comprador con su seguimiento.
library;

import '../../../core/supabase_client.dart';
import '../domain/order_tracking_model.dart';
import '../domain/sale_model.dart';

class OrderRepository {
  final _client = SupabaseClientHelper.client;

  /// Pedidos del comprador (agrupados por checkout) con estado de entrega,
  /// para la pantalla de seguimiento con animación.
  Future<List<PedidoTracking>> getMyPedidos() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    final data = await _client
        .from('orders')
        .select(
          'id, seller_id, agreed_price, checkout_id, '
          'products:product_id ( title, product_images ( image_path, is_primary ) ), '
          'seller:seller_id ( full_name ), '
          'checkout:checkout_id ( status, fulfillment_status, rejected_reason, '
          'total_amount, shipping_fee, created_at, paid_at, '
          'delivery_recipient, delivery_phone, delivery_address, '
          'delivery_reference, delivery_city )',
        )
        .eq('buyer_id', uid)
        .order('created_at', ascending: false);

    // Agrupar las órdenes por checkout, conservando el orden de llegada.
    final rows = (data as List<dynamic>).cast<Map<String, dynamic>>();
    final groups = <String, List<Map<String, dynamic>>>{};
    final order = <String>[];
    for (final r in rows) {
      final cid = r['checkout_id'] as String?;
      if (cid == null) continue; // órdenes legacy sin checkout: se omiten
      if (!groups.containsKey(cid)) {
        groups[cid] = [];
        order.add(cid);
      }
      groups[cid]!.add(r);
    }

    return order.map((cid) {
      final group = groups[cid]!;
      final checkout = group.first['checkout'] as Map<String, dynamic>?;
      final lines = group.map(PedidoLine.fromOrderRow).toList();
      return PedidoTracking.fromCheckout(cid, checkout, lines);
    }).toList();
  }

  /// Ventas del vendedor actual (agrupadas por pedido), para calificar al
  /// comprador cuando el pedido esté entregado.
  Future<List<SaleGroup>> getMySales() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    final data = await _client
        .from('orders')
        .select(
          'id, buyer_id, agreed_price, checkout_id, '
          'products:product_id ( title, product_images ( image_path, is_primary ) ), '
          'buyer:buyer_id ( full_name ), '
          'checkout:checkout_id ( status, fulfillment_status, created_at )',
        )
        .eq('seller_id', uid)
        .order('created_at', ascending: false);

    final rows = (data as List<dynamic>).cast<Map<String, dynamic>>();
    final groups = <String, List<Map<String, dynamic>>>{};
    final order = <String>[];
    for (final r in rows) {
      final cid = r['checkout_id'] as String?;
      if (cid == null) continue;
      if (!groups.containsKey(cid)) {
        groups[cid] = [];
        order.add(cid);
      }
      groups[cid]!.add(r);
    }

    return order.map((cid) {
      final g = groups[cid]!;
      final first = g.first;
      final checkout = first['checkout'] as Map<String, dynamic>?;
      final buyer = first['buyer'] as Map<String, dynamic>?;
      final items = g.map((r) {
        final product = r['products'] as Map<String, dynamic>?;
        return SaleLine(
          title: (product?['title'] as String?) ?? 'Producto',
          imageKey: _firstImage(product),
          price: (r['agreed_price'] as num?)?.toDouble() ?? 0,
        );
      }).toList();
      return SaleGroup(
        checkoutId: cid,
        buyerId: first['buyer_id'] as String? ?? '',
        buyerName: (buyer?['full_name'] as String?) ?? 'Comprador',
        paymentStatus: (checkout?['status'] as String?) ?? 'pending_payment',
        fulfillmentStatus:
            (checkout?['fulfillment_status'] as String?) ?? 'pending',
        createdAt: checkout?['created_at'] != null
            ? DateTime.parse(checkout!['created_at'] as String)
            : DateTime.now(),
        items: items,
      );
    }).toList();
  }

  static String? _firstImage(Map<String, dynamic>? product) {
    final images = (product?['product_images'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    if (images.isEmpty) return null;
    images.sort((a, b) => ((b['is_primary'] as bool? ?? false) ? 1 : 0)
        .compareTo((a['is_primary'] as bool? ?? false) ? 1 : 0));
    final path = images.first['image_path'] as String?;
    return (path == null || path.isEmpty) ? null : path;
  }
}
