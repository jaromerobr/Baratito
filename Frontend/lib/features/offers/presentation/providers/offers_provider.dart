/// Providers de ofertas / negociación.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/offer_repository.dart';
import '../../domain/offer_model.dart';

final offerRepositoryProvider = Provider<OfferRepository>((ref) {
  return OfferRepository();
});

typedef OfferArgs = ({String productId, String otherUserId});

/// Contexto de negociación de un producto dentro de un chat.
final offerContextProvider =
    FutureProvider.family<OfferContext?, OfferArgs>((ref, args) async {
  return ref.watch(offerRepositoryProvider).getContext(
        productId: args.productId,
        otherUserId: args.otherUserId,
      );
});
