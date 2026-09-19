import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Controla la música de fondo en la app.
class MusicService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  bool _muted = false;
  bool _started = false;

  bool get isMuted => _muted;

  static const String trackFile = 'bg_music.mp3';
  static const double _defaultVolume = 0.45;

  /// Intenta arrancar la música. Los navegadores (Chrome, Safari) bloquean
  /// el autoplay con sonido hasta que el usuario interactúa con la página
  /// al menos una vez — por eso este primer intento puede fallar
  /// silenciosamente, y por eso existe [resumeIfBlocked] más abajo.
  Future<void> start() async {
    if (_started) return;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(_muted ? 0 : _defaultVolume);
      await _player.play(AssetSource(trackFile));
      _started = true;
    } catch (_) {
      // No pasa nada: se reintenta en el primer toque del usuario.
    }
  }

  /// Llamar en el primer toque/tap que el jugador haga en la app
  Future<void> resumeIfBlocked() async {
    if (!_started) {
      await start();
      return;
    }
    if (!_muted && _player.state != PlayerState.playing) {
      await _player.resume();
    }
  }

  Future<void> toggleMute() async {
    _muted = !_muted;
    await _player.setVolume(_muted ? 0 : _defaultVolume);
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
