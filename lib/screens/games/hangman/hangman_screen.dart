import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/narrator_overlay.dart';
import '../../../widgets/fit_appbar_title.dart';

final List<Map<String, String>> hangmanWords = [
  {'word': 'AMOR', 'clue': 'Lo que sentimos los dos <3'},
  {'word': 'BIOPARQUE', 'clue': 'Lugar donde fue nuestra primera cita'},
  {
    'word': 'SUPER MARIO BROS',
    'clue': 'Película que vimos en nuestra primera cita'
  },
  {
    'word': 'TOBOGAN',
    'clue': 'Juego en el que nos tomamos nuestra primera foto'
  },
  {'word': 'CARLOTA', 'clue': 'Mi postre favorito'},
  {'word': 'HAMBURGUESA', 'clue': 'Mi comida rápida favorita'},
  {'word': 'CYAN', 'clue': '¿Cuál es mi color favorito?'},
  {
    'word': 'CAFETERIA',
    'clue': 'Lugar al que me gusta mucho ir en nuestras citas'
  },
  {'word': 'XTREMES', 'clue': 'Mi dulce favorito'},
  {'word': 'NAVIDAD', 'clue': '¿Cuál es mi festividad favorita del año?'},
  {'word': 'PAPAYA', 'clue': 'Fruta que no me gusta comer jaja'},
  {'word': 'SCAPE ROOM', 'clue': '¿Dónde fue la cita que más me ha gustado?'},
  {
    'word': 'CHIRRIS',
    'clue': 'Palabra que usamos para decir que alguien es tierno'
  },
  {'word': 'MUCHACHO', 'clue': 'De qué manera suelo llamarte (apodo)'},
  {
    'word': 'UVA',
    'clue': '¿Qué fruta no puedo comer cuando estoy en mis días?'
  },
  {'word': 'LOBA BLANCA', 'clue': 'Mi animal espiritual'},
  {
    'word': 'OSO PANDA',
    'clue': '¿Qué animal digo que me parezco más en personalidad?'
  },
  {'word': 'TOP GLOBAL', 'clue': 'Frase de chavos que digo mucho y te da risa'},
  {'word': 'CHUCKY', 'clue': 'Personaje que me da miedo'},
  {'word': 'TEAM FRIO', 'clue': '¿Soy team frío o team calor?'}, //20
];

const int kMaxFails = 6;
const int kTotalRounds = 5;

/// Condición del ticket: la partida completa (5 palabras) debe ganarse con
/// muy pocos errores en total, para que sea "difícil/complicada" de lograr
/// y no se regale en cualquier partida ganada.
const int kMaxTotalFailsForTicket = 4;

class HangmanScreen extends StatefulWidget {
  const HangmanScreen({super.key});

  @override
  State<HangmanScreen> createState() => _HangmanScreenState();
}

class _HangmanScreenState extends State<HangmanScreen> {
  late List<Map<String, String>> _gameWords;
  int _currentRound = 0;

  late String _word;
  late String _clue;
  final Set<String> _guessed = {};
  int _fails = 0; // fallos de la ronda actual (para dibujar el muñeco)
  int _totalFails = 0; // fallos acumulados de TODA la partida (para el ticket)
  bool _finished = false;
  bool _wonGame = false;

  static const _letters = 'ABCDEFGHIJKLMNÑOPQRSTUVWXYZ';

