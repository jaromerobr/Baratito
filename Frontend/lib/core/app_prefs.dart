/// Flags de arranque persistentes (SharedPreferences), cargados una vez en
/// main() para poder leerlos de forma síncrona (p. ej. en el redirect del router).
library;

import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  static const _seenWelcomeKey = 'baratito_seen_welcome';

  /// True si el usuario ya vio la pantalla de bienvenida (solo se muestra 1 vez).
  static bool seenWelcome = false;

  /// Cargar los flags al iniciar la app (antes de runApp).
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    seenWelcome = prefs.getBool(_seenWelcomeKey) ?? false;
  }

  /// Marcar la bienvenida como vista (persistente).
  static Future<void> markWelcomeSeen() async {
    if (seenWelcome) return;
    seenWelcome = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenWelcomeKey, true);
  }
}
