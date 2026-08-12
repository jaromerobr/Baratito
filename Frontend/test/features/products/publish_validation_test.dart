/// Tests for [PublishValidation] — the data a listing must carry before it
/// can be sent to `ProductRepository.createProduct`.
library;

import 'package:baratito/features/products/domain/publish_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PublishValidation.title', () {
    test('acepta un título con al menos 5 caracteres', () {
      expect(PublishValidation.title('iPhone 13 Pro 128GB'), isNull);
    });

    test('rechaza un título demasiado corto', () {
      expect(PublishValidation.title('TV'), 'Mínimo 5 caracteres');
    });

    test('rechaza un título nulo o vacío', () {
      expect(PublishValidation.title(null), 'Mínimo 5 caracteres');
      expect(PublishValidation.title(''), 'Mínimo 5 caracteres');
    });

    test('rechaza un título que solo son espacios', () {
      // Se valida sobre el texto recortado: "      " no es un título.
      expect(PublishValidation.title('        '), 'Mínimo 5 caracteres');
    });
  });

  group('PublishValidation.price', () {
    test('acepta un precio con punto decimal', () {
      expect(PublishValidation.price('380.00'), isNull);
    });

    test('acepta un precio con coma decimal', () {
      expect(PublishValidation.price('380,50'), isNull);
    });

    test('rechaza un precio no numérico', () {
      expect(PublishValidation.price('gratis'), 'Ingresa un precio válido');
    });

    test('rechaza un precio vacío', () {
      expect(PublishValidation.price(''), 'Ingresa un precio válido');
      expect(PublishValidation.price(null), 'Ingresa un precio válido');
    });

    test('rechaza un precio negativo', () {
      expect(PublishValidation.price('-10'), 'Ingresa un precio válido');
    });

    test('DOCUMENTA el comportamiento actual: acepta precio 0', () {
      // La implementación actual solo rechaza precios negativos, así que un
      // artículo puede publicarse en $0.00. No se cambia aquí: definir si
      // Baratito admite regalos o exige precio > 0 es decisión del equipo.
      expect(PublishValidation.price('0'), isNull);
    });
  });

  group('PublishValidation.hasEnoughPhotos', () {
    test('rechaza una publicación sin fotos', () {
      expect(PublishValidation.hasEnoughPhotos(0), isFalse);
    });

    test('acepta una publicación con al menos una foto', () {
      expect(PublishValidation.hasEnoughPhotos(1), isTrue);
      expect(PublishValidation.hasEnoughPhotos(6), isTrue);
    });
  });
}
