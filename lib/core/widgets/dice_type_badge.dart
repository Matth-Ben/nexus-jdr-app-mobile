import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Pastille "icône de dé + notation" (ex. icône à 8 faces + "1d8") affichée à
/// côté du nom d'un sort (`CharacterSpellsSection::_SpellRow`) ou d'un objet
/// d'inventaire (`CharacterInventoryItemCard`) quand un dé de dégâts a pu
/// être détecté — voir `SpellDamageDiceExtractor`/`DiceNotationParser`
/// (`features/characters/domain/`).
///
/// Non interactif : le tap remonte au parent (la ligne entière reste
/// cliquable), ni `InkWell` ni `GestureDetector` propre ici.
class DiceTypeBadge extends StatelessWidget {
  const DiceTypeBadge({required this.sides, required this.label, super.key});

  /// Nombre de faces du dé (ex. 8 pour "1d8") — sert uniquement au rendu de
  /// la silhouette et au label d'accessibilité, indépendamment de [label].
  final int sides;

  /// Texte affiché à côté de l'icône, toujours normalisé `'${count}d${sides}'`
  /// (ex. "1d8"), jamais le substring brut matché par l'extracteur appelant.
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'dé à $sides faces, $label',
      container: true,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: const Size(14, 14),
            painter: _DiceShapePainter(sides: sides),
          ),
          const SizedBox(width: AppSpacing.xs / 2),
          Text(
            label,
            style: AppTypography.body(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dessine une silhouette de dé stylisée "3D" (deux facettes claire/sombre
/// séparées par une scission, contour bois foncé) pour [sides] faces —
/// repli générique (cercle) pour toute valeur hors `{4, 6, 8, 10, 12, 20}`
/// (dont d100, imprécis à représenter fidèlement sur 14px).
///
/// Canvas 14×14, marge interne 1.5px (zone utile ≈11×11px centrée en (7,7)).
/// Palette `wood.*` exclusivement — voir `10-design-system.md`.
class _DiceShapePainter extends CustomPainter {
  const _DiceShapePainter({required this.sides});

  final int sides;

  static const double _margin = 1.5;
  static const double _strokeWidth = 1.2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - _margin;

    switch (sides) {
      case 4:
        _paintTriangle(canvas, center, radius);
      case 6:
        _paintSquareWithNotch(canvas, center, radius);
      case 8:
        _paintDiamond(canvas, center, radius);
      case 10:
        _paintKite(canvas, center, radius);
      case 12:
        _paintPentagon(canvas, center, radius);
      case 20:
        _paintHexagon(canvas, center, radius);
      default:
        _paintFallbackCircle(canvas, center, radius);
    }
  }

  /// Sommet d'un polygone régulier inscrit dans un cercle de [radius] centré
  /// sur [center], [degrees] mesurés depuis le haut (0°) en sens horaire.
  static Offset _vertex(Offset center, double radius, double degrees) {
    final radians = degrees * math.pi / 180;
    return center +
        Offset(radius * math.sin(radians), -radius * math.cos(radians));
  }

  static Paint get _lightFill => Paint()
    ..color = AppColors.woodLight
    ..style = PaintingStyle.fill;

  static Paint get _mediumFill => Paint()
    ..color = AppColors.woodMedium
    ..style = PaintingStyle.fill;

  static Paint get _darkStroke => Paint()
    ..color = AppColors.woodDark
    ..style = PaintingStyle.stroke
    ..strokeWidth = _strokeWidth
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  /// Remplit les deux moitiés (gauche claire, droite sombre) et trace leur
  /// contour (couvrant à la fois le périmètre externe et la ligne de
  /// scission, arête partagée par les deux polygones).
  void _paintSplit(
    Canvas canvas, {
    required List<Offset> leftPoints,
    required List<Offset> rightPoints,
  }) {
    final leftPath = Path()..addPolygon(leftPoints, true);
    final rightPath = Path()..addPolygon(rightPoints, true);
    canvas
      ..drawPath(leftPath, _lightFill)
      ..drawPath(rightPath, _mediumFill)
      ..drawPath(leftPath, _darkStroke)
      ..drawPath(rightPath, _darkStroke);
  }

  void _paintTriangle(Canvas canvas, Offset center, double radius) {
    final top = _vertex(center, radius, 0);
    final bottomRight = _vertex(center, radius, 120);
    final bottomLeft = _vertex(center, radius, 240);
    final baseMid = Offset.lerp(bottomRight, bottomLeft, 0.5)!;
    _paintSplit(
      canvas,
      leftPoints: [top, baseMid, bottomLeft],
      rightPoints: [top, bottomRight, baseMid],
    );
  }

  void _paintDiamond(Canvas canvas, Offset center, double radius) {
    final top = _vertex(center, radius, 0);
    final right = _vertex(center, radius, 90);
    final bottom = _vertex(center, radius, 180);
    final left = _vertex(center, radius, 270);
    _paintSplit(
      canvas,
      leftPoints: [top, bottom, left],
      rightPoints: [top, right, bottom],
    );
  }

  void _paintKite(Canvas canvas, Offset center, double radius) {
    // Apex haut/bas, sommets latéraux à 37,5% de la hauteur depuis le haut
    // (dans la fourchette "35-40%" de la spec), pas au centre.
    const lateralFactor = 0.375;
    final top = Offset(center.dx, center.dy - radius);
    final bottom = Offset(center.dx, center.dy + radius);
    final lateralY = top.dy + lateralFactor * (bottom.dy - top.dy);
    final right = Offset(center.dx + radius, lateralY);
    final left = Offset(center.dx - radius, lateralY);
    _paintSplit(
      canvas,
      leftPoints: [top, bottom, left],
      rightPoints: [top, right, bottom],
    );
  }

  void _paintPentagon(Canvas canvas, Offset center, double radius) {
    final v0 = _vertex(center, radius, 0);
    final v1 = _vertex(center, radius, 72);
    final v2 = _vertex(center, radius, 144);
    final v3 = _vertex(center, radius, 216);
    final v4 = _vertex(center, radius, 288);
    final oppositeMid = Offset.lerp(v2, v3, 0.5)!;
    _paintSplit(
      canvas,
      leftPoints: [v0, oppositeMid, v3, v4],
      rightPoints: [v0, v1, v2, oppositeMid],
    );
  }

  void _paintHexagon(Canvas canvas, Offset center, double radius) {
    // Orientation "plat en haut" : décalage de 30° pour obtenir 2 côtés
    // horizontaux (haut/bas) plutôt qu'un sommet pointe en haut.
    final v0 = _vertex(center, radius, 30);
    final v1 = _vertex(center, radius, 90);
    final v2 = _vertex(center, radius, 150);
    final v3 = _vertex(center, radius, 210);
    final v4 = _vertex(center, radius, 270);
    final v5 = _vertex(center, radius, 330);
    final topMid = Offset.lerp(v5, v0, 0.5)!;
    final bottomMid = Offset.lerp(v2, v3, 0.5)!;
    _paintSplit(
      canvas,
      leftPoints: [topMid, v3, v4, v5],
      rightPoints: [topMid, v0, v1, v2, bottomMid],
    );
  }

  /// Carré occupant l'essentiel de la zone utile (fond `woodMedium`), avec
  /// un petit repli triangulaire au coin supérieur-droit (`woodLight`) —
  /// pas un simple split vertical pour cette forme (spec direction-
  /// artistique).
  void _paintSquareWithNotch(Canvas canvas, Offset center, double radius) {
    final topLeft = Offset(center.dx - radius, center.dy - radius);
    final topRight = Offset(center.dx + radius, center.dy - radius);
    final bottomRight = Offset(center.dx + radius, center.dy + radius);
    final bottomLeft = Offset(center.dx - radius, center.dy + radius);
    final side = radius * 2;

    final squarePath = Path()
      ..addPolygon([topLeft, topRight, bottomRight, bottomLeft], true);
    canvas
      ..drawPath(squarePath, _mediumFill)
      ..drawPath(squarePath, _darkStroke);

    final notchTopPoint = topRight - Offset(side / 3, 0);
    final notchSidePoint = topRight + Offset(0, side / 3);
    final notchPath = Path()
      ..addPolygon([topRight, notchSidePoint, notchTopPoint], true);
    canvas
      ..drawPath(notchPath, _lightFill)
      ..drawLine(notchTopPoint, notchSidePoint, _darkStroke);
  }

  /// Repli générique (dé non standard, dont d100) : cercle inscrit, même
  /// split vertical que les autres formes.
  void _paintFallbackCircle(Canvas canvas, Offset center, double radius) {
    final top = Offset(center.dx, center.dy - radius);
    final bottom = Offset(center.dx, center.dy + radius);

    final leftPath = Path()
      ..moveTo(top.dx, top.dy)
      ..arcToPoint(bottom, radius: Radius.circular(radius))
      ..close();
    final rightPath = Path()
      ..moveTo(top.dx, top.dy)
      ..arcToPoint(bottom, radius: Radius.circular(radius), clockwise: true)
      ..close();

    canvas
      ..drawPath(leftPath, _lightFill)
      ..drawPath(rightPath, _mediumFill)
      ..drawPath(leftPath, _darkStroke)
      ..drawPath(rightPath, _darkStroke);
  }

  @override
  bool shouldRepaint(covariant _DiceShapePainter oldDelegate) =>
      oldDelegate.sides != sides;
}
