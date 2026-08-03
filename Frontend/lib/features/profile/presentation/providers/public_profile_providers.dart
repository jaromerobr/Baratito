/// Providers del perfil público de un usuario (visto desde un producto).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/profile_repository.dart';
import '../../../products/domain/product_model.dart';
import '../../../products/presentation/providers/products_provider.dart';

final publicProfileRepositoryProvider =
    Provider<ProfileRepository>((ref) => ProfileRepository());

final publicProfileProvider =
    FutureProvider.family<PublicProfile?, String>((ref, userId) async {
  return ref.watch(publicProfileRepositoryProvider).getPublicProfile(userId);
});

typedef UserProductsArgs = ({String sellerId, String status});

final userProductsProvider =
    FutureProvider.family<List<Product>, UserProductsArgs>((ref, args) async {
  return ref
      .watch(productRepositoryProvider)
      .fetchUserProducts(sellerId: args.sellerId, status: args.status);
});
