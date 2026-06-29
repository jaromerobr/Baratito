/// Verification repository — uploads KYC docs to a PRIVATE bucket,
/// creates the `identity_verifications` request and pings the local
/// DeepFace service to process it.
library;

import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import '../../../core/supabase_client.dart';
import '../domain/verification_model.dart';

/// Base URL of the Python (FastAPI + DeepFace) service.
///
/// Default `10.0.2.2` is the host machine as seen from the Android emulator.
/// For a physical device pass your PC's LAN IP at run time:
///   flutter run --dart-define=VERIFY_SERVICE_URL=http://192.168.1.50:8000
const String kVerifyServiceUrl = String.fromEnvironment(
  'VERIFY_SERVICE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

class VerificationRepository {
  final _client = SupabaseClientHelper.client;
  static const _bucket = 'verification-docs';

  /// Latest verification request for the current user (or null).
  Future<IdentityVerification?> getMyLatest() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;

    final data = await _client
        .from('identity_verifications')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return data == null ? null : IdentityVerification.fromJson(data);
  }

  /// Upload the 3 photos, create the pending request and trigger processing.
  Future<String> submit({
    required Uint8List cedulaFront,
    required Uint8List cedulaBack,
    required Uint8List selfie,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Debes iniciar sesión.');

    final ts = DateTime.now().millisecondsSinceEpoch;
    final frontPath = '$uid/cedula_front_$ts.jpg';
    final backPath = '$uid/cedula_back_$ts.jpg';
    final selfiePath = '$uid/selfie_$ts.jpg';

    await _upload(frontPath, cedulaFront);
    await _upload(backPath, cedulaBack);
    await _upload(selfiePath, selfie);

    final row = await _client
        .from('identity_verifications')
        .insert({
          'user_id': uid,
          'cedula_front_path': frontPath,
          'cedula_back_path': backPath,
          'selfie_path': selfiePath,
          'status': 'pending',
        })
        .select('id')
        .single();

    final verificationId = row['id'] as String;

    // Best-effort: trigger the local DeepFace service. If it's off, the
    // request simply stays "pending" for manual admin review.
    await _triggerProcessing(verificationId);

    return verificationId;
  }

  Future<void> _upload(String path, Uint8List bytes) async {
    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
  }

  Future<void> _triggerProcessing(String verificationId) async {
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 90),
        ),
      );
      await dio.post(
        '$kVerifyServiceUrl/verify',
        data: {'verification_id': verificationId},
      );
    } catch (_) {
      // Servicio apagado/inaccesible en dev → queda pending. No es error fatal.
    }
  }
}
