import 'dart:math';
import 'package:flutter/material.dart';
import '../models/avatar_config.dart';

/// Dibuja el avatar del jugador estilo "chibi" refinado con cabello
/// en capas integradas (capa trasera + cara + fleco/volumen frontal).
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
    final skinShadowColor = config.skinColor.withOpacity(0.65);
    final hairBase = Paint()..color = config.hairColor;
    final hairHighlight = Paint()..color = _lighten(config.hairColor, 0.22);
    final eyeColor = Paint()..color = config.eyeColor;
    final outfitBase = Paint()..color = config.outfitColor;
    final outfitLight = Paint()..color = _lighten(config.outfitColor, 0.28);
    const outline = Colors.black87;
    final strokeLine = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final headCenter = Offset(w * 0.5, h * 0.45);
    final headRadius = w * 0.31;

    // --- 1. Halo brillante suave de fondo ---
    canvas.drawCircle(headCenter, w * 0.46,
        Paint()..color = config.outfitColor.withOpacity(0.18));

    // --- 2. Cuerpo / Hombros ---
    final bodyPath = Path()
      ..moveTo(w * 0.28, h * 1.0)
      ..lineTo(w * 0.22, h * 0.80)
      ..quadraticBezierTo(w * 0.5, h * 0.68, w * 0.78, h * 0.80)
      ..lineTo(w * 0.72, h * 1.0)
      ..close();
    canvas.drawPath(bodyPath, outfitBase);
    canvas.drawPath(bodyPath, strokeLine);
    canvas.drawArc(
      Rect.fromLTWH(w * 0.35, h * 0.74, w * 0.30, h * 0.14),
      0,
      pi,
      false,
      outfitLight,
    );

    // --- 3. CABELLO: Capas traseras y volumen superior ---
    if (config.hairStyle == HairStyle.largo) {
      final sideL = Path()
        ..moveTo(w * 0.18, h * 0.28)
        ..quadraticBezierTo(w * 0.08, h * 0.60, w * 0.20, h * 0.90)
        ..lineTo(w * 0.32, h * 0.86)
        ..quadraticBezierTo(w * 0.22, h * 0.56, w * 0.28, h * 0.30)
        ..close();
      final sideR = Path()
        ..moveTo(w * 0.82, h * 0.28)
        ..quadraticBezierTo(w * 0.92, h * 0.60, w * 0.80, h * 0.90)
        ..lineTo(w * 0.68, h * 0.86)
        ..quadraticBezierTo(w * 0.78, h * 0.56, w * 0.72, h * 0.30)
        ..close();
      canvas.drawPath(sideL, hairBase);
      canvas.drawPath(sideL, strokeLine);
      canvas.drawPath(sideR, hairBase);
      canvas.drawPath(sideR, strokeLine);
    } else if (config.hairStyle == HairStyle.coleta) {
      final tail = Path()
        ..moveTo(w * 0.72, h * 0.22)
        ..quadraticBezierTo(w * 0.98, h * 0.25, w * 0.92, h * 0.58)
        ..quadraticBezierTo(w * 0.82, h * 0.62, w * 0.72, h * 0.45)
        ..close();
      canvas.drawPath(tail, hairBase);
      canvas.drawPath(tail, strokeLine);
    }

    // Domo principal de cabello sobre la cabeza (da la forma superior)
    final hairTopPath = Path()
      ..addArc(
        Rect.fromCircle(
            center: Offset(w * 0.5, h * 0.38), radius: headRadius * 1.15),
        pi * 0.9,
        pi * 1.2,
      );
    canvas.drawPath(hairTopPath, hairBase);

    // --- 4. CARA / CABEZA ---
    canvas.drawCircle(headCenter, headRadius, skin);
    canvas.drawCircle(headCenter, headRadius, strokeLine);

    // Sombra sutil bajo el mentón
    canvas.drawArc(
      Rect.fromCircle(center: headCenter, radius: headRadius * 0.95),
      0.3,
      2.5,
      false,
      Paint()
        ..color = skinShadowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = headRadius * 0.12,
    );

    // --- 5. CABELLO: Flecos y capas frontales (¡Cubre la frente!) ---
    final frontHairPath = Path();

    switch (config.hairStyle) {
      case HairStyle.corto:
        frontHairPath
          ..moveTo(w * 0.18, h * 0.40)
          ..quadraticBezierTo(w * 0.22, h * 0.18, w * 0.50, h * 0.16)
          ..quadraticBezierTo(w * 0.78, h * 0.18, w * 0.82, h * 0.40)
          ..quadraticBezierTo(w * 0.68, h * 0.30, w * 0.50, h * 0.34)
          ..quadraticBezierTo(w * 0.32, h * 0.30, w * 0.18, h * 0.40)
          ..close();
        break;

      case HairStyle.largo:
        frontHairPath
          ..moveTo(w * 0.18, h * 0.42)
          ..quadraticBezierTo(w * 0.25, h * 0.18, w * 0.50, h * 0.16)
          ..quadraticBezierTo(w * 0.75, h * 0.18, w * 0.82, h * 0.42)
          ..quadraticBezierTo(w * 0.65, h * 0.32, w * 0.50, h * 0.36)
          ..quadraticBezierTo(w * 0.35, h * 0.32, w * 0.18, h * 0.42)
          ..close();
        break;

      case HairStyle.chino:
        // Rizos adorables que caen en la frente
        for (final offset in [
          Offset(w * 0.26, h * 0.22),
          Offset(w * 0.40, h * 0.19),
          Offset(w * 0.60, h * 0.19),
          Offset(w * 0.74, h * 0.22),
          Offset(w * 0.33, h * 0.27),
          Offset(w * 0.50, h * 0.28),
          Offset(w * 0.67, h * 0.27),
        ]) {
          canvas.drawCircle(offset, w * 0.11, hairBase);
          canvas.drawCircle(offset, w * 0.11, strokeLine);
        }
        break;

      case HairStyle.coleta:
        frontHairPath
          ..moveTo(w * 0.18, h * 0.40)
          ..quadraticBezierTo(w * 0.25, h * 0.18, w * 0.50, h * 0.16)
          ..quadraticBezierTo(w * 0.75, h * 0.18, w * 0.82, h * 0.40)
          ..quadraticBezierTo(w * 0.60, h * 0.32, w * 0.50, h * 0.35)
          ..quadraticBezierTo(w * 0.40, h * 0.32, w * 0.18, h * 0.40)
          ..close();
        break;
    }

    if (config.hairStyle != HairStyle.chino) {
      canvas.drawPath(frontHairPath, hairBase);
      canvas.drawPath(frontHairPath, strokeLine);
    }

    // Brillo/Highlight en el cabello frontal
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.20),
        width: w * 0.24,
        height: h * 0.05,
      ),
      hairHighlight,
    );

    // --- 6. MEJILLAS (Blush tierno) ---
    final blush = Paint()..color = const Color(0xFFFF8FA3).withOpacity(0.50);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.32, h * 0.50),
            width: w * 0.11,
            height: h * 0.06),
        blush);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.68, h * 0.50),
            width: w * 0.11,
            height: h * 0.06),
        blush);

    // --- 7. OJOS GRANDES CHIBI ---
    final eyeW = w * 0.10;
    final eyeH = h * 0.12;
    final leftEyeCenter = Offset(w * 0.37, h * 0.46);
    final rightEyeCenter = Offset(w * 0.63, h * 0.46);

    for (final c in [leftEyeCenter, rightEyeCenter]) {
      final r = Rect.fromCenter(center: c, width: eyeW, height: eyeH);
      canvas.drawOval(r, eyeColor);
      canvas.drawOval(r, strokeLine);
      // Pestaña/Línea superior del ojo
      final lash = Path()
        ..moveTo(c.dx - eyeW * 0.55, c.dy - eyeH * 0.2)
        ..quadraticBezierTo(
            c.dx, c.dy - eyeH * 0.7, c.dx + eyeW * 0.55, c.dy - eyeH * 0.2);
      canvas.drawPath(lash, strokeLine);

      // Brillos de los ojos
      canvas.drawCircle(
        Offset(c.dx - eyeW * 0.18, c.dy - eyeH * 0.22),
        eyeW * 0.18,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(c.dx + eyeW * 0.18, c.dy + eyeH * 0.20),
        eyeW * 0.09,
        Paint()..color = Colors.white,
      );
    }

    // --- 8. NARIZ Y SONRISA ---
    canvas.drawCircle(
        Offset(w * 0.5, h * 0.52), w * 0.012, Paint()..color = skinShadowColor);

    final smile = Path()
      ..moveTo(w * 0.43, h * 0.56)
      ..quadraticBezierTo(w * 0.5, h * 0.61, w * 0.57, h * 0.56);
    canvas.drawPath(
      smile,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
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
