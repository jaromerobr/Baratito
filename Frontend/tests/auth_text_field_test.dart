// Pruebas de widget del campo de formulario compartido (AuthTextField).
//
// Demuestran que los CONTROLES reales del formulario funcionan sin levantar
// la app ni conectarse a nada: se monta solo el campo dentro de un Form y
// se simula la escritura del usuario (incluido "pegar" texto inválido).
// Se ejecutan con:  flutter test test/auth_text_field_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baratito/utils/validators.dart';
import 'package:baratito/widgets/auth/auth_text_field.dart';

void main() {
  /// Monta el campo del código OTP tal como está configurado en la app
  /// (teclado numérico + digitsOnly + maxLength 6 + validator).
  Future<GlobalKey<FormState>> pumpOtpField(
    WidgetTester tester,
    TextEditingController controller,
  ) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: AuthTextField(
              controller: controller,
              label: 'Código de 6 dígitos',
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: Validators.otpCode,
            ),
          ),
        ),
      ),
    );
    return formKey;
  }

  testWidgets('el filtro rechaza letras aunque se peguen desde el portapapeles',
      (tester) async {
    final controller = TextEditingController();
    await pumpOtpField(tester, controller);

    // Simula pegar "abc123xyz" — el teclado numérico NO impediría esto;
    // el inputFormatter sí.
    await tester.enterText(find.byType(TextFormField), 'abc123xyz');
    expect(controller.text, '123');
  });

  testWidgets('el maxLength recorta a 6 dígitos reales', (tester) async {
    final controller = TextEditingController();
    await pumpOtpField(tester, controller);

    await tester.enterText(find.byType(TextFormField), '123456789');
    expect(controller.text, '123456');
  });

  testWidgets('al validar un código incompleto el error SE VE en pantalla',
      (tester) async {
    final controller = TextEditingController();
    final formKey = await pumpOtpField(tester, controller);

    await tester.enterText(find.byType(TextFormField), '123');
    formKey.currentState!.validate();
    await tester.pump();

    // Nada de fallos silenciosos: el mensaje aparece bajo el campo.
    expect(find.text('El código debe tener 6 dígitos'), findsOneWidget);
  });

  testWidgets('con un código válido no hay error y el form pasa',
      (tester) async {
    final controller = TextEditingController();
    final formKey = await pumpOtpField(tester, controller);

    await tester.enterText(find.byType(TextFormField), '482913');
    final valid = formKey.currentState!.validate();
    await tester.pump();

    expect(valid, isTrue);
    expect(find.text('El código debe tener 6 dígitos'), findsNothing);
  });
}
