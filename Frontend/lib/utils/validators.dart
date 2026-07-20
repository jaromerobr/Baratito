class Validators {
  Validators._();

  static final RegExp _emailRegex =
      RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu correo electrónico';
    if (!_emailRegex.hasMatch(v)) return 'Ingresa un correo válido';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Ingresa tu contraseña';
    if (v.length < 8) return 'Debe tener al menos 8 caracteres';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Debe incluir al menos un número';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value != original) return 'Las contraseñas no coinciden';
    return null;
  }

  static String? fullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu nombre completo';
    if (v.length < 3) return 'El nombre es muy corto';
    return null;
  }

  static String? otpCode(String? value) {
    final v = value?.trim() ?? '';
    if (v.length != 6) return 'El código debe tener 6 dígitos';
    if (!RegExp(r'^\d{6}$').hasMatch(v)) return 'El código solo debe tener números';
    return null;
  }

  /// Teléfono OPCIONAL: vacío es válido; si se escribe, solo dígitos
  /// (7 a 10, formato Ecuador: fijo o celular 09XXXXXXXX).
  static String? phoneOptional(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (!RegExp(r'^\d{7,10}$').hasMatch(v)) {
      return 'Solo números (7 a 10 dígitos, ej. 0991234567)';
    }
    return null;
  }

  /// Nombre de usuario OPCIONAL: vacío es válido; si se escribe,
  /// 3–20 caracteres con minúsculas, números, punto o guion bajo.
  static String? usernameOptional(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (!RegExp(r'^[a-z0-9._]{3,20}$').hasMatch(v)) {
      return '3–20 caracteres: minúsculas, números, punto o _';
    }
    return null;
  }
}
