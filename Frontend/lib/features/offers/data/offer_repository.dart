/// Repositorio de ofertas: negociación de precio en productos negociables.
library;

import '../../../core/supabase_client.dart';
import '../domain/offer_model.dart';

class OfferRepository {
  final _client = SupabaseClientHelper.client;

  /// Contexto de negociación de un producto para el usuario actual dentro de un
  /// chat (el otro participante es [otherUserId]). Devuelve null si no hay sesión
  /// o el producto no existe.
  Future<OfferContext?> getContext({
    required String productId,
    required String otherUserId,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;

    final prod = await _client
        .from('products')
        .select('seller_id, is_negotiable, price')
        .eq('id', productId)
        .maybeSingle();
    if (prod == null) return null;

    final sellerId = prod['seller_id'] as String;
    // En un chat de producto, el comprador es la parte que no es el vendedor.
    final buyerId = sellerId == uid ? otherUserId : uid;

    final offers = await _client
        .from('product_offers')
        .select()
        .eq('product_id', productId)
        .eq('buyer_id', buyerId)
        .order('created_at', ascending: false)
        .limit(1);

    final list = (offers as List).cast<Map<String, dynamic>>();
    return OfferContext(
      productId: productId,
      sellerId: sellerId,
      buyerId: buyerId,
      isNegotiable: prod['is_negotiable'] as bool? ?? false,
      listPrice: (prod['price'] as num?)?.toDouble() ?? 0,
      latestOffer: list.isEmpty ? null : Offer.fromJson(list.first),
    );
  }

  /// El comprador propone un precio (solo productos negociables; lo valida el RPC).
  Future<void> makeOffer({
    required String productId,
    required double amount,
    String? conversationId,
  }) async {
    await _client.rpc('make_offer', params: {
      'p_product': productId,
      'p_amount': amount,
      'p_conversation': conversationId,
    });
  }

  /// El vendedor acepta ([accept]=true) o rechaza la oferta.
  Future<void> respondOffer(String offerId, bool accept) async {
    await _client.rpc('respond_offer',
        params: {'p_offer': offerId, 'p_accept': accept});
  }
}
