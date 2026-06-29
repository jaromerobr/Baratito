/// Riverpod providers for the cart.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../products/domain/product_model.dart';
import '../../data/cart_repository.dart';

final cartRepositoryProvider =
    Provider<CartRepository>((ref) => CartRepository());

final cartProductsProvider = FutureProvider<List<Product>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(cartRepositoryProvider).getCartProducts();
});

final cartIdsProvider = FutureProvider<Set<String>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(cartRepositoryProvider).getCartIds();
});

/// Number of items in the cart (for the header badge).
final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartIdsProvider).maybeWhen(
        data: (ids) => ids.length,
        orElse: () => 0,
      );
});

final cartControllerProvider = Provider<CartController>((ref) => CartController(ref));

class CartController {
  final Ref _ref;
  CartController(this._ref);

  Future<void> add(String productId) async {
    await _ref.read(cartRepositoryProvider).add(productId);
    _refresh();
  }

  Future<void> remove(String productId) async {
    await _ref.read(cartRepositoryProvider).remove(productId);
    _refresh();
  }

  Future<Map<String, dynamic>> checkout() async {
    final result = await _ref.read(cartRepositoryProvider).checkout();
    _refresh();
    return result;
  }

  void _refresh() {
    _ref.invalidate(cartProductsProvider);
    _ref.invalidate(cartIdsProvider);
  }
}
