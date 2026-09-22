import 'dart:math';
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
    final skinShadowColor = config.skinColor.withOpacity(0.65);
    final hairBase = Paint()..color = config.hairColor;
    final hairHighlight = Paint()..color = _lighten(config.hairColor, 0.22);
    final eyeColor = Paint()..color = config.eyeColor;
    final outfitBase = Paint()..color = config.outfitColor;
    final outfitLight = Paint()..color = _lighten(config.outfitColor, 0.28);
    const outline = Colors.black87;
    final hairOutline = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final headCenter = Offset(w * 0.5, h * 0.44);
    final headRadius = w * 0.30;

    // --- Halo suave detrás del avatar ---
    canvas.drawCircle(headCenter, w * 0.46,
        Paint()..color = config.outfitColor.withOpacity(0.18));

    // --- Cuerpo / hombros (proporción chibi: cuerpo chico) ---
    final bodyPath = Path()
      ..moveTo(w * 0.30, h * 1.0)
      ..lineTo(w * 0.24, h * 0.80)
      ..quadraticBezierTo(w * 0.5, h * 0.70, w * 0.76, h * 0.80)
      ..lineTo(w * 0.70, h * 1.0)
      ..close();
    canvas.drawPath(bodyPath, outfitBase);
    canvas.drawPath(
        bodyPath,
        Paint()
          ..color = outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    canvas.drawArc(
      Rect.fromLTWH(w * 0.36, h * 0.74, w * 0.28, h * 0.14),
      0,
      pi,
      false,
      outfitLight,
    );

    // CABELLO
    // Piezas que van "detrás" de la cabeza (mechones largos, coleta trasera)
    if (config.hairStyle == HairStyle.largo) {
      final sideL = Path()
        ..moveTo(w * 0.17, h * 0.30)
        ..quadraticBezierTo(w * 0.08, h * 0.60, w * 0.19, h * 0.88)
        ..lineTo(w * 0.29, h * 0.84)
        ..quadraticBezierTo(w * 0.20, h * 0.56, w * 0.27, h * 0.30)
        ..close();
      final sideR = Path()
        ..moveTo(w * 0.83, h * 0.30)
        ..quadraticBezierTo(w * 0.92, h * 0.60, w * 0.81, h * 0.88)
        ..lineTo(w * 0.71, h * 0.84)
        ..quadraticBezierTo(w * 0.80, h * 0.56, w * 0.73, h * 0.30)
        ..close();
      canvas.drawPath(sideL, hairBase);
      canvas.drawPath(sideL, hairOutline);
      canvas.drawPath(sideR, hairBase);
      canvas.drawPath(sideR, hairOutline);
    } else if (config.hairStyle == HairStyle.coleta) {
      final tail = Path()
        ..moveTo(w * 0.76, h * 0.26)
        ..quadraticBezierTo(w * 0.98, h * 0.30, w * 0.90, h * 0.60)
        ..quadraticBezierTo(w * 0.83, h * 0.66, w * 0.76, h * 0.50)
        ..close();
      canvas.drawPath(tail, hairBase);
      canvas.drawPath(tail, hairOutline);
    }

    // Gorro/fleco base — un óvalo simple; lo que sobresalga por encima de la
    // cabeza es justo lo que se ve como cabello, todo lo demás queda tapado.
    final capRect = Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.24), width: w * 0.70, height: h * 0.46);
    if (config.hairStyle == HairStyle.chino) {
      // Varios bultos redondos (look rizado) en vez de un óvalo liso
      for (final dx in [0.22, 0.37, 0.52, 0.67]) {
        final r = Rect.fromLTWH(w * dx, h * 0.06, w * 0.20, h * 0.24);
        canvas.drawOval(r, hairBase);
        canvas.drawOval(r, hairOutline);
      }
    } else {
      canvas.drawOval(capRect, hairBase);
      canvas.drawOval(capRect, hairOutline);
    }

    // --- CABEZA (tapa la parte de abajo del cabello, dejando la gorra prolija) ---
    canvas.drawCircle(headCenter, headRadius, skin);
    canvas.drawCircle(
        headCenter,
        headRadius,
        Paint()
          ..color = outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    // Sombra sutil bajo el mentón para dar volumen
    canvas.drawArc(
      Rect.fromCircle(center: headCenter, radius: headRadius * 0.95),
      0.3,
      2.5,
      false,
      Paint()
        ..color = skinShadowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = headRadius * 0.15,
    );

    // --- Mejillas (blush) ---
    final blush = Paint()..color = const Color(0xFFFF8FA3).withOpacity(0.45);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.34, h * 0.48),
            width: w * 0.10,
            height: h * 0.06),
        blush);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.66, h * 0.48),
            width: w * 0.10,
            height: h * 0.06),
        blush);

    // --- Ojos grandes y redondos, con brillo ---
    final eyeW = w * 0.09;
    final eyeH = h * 0.11;
    final leftEyeCenter = Offset(w * 0.38, h * 0.44);
    final rightEyeCenter = Offset(w * 0.62, h * 0.44);
    final eyeOutline = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (final c in [leftEyeCenter, rightEyeCenter]) {
      final r = Rect.fromCenter(center: c, width: eyeW, height: eyeH);
      canvas.drawOval(r, eyeColor);
      canvas.drawOval(r, eyeOutline);
      canvas.drawCircle(
        Offset(c.dx - eyeW * 0.18, c.dy - eyeH * 0.22),
        eyeW * 0.16,
        Paint()..color = Colors.white,
      );
    }

    // --- Nariz (puntito sutil) ---
    canvas.drawCircle(
        Offset(w * 0.5, h * 0.49), w * 0.012, Paint()..color = skinShadowColor);

    // --- Sonrisa curva ---
    final smile = Path()
      ..moveTo(w * 0.43, h * 0.54)
      ..quadraticBezierTo(w * 0.5, h * 0.59, w * 0.57, h * 0.54);
    canvas.drawPath(
      smile,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // --- Brillo de cabello (encima de la cabeza, dentro de la parte visible) ---
    final highlightRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.14),
      width: w * (config.hairStyle == HairStyle.chino ? 0.20 : 0.26),
      height: h * 0.08,
    );
    canvas.drawOval(highlightRect, hairHighlight);
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
