/// Tests for [verifyGateProvider] — the single place where Baratito decides
/// whether a seller's identity is good enough to publish.
///
/// Business rule under test (RN-1): "un vendedor debe tener su identidad
/// verificada y aprobada antes de poder publicar un artículo".
///
/// No Supabase involved: both upstream providers are overridden, so the
/// repositories are never constructed.
library;

import 'dart:async';

import 'package:baratito/features/auth/domain/user_model.dart';
import 'package:baratito/features/auth/presentation/providers/auth_provider.dart';
import 'package:baratito/features/verification/domain/verification_model.dart';
import 'package:baratito/features/verification/presentation/providers/verification_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Fixtures ────────────────────────────────────────────
UserProfile _profile({required bool isVerified}) => UserProfile(
      id: 'seller-1',
      email: 'vendedor@baratito.ec',
      isVerified: isVerified,
      createdAt: DateTime.utc(2026, 1, 1),
    );

IdentityVerification _request(VerifyStatus status) => IdentityVerification(
      id: 'verif-1',
      userId: 'seller-1',
      status: status,
      createdAt: DateTime.utc(2026, 1, 1),
    );

// ── Overrides ───────────────────────────────────────────
Override _profileIs(UserProfile? value) =>
    currentUserProfileProvider.overrideWith((ref) => value);

Override _profileLoading() => currentUserProfileProvider
    .overrideWith((ref) => Completer<UserProfile?>().future);

Override _profileFails() => currentUserProfileProvider
    .overrideWith((ref) => throw Exception('perfil no disponible'));

Override _verificationIs(IdentityVerification? value) =>
    myVerificationProvider.overrideWith((ref) => value);

Override _verificationLoading() => myVerificationProvider
    .overrideWith((ref) => Completer<IdentityVerification?>().future);

VerifyGate _gateWith({required Override profile, required Override verification}) {
  final container = ProviderContainer(overrides: [profile, verification]);
  addTearDown(container.dispose);
  return container.read(verifyGateProvider);
}

void main() {
  group('verifyGateProvider — identidad aprobada', () {
    test('perfil con is_verified = true habilita la publicación', () {
      final gate = _gateWith(
        profile: _profileIs(_profile(isVerified: true)),
        verification: _verificationIs(null),
      );

      expect(gate, VerifyGate.verified);
    });

    test(
        'perfil aún sin el flag pero con solicitud aprobada habilita la '
        'publicación', () {
      // El trigger SQL que pone profiles.is_verified = true puede no haberse
      // reflejado todavía en el perfil cacheado; la solicitud aprobada manda.
      final gate = _gateWith(
        profile: _profileIs(_profile(isVerified: false)),
        verification: _verificationIs(_request(VerifyStatus.approved)),
      );

      expect(gate, VerifyGate.verified);
    });
  });

  group('verifyGateProvider — identidad NO aprobada', () {
    test('solicitud en revisión NO habilita la publicación', () {
      final gate = _gateWith(
        profile: _profileIs(_profile(isVerified: false)),
        verification: _verificationIs(_request(VerifyStatus.pending)),
      );

      expect(gate, VerifyGate.pending);
      expect(gate, isNot(VerifyGate.verified));
    });

    test('solicitud rechazada NO habilita la publicación', () {
      final gate = _gateWith(
        profile: _profileIs(_profile(isVerified: false)),
        verification: _verificationIs(_request(VerifyStatus.rejected)),
      );

      expect(gate, VerifyGate.rejected);
    });

    test('usuario sin solicitud de verificación NO habilita la publicación',
        () {
      final gate = _gateWith(
        profile: _profileIs(_profile(isVerified: false)),
        verification: _verificationIs(null),
      );

      expect(gate, VerifyGate.notSubmitted);
    });

    test('estado desconocido se trata como pendiente (fail-closed)', () {
      // VerifyStatus.unknown aparece cuando la BD devuelve un estado que la app
      // no conoce. Denegar es deliberado: nunca se publica ante la duda.
      final gate = _gateWith(
        profile: _profileIs(_profile(isVerified: false)),
        verification: _verificationIs(_request(VerifyStatus.unknown)),
      );

      expect(gate, VerifyGate.pending);
    });
  });

  group('verifyGateProvider — sesión y estados no concluyentes', () {
    test('usuario sin sesión NO habilita la publicación', () {
      final gate = _gateWith(
        profile: _profileIs(null),
        verification: _verificationIs(null),
      );

      expect(gate, VerifyGate.notLoggedIn);
    });

    test('perfil cargando devuelve loading, nunca verified', () {
      final gate = _gateWith(
        profile: _profileLoading(),
        verification: _verificationIs(null),
      );

      expect(gate, VerifyGate.loading);
    });

    test('verificación aún cargando devuelve loading, nunca verified', () {
      final gate = _gateWith(
        profile: _profileIs(_profile(isVerified: false)),
        verification: _verificationLoading(),
      );

      expect(gate, VerifyGate.loading);
    });

    test('error al cargar el perfil deniega la publicación', () {
      // Comportamiento actual: el error se reporta como notSubmitted.
      // Deniega correctamente, aunque el mensaje al usuario sea impreciso.
      final gate = _gateWith(
        profile: _profileFails(),
        verification: _verificationIs(null),
      );

      expect(gate, isNot(VerifyGate.verified));
      expect(gate, VerifyGate.notSubmitted);
    });
  });
}
