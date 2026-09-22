import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/narrator_overlay.dart';
import '../../../widgets/fit_appbar_title.dart';

/// ZONA DE COMBATE — Galería de tiro pixel art estilo battle royale.
/// Van apareciendo objetivos por toda la pantalla y hay que tocarlos antes
/// de que desaparezcan. Algunos suman puntos/tiempo, otros restan vida.
/// Encadenar aciertos sube un multiplicador de combo (x1 a x5) para que se
/// sienta adictivo, como los juegos de puntería/reflejos que le gustan.

enum BtDifficulty { facil, medio, dificil }

extension on BtDifficulty {
  String get label => switch (this) {
        BtDifficulty.facil => 'Fácil',
        BtDifficulty.medio => 'Medio',
        BtDifficulty.dificil => 'Difícil',
      };

  // Cada cuánto aparece un objetivo nuevo
  Duration get spawnInterval => switch (this) {
        BtDifficulty.facil => const Duration(milliseconds: 950),
        BtDifficulty.medio => const Duration(milliseconds: 700),
        BtDifficulty.dificil => const Duration(milliseconds: 500),
      };

  // Cuánto dura un objetivo en pantalla antes de desaparecer solo
  Duration get targetLifespan => switch (this) {
        BtDifficulty.facil => const Duration(milliseconds: 1500),
        BtDifficulty.medio => const Duration(milliseconds: 1150),
        BtDifficulty.dificil => const Duration(milliseconds: 850),
      };

  // Probabilidad de que lo que aparezca sea una trampa (aliado/granada)
  double get trapChance => switch (this) {
        BtDifficulty.facil => 0.12,
        BtDifficulty.medio => 0.20,
        BtDifficulty.dificil => 0.28,
      };
}

enum TargetKind { casco, drop, aliado, granada }

class _ActiveTarget {
  final String id;
  final TargetKind kind;
  final double leftFrac; // posición relativa 0..1 dentro del área de juego
  final double topFrac;
  _ActiveTarget({
    required this.id,
    required this.kind,
    required this.leftFrac,
    required this.topFrac,
  });
}

class _FloatingText {
  final String id;
  final String text;
  final Color color;
  final double leftFrac;
  final double topFrac;
  _FloatingText({
    required this.id,
    required this.text,
    required this.color,
    required this.leftFrac,
    required this.topFrac,
  });
}

const int kGameSeconds = 30;
const int kMaxHearts = 3;
const int kTicketScoreThreshold =
    400; // puntaje mínimo en difícil para el ticket

class BattleTargetScreen extends StatefulWidget {
  const BattleTargetScreen({super.key});
  @override
  State<BattleTargetScreen> createState() => _BattleTargetScreenState();
}

class _BattleTargetScreenState extends State<BattleTargetScreen> {
  BtDifficulty? _difficulty;
  final Random _rnd = Random();

  Timer? _spawnTimer;
  Timer? _countdownTimer;
  late ConfettiController _confetti;

  final List<_ActiveTarget> _targets = [];
  final List<_FloatingText> _floatingTexts = [];

