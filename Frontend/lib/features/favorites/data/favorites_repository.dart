/// Favorites repository — save/unsave products.
library;

import '../../../core/supabase_client.dart';
import '../../products/data/product_repository.dart';
import '../../products/domain/product_model.dart';

class FavoritesRepository {
  final _client = SupabaseClientHelper.client;

  String? get _uid => _client.auth.currentUser?.id;

  /// Set of product ids the current user has favorited.
  Future<Set<String>> getFavoriteIds() async {
    final uid = _uid;
    if (uid == null) return {};
    final data = await _client
        .from('favorites')
        .select('product_id')
        .eq('user_id', uid);
    return (data as List<dynamic>)
        .map((e) => (e as Map<String, dynamic>)['product_id'] as String)
        .toSet();
  }

  /// Favorited products (full product shape) for the "Guardados" tab.
  Future<List<Product>> getFavoriteProducts() async {
    final uid = _uid;
    if (uid == null) return [];
    final data = await _client
        .from('favorites')
        .select('product:product_id ( ${ProductRepository.productRelations} )')
        .eq('user_id', uid)
        .order('saved_at', ascending: false);

    return (data as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((row) => row['product'] as Map<String, dynamic>?)
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .where((p) => p.hasVisibleImage)
        .toList();
  }

  Future<void> add(String productId) async {
    final uid = _uid;
    if (uid == null) return;
    await _client.from('favorites').upsert(
      {'user_id': uid, 'product_id': productId},
      onConflict: 'user_id,product_id',
      ignoreDuplicates: true,
    );
  }

  Future<void> remove(String productId) async {
    final uid = _uid;
    if (uid == null) return;
    await _client
        .from('favorites')
        .delete()
        .eq('user_id', uid)
        .eq('product_id', productId);
  }
}
