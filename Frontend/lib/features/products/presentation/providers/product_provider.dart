/// Riverpod providers for the products feature.
library;

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/product_repository.dart';
import '../../domain/mock_products.dart';
import '../../domain/product_model.dart';

// ── Repository ────────────────────────────────────────────

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

// ── Categories ────────────────────────────────────────────

final categoriesProvider = FutureProvider<List<ProductCategory>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  final result = await repo.fetchCategories();
  return switch (result) {
    Success(data: final list) => list,
    Failure() => <ProductCategory>[],
  };
});

// ── Feed filters state ────────────────────────────────────

class FeedFilters {
  final String? search;
  final String? categoryId;
  final String? condition;

  const FeedFilters({this.search, this.categoryId, this.condition});

  FeedFilters copyWith({
    String? search,
    String? categoryId,
    String? condition,
    bool clearSearch = false,
    bool clearCategory = false,
    bool clearCondition = false,
  }) {
    return FeedFilters(
      search: clearSearch ? null : search ?? this.search,
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      condition: clearCondition ? null : condition ?? this.condition,
    );
  }
}

class FeedFiltersNotifier extends StateNotifier<FeedFilters> {
  FeedFiltersNotifier() : super(const FeedFilters());

  void setSearch(String? value) {
    state = state.copyWith(
      search: (value?.isEmpty ?? true) ? null : value,
      clearSearch: value?.isEmpty ?? true,
    );
  }

  void setCategory(String? id) {
    state = state.copyWith(
      categoryId: id,
      clearCategory: id == null,
    );
  }

  void setCondition(String? c) {
    state = state.copyWith(
      condition: c,
      clearCondition: c == null,
    );
  }

  void clear() {
    state = const FeedFilters();
  }
}

final feedFiltersProvider =
    StateNotifierProvider<FeedFiltersNotifier, FeedFilters>(
  (ref) => FeedFiltersNotifier(),
);

// ── Product feed ──────────────────────────────────────────

final productFeedProvider = FutureProvider<List<Product>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  final filters = ref.watch(feedFiltersProvider);

  final result = await repo.fetchFeed(
    search: filters.search,
    categoryId: filters.categoryId,
    condition: filters.condition,
  );

  return switch (result) {
    Success(data: final list) => list,
    Failure() => <Product>[],
  };
});

// ── Single product ────────────────────────────────────────

final productDetailProvider =
    FutureProvider.family<Product?, String>((ref, productId) async {
  // Check mock data first (demo mode — no DB required)
  final mock = mockProducts.where((p) => p.id == productId).firstOrNull;
  if (mock != null) return mock;

  // Fall back to Supabase
  final repo = ref.watch(productRepositoryProvider);
  final result = await repo.fetchProduct(productId);
  return switch (result) {
    Success(data: final p) => p,
    Failure() => null,
  };
});

// ── My listings ───────────────────────────────────────────

final myListingsProvider = FutureProvider<List<Product>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.whenOrNull(
    data: (s) => s.session?.user.id,
  );
  if (userId == null) return [];

  final repo = ref.watch(productRepositoryProvider);
  final result = await repo.fetchMyListings(userId);
  return switch (result) {
    Success(data: final list) => list,
    Failure() => <Product>[],
  };
});

// ── Favorites ─────────────────────────────────────────────

final favoritesProvider = FutureProvider<List<Product>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.whenOrNull(
    data: (s) => s.session?.user.id,
  );
  if (userId == null) return [];

  final repo = ref.watch(productRepositoryProvider);
  final result = await repo.fetchFavorites(userId);
  return switch (result) {
    Success(data: final list) => list,
    Failure() => <Product>[],
  };
});

final isFavoriteProvider =
    FutureProvider.family<bool, String>((ref, productId) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.whenOrNull(data: (s) => s.session?.user.id);
  if (userId == null) return false;

  final repo = ref.watch(productRepositoryProvider);
  final result = await repo.isFavorite(userId, productId);
  return switch (result) {
    Success(data: final v) => v,
    Failure() => false,
  };
});

// ── Product form controller ───────────────────────────────

class ProductFormState {
  final bool isLoading;
  final String? errorMessage;
  final String? successProductId;

  const ProductFormState({
    this.isLoading = false,
    this.errorMessage,
    this.successProductId,
  });

  ProductFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successProductId,
  }) {
    return ProductFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successProductId: successProductId,
    );
  }
}

class ProductFormController extends StateNotifier<ProductFormState> {
  final ProductRepository _repo;
  final String _sellerId;

  ProductFormController(this._repo, this._sellerId)
      : super(const ProductFormState());

  Future<bool> submitProduct({
    required String title,
    String? description,
    required double price,
    required bool isNegotiable,
    required ProductCondition condition,
    String? categoryId,
    String? brand,
    required List<File> images,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    if (images.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Agrega al menos una foto.',
      );
      return false;
    }

    final product = Product(
      id: '',
      sellerId: _sellerId,
      categoryId: categoryId,
      title: title,
      description: description,
      price: price,
      isNegotiable: isNegotiable,
      condition: condition,
      status: ProductStatus.active,
      brand: brand,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final createResult = await _repo.createProduct(product);
    if (createResult is Failure) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: (createResult as Failure).message,
      );
      return false;
    }

    final productId = (createResult as Success<String>).data;

    // Upload images
    for (int i = 0; i < images.length; i++) {
      final uploadResult = await _repo.uploadImage(
        sellerId: _sellerId,
        productId: productId,
        imageFile: images[i],
        sortOrder: i,
      );
      if (uploadResult is Failure<String>) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Error al subir imagen ${i + 1}: ${(uploadResult as Failure).message}',
        );
        return false;
      }
    }

    state = state.copyWith(isLoading: false, successProductId: productId);
    return true;
  }
}

final productFormControllerProvider =
    StateNotifierProvider<ProductFormController, ProductFormState>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final userId = authState.whenOrNull(data: (s) => s.session?.user.id) ?? '';
  return ProductFormController(repo, userId);
});
