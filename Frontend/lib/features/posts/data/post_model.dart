/// Post model — mirrors JSONPlaceholder `/posts` schema.
///
/// Used for the Dio + FutureBuilder demo screen.
class Post {
  final int? id;
  final int? userId;
  final String title;
  final String body;

  const Post({
    this.id,
    this.userId,
    required this.title,
    required this.body,
  });

  /// Create a [Post] from a JSON map.
  /// Dio decodes JSON automatically, so we receive `Map<String, dynamic>`.
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int?,
      userId: json['userId'] as int?,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  /// Convert this [Post] to a JSON map for POST/PUT requests.
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'userId': userId,
      'title': title,
      'body': body,
    };
  }
}
