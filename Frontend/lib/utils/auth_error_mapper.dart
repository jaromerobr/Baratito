import 'package:supabase_flutter/supabase_flutter.dart';

String mapAuthError(AuthException e) {
  final msg = e.message.toLowerCase();

  if (msg.contains('invalid login credentials')) {
    return 'Correo o contraseña incorrectos';
  }
  if (msg.contains('user already registered')) {
    return 'Ya existe una cuenta registrada con este correo';
  }
  if (msg.contains('email not confirmed')) {
    return 'Debes confirmar tu correo antes de iniciar sesión';
  }
  if (msg.contains('token has expired') || msg.contains('invalid token') ||
      msg.contains('otp_expired')) {
    return 'El código ingresado no es válido o ya expiró';
  }
  if (msg.contains('password should be at least')) {
    return 'La contraseña es demasiado corta';
  }
  if (msg.contains('rate limit') || msg.contains('over_email_send_rate_limit')) {
    return 'Demasiados intentos. Espera unos minutos e intenta de nuevo';
  }
  return 'Ocurrió un error. Intenta de nuevo';
}
