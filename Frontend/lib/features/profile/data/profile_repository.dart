/// Profile repository — edit profile fields and upload the avatar.
library;

import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import '../../../core/supabase_client.dart';

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

  /// Public URL for an avatar path (or null).
  static String? avatarUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return SupabaseClientHelper.client.storage
        .from(_bucket)
        .getPublicUrl(path);
  }
}
