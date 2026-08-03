/// Domain models for the marketplace catalog.
///
/// [Product] maps the `public.products` table (joined with its images,
/// seller profile and category). [ProductCondition] gives a Spanish label
/// for the `product_condition` enum, tolerating English or Spanish values.
library;

class Product {
  final String id;
  final String sellerId;
  final String? categoryId;
  final String title;
  final String? description;
  final double price;
  final double? originalPrice;
  final String condition;
  final String status;
  final String? brand;
  final String locationCity;
  final bool isNegotiable;
  final int likesCount;
  final int viewsCount;
  final DateTime createdAt;
  final DateTime? publishedAt;

  // ── Joined data ───────────────────────────────────────
  /// Object keys de las imágenes en MinIO (la URL se firma al mostrarlas).
  final List<String> imageKeys;
  final String? sellerName;
  final String? sellerAvatarPath;
  final String? categoryName;

  /// Valoración del vendedor (promedio 0-5 y número de reseñas).
  final double sellerRatingAvg;
  final int sellerRatingCount;

  const Product({
    required this.id,
    required this.sellerId,
    this.categoryId,
    required this.title,
    this.description,
    required this.price,
    this.originalPrice,
    required this.condition,
    required this.status,
    this.brand,
    this.locationCity = 'Loja',
    this.isNegotiable = false,
    this.likesCount = 0,
    this.viewsCount = 0,
    required this.createdAt,
    this.publishedAt,
    this.imageKeys = const [],
    this.sellerName,
    this.sellerAvatarPath,
    this.categoryName,
    this.sellerRatingAvg = 0,
    this.sellerRatingCount = 0,
  });

  /// Primary image key, or null when the product has no images.
  String? get primaryImageKey => imageKeys.isNotEmpty ? imageKeys.first : null;

  /// True si el producto tiene al menos una imagen que hoy se puede mostrar:
  /// una key de MinIO (`products/...`) o una URL http (semilla). Los productos
  /// que solo tienen imágenes del storage viejo de Supabase (formato
  /// `<userId>/<productId>/<i>.<ext>`, ya inexistentes) devuelven false y se
  /// ocultan del catálogo.
  bool get hasVisibleImage => imageKeys.any(
        (k) => k.startsWith('products/') || k.startsWith('http'),
      );

  /// Human-readable Spanish label for the condition.
  String get conditionLabel => ProductCondition.label(condition);

  /// Price formatted like `$380.00`.
  String get priceLabel => '\$${price.toStringAsFixed(2)}';

  factory Product.fromJson(Map<String, dynamic> json) {
    // ── Images: sort primary first, then by sort_order ──
    final rawImages = (json['product_images'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
      ..sort((a, b) {
        final pa = (a['is_primary'] as bool? ?? false) ? 0 : 1;
        final pb = (b['is_primary'] as bool? ?? false) ? 0 : 1;
        if (pa != pb) return pa.compareTo(pb);
        return ((a['sort_order'] as num?) ?? 0)
            .compareTo((b['sort_order'] as num?) ?? 0);
      });
    final imageKeys = rawImages
        .map((img) => img['image_path'] as String?)
        .whereType<String>()
        .where((path) => path.isNotEmpty)
        .toList();

    // ── Seller (embedded profile) ──
    final seller = json['profiles'] as Map<String, dynamic>?;
    // ── Category (embedded) ──
    final category = json['categories'] as Map<String, dynamic>?;

    return Product(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      categoryId: json['category_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      originalPrice: (json['original_price'] as num?)?.toDouble(),
      condition: json['condition'] as String? ?? '',
      status: json['status'] as String? ?? 'draft',
      brand: json['brand'] as String?,
      locationCity: json['location_city'] as String? ?? 'Loja',
      isNegotiable: json['is_negotiable'] as bool? ?? false,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      viewsCount: (json['views_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : null,
      imageKeys: imageKeys,
      sellerName: seller?['full_name'] as String?,
      sellerAvatarPath: seller?['avatar_path'] as String?,
      categoryName: category?['name'] as String?,
      sellerRatingAvg: (seller?['rating_avg'] as num?)?.toDouble() ?? 0,
      sellerRatingCount: (seller?['rating_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Maps the `product_condition` enum to a Spanish UI label.
/// Tolerates English or Spanish enum values so we don't hard-depend
/// on the exact strings in the database.
class ProductCondition {
  ProductCondition._();

  static const List<String> filterLabels = [
    'Todos',
    'Nuevo',
    'Como nuevo',
    'Buen estado',
    'Usado',
  ];

  /// Raw `product_condition` enum value for a filter label.
  /// DB enum: new | like_new | good | used.
  static List<String> rawCandidates(String filterLabel) {
    switch (filterLabel) {
      case 'Nuevo':
        return ['new'];
      case 'Como nuevo':
        return ['like_new'];
      case 'Buen estado':
        return ['good'];
      case 'Usado':
        return ['used'];
      default:
        return const [];
    }
  }

  /// Maps a filter label to the single raw enum value (for writing products).
  static String? rawValue(String filterLabel) {
    final c = rawCandidates(filterLabel);
    return c.isEmpty ? null : c.first;
  }

  /// The 4 selectable conditions for the publish form (label → raw value).
  static const Map<String, String> selectable = {
    'Nuevo': 'new',
    'Como nuevo': 'like_new',
    'Buen estado': 'good',
    'Usado': 'used',
  };

  static String label(String raw) {
    switch (raw.toLowerCase()) {
      case 'nuevo':
      case 'new':
        return 'Nuevo';
      case 'como_nuevo':
      case 'como nuevo':
      case 'like_new':
        return 'Como nuevo';
      case 'buen_estado':
      case 'buen estado':
      case 'good':
        return 'Buen estado';
      case 'aceptable':
      case 'fair':
        return 'Aceptable';
      case 'usado':
      case 'used':
        return 'Usado';
      default:
        if (raw.isEmpty) return 'Usado';
        // Capitalize and replace underscores for unknown values.
        final clean = raw.replaceAll('_', ' ');
        return clean[0].toUpperCase() + clean.substring(1);
    }
  }
}
