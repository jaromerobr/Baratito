// Prueba unitaria de la regla de negocio del envío.
// Sin app, sin red: función pura.
import 'package:flutter_test/flutter_test.dart';
import 'package:baratito/features/cart/domain/shipping_rules.dart';

void main() {
  group('Regla de envío (\$2 un vendedor / \$1 por vendedor si 2+)', () {
    test('un vendedor cuesta \$2.00', () {
      expect(shippingFeeForSellers(1), 2.0);
    });

    test('dos vendedores cuestan \$2.00 (\$1 × 2, Baratito consolida)', () {
      expect(shippingFeeForSellers(2), 2.0);
    });

    test('tres vendedores cuestan \$3.00', () {
      expect(shippingFeeForSellers(3), 3.0);
    });

    test('cinco vendedores cuestan \$5.00', () {
      expect(shippingFeeForSellers(5), 5.0);
    });

    test('carrito vacío o inválido no cobra envío', () {
      expect(shippingFeeForSellers(0), 0);
      expect(shippingFeeForSellers(-1), 0);
    });
  });
}
