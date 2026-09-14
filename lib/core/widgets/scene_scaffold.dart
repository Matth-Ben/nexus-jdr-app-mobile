import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// [Scaffold] avec le fond "scène" (dégradé bois foncé + effet planche en
/// bois, voir [WoodPlankPainter]) utilisé par les écrans listés en
/// section 6 de `docs/cahier-des-charges/10-design-system.md` (connexion,
/// liste des personnages, récapitulatifs ponctuels), par opposition au
/// fond "parchemin" uni posé par défaut dans [AppTheme].
class SceneScaffold extends StatelessWidget {
  const SceneScaffold({required this.body, this.appBar, super.key});

  final Widget body;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.sceneBackground),
        child: CustomPaint(painter: const WoodPlankPainter(), child: body),
      ),
    );
  }
}

/// Dessine les lisérés horizontaux (jointures de planches) + le grain
/// vertical discret par-dessus [AppColors.sceneBackground] — reproduit
/// l'effet "planche en bois" visible sur les maquettes "scène"
/// (`docs/cahier-des-charges/09-maquettes-captures.md`, ex. "Écran de
/// connexion"), absent du dégradé plat qui existait avant. Mesuré sur la
/// maquette source (`cran-de-connexion-style-sc-ne.jpg`, 390px de large) :
/// jointures espacées de ~34px, ~10-15% plus sombres que le fond local —
/// reproduit ici avec un noir semi-transparent plutôt qu'une teinte fixe,
/// pour rester cohérent quelle que soit la position dans le dégradé.
///
/// Peint directement sur le [Canvas] (pas d'asset image à charger/mettre à
/// l'échelle) : motif entièrement procédural, agnostique de la taille
/// d'écran, cohérent avec les autres effets "faits à la main" déjà dans ce
/// dépôt (`DashedBorderPainter`).
class WoodPlankPainter extends CustomPainter {
  const WoodPlankPainter();

  /// Hauteur d'une planche, en pixels logiques — valeur mesurée sur la
  /// maquette source (voir la doc de classe), fixe plutôt que relative à la
  /// largeur de l'écran : une planche réelle a une hauteur constante, quelle
  /// que soit la largeur du téléphone qui l'affiche.
  static const double _plankHeight = 34;

  @override
  void paint(Canvas canvas, Size size) {
    final seamPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.16)
      ..strokeWidth = 1.2;
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    for (var y = _plankHeight; y < size.height; y += _plankHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), seamPaint);
      canvas.drawLine(
        Offset(0, y + 1),
        Offset(size.width, y + 1),
        highlightPaint,
      );
    }

    _paintGrain(canvas, size);
  }

  /// Grain vertical discret dans chaque planche — quelques traits fins,
  /// position/opacité tirées d'un générateur à graine fixe (jamais
  /// `Random()` sans graine : le motif doit rester identique d'un rebuild à
  /// l'autre, pas scintiller).
  void _paintGrain(Canvas canvas, Size size) {
    final random = Random(1337);
    final grainPaint = Paint()..strokeWidth = 1;

    for (var y = 0.0; y < size.height; y += _plankHeight) {
      final grainCount = 4 + random.nextInt(3);
      for (var i = 0; i < grainCount; i++) {
        final x = random.nextDouble() * size.width;
        final grainLength = _plankHeight * (0.3 + random.nextDouble() * 0.5);
        final startY = y + random.nextDouble() * (_plankHeight - grainLength);
        grainPaint.color = Colors.black.withValues(
          alpha: 0.03 + random.nextDouble() * 0.03,
        );
        canvas.drawLine(
          Offset(x, startY),
          Offset(x, startY + grainLength),
          grainPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant WoodPlankPainter oldDelegate) => false;
}
