import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/narrator_overlay.dart';
import '../../../widgets/fit_appbar_title.dart';
import 'playing_card.dart';
import 'card_widgets.dart';

/// Describe qué cartas se están arrastrando y de dónde vienen, para poder
/// quitarlas de su lugar original si el movimiento resulta válido.
class _Move {
  final bool fromWaste;
  final int sourceColumn; // -1 si viene del mazo (waste)
  final int startIndex; // índice donde empieza la corrida dentro de la columna
  final List<PlayingCard> cards;
  _Move({
    required this.fromWaste,
    required this.sourceColumn,
    required this.startIndex,
    required this.cards,
  });
}

class SolitaireScreen extends StatefulWidget {
  const SolitaireScreen({super.key});
  @override
  State<SolitaireScreen> createState() => _SolitaireScreenState();
}

class _SolitaireScreenState extends State<SolitaireScreen> {
  late List<List<PlayingCard>> tableau;
  late List<PlayingCard> stock;
  late List<PlayingCard> waste;
  late Map<CardSuit, List<PlayingCard>> foundations;

  int _recycles = 0;
  int _moves = 0;
  int _seconds = 0;
  bool _won = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _newGame();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_won) setState(() => _seconds++);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showNarratorIfNeeded(
        context,
        gameKey: 'solitaire',
        lines: [
          'Es el clásico Solitario ♠️♥️. Arrastra las cartas para armar hileras que bajen de número y alternen color (rojo-negro-rojo...).',
          'Toca el mazo para robar cartas. Manda cada carta a su fundación (arriba a la derecha) empezando por el As, en orden, para ganar.',
          'Ganas cuando las 4 fundaciones queden completas. Si ganas reciclando el mazo 1 vez o menos, te llevas +700 XP y un ticket sorpresa 🎟️ — si te tardas más, ganas +500 XP igual, pero sin ticket.',
        ],
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _newGame() {
    final deck = buildShuffledDeck();
    var idx = 0;
    tableau = List.generate(7, (i) {
      final col = <PlayingCard>[];
      for (var j = 0; j <= i; j++) {
        final c = deck[idx++];
        c.faceUp = j == i;
        col.add(c);
      }
      return col;
    });
    stock = deck.sublist(idx);
    waste = [];
    foundations = {for (final s in CardSuit.values) s: <PlayingCard>[]};
    _recycles = 0;
    _moves = 0;
    _seconds = 0;
    _won = false;
  }

  // ---------------------------------------------------------------------
  // Reglas
  // ---------------------------------------------------------------------

  bool _canPlaceOnTableau(List<PlayingCard> col, PlayingCard card) {
    if (col.isEmpty) return card.rank == 13; // solo un Rey empieza columna vacía
    final top = col.last;
    return top.faceUp && top.rank == card.rank + 1 && top.isRed != card.isRed;
  }

  bool _canPlaceOnFoundation(CardSuit suit, PlayingCard card) {
    if (card.suit != suit) return false;
    final pile = foundations[suit]!;
    if (pile.isEmpty) return card.rank == 1;
    return pile.last.rank == card.rank - 1;
  }

  void _removeSource(_Move move) {
    if (move.fromWaste) {
      waste.removeLast();
    } else {
      final col = tableau[move.sourceColumn];
      col.removeRange(move.startIndex, col.length);
      if (col.isNotEmpty && !col.last.faceUp) col.last.faceUp = true;
    }
  }

  void _drawFromStock() {
    setState(() {
      if (stock.isNotEmpty) {
        final c = stock.removeLast();
        c.faceUp = true;
        waste.add(c);
      } else if (waste.isNotEmpty) {
        stock = waste.reversed.map((c) {
          c.faceUp = false;
          return c;
        }).toList();
        waste = [];
        _recycles++;
      }
    });
  }

  void _tryAutoToFoundation(PlayingCard card, _Move sourceMove) {
    if (_canPlaceOnFoundation(card.suit, card)) {
      setState(() {
        _removeSource(sourceMove);
        foundations[card.suit]!.add(card);
        _moves++;
        _checkWin();
      });
    }
  }

  Future<void> _checkWin() async {
    final total = foundations.values.fold<int>(0, (s, l) => s + l.length);
    if (total < 52 || _won) return;
    setState(() => _won = true);
    _timer?.cancel();

    final auth = context.read<AuthService>();
    final db = context.read<FirestoreService>();
    final uid = auth.currentUser!.uid;
    await db.addXp(uid, 500);
    if (_recycles <= 1) {
      await db.addXp(uid, 200); // bonus extra por ganar "limpio"
      await db.unlockRandomTicketForGame(uid, 'solitaire');
    }
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FitAppBarTitle('Solitario — $_moves mov. — ${_formatTime(_seconds)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Nueva partida',
            onPressed: () => setState(_newGame),
          ),
        ],
      ),
      body: _won ? _buildWinScreen() : _buildBoard(),
    );
  }

  String _formatTime(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }

  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 7 columnas con un pequeño margen entre ellas
        final cardW = ((constraints.maxWidth - 16) / 7).clamp(34.0, 64.0);
        final cardH = cardW * 1.42;
        final overlap = cardH * 0.26;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopRow(cardW, cardH),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                  7,
                  (t) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: _buildColumn(t, cardW, cardH, overlap),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopRow(double cardW, double cardH) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mazo (toca para robar)
          GestureDetector(
            onTap: _drawFromStock,
            child: stock.isNotEmpty
                ? CardBackWidget(width: cardW, height: cardH)
                : EmptySlotWidget(width: cardW, height: cardH, hint: '↻'),
          ),
          const SizedBox(width: 6),
          // Descarte (waste) — se puede arrastrar o tocar para ir directo a la fundación
          waste.isNotEmpty ? _buildWasteCard(cardW, cardH) : EmptySlotWidget(width: cardW, height: cardH),
          const Spacer(),
          // 4 fundaciones
          for (final suit in CardSuit.values)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: _buildFoundation(suit, cardW, cardH),
            ),
        ],
      ),
    );
  }

  Widget _buildWasteCard(double cardW, double cardH) {
    final card = waste.last;
    final move = _Move(fromWaste: true, sourceColumn: -1, startIndex: waste.length - 1, cards: [card]);
    return Draggable<_Move>(
      data: move,
      feedback: Material(color: Colors.transparent, child: CardFaceWidget(card: card, width: cardW, height: cardH)),
      childWhenDragging: EmptySlotWidget(width: cardW, height: cardH),
      child: GestureDetector(
        onTap: () => _tryAutoToFoundation(card, move),
        child: CardFaceWidget(card: card, width: cardW, height: cardH),
      ),
    );
  }

  Widget _buildFoundation(CardSuit suit, double cardW, double cardH) {
    final pile = foundations[suit]!;
    return DragTarget<_Move>(
      onWillAccept: (move) => move != null && move.cards.length == 1 && _canPlaceOnFoundation(suit, move.cards.first),
      onAccept: (move) {
        setState(() {
          _removeSource(move);
          foundations[suit]!.add(move.cards.first);
          _moves++;
          _checkWin();
        });
      },
      builder: (context, candidates, rejects) {
        final highlight = candidates.isNotEmpty;
        return Container(
          decoration: highlight
              ? BoxDecoration(border: Border.all(color: AppColors.gold, width: 2), borderRadius: BorderRadius.circular(4))
              : null,
          child: pile.isEmpty
              ? EmptySlotWidget(width: cardW, height: cardH, hint: suit.symbol)
              : CardFaceWidget(card: pile.last, width: cardW, height: cardH),
        );
      },
    );
  }

  Widget _buildColumn(int t, double cardW, double cardH, double overlap) {
    final col = tableau[t];
    return DragTarget<_Move>(
      onWillAccept: (move) => move != null && _canPlaceOnTableau(col, move.cards.first),
      onAccept: (move) {
        setState(() {
          _removeSource(move);
          col.addAll(move.cards);
          _moves++;
          _checkWin();
        });
      },
      builder: (context, candidates, rejects) {
        final height = cardH + (col.isEmpty ? 0 : overlap * (col.length - 1)) + 4;
        return SizedBox(
          width: cardW,
          height: height < cardH ? cardH : height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (col.isEmpty) EmptySlotWidget(width: cardW, height: cardH),
              for (var i = 0; i < col.length; i++)
                Positioned(
                  top: overlap * i,
                  child: _buildTableauCard(t, i, col, cardW, cardH),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableauCard(int t, int i, List<PlayingCard> col, double cardW, double cardH) {
    final card = col[i];
    if (!card.faceUp) {
      return CardBackWidget(width: cardW, height: cardH);
    }
    final run = col.sublist(i);
    final move = _Move(fromWaste: false, sourceColumn: t, startIndex: i, cards: run);
    final isTopCard = i == col.length - 1;

    return Draggable<_Move>(
      data: move,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: cardW,
          height: cardH + (cardH * 0.26) * (run.length - 1),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var k = 0; k < run.length; k++)
                Positioned(
                  top: (cardH * 0.26) * k,
                  child: CardFaceWidget(card: run[k], width: cardW, height: cardH),
                ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: CardFaceWidget(card: card, width: cardW, height: cardH)),
      child: GestureDetector(
        onTap: isTopCard ? () => _tryAutoToFoundation(card, move) : null,
        child: CardFaceWidget(card: card, width: cardW, height: cardH),
      ),
    );
  }

  Widget _buildWinScreen() {
    final wonTicket = _recycles <= 1;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 64, color: AppColors.gold),
            const SizedBox(height: 16),
            Text('¡Ganaste el solitario! 🎉', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Tiempo: ${_formatTime(_seconds)} · Movimientos: $_moves · Reciclados de mazo: $_recycles',
                style: const TextStyle(fontSize: 12, color: Colors.white70), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              wonTicket
                  ? '¡Ganaste limpio! +700 XP y ticket sorpresa 🎟️'
                  : 'Ganaste +500 XP. Tip: para el ticket, recicla el mazo 1 vez o menos.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.gold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => setState(_newGame),
                  child: const Text('JUGAR DE NUEVO'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('VOLVER AL ARCADE'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
