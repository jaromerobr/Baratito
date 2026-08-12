/// Tests for [PublishPermission.canPublish] — the rule the publish FAB uses
/// to decide whether to open the form or send the user to /verify.
library;

import 'package:baratito/features/verification/domain/publish_permission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PublishPermission.canPublish — vendedor normal', () {
    test('identidad verificada puede publicar', () {
      expect(
        PublishPermission.canPublish(
          gate: VerifyGate.verified,
          isAdmin: false,
        ),
        isTrue,
      );
    });

    test('ningún estado distinto de verified permite publicar', () {
      const denied = [
        VerifyGate.loading,
        VerifyGate.notLoggedIn,
        VerifyGate.notSubmitted,
        VerifyGate.pending,
        VerifyGate.rejected,
      ];

      for (final gate in denied) {
        expect(
          PublishPermission.canPublish(gate: gate, isAdmin: false),
          isFalse,
          reason: 'el estado $gate no debe permitir publicar',
        );
      }
    });
  });

  group('PublishPermission.canPublish — administrador', () {
    test('admin sin verificación de identidad puede publicar', () {
      // Excepción real del proyecto: los admins están exentos del KYC.
      expect(
        PublishPermission.canPublish(
          gate: VerifyGate.notSubmitted,
          isAdmin: true,
        ),
        isTrue,
      );
    });

    test('admin sin sesión NO puede publicar', () {
      // Sin sesión no hay seller_id que asociar al producto (RN-5).
      expect(
        PublishPermission.canPublish(
          gate: VerifyGate.notLoggedIn,
          isAdmin: true,
        ),
        isFalse,
      );
    });
  });
}
