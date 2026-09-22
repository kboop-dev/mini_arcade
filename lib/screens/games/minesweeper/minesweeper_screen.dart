import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/narrator_overlay.dart';
import '../../../widgets/fit_appbar_title.dart';

enum Difficulty { facil, medio, dificil }

extension on Difficulty {
  int get size => switch (this) {
        Difficulty.facil => 8,
        Difficulty.medio => 10,
        Difficulty.dificil => 12,
      };
  int get bombs => switch (this) {
        Difficulty.facil => 8,
        Difficulty.medio => 16,
        Difficulty.dificil => 30,
      };
  String get label => switch (this) {
        Difficulty.facil => 'Fácil',
        Difficulty.medio => 'Medio',
        Difficulty.dificil => 'Difícil',
      };
}

/// Modo de toque, igual que el Buscaminas de Google Play:
/// - picar: destapa la casilla (como antes)
/// - bandera: marca/desmarca una casilla sospechosa sin destaparla
enum TapMode { picar, bandera }

class MinesweeperScreen extends StatefulWidget {
  const MinesweeperScreen({super.key});
  @override
  State<MinesweeperScreen> createState() => _MinesweeperScreenState();
}

class _MinesweeperScreenState extends State<MinesweeperScreen> {
  Difficulty? _difficulty;
  TapMode _tapMode = TapMode.picar;
  late List<List<bool>> _bombGrid; // true = bomba
  late List<List<int>> _neighborCount;
  late List<List<bool>> _revealed;
  late List<List<bool>> _flagged;
  bool _gameOver = false;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showNarratorIfNeeded(
        context,
        gameKey: 'minesweeper',
        lines: [
          'Este es nuestro buscaminas de corazones y besos 💣💋. Elige un nivel: fácil, medio o difícil.',
          'Toca 🪏 para destapar casillas, o cambia a 🚩 para poner una bandera donde creas que hay una bomba, sin destaparla.',
          'Si ganas en dificultad DIFÍCIL, te llevas +600 XP y un ticket sorpresa 🎟️ (en fácil y medio no hay ticket, ¡ese es solo para los valientes!).',
        ],
      );
    });
  }

  void _start(Difficulty d) {
    final n = d.size;
    final rnd = Random();
    _bombGrid = List.generate(n, (_) => List.filled(n, false));
    int placed = 0;
    while (placed < d.bombs) {
      final r = rnd.nextInt(n), c = rnd.nextInt(n);
      if (!_bombGrid[r][c]) {
        _bombGrid[r][c] = true;
        placed++;
      }
    }
    _neighborCount = List.generate(n, (r) => List.generate(n, (c) {
          if (_bombGrid[r][c]) return -1;
          int count = 0;
          for (var dr = -1; dr <= 1; dr++) {
            for (var dc = -1; dc <= 1; dc++) {
              final nr = r + dr, nc = c + dc;
              if (nr >= 0 && nr < n && nc >= 0 && nc < n && _bombGrid[nr][nc]) {
                count++;
              }
            }
          }
          return count;
        }));
    _revealed = List.generate(n, (_) => List.filled(n, false));
    _flagged = List.generate(n, (_) => List.filled(n, false));
    setState(() {
      _difficulty = d;
      _tapMode = TapMode.picar;
      _gameOver = false;
      _won = false;
    });
  }

  void _onCellTap(int r, int c) {
    if (_gameOver || _revealed[r][c]) return;
    if (_tapMode == TapMode.bandera) {
      setState(() => _flagged[r][c] = !_flagged[r][c]);
      return;
    }
    if (_flagged[r][c]) return; // no se puede destapar una casilla con bandera
    _reveal(r, c);
  }

  void _reveal(int r, int c) {
    setState(() {
      if (_bombGrid[r][c]) {
        _gameOver = true;
        _won = false;
        _revealAll();
        return;
      }
      _floodReveal(r, c);
      _checkWin();
    });
  }

  void _floodReveal(int r, int c) {
    final n = _difficulty!.size;
    if (r < 0 || r >= n || c < 0 || c >= n || _revealed[r][c]) return;
    _revealed[r][c] = true;
    _flagged[r][c] = false; // al destapar se quita cualquier bandera
    if (_neighborCount[r][c] == 0) {
      for (var dr = -1; dr <= 1; dr++) {
        for (var dc = -1; dc <= 1; dc++) {
          if (dr != 0 || dc != 0) _floodReveal(r + dr, c + dc);
        }
      }
    }
  }

  void _revealAll() {
    for (var row in _revealed) {
      for (var i = 0; i < row.length; i++) {
        row[i] = true;
      }
    }
  }

  /// Bombas restantes según banderas puestas (como en el buscaminas real,
  /// el contador puede llegar a negativo si pones de más, no pasa nada).
  int get _bombsLeftCounter {
    int flags = 0;
    for (var row in _flagged) {
      flags += row.where((f) => f).length;
    }
    return _difficulty!.bombs - flags;
  }

  Future<void> _checkWin() async {
    final n = _difficulty!.size;
    int revealedSafe = 0;
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (_revealed[r][c] && !_bombGrid[r][c]) revealedSafe++;
      }
    }
    final totalSafe = n * n - _difficulty!.bombs;
    if (revealedSafe == totalSafe) {
      _gameOver = true;
      _won = true;
      // Condición del ticket: SOLO en dificultad difícil (la más complicada)
      if (_difficulty == Difficulty.dificil) {
        final auth = context.read<AuthService>();
        final db = context.read<FirestoreService>();
        final uid = auth.currentUser!.uid;
        await db.addXp(uid, 600);
        await db.unlockRandomTicketForGame(uid, 'minesweeper');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: FitAppBarTitle('Buscaminas 💣💋')),
      body: _difficulty == null ? _buildDifficultyPicker() : _buildBoard(),
    );
  }

  Widget _buildDifficultyPicker() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: Difficulty.values
            .map((d) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ElevatedButton(
                    onPressed: () => _start(d),
                    child: Text(d.label.toUpperCase()),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildBoard() {
    final n = _difficulty!.size;
    return Column(
      children: [
        if (_gameOver)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _won ? '¡Ganaste! 💕' : '¡Boom! Perdiste 💣',
              style: TextStyle(
                color: _won ? Colors.greenAccent : AppColors.heartRed,
                fontSize: 18,
              ),
            ),
          )
        else
          // Barra de controles estilo Google Play: contador de bombas + toggle picar/bandera
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.dangerous, color: AppColors.heartRed, size: 18),
                    const SizedBox(width: 4),
                    Text('$_bombsLeftCounter', style: const TextStyle(fontSize: 16)),
                  ],
                ),
                _TapModeToggle(
                  mode: _tapMode,
                  onChanged: (m) => setState(() => _tapMode = m),
                ),
              ],
            ),
          ),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: n),
                  itemCount: n * n,
                  itemBuilder: (context, index) {
                    final r = index ~/ n, c = index % n;
                    return _buildCell(r, c);
                  },
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              if (_gameOver)
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('REINICIAR'),
                  onPressed: () => _start(_difficulty!),
                ),
              OutlinedButton(
                onPressed: () => setState(() => _difficulty = null),
                child: const Text('CAMBIAR NIVEL'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCell(int r, int c) {
    final revealed = _revealed[r][c];
    final flagged = _flagged[r][c];
    final isBomb = _bombGrid[r][c];
    final count = _neighborCount[r][c];

    Widget child = const SizedBox.shrink();
    if (revealed) {
      if (isBomb) {
        child = const Icon(Icons.dangerous, color: Colors.black, size: 16);
      } else if (count > 0) {
        child = Text('$count',
            style: TextStyle(color: _numberColor(count), fontWeight: FontWeight.bold));
      } else {
        child = const Icon(Icons.favorite, color: AppColors.pink, size: 12);
      }
    } else if (flagged) {
      child = const Icon(Icons.flag, color: AppColors.gold, size: 16);
    }

    return GestureDetector(
      onTap: () => _onCellTap(r, c),
      // Mantener presionado también pone/quita bandera, como en Google Play,
      // sin importar en qué modo esté el toggle.
      onLongPress: () {
        if (_gameOver || _revealed[r][c]) return;
        setState(() => _flagged[r][c] = !_flagged[r][c]);
      },
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: revealed ? AppColors.bgDark2 : AppColors.magenta,
          border: Border.all(color: Colors.black26),
        ),
        child: Center(child: child),
      ),
    );
  }

  Color _numberColor(int n) {
    const colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.black,
      Colors.grey,
    ];
    return colors[(n - 1).clamp(0, colors.length - 1)];
  }
}

class _TapModeToggle extends StatelessWidget {
  final TapMode mode;
  final ValueChanged<TapMode> onChanged;
  const _TapModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cyan),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleButton(
            icon: Icons.back_hand,
            selected: mode == TapMode.picar,
            onTap: () => onChanged(TapMode.picar),
          ),
          _ToggleButton(
            icon: Icons.flag,
            selected: mode == TapMode.bandera,
            onTap: () => onChanged(TapMode.bandera),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleButton({required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        color: selected ? AppColors.cyan : Colors.transparent,
        child: Icon(icon, size: 20, color: selected ? AppColors.bgDark : AppColors.cyan),
      ),
    );
  }
}
