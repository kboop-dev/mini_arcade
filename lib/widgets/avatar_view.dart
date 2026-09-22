import 'package:flutter/material.dart';
import '../models/avatar_config.dart';

/// Dibuja el avatar del jugador estilo "chibi" (cabeza grande, cuerpo chico,
/// look tierno) combinando tono de piel, cabello, ojos y ropa según [config].
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
    final skinShadow = Paint()..color = config.skinColor.withOpacity(0.65);
    final hairBase = Paint()..color = config.hairColor;
    final hairHighlight = Paint()..color = _lighten(config.hairColor, 0.22);
    final eyeColor = Paint()..color = config.eyeColor;
    final outfitBase = Paint()..color = config.outfitColor;
    final outfitLight = Paint()..color = _lighten(config.outfitColor, 0.28);
    const outline = Colors.black87;
    final outlinePaint = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // --- Halo suave detrás del avatar (le da un "pop" de personaje de juego) ---
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.48),
      w * 0.46,
      Paint()..color = config.outfitColor.withOpacity(0.18),
    );

    // --- Cuerpo / hombros (proporción chibi: cuerpo chico) ---
    final bodyPath = Path()
      ..moveTo(w * 0.30, h * 1.0)
      ..lineTo(w * 0.24, h * 0.80)
      ..quadraticBezierTo(w * 0.5, h * 0.70, w * 0.76, h * 0.80)
      ..lineTo(w * 0.70, h * 1.0)
      ..close();
    canvas.drawPath(bodyPath, outfitBase);
    canvas.drawPath(bodyPath, outlinePaint);
    // Cuello/collar más claro, de dos tonos
    canvas.drawArc(
      Rect.fromLTWH(w * 0.36, h * 0.74, w * 0.28, h * 0.14),
      0,
      3.14,
      false,
      outfitLight,
    );

    // --- Cabeza grande y redonda (look chibi/tierno) ---
    final headCenter = Offset(w * 0.5, h * 0.42);
    final headRadius = w * 0.30;
    canvas.drawCircle(headCenter, headRadius, skin);
    canvas.drawCircle(headCenter, headRadius, outlinePaint);

    // Sombra sutil bajo el mentón para dar volumen
    canvas.drawArc(
      Rect.fromCircle(center: headCenter, radius: headRadius * 0.95),
      0.3,
      2.5,
      false,
      Paint()
        ..color = skinShadow.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = headRadius * 0.15,
    );

    // --- Mejillas (blush) ---
    final blush = Paint()..color = const Color(0xFFFF8FA3).withOpacity(0.45);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(w * 0.34, h * 0.46), width: w * 0.10, height: h * 0.06),
        blush);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(w * 0.66, h * 0.46), width: w * 0.10, height: h * 0.06),
        blush);

    // --- Ojos grandes y redondos, con brillo (look tierno) ---
    final eyeW = w * 0.09;
    final eyeH = h * 0.11;
    final leftEyeCenter = Offset(w * 0.38, h * 0.42);
    final rightEyeCenter = Offset(w * 0.62, h * 0.42);
    for (final c in [leftEyeCenter, rightEyeCenter]) {
      canvas.drawOval(
        Rect.fromCenter(center: c, width: eyeW, height: eyeH),
        eyeColor,
      );
      canvas.drawOval(
        Rect.fromCenter(center: c, width: eyeW, height: eyeH),
        outlinePaint..strokeWidth = 1.4,
      );
      // Brillito blanco
      canvas.drawCircle(
        Offset(c.dx - eyeW * 0.18, c.dy - eyeH * 0.22),
        eyeW * 0.16,
        Paint()..color = Colors.white,
      );
    }
    outlinePaint.strokeWidth = 2;

    // --- Nariz (puntito sutil) ---
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.47),
      w * 0.012,
      Paint()..color = skinShadow.color,
    );

    // --- Sonrisa curva ---
    final smile = Path()
      ..moveTo(w * 0.43, h * 0.52)
      ..quadraticBezierTo(w * 0.5, h * 0.57, w * 0.57, h * 0.52);
    canvas.drawPath(
      smile,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // --- Cabello — la forma cambia según el estilo elegido, con brillo de
    // dos tonos para que no se vea plano ---
    void drawHairShape(Path path) {
      canvas.drawPath(path, hairBase);
      canvas.drawPath(path, outlinePaint);
    }

    switch (config.hairStyle) {
      case HairStyle.corto:
        final p = Path()
          ..moveTo(w * 0.20, h * 0.30)
          ..quadraticBezierTo(w * 0.5, h * 0.02, w * 0.80, h * 0.30)
          ..quadraticBezierTo(w * 0.5, h * 0.16, w * 0.20, h * 0.30)
          ..close();
        drawHairShape(p);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(w * 0.5, h * 0.16), width: w * 0.28, height: h * 0.10),
          hairHighlight,
        );
        break;
      case HairStyle.largo:
        final top = Path()
          ..moveTo(w * 0.20, h * 0.32)
          ..quadraticBezierTo(w * 0.5, h * 0.02, w * 0.80, h * 0.32)
          ..quadraticBezierTo(w * 0.5, h * 0.16, w * 0.20, h * 0.32)
          ..close();
        drawHairShape(top);
        final sideL = Path()
          ..moveTo(w * 0.16, h * 0.30)
          ..quadraticBezierTo(w * 0.10, h * 0.62, w * 0.20, h * 0.86)
          ..lineTo(w * 0.28, h * 0.82)
          ..quadraticBezierTo(w * 0.20, h * 0.55, w * 0.26, h * 0.32)
          ..close();
        final sideR = Path()
          ..moveTo(w * 0.84, h * 0.30)
          ..quadraticBezierTo(w * 0.90, h * 0.62, w * 0.80, h * 0.86)
          ..lineTo(w * 0.72, h * 0.82)
          ..quadraticBezierTo(w * 0.80, h * 0.55, w * 0.74, h * 0.32)
          ..close();
        drawHairShape(sideL);
        drawHairShape(sideR);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(w * 0.5, h * 0.16), width: w * 0.28, height: h * 0.10),
          hairHighlight,
        );
        break;
      case HairStyle.chino:
        for (final dx in [0.20, 0.36, 0.52, 0.68]) {
          canvas.drawOval(Rect.fromLTWH(w * dx, h * 0.08, w * 0.22, h * 0.22), hairBase);
        }
        for (final dx in [0.24, 0.56]) {
          canvas.drawOval(Rect.fromLTWH(w * dx, h * 0.06, w * 0.14, h * 0.12), hairHighlight);
        }
        canvas.drawOval(
          Rect.fromLTWH(w * 0.18, h * 0.16, w * 0.64, h * 0.16),
          Paint()..color = hairBase.color,
        );
        break;
      case HairStyle.coleta:
        final top = Path()
          ..moveTo(w * 0.20, h * 0.30)
          ..quadraticBezierTo(w * 0.5, h * 0.04, w * 0.80, h * 0.30)
          ..quadraticBezierTo(w * 0.5, h * 0.16, w * 0.20, h * 0.30)
          ..close();
        drawHairShape(top);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(w * 0.5, h * 0.16), width: w * 0.26, height: h * 0.09),
          hairHighlight,
        );
        // Coleta de lado
        final tail = Path()
          ..moveTo(w * 0.78, h * 0.28)
          ..quadraticBezierTo(w * 0.96, h * 0.30, w * 0.90, h * 0.56)
          ..quadraticBezierTo(w * 0.84, h * 0.62, w * 0.78, h * 0.50)
          ..close();
        drawHairShape(tail);
        break;
    }
  }

  Color _lighten(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    final lighter = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return lighter.toColor();
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) =>
      oldDelegate.config.toMap().toString() != config.toMap().toString();
}
