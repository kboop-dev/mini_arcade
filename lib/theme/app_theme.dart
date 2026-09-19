import 'package:flutter/material.dart';

/// Paleta estilo "arcade pixel love": morado/rosa profundo + acentos neón.
class AppColors {
  static const bgDark = Color(0xFF1B1035);
  static const bgDark2 = Color(0xFF2B1656);
  static const pink = Color(0xFFFF5FA2);
  static const magenta = Color(0xFFB6299B);
  static const cyan = Color(0xFF4CE0E8);
  static const gold = Color(0xFFFFD866);
  static const heartRed = Color(0xFFFF4D6D);
  static const textLight = Color(0xFFFDF4FF);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bgDark,
      fontFamily: 'PixelFont',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.magenta,
        brightness: Brightness.dark,
        primary: AppColors.pink,
        secondary: AppColors.cyan,
        surface: AppColors.bgDark2,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: AppColors.textLight,
          fontSize: 22,
          height: 1.4,
        ),
        bodyMedium: TextStyle(color: AppColors.textLight, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.pink,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: Colors.white, width: 2),
          ),
          textStyle: const TextStyle(fontFamily: 'PixelFont', fontSize: 12),
        ),
      ),
    );
  }
}

/// Helper de breakpoints para que TODO el diseño se adapte a
/// celular / tablet / escritorio desde un solo lugar.
class Responsive {
  static bool isMobile(BuildContext c) => MediaQuery.of(c).size.width < 600;
  static bool isTablet(BuildContext c) {
    final w = MediaQuery.of(c).size.width;
    return w >= 600 && w < 1024;
  }

  static bool isDesktop(BuildContext c) => MediaQuery.of(c).size.width >= 1024;

  /// Número de columnas para grids (galería de fotos, tickets, etc.)
  static int gridColumns(BuildContext c) {
    if (isDesktop(c)) return 4;
    if (isTablet(c)) return 3;
    return 2;
  }

  /// Ancho máximo del contenido central, para que en pantallas grandes
  /// no se estire feo de borde a borde.
  static double maxContentWidth(BuildContext c) {
    if (isDesktop(c)) return 900;
    if (isTablet(c)) return 700;
    return double.infinity;
  }
}
