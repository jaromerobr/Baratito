/// Profile repository — edit profile fields and upload the avatar.
library;

import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import '../../../core/supabase_client.dart';

/// Perfil público de un usuario (para verlo desde un producto).
class PublicProfile {
  final String id;
  final String fullName;
  final String? username;
  final String? avatarPath;
  final String? bio;
  final double ratingAvg;
  final int ratingCount;

  const PublicProfile({
    required this.id,
    required this.fullName,
    required this.username,
    required this.avatarPath,
    required this.bio,
    required this.ratingAvg,
    required this.ratingCount,
  });

  String? get avatarUrl => ProfileRepository.avatarUrl(avatarPath);

  factory PublicProfile.fromJson(Map<String, dynamic> json) {
    return PublicProfile(
      id: json['id'] as String,
      fullName: (json['full_name'] as String?) ?? 'Usuario',
      username: json['username'] as String?,
      avatarPath: json['avatar_path'] as String?,
      bio: json['bio'] as String?,
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProfileRepository {
  final _client = SupabaseClientHelper.client;
  static const _bucket = 'avatars';

  /// Update editable profile fields. Null values clear optional fields.
  Future<void> updateProfile({
    required String fullName,
    String? username,
    String? phone,
    String? bio,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Sin sesión.');

    await _client.from('profiles').update({
      'full_name': fullName.trim(),
      'username': (username == null || username.trim().isEmpty)
          ? null
          : username.trim(),
      'phone':
          (phone == null || phone.trim().isEmpty) ? null : phone.trim(),
      'bio': (bio == null || bio.trim().isEmpty) ? null : bio.trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', uid);
  }

  /// Upload a new avatar and store its path in the profile.
  Future<String> uploadAvatar(Uint8List bytes, {String ext = 'jpg'}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Sin sesión.');

    final path = '$uid/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
            upsert: true,
          ),
        );
    await _client.from('profiles').update({'avatar_path': path}).eq('id', uid);
    return path;
  }

  /// Perfil público de cualquier usuario por id.
  Future<PublicProfile?> getPublicProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select('id, full_name, username, avatar_path, bio, rating_avg, rating_count')
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return PublicProfile.fromJson(data);
  }

  /// Public URL for an avatar path (or null).
  static String? avatarUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return SupabaseClientHelper.client.storage
        .from(_bucket)
        .getPublicUrl(path);
  }
}
