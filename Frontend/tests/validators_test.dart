// Pruebas unitarias de la lógica de validación de TODOS los formularios.
//
// No levantan la app, no tocan internet ni la base de datos: los
// validadores son funciones puras (entrada → mensaje de error o null).
// Se ejecutan con:  flutter test test/validators_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:baratito/utils/validators.dart';

void main() {
  group('Correo electrónico (login, registro, recuperación)', () {
    test('acepta correos válidos', () {
      expect(Validators.email('eg.pd2005@gmail.com'), isNull);
      expect(Validators.email('james201romero@gmail.com'), isNull);
      expect(Validators.email('a.b-c@sub.dominio.ec'), isNull);
    });

    test('rechaza vacío con mensaje visible', () {
      expect(Validators.email(''), 'Ingresa tu correo electrónico');
      expect(Validators.email(null), 'Ingresa tu correo electrónico');
      expect(Validators.email('   '), 'Ingresa tu correo electrónico');
    });

    test('rechaza formatos inválidos', () {
      expect(Validators.email('correo'), 'Ingresa un correo válido');
      expect(Validators.email('correo@'), 'Ingresa un correo válido');
      expect(Validators.email('correo@dominio'), 'Ingresa un correo válido');
      expect(Validators.email('@dominio.com'), 'Ingresa un correo válido');
      expect(Validators.email('a b@dominio.com'), 'Ingresa un correo válido');
    });

    test('ignora espacios alrededor (trim)', () {
      expect(Validators.email('  eg.pd2005@gmail.com  '), isNull);
    });
  });

  group('Contraseña (mínimo 8 caracteres y 1 número)', () {
    test('acepta contraseñas que cumplen la política', () {
      expect(Validators.password('baratito1'), isNull);
      expect(Validators.password('12345678'), isNull);
    });

    test('rechaza vacía', () {
      expect(Validators.password(''), 'Ingresa tu contraseña');
      expect(Validators.password(null), 'Ingresa tu contraseña');
    });

    test('rechaza menos de 8 caracteres', () {
      expect(Validators.password('abc1234'), 'Debe tener al menos 8 caracteres');
    });

    test('rechaza sin números', () {
      expect(
          Validators.password('sinnumeros'), 'Debe incluir al menos un número');
    });
  });

  group('Confirmación de contraseña', () {
    test('acepta cuando coinciden', () {
      expect(Validators.confirmPassword('clave123', 'clave123'), isNull);
    });

    test('rechaza cuando no coinciden', () {
      expect(Validators.confirmPassword('clave123', 'otra456'),
          'Las contraseñas no coinciden');
      expect(Validators.confirmPassword('', 'clave123'),
          'Las contraseñas no coinciden');
    });
  });

  group('Nombre completo (registro y perfil)', () {
    test('acepta nombres válidos', () {
      expect(Validators.fullName('Eduardo Davila'), isNull);
      expect(Validators.fullName('Ana'), isNull);
    });

    test('rechaza vacío y muy corto', () {
      expect(Validators.fullName(''), 'Ingresa tu nombre completo');
      expect(Validators.fullName('  '), 'Ingresa tu nombre completo');
      expect(Validators.fullName('Ed'), 'El nombre es muy corto');
    });
  });

  group('Código OTP de 6 dígitos (confirmar correo y recuperación)', () {
    test('acepta exactamente 6 dígitos', () {
      expect(Validators.otpCode('123456'), isNull);
      expect(Validators.otpCode('000000'), isNull);
    });

    test('rechaza longitud incorrecta — el caso del fallo silencioso', () {
      expect(Validators.otpCode('123'), 'El código debe tener 6 dígitos');
      expect(Validators.otpCode(''), 'El código debe tener 6 dígitos');
      expect(Validators.otpCode('1234567'), 'El código debe tener 6 dígitos');
    });

    test('rechaza letras pegadas desde el portapapeles', () {
      expect(
          Validators.otpCode('abc123'), 'El código solo debe tener números');
      expect(
          Validators.otpCode('12345a'), 'El código solo debe tener números');
    });
  });

  group('Teléfono opcional (perfil)', () {
    test('vacío es válido (campo opcional)', () {
      expect(Validators.phoneOptional(''), isNull);
      expect(Validators.phoneOptional(null), isNull);
    });

    test('acepta formatos de Ecuador (7 a 10 dígitos)', () {
      expect(Validators.phoneOptional('0991234567'), isNull); // celular
      expect(Validators.phoneOptional('2570123'), isNull); // fijo Loja
    });

    test('rechaza letras y longitudes inválidas', () {
      expect(Validators.phoneOptional('abc099'), isNotNull);
      expect(Validators.phoneOptional('12345'), isNotNull); // muy corto
      expect(Validators.phoneOptional('09912345678'), isNotNull); // muy largo
      expect(Validators.phoneOptional('099-123-456'), isNotNull); // símbolos
    });
  });

  group('Nombre de usuario opcional (perfil)', () {
    test('vacío es válido (campo opcional)', () {
      expect(Validators.usernameOptional(''), isNull);
    });

    test('acepta el formato permitido', () {
      expect(Validators.usernameOptional('eduardo.pd'), isNull);
      expect(Validators.usernameOptional('james_01'), isNull);
    });

    test('rechaza mayúsculas, espacios, símbolos y longitudes inválidas', () {
      expect(Validators.usernameOptional('Eduardo'), isNotNull); // mayúscula
      expect(Validators.usernameOptional('juan perez'), isNotNull); // espacio
      expect(Validators.usernameOptional('ab'), isNotNull); // < 3
      expect(Validators.usernameOptional('a' * 21), isNotNull); // > 20
      expect(Validators.usernameOptional('juan!'), isNotNull); // símbolo
    });
  });
}
