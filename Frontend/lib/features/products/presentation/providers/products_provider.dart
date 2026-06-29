/// Riverpod providers for the marketplace catalog.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/product_repository.dart';
import '../../domain/product_model.dart';
import '../../domain/category_model.dart';

// ── Repository ──────────────────────────────────────────
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

// ── Active filters ──────────────────────────────────────
class ProductFilters {
  final String? categoryId;
  /// Selected condition *filter label* (e.g. 'Nuevo'); null means "Todos".
  final String? condition;
  final String search;

  const ProductFilters({
    this.categoryId,
    this.condition,
    this.search = '',
  });

  ProductFilters copyWith({
    Object? categoryId = _sentinel,
    Object? condition = _sentinel,
    String? search,
  }) {
    return ProductFilters(
      categoryId:
          categoryId == _sentinel ? this.categoryId : categoryId as String?,
      condition:
          condition == _sentinel ? this.condition : condition as String?,
      search: search ?? this.search,
    );
  }

  static const _sentinel = Object();
}

class ProductFiltersNotifier extends StateNotifier<ProductFilters> {
  ProductFiltersNotifier() : super(const ProductFilters());

  void setCategory(String? categoryId) =>
      state = state.copyWith(categoryId: categoryId);

  void setCondition(String? condition) =>
      state = state.copyWith(condition: condition);

  void setSearch(String search) => state = state.copyWith(search: search);

  void clear() => state = const ProductFilters();
}

final productFiltersProvider =
    StateNotifierProvider<ProductFiltersNotifier, ProductFilters>((ref) {
  return ProductFiltersNotifier();
});

// ── Categories ──────────────────────────────────────────
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.fetchCategories();
});

// ── Products (reacts to the active filters) ─────────────
final productsProvider = FutureProvider<List<Product>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  final filters = ref.watch(productFiltersProvider);
  return repo.fetchProducts(
    categoryId: filters.categoryId,
    conditions: filters.condition == null
        ? null
        : ProductCondition.rawCandidates(filters.condition!),
    search: filters.search,
  );
});

// ── My products (by status) ─────────────────────────────
final myProductsProvider =
    FutureProvider.family<List<Product>, String?>((ref, status) async {
  ref.watch(authStateProvider);
  return ref.watch(productRepositoryProvider).fetchMyProducts(status: status);
});

// ── Single product detail ───────────────────────────────
final productDetailProvider =
    FutureProvider.family<Product, String>((ref, id) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.fetchProductById(id);
});
