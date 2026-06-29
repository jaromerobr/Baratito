/// Product repository — reads the marketplace catalog from Supabase.
///
/// All "live" products are those with a non-null `published_at`. This keeps
/// us independent from the exact value of the `product_status` enum.
library;

import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import '../../../core/supabase_client.dart';
import '../domain/product_model.dart';
import '../domain/category_model.dart';

/// One image to upload when publishing a product.
typedef NewImage = ({Uint8List bytes, String ext});

class ProductRepository {
  final _client = SupabaseClientHelper.client;

  /// Columns + embedded relations fetched for every product card.
  /// Public so favorites/cart can embed the same product shape.
  static const String productRelations = '''
        *,
        product_images ( image_path, is_primary, sort_order ),
        profiles:seller_id ( full_name, username, avatar_path ),
        categories:category_id ( name, slug )
      ''';
  static const String _select = productRelations;

  /// Fetch published products, newest first.
  ///
  /// [categoryId] filters by category, [conditions] by any of the given raw
  /// enum values, and [search] does a case-insensitive match on the title.
  Future<List<Product>> fetchProducts({
    String? categoryId,
    List<String>? conditions,
    String? search,
    int limit = 40,
  }) async {
    var query = _client
        .from('products')
        .select(_select)
        .not('published_at', 'is', null);

    if (categoryId != null) query = query.eq('category_id', categoryId);
    if (conditions != null && conditions.isNotEmpty) {
      query = query.inFilter('condition', conditions);
    }
    if (search != null && search.trim().isNotEmpty) {
      query = query.ilike('title', '%${search.trim()}%');
    }

    final data = await query
        .order('published_at', ascending: false)
        .limit(limit);

    return (data as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  }

  /// Products owned by the current user, optionally filtered by status
  /// (e.g. 'active' = en venta, 'sold' = vendidos).
  Future<List<Product>> fetchMyProducts({String? status}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    var query = _client.from('products').select(_select).eq('seller_id', uid);
    if (status != null) query = query.eq('status', status);

    final data = await query.order('created_at', ascending: false);
    return (data as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  }

  /// Fetch a single product by id (with all relations).
  Future<Product> fetchProductById(String id) async {
    final data =
        await _client.from('products').select(_select).eq('id', id).single();
    return Product.fromJson(data);
  }

  /// Publish a new product: insert the row, upload images to storage and
  /// register them in `product_images`. Returns the new product id.
  Future<String> createProduct({
    required String title,
    String? description,
    required double price,
    String? categoryId,
    required String conditionRaw,
    String? brand,
    bool isNegotiable = false,
    List<NewImage> images = const [],
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Debes iniciar sesión para publicar.');
    }

    // 1. Insert the product (published immediately).
    final row = await _client
        .from('products')
        .insert({
          'seller_id': userId,
          'category_id': categoryId,
          'title': title.trim(),
          'description': description?.trim(),
          'price': price,
          'condition': conditionRaw,
          'status': 'active',
          'brand': brand?.trim(),
          'is_negotiable': isNegotiable,
          'published_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select('id')
        .single();

    final productId = row['id'] as String;

    // 2. Upload each image and register it.
    for (var i = 0; i < images.length; i++) {
      final img = images[i];
      final ext = img.ext == 'png' ? 'png' : 'jpg';
      final path = '$userId/$productId/$i.$ext';

      await _client.storage.from(kProductImagesBucket).uploadBinary(
            path,
            img.bytes,
            fileOptions: FileOptions(
              contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
              upsert: true,
            ),
          );

      await _client.from('product_images').insert({
        'product_id': productId,
        'image_path': path,
        'is_primary': i == 0,
        'sort_order': i,
      });
    }

    return productId;
  }

  /// Fetch active top-level categories ordered by `sort_order`.
  Future<List<Category>> fetchCategories() async {
    final data = await _client
        .from('categories')
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    return (data as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Category.fromJson)
        .toList();
  }
}