  @override
  void initState() {
    super.initState();
    _startNewGame();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showNarratorIfNeeded(
        context,
        gameKey: 'hangman',
        lines: [
          '¡Bienvenido a "¿Qué tanto me conoces?"! Te voy a dar 5 acertijos, uno por uno y tienes que adivinar la palabra.',
          'Si fallas 6 veces en un acertijo, pierdes esa ronda y termina el juego.',
          'Si ganas las 5 palabras cometiendo pocos errores en total, te ganas +400 XP y un ticket sorpresa 🎟️ (si te equivocas mucho, ganas las XP pero no el ticket). Échale ganas ehh, está muy facilísimo',
        ],
      );
    });
  }

  void _startNewGame() {
    final listCopy = List<Map<String, String>>.from(hangmanWords);
    listCopy.shuffle(Random());
    _gameWords = listCopy.take(kTotalRounds).toList();
    _currentRound = 0;
    _wonGame = false;
    _finished = false;
    _totalFails = 0;
    _loadRound(_currentRound);
  }

  void _loadRound(int roundIndex) {
    setState(() {
      _word = _gameWords[roundIndex]['word']!;
      _clue = _gameWords[roundIndex]['clue']!;
      _guessed.clear();
      _fails = 0;
    });
  }

  void _guess(String letter) {
    if (_finished || _guessed.contains(letter)) return;

    setState(() {
      _guessed.add(letter);
      if (!_word.contains(letter)) {
        _fails++;
        _totalFails++;
      }

      final solved =
          _word.split('').every((c) => c == ' ' || _guessed.contains(c));

      if (solved) {
        if (_currentRound + 1 < kTotalRounds) {
          _currentRound++;
          _loadRound(_currentRound);
        } else {
          _finished = true;
          _wonGame = true;
          _onWinAll();
        }
      } else if (_fails >= kMaxFails) {
        _finished = true;
        _wonGame = false;
      }
    });
  }

  Future<void> _onWinAll() async {
    final auth = context.read<AuthService>();
    final db = context.read<FirestoreService>();
    final uid = auth.currentUser!.uid;
    await db.addXp(uid, 400);
    // Ticket condicionado: solo si la partida fue "limpia" (pocos errores)
    if (_totalFails <= kMaxTotalFailsForTicket) {
      await db.unlockRandomTicketForGame(uid, 'hangman');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FitAppBarTitle(
            '¿Qué tanto me conoces? (${_currentRound + 1}/$kTotalRounds)'),
      ),
      body: LayoutBuilder(
        builder: (context, outerConstraints) {
          // Calcula el tamaño de cada botón según el ancho disponible,
          // apuntando a ~7 columnas en celular y más en pantallas anchas,
          // para que nunca se vea apretado ni cortado.
          const spacing = 6.0;
          const horizontalPadding = 20.0;
          final availableWidth =
              outerConstraints.maxWidth - horizontalPadding * 2;
          final targetColumns = (availableWidth / 52).floor().clamp(5, 10);
          final buttonSize =
              ((availableWidth - spacing * (targetColumns - 1)) / targetColumns)
                  .clamp(32.0, 46.0);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(horizontalPadding),
            child: Column(
              children: [
                Text(
                  _clue,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: CustomPaint(
                    size: const Size(160, 160),
                    painter: HangmanPainter(fails: _fails),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: _word.split('').map((c) {
                    if (c == ' ') {
                      return const SizedBox(width: 20, height: 40);
                    }
                    final revealed = _guessed.contains(c) || _finished;
                    return Container(
                      width: 32,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        border: Border(
                            bottom:
                                BorderSide(color: AppColors.cyan, width: 2)),
                      ),
                      child: Text(
                        revealed ? c : '',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                if (_finished)
                  Column(
                    children: [
                      Text(
                        _wonGame
                            ? (_totalFails <= kMaxTotalFailsForTicket
                                ? '¡Felicidades, completaste las 5 palabras casi sin fallar! 🎉\n¡Ganaste un ticket sorpresa!'
                                : '¡Completaste las 5 palabras! 🎉\nTe faltó un poco de actitud jaja pero ganaste tus XP igual.')
                            : '¡Sé que la próxima podrás hacerlo mejor! ❤️\nLa palabra era: $_word',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('VOLVER AL ARCADE'),
                      ),
                    ],
                  )
                else
                  Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    alignment: WrapAlignment.center,
                    children: _letters.split('').map((l) {
                      final used = _guessed.contains(l);
                      return SizedBox(
                        width: buttonSize,
                        height: buttonSize,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                used ? Colors.white24 : AppColors.pink,
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: used ? null : () => _guess(l),
                          child: Text(l, style: const TextStyle(fontSize: 12)),
                        ),
                      );
                    }).toList(),
                  ),
                // Deja aire al final para que el último renglón del teclado
                // nunca quede pegado al borde de la pantalla.
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Dibuja al muñequito del ahorcado de verdad: horca + soga siempre visibles,
/// y va agregando cabeza, cuerpo, brazos y piernas según el número de fallos.
class HangmanPainter extends CustomPainter {
  final int fails; // 0 a 6

  HangmanPainter({required this.fails});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.textLight
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final bodyPaint = Paint()
      ..color = AppColors.heartRed
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // Base
    canvas.drawLine(
        Offset(w * 0.1, h * 0.95), Offset(w * 0.6, h * 0.95), linePaint);
    // Poste vertical
    canvas.drawLine(
        Offset(w * 0.25, h * 0.95), Offset(w * 0.25, h * 0.05), linePaint);
    // Poste horizontal
    canvas.drawLine(
        Offset(w * 0.25, h * 0.05), Offset(w * 0.65, h * 0.05), linePaint);
    // Soga
    canvas.drawLine(
        Offset(w * 0.65, h * 0.05), Offset(w * 0.65, h * 0.2), linePaint);

    const headRadius = 0.08;

    if (fails >= 1) {
      canvas.drawCircle(
          Offset(w * 0.65, h * headRadius * 3.5), w * headRadius, bodyPaint);
    }
    if (fails >= 2) {
      // Cuerpo
      canvas.drawLine(
        Offset(w * 0.65, h * 0.36),
        Offset(w * 0.65, h * 0.65),
        bodyPaint,
      );
    }
    if (fails >= 3) {
      // Brazo izquierdo
      canvas.drawLine(
        Offset(w * 0.65, h * 0.45),
        Offset(w * 0.5, h * 0.58),
        bodyPaint,
      );
    }
    if (fails >= 4) {
      // Brazo derecho
      canvas.drawLine(
        Offset(w * 0.65, h * 0.45),
        Offset(w * 0.8, h * 0.58),
        bodyPaint,
      );
    }
    if (fails >= 5) {
      // Pierna izquierda
      canvas.drawLine(
        Offset(w * 0.65, h * 0.65),
        Offset(w * 0.52, h * 0.85),
        bodyPaint,
      );
    }
    if (fails >= 6) {
      // Pierna derecha
      canvas.drawLine(
        Offset(w * 0.65, h * 0.65),
        Offset(w * 0.78, h * 0.85),
        bodyPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant HangmanPainter oldDelegate) =>
      oldDelegate.fails != fails;
}
