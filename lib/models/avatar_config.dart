import 'package:flutter/material.dart';

enum HairStyle { corto, largo, chino, coleta }

class AvatarConfig {
  final int skinIndex;
  final int hairStyleIndex;
  final int hairColorIndex;
  final int eyeColorIndex;
  final int outfitColorIndex;

  const AvatarConfig({
    this.skinIndex = 0,
    this.hairStyleIndex = 0,
    this.hairColorIndex = 0,
    this.eyeColorIndex = 0,
    this.outfitColorIndex = 0,
  });

  factory AvatarConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const AvatarConfig();
    return AvatarConfig(
      skinIndex: (map['skin'] ?? 0) as int,
      hairStyleIndex: (map['hairStyle'] ?? 0) as int,
      hairColorIndex: (map['hairColor'] ?? 0) as int,
      eyeColorIndex: (map['eyeColor'] ?? 0) as int,
      outfitColorIndex: (map['outfit'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() => {
        'skin': skinIndex,
        'hairStyle': hairStyleIndex,
        'hairColor': hairColorIndex,
        'eyeColor': eyeColorIndex,
        'outfit': outfitColorIndex,
      };

  AvatarConfig copyWith({
    int? skinIndex,
    int? hairStyleIndex,
    int? hairColorIndex,
    int? eyeColorIndex,
    int? outfitColorIndex,
  }) {
    return AvatarConfig(
      skinIndex: skinIndex ?? this.skinIndex,
      hairStyleIndex: hairStyleIndex ?? this.hairStyleIndex,
      hairColorIndex: hairColorIndex ?? this.hairColorIndex,
      eyeColorIndex: eyeColorIndex ?? this.eyeColorIndex,
      outfitColorIndex: outfitColorIndex ?? this.outfitColorIndex,
    );
  }

  Color get skinColor => avatarSkinTones[skinIndex % avatarSkinTones.length];
  Color get hairColor => avatarHairColors[hairColorIndex % avatarHairColors.length];
  Color get eyeColor => avatarEyeColors[eyeColorIndex % avatarEyeColors.length];
  Color get outfitColor => avatarOutfitColors[outfitColorIndex % avatarOutfitColors.length];
  HairStyle get hairStyle => HairStyle.values[hairStyleIndex % HairStyle.values.length];
}

// Paletas de opciones para el editor de avatar (por ahora colores planos +
// formas simples estilo "pixel"; se puede sofisticar más adelante con
// sprites reales si Keyla/Ian quieren un estilo más detallado).
const List<Color> avatarSkinTones = [
  Color(0xFFFFE0BD),
  Color(0xFFF1C27D),
  Color(0xFFE0AC69),
  Color(0xFFC68642),
  Color(0xFF8D5524),
];

const List<Color> avatarHairColors = [
  Color(0xFF2B1B12), // negro/café oscuro
  Color(0xFF6D4C33), // castaño
  Color(0xFFB57A3F), // castaño claro
  Color(0xFFF2C641), // rubio
  Color(0xFFE85D9C), // rosa fantasía
  Color(0xFF4CE0E8), // cyan fantasía
];

const List<Color> avatarEyeColors = [
  Color(0xFF3D2B1F), // café
  Color(0xFF1A1A1A), // negro
  Color(0xFF4CE0E8), // cyan
  Color(0xFF6FCF6F), // verde
];

const List<Color> avatarOutfitColors = [
  Color(0xFFFF5FA2), // rosa
  Color(0xFF4CE0E8), // cyan
  Color(0xFFFFD866), // dorado
  Color(0xFFB6299B), // magenta
  Color(0xFF6FCF6F), // verde
  Color(0xFFFF8A4C), // naranja
];

const List<String> hairStyleLabels = ['Corto', 'Largo', 'Chino', 'Coleta'];
