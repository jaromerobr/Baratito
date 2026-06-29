/// Cart repository — persistent cart + checkout (split per seller).
library;

import '../../../core/supabase_client.dart';
import '../../products/data/product_repository.dart';
import '../../products/domain/product_model.dart';

class CartRepository {
  final _client = SupabaseClientHelper.client;
  String? get _uid => _client.auth.currentUser?.id;

  /// Products currently in the cart (newest first).
  Future<List<Product>> getCartProducts() async {
    final uid = _uid;
    if (uid == null) return [];
    final data = await _client
        .from('cart_items')
        .select('added_at, product:product_id ( ${ProductRepository.productRelations} )')
        .eq('user_id', uid)
        .order('added_at', ascending: false);

    return (data as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((row) => row['product'] as Map<String, dynamic>?)
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  }

  /// Product ids in the cart (for badge + "in cart" state).
  Future<Set<String>> getCartIds() async {
    final uid = _uid;
    if (uid == null) return {};
    final data =
        await _client.from('cart_items').select('product_id').eq('user_id', uid);
    return (data as List<dynamic>)
        .map((e) => (e as Map<String, dynamic>)['product_id'] as String)
        .toSet();
  }

  Future<void> add(String productId) async {
    final uid = _uid;
    if (uid == null) return;
    await _client.from('cart_items').upsert(
      {'user_id': uid, 'product_id': productId},
      onConflict: 'user_id,product_id',
      ignoreDuplicates: true,
    );
  }

  Future<void> remove(String productId) async {
    final uid = _uid;
    if (uid == null) return;
    await _client
        .from('cart_items')
        .delete()
        .eq('user_id', uid)
        .eq('product_id', productId);
  }

  /// Atomic checkout: creates one order per product (split per seller),
  /// all sharing a checkout_id. Returns {checkout_id, orders, sellers}.
  Future<Map<String, dynamic>> checkout() async {
    final res = await _client.rpc('checkout_cart');
    return Map<String, dynamic>.from(res as Map);
  }
}
