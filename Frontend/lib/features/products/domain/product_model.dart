/// Product domain model — matches `public.products` + `product_images` tables.
library;

// ── Enums ────────────────────────────────────────────────

enum ProductCondition {
  nuevo('nuevo', 'Nuevo'),
  comoNuevo('como_nuevo', 'Como nuevo'),
  buenEstado('buen_estado', 'Buen estado'),
  usado('usado', 'Usado');

  final String value;
  final String label;
  const ProductCondition(this.value, this.label);

  static ProductCondition fromString(String value) {
    return ProductCondition.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ProductCondition.usado,
    );
  }
}

enum ProductStatus {
  active('active'),
  sold('sold'),
  paused('paused'),
  deleted('deleted');

  final String value;
  const ProductStatus(this.value);

  static ProductStatus fromString(String value) {
    return ProductStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ProductStatus.active,
    );
  }
}

// ── Product Image ─────────────────────────────────────────

class ProductImage {
  final String id;
  final String productId;
  final String imagePath;
  final bool isPrimary;
  final int sortOrder;

  const ProductImage({
    required this.id,
    required this.productId,
    required this.imagePath,
    required this.isPrimary,
    required this.sortOrder,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      imagePath: json['image_path'] as String,
      isPrimary: json['is_primary'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}

// ── Product ───────────────────────────────────────────────

class Product {
  final String id;
  final String sellerId;
  final String? categoryId;
  final String title;
  final String? description;
  final double price;
  final bool isNegotiable;
  final ProductCondition condition;
  final ProductStatus status;
  final String? brand;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields
  final List<ProductImage> images;
  final String? sellerName;
  final String? sellerAvatarUrl;
  final int? sellerTrustScore;
  final String? categoryName;

  const Product({
    required this.id,
    required this.sellerId,
    this.categoryId,
    required this.title,
    this.description,
    required this.price,
    this.isNegotiable = false,
    required this.condition,
    required this.status,
    this.brand,
    required this.createdAt,
    required this.updatedAt,
    this.images = const [],
    this.sellerName,
    this.sellerAvatarUrl,
    this.sellerTrustScore,
    this.categoryName,
  });

  String? get primaryImagePath {
    if (images.isEmpty) return null;
    final primary = images.where((i) => i.isPrimary).firstOrNull;
    return (primary ?? images.first).imagePath;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final imagesJson = json['product_images'] as List<dynamic>? ?? [];
    final images = imagesJson
        .map((e) => ProductImage.fromJson(e as Map<String, dynamic>))
        .toList();
    images.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final seller = json['profiles'] as Map<String, dynamic>?;

    return Product(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      categoryId: json['category_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      isNegotiable: json['is_negotiable'] as bool? ?? false,
      condition: ProductCondition.fromString(
        json['condition'] as String? ?? 'usado',
      ),
      status: ProductStatus.fromString(json['status'] as String? ?? 'active'),
      brand: json['brand'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      images: images,
      sellerName: seller?['full_name'] as String?,
      sellerAvatarUrl: seller?['avatar_url'] as String?,
      sellerTrustScore: seller?['trust_score'] as int?,
      categoryName: (json['categories'] as Map<String, dynamic>?)?['name']
          as String?,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'seller_id': sellerId,
      if (categoryId != null) 'category_id': categoryId,
      'title': title,
      if (description != null) 'description': description,
      'price': price,
      'is_negotiable': isNegotiable,
      'condition': condition.value,
      'status': status.value,
      if (brand != null) 'brand': brand,
    };
  }
}

// ── Category ──────────────────────────────────────────────

class ProductCategory {
  final String id;
  final String name;
  final String? iconName;

  const ProductCategory({
    required this.id,
    required this.name,
    this.iconName,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      iconName: json['icon_name'] as String?,
    );
  }
}
