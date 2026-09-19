import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/narrator_overlay.dart';
import 'puzzle_gallery_screen.dart';

/// Rompecabezas por intercambio de piezas cuadradas (tap a dos piezas para
/// intercambiarlas). Se usan piezas cuadradas simples a propósito — se
/// probó una versión con bordes tipo jigsaw (salientes/entrantes) pero
/// tenía errores visuales (huecos negros), así que se optó por esta
/// versión, mucho más confiable, con marco degradado en vez de forma
/// irregular para que se siga viendo "de rompecabezas".
class PuzzleGameScreen extends StatefulWidget {
  final String puzzleId;
  final String? assetPath; // foto oficial (assets del proyecto)
  final Uint8List?
      customImageBytes; // foto subida por el usuario (funciona también en web)
  final int pieceCount; // 35, 50 o 100 (aproximado a una cuadrícula NxN)
  final PuzzleMode mode;

  const PuzzleGameScreen({
    super.key,
    required this.puzzleId,
    this.assetPath,
    this.customImageBytes,
    required this.pieceCount,
    required this.mode,
  });

  @override
  State<PuzzleGameScreen> createState() => _PuzzleGameScreenState();
}

class _PuzzleGameScreenState extends State<PuzzleGameScreen> {
  late int _gridSize; // NxN
  late List<int> _order; // posición actual -> índice de pieza original
  int? _firstSelected;
  Timer? _timer;
  int _secondsLeft = 120;
  bool _finished = false;
  bool _lost = false;

  bool get _isOfficial => widget.assetPath != null;

  /// Condición del ticket: solo en modo cronómetro Y con el máximo de
  /// piezas (100), que es la configuración más difícil disponible.
  bool get _isHardestConfig =>
      widget.mode == PuzzleMode.cronometro && widget.pieceCount == 100;

  @override
  void initState() {
    super.initState();
    _gridSize = sqrt(widget.pieceCount).round().clamp(4, 12);
    final total = _gridSize * _gridSize;
    _order = List.generate(total, (i) => i)..shuffle(Random());
    _maybeLoadCreativeProgress();
    if (widget.mode == PuzzleMode.cronometro) _startTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showNarratorIfNeeded(
        context,
        gameKey: 'puzzle',
        lines: [
          '¡Hola otra veez! este es el clásico juego de rompecabezas, toca dos piezas para intercambiarlas de lugar hasta armar la foto completa 🧩. Arriba a la derecha tienes la imagen de referencia por si se te olvida cómo va.',
          'Puedes jugar a tu ritmo (modo creativo, guarda tu avance) o contra el reloj (modo cronómetro, 2 minutos).',
          'El ticket sorpresa 🎟️ solo se gana en el modo más difícil: cronómetro CON 100 piezas. ¡Con menos piezas ganas XP, pero el ticket es solo para retos grandes! Sé que podrás conseguirlo',
        ],
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (widget.mode == PuzzleMode.creativo) _saveCreativeProgress();
    super.dispose();
  }

  Future<void> _maybeLoadCreativeProgress() async {
    if (widget.mode != PuzzleMode.creativo) return;
    final auth = context.read<AuthService>();
    final db = context.read<FirestoreService>();
    final saved = await db.loadPuzzleCreativeProgress(
        auth.currentUser!.uid, widget.puzzleId);
    if (saved != null && saved['order'] != null) {
      setState(() {
        _order = List<int>.from(saved['order']);
      });
    }
  }

  Future<void> _saveCreativeProgress() async {
    final auth = context.read<AuthService>();
    final db = context.read<FirestoreService>();
    await db.savePuzzleCreativeProgress(
      auth.currentUser!.uid,
      widget.puzzleId,
      {'order': _order, 'gridSize': _gridSize},
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        setState(() {
          _finished = true;
          _lost = true;
        });
      }
    });
  }

  void _tapPiece(int position) {
    if (_finished) return;
    setState(() {
      if (_firstSelected == null) {
        _firstSelected = position;
      } else {
        final a = _firstSelected!;
        final b = position;
        final tmp = _order[a];
        _order[a] = _order[b];
        _order[b] = tmp;
        _firstSelected = null;
        _checkSolved();
      }
    });
  }

  Future<void> _checkSolved() async {
    final solved = List.generate(_order.length, (i) => i);
    if (_listEquals(_order, solved)) {
      _timer?.cancel();
      setState(() {
        _finished = true;
        _lost = false;
      });
      final auth = context.read<AuthService>();
      final db = context.read<FirestoreService>();
      final uid = auth.currentUser!.uid;

      if (widget.mode == PuzzleMode.cronometro) {
        if (_isOfficial) {
          await db.completePuzzleSurvival(uid, widget.puzzleId);
        }
        // Ticket condicionado a la dificultad más alta (100 piezas)
        if (_isHardestConfig) {
          await db.unlockRandomTicketForGame(uid, 'puzzle');
        }
      }
    }
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Flutter Web recibe los BYTES de la imagen (Uint8List) y se usa
  /// MemoryImage, que sí funciona igual en web, celular y escritorio.
  ImageProvider get _image {
    if (widget.customImageBytes != null) {
      return MemoryImage(widget.customImageBytes!);
    }
    return AssetImage(widget.assetPath!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == PuzzleMode.cronometro
            ? 'Rompecabezas — $_secondsLeft s'
            : 'Rompecabezas (creativo)'),
      ),
      body: _finished ? _buildResult() : _buildBoardWithReference(),
    );
  }

  Widget _buildBoardWithReference() {
    return Stack(
      children: [
        _buildBoard(),
        // Imagen de referencia, siempre visible en la esquina superior derecha
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.gold, width: 2),
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 6)
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image(image: _image, fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }

  Widget _buildBoard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AspectRatio(
          aspectRatio: 1,
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _gridSize),
            itemCount: _order.length,
            itemBuilder: (context, position) {
              final pieceIndex = _order[position];
              final row = pieceIndex ~/ _gridSize;
              final col = pieceIndex % _gridSize;
              final selected = _firstSelected == position;
              return GestureDetector(
                onTap: () => _tapPiece(position),
                child: Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selected ? AppColors.gold : Colors.black45,
                      width: selected ? 3 : 1,
                    ),
                  ),
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment(
                        _gridSize == 1 ? 0 : -1 + 2 * col / (_gridSize - 1),
                        _gridSize == 1 ? 0 : -1 + 2 * row / (_gridSize - 1),
                      ),
                      widthFactor: 1 / _gridSize,
                      heightFactor: 1 / _gridSize,
                      child: Image(image: _image, fit: BoxFit.cover),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_lost ? Icons.timer_off : Icons.emoji_events,
              size: 64, color: _lost ? AppColors.heartRed : AppColors.gold),
          const SizedBox(height: 16),
          Text(_lost ? '¡Se acabó el tiempo!' : '¡Rompecabezas completado! 🧩',
              style: Theme.of(context).textTheme.headlineMedium),
          if (!_lost &&
              widget.mode == PuzzleMode.cronometro &&
              !_isHardestConfig) ...[
            const SizedBox(height: 8),
            const Text(
              'Tip: el ticket sorpresa se gana con 100 piezas en modo cronómetro 🎟️',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('VOLVER'),
          ),
        ],
      ),
    );
  }
}
