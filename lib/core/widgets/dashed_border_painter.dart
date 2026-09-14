import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Dessine une bordure pointillée sur tout le pourtour du widget parent (pas
/// de support natif de bordure pointillée dans `BoxDecoration`).
///
/// Extrait de `core/widgets/portrait_frame.dart` (où il était privé,
/// `_DashedBorderPainter`) pour être réutilisé ailleurs que sur le cadre de
/// portrait — ex. la tuile "Portrait" (non fonctionnelle) de l'étape 8/9 de
/// l'assistant de création, `character_creation/presentation
/// /appearance_and_backstory_step_screen.dart`. [PortraitFrame] continue de
/// s'appuyer dessus après cette extraction, sans changement de rendu.
///
/// [shape] par défaut ([BoxShape.rectangle]) dessine toujours un rectangle
/// droit (aucune gestion de coin arrondi : le widget parent doit lui-même
/// clipper via `Container.clipBehavior: Clip.antiAlias` + `borderRadius` s'il
/// veut un rayon de coin, comme le fait déjà [PortraitFrame]).
/// [BoxShape.circle] (ajouté lors du recettage direction-artistique du
/// 13/09 pour les médaillons "état vide" de `character_list_screen.dart`/
/// `group_list_screen.dart`) dessine plutôt une ellipse inscrite dans les
/// bornes du widget — utiliser un parent carré pour obtenir un cercle exact.
class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dashLength = 4,
    this.gapLength = 3,
    this.shape = BoxShape.rectangle,
  });

  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final BoxShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = shape == BoxShape.circle
        ? (Path()..addOval(Offset.zero & size))
        : (Path()..addRect(Offset.zero & size));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.gapLength != gapLength ||
      oldDelegate.shape != shape;
}
