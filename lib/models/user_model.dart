import 'avatar_config.dart';

class AppUser {
  final String uid;
  final String username;
  final String email;
  final int xp;
  final DateTime createdAt;
  final AvatarConfig avatar;

  // IDs de rompecabezas oficiales completados en modo supervivencia (1-10)
  final List<String> puzzlesCompletedSurvival;

  // IDs de tickets ya desbloqueados y si ya fueron canjeados
  final Map<String, bool> ticketsUnlocked; // ticketId -> canjeado?

  AppUser({
    required this.uid,
    required this.username,
    required this.email,
    this.xp = 0,
    required this.createdAt,
    this.avatar = const AvatarConfig(),
    this.puzzlesCompletedSurvival = const [],
    this.ticketsUnlocked = const {},
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      username: map['username'] ?? 'Jugador',
      email: map['email'] ?? '',
      xp: (map['xp'] ?? 0) as int,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      avatar: AvatarConfig.fromMap(
          map['avatar'] != null ? Map<String, dynamic>.from(map['avatar']) : null),
      puzzlesCompletedSurvival:
          List<String>.from(map['puzzlesCompletedSurvival'] ?? []),
      ticketsUnlocked: Map<String, bool>.from(map['ticketsUnlocked'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'xp': xp,
      'createdAt': createdAt.toIso8601String(),
      'avatar': avatar.toMap(),
      'puzzlesCompletedSurvival': puzzlesCompletedSurvival,
      'ticketsUnlocked': ticketsUnlocked,
    };
  }
}

/// Rango de jugador según XP acumulado.
enum PlayerRank {
  recluta('Novio Recluta', 0),
  elite('Novio Élite', 4000),
  maestro('Novio Maestro', 10000),
  mitico('Novio Mítico / Leyenda', 20000);

  final String label;
  final int minXp;
  const PlayerRank(this.label, this.minXp);

  static PlayerRank fromXp(int xp) {
    if (xp >= mitico.minXp) return mitico;
    if (xp >= maestro.minXp) return maestro;
    if (xp >= elite.minXp) return elite;
    return recluta;
  }

  /// Siguiente rango (null si ya es el máximo)
  PlayerRank? get next {
    final values = PlayerRank.values;
    final i = values.indexOf(this);
    return i + 1 < values.length ? values[i + 1] : null;
  }
}
