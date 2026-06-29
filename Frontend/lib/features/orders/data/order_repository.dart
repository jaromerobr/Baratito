/// Orders repository — purchase history for the current user.
library;

import '../../../core/supabase_client.dart';
import '../../products/domain/product_model.dart' show kProductImagesBucket;

/// A purchase (order) joined with minimal product/seller info.
class PurchaseItem {
  final String id;
  final String status;
  final double agreedPrice;
  final DateTime createdAt;
  final String productTitle;
  final String? productImageUrl;
  final String sellerName;

  const PurchaseItem({
    required this.id,
    required this.status,
    required this.agreedPrice,
    required this.createdAt,
    required this.productTitle,
    required this.productImageUrl,
    required this.sellerName,
  });

  String get priceLabel => '\$${agreedPrice.toStringAsFixed(2)}';
}

class OrderRepository {
  final _client = SupabaseClientHelper.client;

  Future<List<PurchaseItem>> getMyPurchases() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    final data = await _client
        .from('orders')
        .select(
          '*, products:product_id ( title, product_images ( image_path, is_primary ) ), seller:seller_id ( full_name )',
        )
        .eq('buyer_id', uid)
        .order('created_at', ascending: false);

    return (data as List<dynamic>).cast<Map<String, dynamic>>().map((row) {
      final product = row['products'] as Map<String, dynamic>?;
      final seller = row['seller'] as Map<String, dynamic>?;
      return PurchaseItem(
        id: row['id'] as String,
        status: row['status'] as String? ?? 'pending',
        agreedPrice: (row['agreed_price'] as num?)?.toDouble() ?? 0,
        createdAt: DateTime.parse(row['created_at'] as String),
        productTitle: (product?['title'] as String?) ?? 'Producto',
        productImageUrl: _firstImage(product),
        sellerName: (seller?['full_name'] as String?) ?? 'Vendedor',
      );
    }).toList();
  }

  static String? _firstImage(Map<String, dynamic>? product) {
    final images = (product?['product_images'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    if (images.isEmpty) return null;
    images.sort((a, b) =>
        ((b['is_primary'] as bool? ?? false) ? 1 : 0)
            .compareTo((a['is_primary'] as bool? ?? false) ? 1 : 0));
    final path = images.first['image_path'] as String?;
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return SupabaseClientHelper.client.storage
        .from(kProductImagesBucket)
        .getPublicUrl(path);
  }
}
