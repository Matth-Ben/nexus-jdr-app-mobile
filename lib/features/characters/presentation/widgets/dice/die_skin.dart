/// Skins du dé animé (P2b) : un skin est un objet de **paramètres seulement**
/// (couleurs, paliers d'ombrage, texture et shader choisis dans des listes
/// fermées). Jamais de code ni de shader fourni par l'utilisateur : changer de
/// skin, c'est passer un autre [DieSkin] au widget.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Textures procédurales disponibles (liste fermée, calculées dans le shader,
/// jamais de bitmap).
enum DieTextureId { none, grain, dots }

/// Shaders disponibles (liste fermée). Chaque valeur désigne un fichier
/// embarqué dans l'application, jamais un chemin libre.
enum DieShaderId {
  texture('shaders/die_texture.frag');

  const DieShaderId(this.asset);

  /// Chemin de l'asset déclaré dans `pubspec.yaml`.
  final String asset;
}

/// Ratio de contraste minimal chiffre / pastille (WCAG AA, texte normal).
const double kMinNumberContrast = 4.5;

/// Skin immuable d'un dé.
@immutable
class DieSkin {
  const DieSkin({
    required this.name,
    required this.baseColor,
    required this.shadeColor,
    required this.edgeColor,
    required this.numberColor,
    required this.numberBackdropColor,
    required this.lightTint,
    this.shadeAmount = 1,
    this.lightTintOpacity = 0.12,
    this.numberBackdropOpacity = 0.7,
    this.shadeSteps = 4,
    this.textureId = DieTextureId.none,
    this.textureOpacity = 0,
    this.shaderId = DieShaderId.texture,
    this.edgeWidth = 2,
  }) : assert(shadeSteps >= 3 && shadeSteps <= 5, 'shadeSteps : 3 à 5'),
       assert(edgeWidth >= 1 && edgeWidth <= 2, 'edgeWidth : 1 à 2 dp'),
       assert(textureOpacity >= 0 && textureOpacity <= 1),
       assert(shadeAmount >= 0 && shadeAmount <= 1),
       assert(lightTintOpacity >= 0 && lightTintOpacity <= 1),
       assert(numberBackdropOpacity >= 0 && numberBackdropOpacity <= 1);

  /// Nom d'affichage du skin (non utilisé dans l'UI pour l'instant).
  final String name;

  /// Couleur d'une face pleinement éclairée.
  final Color baseColor;

  /// Couleur vers laquelle les faces à l'ombre sont ombrées.
  final Color shadeColor;

  /// Part (0..1) du dégradé base -> [shadeColor] réellement appliquée.
  final double shadeAmount;

  final Color edgeColor;
  final Color numberColor;
  final Color numberBackdropColor;

  /// Teinte de la lumière, mélangée aux faces les plus éclairées.
  final Color lightTint;
  final double lightTintOpacity;

  /// Opacité de la pastille du chiffre (spec : ≥ 70 %).
  final double numberBackdropOpacity;

  /// Nombre de paliers de l'ombrage plat (3 à 5).
  final int shadeSteps;

  final DieTextureId textureId;
  final double textureOpacity;
  final DieShaderId shaderId;

  /// Épaisseur des arêtes, en dp (1 à 2).
  final double edgeWidth;

  /// « Chêne de taverne » (défaut) : bois clair ombré vers le bois moyen,
  /// lumière dorée, arêtes bois foncé, grain.
  static const DieSkin tavernOak = DieSkin(
    name: 'Chêne de taverne',
    baseColor: AppColors.woodLight,
    shadeColor: AppColors.woodMedium,
    edgeColor: AppColors.woodDark,
    numberColor: AppColors.textOnWood,
    numberBackdropColor: AppColors.woodDark,
    lightTint: AppColors.goldStart,
    lightTintOpacity: 0.12,
    numberBackdropOpacity: 0.7,
    shadeSteps: 4,
    textureId: DieTextureId.grain,
    textureOpacity: 0.2,
    edgeWidth: 2,
  );

  /// « Sceau de laiton » : parchemin sombre ombré à 35 % vers le bois clair,
  /// arêtes dorées, points.
  static const DieSkin brassSeal = DieSkin(
    name: 'Sceau de laiton',
    baseColor: AppColors.parchmentCardAlt,
    shadeColor: AppColors.woodLight,
    shadeAmount: 0.35,
    edgeColor: AppColors.goldEnd,
    numberColor: AppColors.textPrimary,
    numberBackdropColor: AppColors.parchmentCard,
    lightTint: AppColors.goldStart,
    lightTintOpacity: 0.12,
    numberBackdropOpacity: 0.8,
    shadeSteps: 3,
    textureId: DieTextureId.dots,
    textureOpacity: 0.15,
    edgeWidth: 2,
  );

