/// Domain model for `public.categories`.
library;

class Category {
  final String id;
  final String? parentId;
  final String name;
  final String slug;
  final String? iconPath;
  final int sortOrder;

  const Category({
    required this.id,
    this.parentId,
    required this.name,
    required this.slug,
    this.iconPath,
    this.sortOrder = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      parentId: json['parent_id'] as String?,
      name: json['name'] as String,
      slug: json['slug'] as String,
      iconPath: json['icon_path'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
