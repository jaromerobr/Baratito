// Pruebas unitarias del parser de comprobantes (la parte pura del OCR).
// Usa el TEXTO REAL de un comprobante del Banco de Loja — sin cámara,
// sin ML Kit, sin red.
import 'package:flutter_test/flutter_test.dart';
import 'package:baratito/features/payments/data/receipt_ocr_service.dart';

/// Texto tal como lo lee el OCR de un comprobante real del Banco de Loja.
const comprobanteBancoLoja = '''
¡Envío exitoso!
02/07/2026
Monto transferido
\$2,00
Desde
PARDO DAVILA, EDUARDO GABRIEL
CUENTA DE AHORROS CUENTA ACTIVA
N°. 29XXXXX802
Para
AYORA DELGADO, JOSEPH MICHAEL
BANCO DE LOJA
Cta. Ahorro N°. 29XXXXX001
C.I. 11XXXXX488
Costo de transacción: \$0,00
Nro. comprobante: 119925090
''';

void main() {
  group('Extracción del monto', () {
    test('lee el monto transferido del comprobante real (\$2,00)', () {
      expect(ReceiptOcrService.extractAmount(comprobanteBancoLoja, 2.00), 2.00);
    });

    test('ignora el "Costo de transacción: \$0,00" (la trampa del formato)',
        () {
      // Aunque el total esperado no coincida, debe devolver 2.00 y nunca 0.00.
      expect(
          ReceiptOcrService.extractAmount(comprobanteBancoLoja, 15.50), 2.00);
    });

    test('entiende coma decimal (formato Ecuador) y punto de miles', () {
      expect(ReceiptOcrService.parseAmount('2,00'), 2.00);
      expect(ReceiptOcrService.parseAmount('1.234,56'), 1234.56);
      expect(ReceiptOcrService.parseAmount('1,234.56'), 1234.56);
      expect(ReceiptOcrService.parseAmount('427.00'), 427.00);
    });

    test('sin montos en el texto devuelve null (→ revisión manual)', () {
      expect(ReceiptOcrService.extractAmount('sin números aquí', 10), isNull);
    });

    test('con varios montos prefiere el que coincide con el total esperado',
        () {
      const texto = 'Saldo: \$500,00\nMonto transferido \$47,00\nIVA \$5,64';
      expect(ReceiptOcrService.extractAmount(texto, 47.00), 47.00);
    });
  });

  group('Extracción de la referencia', () {
    test('lee el Nro. de comprobante del Banco de Loja', () {
      expect(ReceiptOcrService.extractReference(comprobanteBancoLoja),
          '119925090');
    });

    test('reconoce otras variantes de etiqueta', () {
      expect(ReceiptOcrService.extractReference('Referencia: 445566'),
          '445566');
      expect(ReceiptOcrService.extractReference('documento # 78901'), '78901');
    });

    test('sin referencia devuelve null', () {
      expect(ReceiptOcrService.extractReference('texto sin nada'), isNull);
    });
  });
}
