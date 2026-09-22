import 'package:flutter/material.dart';
import 'playing_card.dart';
import '../../../theme/app_theme.dart';

/// Una carta boca arriba, con su número/letra y el símbolo de su palo,
/// dibujada con bordes filosos para que combine con el resto del arcade.
class CardFaceWidget extends StatelessWidget {
  final PlayingCard card;
  final double width;
  final double height;
  const CardFaceWidget({super.key, required this.card, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final color = card.isRed ? const Color(0xFFE84A5F) : const Color(0xFF2B2440);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black87, width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 2, offset: Offset(1, 1))],
      ),
      padding: EdgeInsets.all(width * 0.08),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: _CornerLabel(card: card, color: color, size: width * 0.24),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Transform.rotate(
              angle: 3.14159,
              child: _CornerLabel(card: card, color: color, size: width * 0.24),
            ),
          ),
          Center(
            child: Text(
              card.suit.symbol,
              style: TextStyle(color: color, fontSize: height * 0.34, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerLabel extends StatelessWidget {
  final PlayingCard card;
  final Color color;
  final double size;
  const _CornerLabel({required this.card, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(card.rankLabel,
            style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.bold, height: 1)),
        Text(card.suit.symbol, style: TextStyle(color: color, fontSize: size * 0.8, height: 1)),
      ],
    );
  }
}

/// El reverso de la carta (boca abajo), con el estilo arcade de la app.
class CardBackWidget extends StatelessWidget {
  final double width;
  final double height;
  const CardBackWidget({super.key, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.magenta,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Center(
        child: Icon(Icons.favorite, color: Colors.white.withOpacity(0.5), size: width * 0.4),
      ),
    );
  }
}

/// Espacio vacío (donde no hay carta todavía): un hueco con borde punteado.
class EmptySlotWidget extends StatelessWidget {
  final double width;
  final double height;
  final String? hint;
  const EmptySlotWidget({super.key, required this.width, required this.height, this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      alignment: Alignment.center,
      child: hint != null
          ? Text(hint!, style: TextStyle(color: Colors.white24, fontSize: width * 0.3))
          : null,
    );
  }
}