  int _score = 0;
  int _combo = 1; // multiplicador actual (x1 a x5)
  int _hearts = kMaxHearts;
  int _secondsLeft = kGameSeconds;
  bool _finished = false;
  bool _survived = false; // true si el tiempo se acabó sin perder los corazones
  bool _flashRed = false; // parpadeo rápido al recibir daño

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showNarratorIfNeeded(
        context,
        gameKey: 'battle_target',
        lines: [
          '¡Bienvenido a la Zona de Combate! 🎯 Van a aparecer objetivos por toda la pantalla, tienes que tocarlos lo más rápido que puedas antes de que desaparezcan.',
          'Los cascos 🪖 te dan puntos. Los regalos 🎁 dan puntos dobles y tiempo extra, ¡pero cuidado! Si tocas a un aliado 🙂 o una granada 💣 pierdes un corazón.',
          'Encadena aciertos seguidos para subir tu combo (hasta x5) y ganar más puntos por objetivo. Tienes ${kGameSeconds}s y $kMaxHearts corazones.',
          'Si terminas la partida en dificultad DIFÍCIL con $kTicketScoreThreshold puntos o más, te llevas +450 XP y un ticket sorpresa 🎟️. En fácil y medio solo ganas XP de práctica, ¡yo sé que tu puedes, ánimoo',
        ],
      );
    });
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _countdownTimer?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  void _start(BtDifficulty d) {
    setState(() {
      _difficulty = d;
      _targets.clear();
      _floatingTexts.clear();
      _score = 0;
      _combo = 1;
      _hearts = kMaxHearts;
      _secondsLeft = kGameSeconds;
      _finished = false;
      _survived = false;
    });

    _spawnTimer = Timer.periodic(d.spawnInterval, (_) => _spawnTarget());
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        _endGame(survived: true);
      }
    });
  }

  void _spawnTarget() {
    if (_finished || !mounted) return;
    final d = _difficulty!;
    final isTrap = _rnd.nextDouble() < d.trapChance;
    TargetKind kind;
    if (isTrap) {
      kind = _rnd.nextBool() ? TargetKind.aliado : TargetKind.granada;
    } else {
      // 1 de cada ~6 objetivos "buenos" es un drop de suministros (power-up)
      kind = _rnd.nextInt(6) == 0 ? TargetKind.drop : TargetKind.casco;
    }

    final id = '${DateTime.now().microsecondsSinceEpoch}_${_rnd.nextInt(9999)}';
    final target = _ActiveTarget(
      id: id,
      kind: kind,
      leftFrac: 0.05 + _rnd.nextDouble() * 0.82,
      topFrac: 0.05 + _rnd.nextDouble() * 0.82,
    );

    setState(() => _targets.add(target));

    Future.delayed(d.targetLifespan, () {
      if (!mounted) return;
      final stillThere = _targets.any((t) => t.id == id);
      if (stillThere) {
        setState(() {
          _targets.removeWhere((t) => t.id == id);
          // Dejar pasar un objetivo bueno reinicia el combo (presión extra);
          // dejar pasar una trampa no tiene castigo.
          if (kind == TargetKind.casco || kind == TargetKind.drop) {
            _combo = 1;
          }
        });
      }
    });
  }

  void _addFloatingText(
      String text, Color color, double leftFrac, double topFrac) {
    final id = '${DateTime.now().microsecondsSinceEpoch}_${_rnd.nextInt(9999)}';
    setState(() => _floatingTexts.add(_FloatingText(
        id: id,
        text: text,
        color: color,
        leftFrac: leftFrac,
        topFrac: topFrac)));
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _floatingTexts.removeWhere((f) => f.id == id));
    });
  }

  void _onTapTarget(_ActiveTarget target) {
    if (_finished) return;
    setState(() => _targets.removeWhere((t) => t.id == target.id));

    switch (target.kind) {
      case TargetKind.casco:
        final points = 10 * _combo;
        _score += points;
        _addFloatingText(
            '+$points', AppColors.gold, target.leftFrac, target.topFrac);
        setState(() => _combo = min(_combo + 1, 5));
        break;
      case TargetKind.drop:
        const points = 30;
        _score += points;
        _secondsLeft = min(_secondsLeft + 3, kGameSeconds + 15);
        _addFloatingText(
            '+$points  +3s', AppColors.cyan, target.leftFrac, target.topFrac);
        setState(() => _combo = min(_combo + 1, 5));
        break;
      case TargetKind.aliado:
      case TargetKind.granada:
        _score = max(0, _score - 20);
        _hearts = max(0, _hearts - 1);
        _combo = 1;
        _addFloatingText(
            '-20', AppColors.heartRed, target.leftFrac, target.topFrac);
        _flashDamage();
        if (_hearts <= 0) {
          _endGame(survived: false);
        }
        break;
    }
    setState(() {});
  }

  void _flashDamage() {
    setState(() => _flashRed = true);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _flashRed = false);
    });
  }

  Future<void> _endGame({required bool survived}) async {
    _spawnTimer?.cancel();
    _countdownTimer?.cancel();
    setState(() {
      _finished = true;
      _survived = survived;
      _targets.clear();
    });

    final auth = context.read<AuthService>();
    final db = context.read<FirestoreService>();
    final uid = auth.currentUser!.uid;

    // XP de práctica según dificultad, solo si terminó la partida (con o sin
    // los 3 corazones, pero si sobrevivió hasta el final del tiempo)
    if (survived) {
      final xp = switch (_difficulty!) {
        BtDifficulty.facil => 150,
        BtDifficulty.medio => 300,
        BtDifficulty.dificil => 450,
      };
      await db.addXp(uid, xp);

      // Ticket condicionado: SOLO en difícil y con buen puntaje (partida
      // realmente complicada de lograr, no cualquier partida ganada).
      if (_difficulty == BtDifficulty.dificil &&
          _score >= kTicketScoreThreshold) {
        await db.unlockRandomTicketForGame(uid, 'battle_target');
        _confetti.play();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: FitAppBarTitle('Zona de Combate 🎯')),
      body: _difficulty == null
          ? _buildDifficultyPicker()
          : (_finished ? _buildResult() : _buildBattlefield()),
    );
  }

  Widget _buildDifficultyPicker() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.gps_fixed, size: 64, color: AppColors.heartRed),
            const SizedBox(height: 12),
            const Text(
              'Elige tu nivel de combate',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            // Explicación clara de cómo se gana, siempre visible antes de jugar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgDark2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cyan.withOpacity(0.5)),
              ),
              child: const Text(
                '🎯 Cómo ganar: sobrevive los 30 segundos sin quedarte sin '
                'corazones (❤️❤️❤️). Toca cascos y drops para sumar puntos.\n\n'
                '🎟️ El ticket sorpresa SOLO se gana en dificultad DIFÍCIL, '
                'terminando la partida con $kTicketScoreThreshold puntos o más '
                '(verás tu meta en pantalla mientras juegas).',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 12, height: 1.5, color: Colors.white70),
              ),
            ),
            const SizedBox(height: 20),
            ...BtDifficulty.values.map(
              (d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 220,
                  child: ElevatedButton(
                    onPressed: () => _start(d),
                    child: Text(d.label.toUpperCase()),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBattlefield() {
    return Stack(
      children: [
        // Fondo con parpadeo rojo al recibir daño
        AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _flashRed
              ? AppColors.heartRed.withOpacity(0.25)
              : Colors.transparent,
        ),
        Column(
          children: [
            _buildHud(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final t in _targets)
                        Positioned(
                          left: t.leftFrac * constraints.maxWidth,
                          top: t.topFrac * constraints.maxHeight,
                          child: _TargetWidget(
                            kind: t.kind,
                            onTap: () => _onTapTarget(t),
                          ),
                        ),
                      for (final f in _floatingTexts)
                        Positioned(
                          left: f.leftFrac * constraints.maxWidth,
                          top: f.topFrac * constraints.maxHeight,
                          child:
                              _FloatingScoreText(text: f.text, color: f.color),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHud() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(
                  kMaxHearts,
                  (i) => Icon(
                    i < _hearts ? Icons.favorite : Icons.favorite_border,
                    color: AppColors.heartRed,
                    size: 20,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.timer, color: AppColors.cyan, size: 18),
                  const SizedBox(width: 4),
                  Text('$_secondsLeft s', style: const TextStyle(fontSize: 16)),
                ],
              ),
              Row(
                children: [
                  Text('$_score',
                      style:
                          const TextStyle(fontSize: 16, color: AppColors.gold)),
                  if (_combo > 1) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.magenta,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('x$_combo',
                          style: const TextStyle(fontSize: 11)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        // Meta del ticket, SIEMPRE visible mientras juegas en difícil, para
        // que sepas exactamente qué tan cerca estás de ganarlo.
        if (_difficulty == BtDifficulty.dificil)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.confirmation_number,
                        color: AppColors.gold, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Meta para el ticket: $_score / $kTicketScoreThreshold pts',
                      style:
                          const TextStyle(fontSize: 11, color: AppColors.gold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value:
                        (_score / kTicketScoreThreshold).clamp(0, 1).toDouble(),
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildResult() {
    final wonTicket = _difficulty == BtDifficulty.dificil &&
        _survived &&
        _score >= kTicketScoreThreshold;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [AppColors.pink, AppColors.gold, AppColors.cyan],
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _survived ? Icons.emoji_events : Icons.heart_broken,
                  size: 64,
                  color: _survived ? AppColors.gold : AppColors.heartRed,
                ),
                const SizedBox(height: 12),
                Text(
                  _survived
                      ? '¡Tiempo cumplido! 🎯'
                      : '¡Te quedaste sin corazones!',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text('Puntaje final: $_score',
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                if (wonTicket)
                  const Text(
                    '¡Nivel difícil superado con muy buen puntaje!\n+450 XP y ticket sorpresa 🎟️',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.gold, fontSize: 13),
                  )
                else if (_survived)
                  Text(
                    _difficulty == BtDifficulty.dificil
                        ? 'Te faltó puntaje para el ticket (necesitas $kTicketScoreThreshold+). ¡Otra vez!'
                        : 'Tip: el ticket sorpresa solo se gana en dificultad DIFÍCIL con $kTicketScoreThreshold+ puntos 🎟️',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                const SizedBox(height: 20),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     OutlinedButton(
                //       onPressed: () => setState(() => _difficulty = null),
                //       child: const Text('CAMBIAR NIVEL'),
                //     ),
                //     const SizedBox(width: 12),
                //     ElevatedButton(
                //       onPressed: () => Navigator.pop(context),
                //       child: const Text('VOLVER AL ARCADE'),
                //     ),
                //   ],
                // ),

                //adaptativo a celular
                SizedBox(
                  width: double
                      .infinity, // Hace que los botones abarquen un ancho uniforme
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: () => setState(() => _difficulty = null),
                        child: const Text('CAMBIAR NIVEL'),
                      ),
                      const SizedBox(
                          height: 10), // Espacio vertical entre botones
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('VOLVER AL ARCADE'),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TargetWidget extends StatelessWidget {
  final TargetKind kind;
  final VoidCallback onTap;
  const _TargetWidget({required this.kind, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (kind) {
      TargetKind.casco => (Icons.security, AppColors.gold),
      TargetKind.drop => (Icons.card_giftcard, AppColors.cyan),
      TargetKind.aliado => (Icons.face, Colors.lightBlueAccent),
      TargetKind.granada => (Icons.dangerous, AppColors.heartRed),
    };

    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 180),
        curve: Curves.elasticOut,
        builder: (context, value, child) =>
            Transform.scale(scale: value, child: child),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.bgDark2,
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.6), blurRadius: 8)
            ],
          ),
          child: Icon(icon, color: color, size: 26),
        ),
      ),
    );
  }
}

class _FloatingScoreText extends StatelessWidget {
  final String text;
  final Color color;
  const _FloatingScoreText({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -20 * value),
          child: Opacity(
            opacity: 1 - value,
            child: child,
          ),
        );
      },
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
    );
  }
}
