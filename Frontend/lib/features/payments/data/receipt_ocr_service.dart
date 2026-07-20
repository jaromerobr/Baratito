/// OCR del comprobante de transferencia (ML Kit, on-device y gratuito).
///
/// Lee el texto de la imagen y extrae:
///  - el monto transferido (busca el valor que coincida con el total
///    esperado; si ninguno coincide, devuelve el mayor encontrado), y
///  - un número de referencia/documento si aparece.
library;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ReceiptOcrResult {
  final double? amount;
  final String? reference;
  final String rawText;

  const ReceiptOcrResult({this.amount, this.reference, required this.rawText});
}

class ReceiptOcrService {
  /// Procesa la imagen del comprobante en [imagePath].
  /// [expectedTotal] ayuda a elegir el monto correcto entre varios números.
  static Future<ReceiptOcrResult> read(
    String imagePath, {
    required double expectedTotal,
  }) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final input = InputImage.fromFilePath(imagePath);
      final result = await recognizer.processImage(input);
      final text = result.text;

      return ReceiptOcrResult(
        amount: extractAmount(text, expectedTotal),
        reference: extractReference(text),
        rawText: text,
      );
    } finally {
      recognizer.close();
    }
  }

  // ── Monto ───────────────────────────────────────────────
  // Formato real Banco de Loja: "Monto transferido" y debajo "$2,00"
  // (coma decimal). También aparece "Costo de transacción: $0,00",
  // que NO es el monto (se descarta por ser 0 y por prioridad).
  @visibleForTesting
  static double? extractAmount(String text, double expected) {
    // 1º: el monto que sigue a la palabra "monto" (Banco de Loja).
    final montoMatch = RegExp(
      r'monto[^\d$]*\$?\s*(\d{1,3}(?:[.,]\d{3})*[.,]\d{2})',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(text);
    if (montoMatch != null) {
      final v = parseAmount(montoMatch.group(1)!);
      if (v != null && v > 0) return v;
    }

    // 2º: cualquier número con decimales del texto.
    final matches = RegExp(r'(\d{1,3}(?:[.,]\d{3})*[.,]\d{2})\b')
        .allMatches(text)
        .map((m) => parseAmount(m.group(1)!))
        .whereType<double>()
        .where((v) => v > 0 && v < 100000)
        .toList();
    if (matches.isEmpty) return null;

    // Prioridad: un valor que coincida con el total esperado (± 1 centavo).
    for (final v in matches) {
      if ((v - expected).abs() <= 0.01) return v;
    }
    // Último recurso: el mayor (suele ser el monto transferido).
    matches.sort();
    return matches.last;
  }

  @visibleForTesting
  static double? parseAmount(String raw) {
    var s = raw.trim();
    // "1.234,56" (formato latino) → "1234.56" · "1,234.56" → "1234.56"
    final lastComma = s.lastIndexOf(',');
    final lastDot = s.lastIndexOf('.');
    if (lastComma > lastDot) {
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else {
      s = s.replaceAll(',', '');
    }
    return double.tryParse(s);
  }

  // ── Referencia / número de documento ────────────────────
  @visibleForTesting
  static String? extractReference(String text) {
    final m = RegExp(
      r'(?:referencia|ref\.?|documento|comprobante|transacci[oó]n|nro\.?|no\.?)\s*[:#]?\s*(\d{4,})',
      caseSensitive: false,
    ).firstMatch(text);
    return m?.group(1);
  }
}
