/// UserProfile model matching the `public.profiles` table in Supabase.
class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final String? username;
  final String? phone;
  final String? avatarPath;
  final String? bio;
  final UserRole role;
  final bool isActive;
  final bool isVerified;
  final int trustScore;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.username,
    this.phone,
    this.avatarPath,
    this.bio,
    this.role = UserRole.both,
    this.isActive = true,
    this.isVerified = false,
    this.trustScore = 50,
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
      avatarPath: json['avatar_path'] as String?,
      bio: json['bio'] as String?,
      role: UserRole.fromString(json['role'] as String? ?? 'both'),
      isActive: json['is_active'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
      trustScore: (json['trust_score'] as num?)?.toInt() ?? 50,
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
      'avatar_path': avatarPath,
      'bio': bio,
      'role': role.value,
      'is_active': isActive,
      'is_verified': isVerified,
      'trust_score': trustScore,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields.
  UserProfile copyWith({
    String? fullName,
    String? username,
    String? phone,
    String? avatarPath,
    String? bio,
    UserRole? role,
    bool? isActive,
    bool? isVerified,
    int? trustScore,
  }) {
    return UserProfile(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      avatarPath: avatarPath ?? this.avatarPath,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      trustScore: trustScore ?? this.trustScore,
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
