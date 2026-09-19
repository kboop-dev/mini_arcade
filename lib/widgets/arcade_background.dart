import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Envuelve cualquier pantalla para ponerle una imagen de fondo que se
/// ajusta 100% responsivo (celular/tablet/escritorio), con una capa oscura
/// encima para que el texto y los botones sigan siendo legibles.
///
/// Uso:
/// ```dart
/// return ArcadeBackground(
///   imagePath: 'assets/images/backgrounds/bg_home.png',
///   child: Scaffold(
///     backgroundColor: Colors.transparent, // importante: deja ver el fondo
///     body: ...,
///   ),
/// );
/// ```
class ArcadeBackground extends StatelessWidget {
  final String imagePath;
  final Widget child;
  final double overlayOpacity;

  const ArcadeBackground({
    super.key,
    required this.imagePath,
    required this.child,
    this.overlayOpacity = 0.55,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Color sólido de respaldo mientras carga o si falta la imagen
        Container(color: AppColors.bgDark),
        Positioned.fill(
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover, // cubre toda la pantalla sin deformarse
            errorBuilder: (_, __, ___) => Container(color: AppColors.bgDark),
          ),
        ),
        // Capa oscura para que el texto siga siendo legible sobre la foto
        Positioned.fill(
          child: Container(color: Colors.black.withOpacity(overlayOpacity)),
        ),
        child,
      ],
    );
  }
}
