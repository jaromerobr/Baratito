/// UserProfile model matching the `public.users` table in Supabase.
class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final String? username;
  final String? phone;
  final String? avatarUrl;
  final UserRole role;
  final bool isActive;
  final bool isVerified;
  final DateTime? emailVerifiedAt;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.username,
    this.phone,
    this.avatarUrl,
    this.role = UserRole.buyer,
    this.isActive = true,
    this.isVerified = false,
    this.emailVerifiedAt,
    required this.createdAt,
  });

  /// Create a [UserProfile] from a Supabase JSON row.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      username: json['username'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: UserRole.fromString(json['role'] as String? ?? 'buyer'),
      isActive: json['is_active'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to a JSON map for Supabase updates.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'username': username,
      'phone': phone,
      'avatar_url': avatarUrl,
      'role': role.value,
      'is_active': isActive,
      'is_verified': isVerified,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields.
  UserProfile copyWith({
    String? fullName,
    String? username,
    String? phone,
    String? avatarUrl,
    UserRole? role,
    bool? isActive,
    bool? isVerified,
    DateTime? emailVerifiedAt,
  }) {
    return UserProfile(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      createdAt: createdAt,
    );
  }
}

/// Enum matching the `user_role` PostgreSQL enum.
enum UserRole {
  buyer('buyer'),
  seller('seller'),
  both('both');

  final String value;
  const UserRole(this.value);

  /// Parse a string value into a [UserRole].
  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserRole.buyer,
    );
  }

  /// Human-readable label in Spanish for the UI.
  String get label {
    switch (this) {
      case UserRole.buyer:
        return 'Quiero comprar';
      case UserRole.seller:
        return 'Quiero vender';
      case UserRole.both:
        return 'Ambos';
    }
  }
}
