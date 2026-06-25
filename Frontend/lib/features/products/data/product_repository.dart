/// Product repository — Supabase data layer.
library;

import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase_client.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../domain/product_model.dart';

// ── Query helpers ─────────────────────────────────────────

const _productSelect = '''
  id, seller_id, category_id, title, description, price, is_negotiable,
  condition, status, brand, created_at, updated_at,
  product_images(id, product_id, image_path, is_primary, sort_order),
  profiles:seller_id(full_name, avatar_url, trust_score),
  categories:category_id(name)
''';

// ── Repository ────────────────────────────────────────────

class ProductRepository {
  final SupabaseClient _client = SupabaseClientHelper.client;

  // ── Fetch feed ──────────────────────────────────────────

  Future<Result<List<Product>>> fetchFeed({
    String? search,
    String? categoryId,
    String? condition,
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      var query = _client
          .from('products')
          .select(_productSelect)
          .eq('status', 'active');

      if (categoryId != null) query = query.eq('category_id', categoryId);
      if (condition != null) query = query.eq('condition', condition);
      if (search != null && search.isNotEmpty) {
        query = query.ilike('title', '%$search%');
      }

      final data = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return Success(
        (data as List).map((e) => Product.fromJson(e)).toList(),
      );
    } catch (e) {
      return Failure('Error al cargar productos.', code: e.toString());
    }
  }

  // ── Fetch single product ────────────────────────────────

  Future<Result<Product>> fetchProduct(String productId) async {
    try {
      final data = await _client
          .from('products')
          .select(_productSelect)
          .eq('id', productId)
          .single();
      return Success(Product.fromJson(data));
    } catch (e) {
      return Failure('Error al cargar el producto.', code: e.toString());
    }
  }

  // ── Fetch my listings ───────────────────────────────────

  Future<Result<List<Product>>> fetchMyListings(String sellerId) async {
    try {
      final data = await _client
          .from('products')
          .select(_productSelect)
          .eq('seller_id', sellerId)
          .neq('status', 'deleted')
          .order('created_at', ascending: false);
      return Success(
        (data as List).map((e) => Product.fromJson(e)).toList(),
      );
    } catch (e) {
      return Failure('Error al cargar tus publicaciones.', code: e.toString());
    }
  }

  // ── Fetch categories ────────────────────────────────────

  Future<Result<List<ProductCategory>>> fetchCategories() async {
    try {
      final data = await _client
          .from('categories')
          .select('id, name, icon_name')
          .eq('is_active', true)
          .order('name');
      return Success(
        (data as List).map((e) => ProductCategory.fromJson(e)).toList(),
      );
    } catch (e) {
      return Failure('Error al cargar categorías.', code: e.toString());
    }
  }

  // ── Create product ──────────────────────────────────────

  Future<Result<String>> createProduct(Product product) async {
    try {
      final data = await _client
          .from('products')
          .insert(product.toInsertJson())
          .select('id')
          .single();
      return Success(data['id'] as String);
    } catch (e) {
      return Failure('Error al publicar el producto.', code: e.toString());
    }
  }

  // ── Update product ──────────────────────────────────────

  Future<Result<void>> updateProduct(
    String productId,
    Map<String, dynamic> fields,
  ) async {
    try {
      await _client.from('products').update(fields).eq('id', productId);
      return const Success(null);
    } catch (e) {
      return Failure('Error al actualizar el producto.', code: e.toString());
    }
  }

  // ── Delete product (soft) ───────────────────────────────

  Future<Result<void>> deleteProduct(String productId) async {
    try {
      await _client
          .from('products')
          .update({'status': 'deleted'}).eq('id', productId);
      return const Success(null);
    } catch (e) {
      return Failure('Error al eliminar el producto.', code: e.toString());
    }
  }

  // ── Upload product image ────────────────────────────────

  Future<Result<String>> uploadImage({
    required String sellerId,
    required String productId,
    required File imageFile,
    required int sortOrder,
  }) async {
    try {
      // Compress image before upload
      final compressed = await FlutterImageCompress.compressWithFile(
        imageFile.path,
        quality: 80,
        minWidth: 1280,
        minHeight: 1280,
        keepExif: false,
      );

      if (compressed == null) {
        return const Failure('No se pudo comprimir la imagen.');
      }

      final ext = imageFile.path.split('.').last.toLowerCase();
      final fileName = '$sellerId/$productId/${sortOrder}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _client.storage
          .from('products')
          .uploadBinary(fileName, compressed);

      // Insert into product_images table
      await _client.from('product_images').insert({
        'product_id': productId,
        'image_path': fileName,
        'is_primary': sortOrder == 0,
        'sort_order': sortOrder,
      });

      return Success(fileName);
    } catch (e) {
      return Failure('Error al subir la imagen.', code: e.toString());
    }
  }

  // ── Delete product image ────────────────────────────────

  Future<Result<void>> deleteImage(String imageId, String imagePath) async {
    try {
      await _client.storage.from('products').remove([imagePath]);
      await _client.from('product_images').delete().eq('id', imageId);
      return const Success(null);
    } catch (e) {
      return Failure('Error al eliminar la imagen.', code: e.toString());
    }
  }

  // ── Get image public URL ────────────────────────────────

  String getImageUrl(String imagePath) {
    return _client.storage.from('products').getPublicUrl(imagePath);
  }

  // ── Favorites ───────────────────────────────────────────

  Future<Result<List<Product>>> fetchFavorites(String userId) async {
    try {
      final data = await _client
          .from('favorites')
          .select('product:product_id($_productSelect)')
          .eq('user_id', userId);

      final products = (data as List)
          .map((e) => Product.fromJson(e['product'] as Map<String, dynamic>))
          .where((p) => p.status == ProductStatus.active)
          .toList();

      return Success(products);
    } catch (e) {
      return Failure('Error al cargar favoritos.', code: e.toString());
    }
  }

  Future<Result<bool>> isFavorite(String userId, String productId) async {
    try {
      final data = await _client
          .from('favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle();
      return Success(data != null);
    } catch (e) {
      return Success(false);
    }
  }

  Future<Result<void>> toggleFavorite(
    String userId,
    String productId,
    bool currentlyFavorite,
  ) async {
    try {
      if (currentlyFavorite) {
        await _client
            .from('favorites')
            .delete()
            .eq('user_id', userId)
            .eq('product_id', productId);
      } else {
        await _client.from('favorites').insert({
          'user_id': userId,
          'product_id': productId,
        });
      }
      return const Success(null);
    } catch (e) {
      return Failure('Error al actualizar favoritos.', code: e.toString());
    }
  }
}
