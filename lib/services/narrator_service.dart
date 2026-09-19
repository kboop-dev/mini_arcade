import 'package:shared_preferences/shared_preferences.dart';

/// Controla si ya se le mostró al jugador la narración de instrucciones
/// de cada juego, para que Keyla solo explique la primera vez que se entra.
class NarratorService {
  static const _prefix = 'narrated_';

  Future<bool> hasSeen(String gameKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix$gameKey') ?? false;
  }

  Future<void> markSeen(String gameKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$gameKey', true);
  }

  /// Útil si Keyla (la dueña de la app) quiere volver a ver las narraciones,
  /// por ejemplo desde un botón de "Ver instrucciones de nuevo" en el perfil.
  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