  /// Skin par défaut.
  static const DieSkin defaultSkin = tavernOak;

  /// Ratio de contraste (WCAG) entre le chiffre et sa pastille, dans le pire
  /// cas : pastille composée sur la face la plus claire ET la plus ombrée.
  double get numberContrast {
    var worst = double.infinity;
    for (final face in [
      baseColor,
      Color.lerp(baseColor, shadeColor, shadeAmount)!,
    ]) {
      final backdrop = Color.alphaBlend(
        numberBackdropColor.withValues(alpha: numberBackdropOpacity),
        face,
      );
      worst = math.min(worst, contrastRatio(numberColor, backdrop));
    }
    return worst;
  }

  /// `true` si le chiffre est lisible (>= [kMinNumberContrast]) et la
  /// pastille assez opaque (>= 70 %).
  bool get isReadable =>
      numberContrast >= kMinNumberContrast && numberBackdropOpacity >= 0.7;

  /// Skin garanti lisible : renvoyé tel quel s'il l'est déjà, sinon le chiffre
  /// et la pastille sont remplacés par `textPrimary` sur `parchmentCard`
  /// opaque (repli automatique, sans jamais afficher d'erreur).
  DieSkin ensureReadable() {
    if (isReadable) return this;
    return copyWith(
      numberColor: AppColors.textPrimary,
      numberBackdropColor: AppColors.parchmentCard,
      numberBackdropOpacity: 1,
    );
  }

  DieSkin copyWith({
    String? name,
    Color? baseColor,
    Color? shadeColor,
    double? shadeAmount,
    Color? edgeColor,
    Color? numberColor,
    Color? numberBackdropColor,
    Color? lightTint,
    double? lightTintOpacity,
    double? numberBackdropOpacity,
    int? shadeSteps,
    DieTextureId? textureId,
    double? textureOpacity,
    DieShaderId? shaderId,
    double? edgeWidth,
  }) => DieSkin(
    name: name ?? this.name,
    baseColor: baseColor ?? this.baseColor,
    shadeColor: shadeColor ?? this.shadeColor,
    shadeAmount: shadeAmount ?? this.shadeAmount,
    edgeColor: edgeColor ?? this.edgeColor,
    numberColor: numberColor ?? this.numberColor,
    numberBackdropColor: numberBackdropColor ?? this.numberBackdropColor,
    lightTint: lightTint ?? this.lightTint,
    lightTintOpacity: lightTintOpacity ?? this.lightTintOpacity,
    numberBackdropOpacity: numberBackdropOpacity ?? this.numberBackdropOpacity,
    shadeSteps: shadeSteps ?? this.shadeSteps,
    textureId: textureId ?? this.textureId,
    textureOpacity: textureOpacity ?? this.textureOpacity,
    shaderId: shaderId ?? this.shaderId,
    edgeWidth: edgeWidth ?? this.edgeWidth,
  );

  /// Couleur (ARGB 32 bits) d'une face à l'étape d'ombrage [step] sur
  /// [shadeSteps] (0 = la plus sombre, `shadeSteps - 1` = la plus claire),
  /// multipliée par [opacity].
  int faceColorArgb(int step, {double opacity = 1}) {
    final steps = shadeSteps;
    final level = steps <= 1 ? 1.0 : step.clamp(0, steps - 1) / (steps - 1);
    var color = Color.lerp(baseColor, shadeColor, (1 - level) * shadeAmount)!;
    if (step >= steps - 1) {
      color = Color.alphaBlend(
        lightTint.withValues(alpha: lightTintOpacity),
        color,
      );
    }
    return color.withValues(alpha: opacity).toARGB32();
  }

  @override
  bool operator ==(Object other) =>
      other is DieSkin &&
      other.name == name &&
      other.baseColor == baseColor &&
      other.shadeColor == shadeColor &&
      other.shadeAmount == shadeAmount &&
      other.edgeColor == edgeColor &&
      other.numberColor == numberColor &&
      other.numberBackdropColor == numberBackdropColor &&
      other.lightTint == lightTint &&
      other.lightTintOpacity == lightTintOpacity &&
      other.numberBackdropOpacity == numberBackdropOpacity &&
      other.shadeSteps == shadeSteps &&
      other.textureId == textureId &&
      other.textureOpacity == textureOpacity &&
      other.shaderId == shaderId &&
      other.edgeWidth == edgeWidth;

  @override
  int get hashCode => Object.hash(
    name,
    baseColor,
    shadeColor,
    shadeAmount,
    edgeColor,
    numberColor,
    numberBackdropColor,
    lightTint,
    lightTintOpacity,
    numberBackdropOpacity,
    shadeSteps,
    textureId,
    textureOpacity,
    shaderId,
    edgeWidth,
  );
}

/// Ratio de contraste WCAG 2.x entre deux couleurs opaques (1..21).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}
