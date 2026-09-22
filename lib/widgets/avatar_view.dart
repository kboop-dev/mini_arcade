import 'package:flutter/material.dart';
import '../models/avatar_config.dart';

/// Dibuja el avatar del jugador con bordes filosos (estilo pixel/bloque),
/// combinando tono de piel, cabello, ojos y color de ropa según [config].
class AvatarView extends StatelessWidget {
  final AvatarConfig config;
  final double size;
  const AvatarView({super.key, required this.config, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AvatarPainter(config),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  final AvatarConfig config;
  _AvatarPainter(this.config);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final skin = Paint()..color = config.skinColor;
    final hair = Paint()..color = config.hairColor;
    final eyes = Paint()..color = config.eyeColor;
    final outfit = Paint()..color = config.outfitColor;
    const blackLine = Colors.black87;

    // Hombros / cuerpo (parte de abajo)
    final bodyRect = Rect.fromLTWH(w * 0.15, h * 0.72, w * 0.7, h * 0.28);
    canvas.drawRect(bodyRect, outfit);
    canvas.drawRect(bodyRect, Paint()..color = blackLine..style = PaintingStyle.stroke..strokeWidth = 2);

    // Cabeza (cuadrada con esquinas ligeramente redondeadas = look pixel/bloque)
    final headRect = Rect.fromLTWH(w * 0.22, h * 0.18, w * 0.56, h * 0.56);
    final headRRect = RRect.fromRectAndRadius(headRect, Radius.circular(w * 0.06));
    canvas.drawRRect(headRRect, skin);
    canvas.drawRRect(
        headRRect, Paint()..color = blackLine..style = PaintingStyle.stroke..strokeWidth = 2);

    // Ojos (dos cuadritos)
    final eyeSize = w * 0.07;
    canvas.drawRect(
        Rect.fromLTWH(w * 0.34, h * 0.42, eyeSize, eyeSize), eyes);
    canvas.drawRect(
        Rect.fromLTWH(w * 0.58, h * 0.42, eyeSize, eyeSize), eyes);

    // Boca (línea simple)
    canvas.drawLine(
      Offset(w * 0.42, h * 0.58),
      Offset(w * 0.58, h * 0.58),
      Paint()
        ..color = blackLine
        ..strokeWidth = 2,
    );

    // Cabello — la forma cambia según el estilo elegido
    switch (config.hairStyle) {
      case HairStyle.corto:
        canvas.drawRect(Rect.fromLTWH(w * 0.20, h * 0.14, w * 0.60, h * 0.20), hair);
        break;
      case HairStyle.largo:
        canvas.drawRect(Rect.fromLTWH(w * 0.20, h * 0.14, w * 0.60, h * 0.20), hair);
        canvas.drawRect(Rect.fromLTWH(w * 0.16, h * 0.30, w * 0.12, h * 0.42), hair);
        canvas.drawRect(Rect.fromLTWH(w * 0.72, h * 0.30, w * 0.12, h * 0.42), hair);
        break;
      case HairStyle.chino:
        for (final dx in [0.18, 0.34, 0.50, 0.66]) {
          canvas.drawOval(Rect.fromLTWH(w * dx, h * 0.12, w * 0.20, h * 0.20), hair);
        }
        break;
      case HairStyle.coleta:
        canvas.drawRect(Rect.fromLTWH(w * 0.20, h * 0.14, w * 0.60, h * 0.18), hair);
        canvas.drawOval(Rect.fromLTWH(w * 0.74, h * 0.20, w * 0.14, h * 0.30), hair);
        break;
    }
    canvas.drawRect(
      Rect.fromLTWH(w * 0.20, h * 0.14, w * 0.60, h * 0.05),
      Paint()..color = blackLine..style = PaintingStyle.stroke..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) =>
      oldDelegate.config.toMap().toString() != config.toMap().toString();
}
