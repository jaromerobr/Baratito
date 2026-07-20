// Pruebas unitarias de los modelos de dominio (parseo de datos del backend).
// Sin app, sin red: JSON de entrada → objeto Dart verificable.
import 'package:flutter_test/flutter_test.dart';
import 'package:baratito/features/verification/domain/verification_model.dart';
import 'package:baratito/features/products/domain/product_model.dart';
import 'package:baratito/features/chat/domain/chat_models.dart';
import 'package:baratito/features/admin/domain/admin_overview.dart';

void main() {
  group('VerifyStatus (estados de la verificación de identidad)', () {
    test('mapea los estados del backend', () {
      expect(VerifyStatus.fromString('pending'), VerifyStatus.pending);
      expect(VerifyStatus.fromString('approved'), VerifyStatus.approved);
      expect(VerifyStatus.fromString('rejected'), VerifyStatus.rejected);
    });

    test('tolera valores desconocidos o nulos sin romper', () {
      expect(VerifyStatus.fromString('otra_cosa'), VerifyStatus.unknown);
      expect(VerifyStatus.fromString(null), VerifyStatus.unknown);
    });
  });

  group('ProductCondition (estado del producto)', () {
    test('traduce los valores del enum de la BD al español', () {
      expect(ProductCondition.label('new'), 'Nuevo');
      expect(ProductCondition.label('like_new'), 'Como nuevo');
      expect(ProductCondition.label('good'), 'Buen estado');
      expect(ProductCondition.label('used'), 'Usado');
    });

    test('el filtro de la UI mapea al valor crudo correcto', () {
      expect(ProductCondition.rawCandidates('Nuevo'), ['new']);
      expect(ProductCondition.rawCandidates('Como nuevo'), ['like_new']);
      expect(ProductCondition.rawValue('Buen estado'), 'good');
      expect(ProductCondition.rawCandidates('Todos'), isEmpty);
    });
  });

  group('Message.fromJson (chat)', () {
    test('parsea un mensaje del backend', () {
      final m = Message.fromJson({
        'id': 'm1',
        'conversation_id': 'c1',
        'sender_id': 'u1',
        'content': 'Hola, ¿sigue disponible?',
        'is_read': false,
        'sent_at': '2026-07-09T00:03:11+00:00',
      });
      expect(m.content, 'Hola, ¿sigue disponible?');
      expect(m.isRead, isFalse);
      expect(m.sentAt.year, 2026);
    });

    test('tolera campos faltantes con valores por defecto', () {
      final m = Message.fromJson({
        'id': 'm2',
        'conversation_id': 'c1',
        'sender_id': 'u1',
        'content': null,
        'sent_at': '2026-07-09T00:00:00Z',
      });
      expect(m.content, '');
      expect(m.isRead, isFalse);
    });
  });

  group('AdminOverview.fromJson (métricas del panel)', () {
    test('parsea el jsonb del RPC admin_overview', () {
      final o = AdminOverview.fromJson({
        'users_total': 10,
        'users_verified': 4,
        'products_active': 7,
        'by_category': [
          {'name': 'Electrónica', 'total': 5},
          {'name': 'Ropa', 'total': 2},
        ],
        'top_sellers': [],
      });
      expect(o.usersTotal, 10);
      expect(o.verifiedRate, 40.0); // 4 de 10 verificados
      expect(o.byCategory.first.name, 'Electrónica');
      expect(o.topSellers, isEmpty);
    });

    test('con base vacía no divide por cero', () {
      final o = AdminOverview.fromJson({});
      expect(o.verifiedRate, 0);
      expect(o.usersTotal, 0);
    });
  });
}
