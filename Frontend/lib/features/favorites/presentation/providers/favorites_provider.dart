/// Riverpod providers for favorites.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../products/domain/product_model.dart';
import '../../data/favorites_repository.dart';

final favoritesRepositoryProvider =
    Provider<FavoritesRepository>((ref) => FavoritesRepository());

/// Set of favorited product ids (for heart state on cards/detail).
final favoriteIdsProvider = FutureProvider<Set<String>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(favoritesRepositoryProvider).getFavoriteIds();
});

/// Favorited products for the "Guardados" tab.
final favoriteProductsProvider = FutureProvider<List<Product>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(favoritesRepositoryProvider).getFavoriteProducts();
});

/// Toggle a product's favorite state and refresh.
final favoritesControllerProvider =
    Provider<FavoritesController>((ref) => FavoritesController(ref));

class FavoritesController {
  final Ref _ref;
  FavoritesController(this._ref);

  Future<void> toggle(String productId, bool currentlyFav) async {
    final repo = _ref.read(favoritesRepositoryProvider);
    if (currentlyFav) {
      await repo.remove(productId);
    } else {
      await repo.add(productId);
    }
    _ref.invalidate(favoriteIdsProvider);
    _ref.invalidate(favoriteProductsProvider);
  }
}
