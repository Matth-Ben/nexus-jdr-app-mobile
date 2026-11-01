import 'package:flutter/material.dart';

/// Logomark Apple, utilisé par [SocialAuthButton] pour le bouton "Continuer
/// avec Apple" de l'écran de connexion (`features/auth/presentation/
/// login_screen.dart`).
///
/// Couleur unique `#000000` (noir pur), **jamais** une teinte de
/// `AppColors` : même exception de marque que [GoogleGLogo]
/// (`core/widgets/google_g_logo.dart`, voir son commentaire de classe pour le
/// même type de justification) — les règles de marque "Sign in with Apple"
/// d'Apple imposent le glyphe en noir (ou blanc) pur, jamais recoloré avec la
/// palette de l'application hôte.
///
/// Dessiné via [CustomPainter] (même pattern que [GoogleGLogo]/
/// `DashedBorderPainter`/`DiceTypeBadge`/`WoodPlankPainter` de ce dépôt)
/// plutôt qu'un asset PNG/SVG — même rationale que [GoogleGLogo] : ce dépôt
/// n'a pas de dépendance de rendu SVG (`flutter_svg`).
///
/// **Provenance des tracés — point à faire valider par `direction-
/// artistique` avant publication, signalé plutôt que présenté comme fini** :
/// contrairement à [GoogleGLogo] (dont le SVG source officiel 18x18 est
/// publiquement accessible sans authentification), le kit de ressources
/// officiel "Sign in with Apple"/Human Interface Guidelines d'Apple
/// (developer.apple.com, section "Design Resources") est distribué derrière
/// une connexion avec un compte Apple Developer — absent sur ce poste au
/// moment de l'écriture de ce fichier (voir la doc de classe de
/// [AuthRepository.signInWithApple]). Les tracés ci-dessous reproduisent donc
/// le logomark Apple depuis la définition vectorielle du projet
/// **Simple Icons** (licence CC0 1.0, `simpleicons.org`/
/// `github.com/simple-icons/simple-icons`, fichier `icons/apple.svg`,
/// viewBox `0 0 24 24`) — une reproduction tierce largement utilisée et
/// fidèle à la silhouette officielle, mais pas un export direct du kit
/// officiel Apple. À comparer visuellement avec le glyphe officiel dès que
/// l'accès au compte Apple Developer Program est disponible (voir la
/// dépendance documentée sur [AuthRepository.signInWithApple]).
class AppleLogo extends StatelessWidget {
  const AppleLogo({this.size = 20, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _AppleLogoPainter()),
    );
  }
}

/// Dimension du viewBox source du logo — voir [AppleLogo].
const double _viewBoxSize = 24;

class _AppleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _viewBoxSize, size.height / _viewBoxSize);

    final paint = Paint()..color = const Color(0xFF000000);
    canvas.drawPath(_bodyPath(), paint);
    canvas.drawPath(_leafPath(), paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  /// Silhouette principale (la "pomme") — voir [AppleLogo].
  ///
  /// `M12.152 6.896c-.948 0-2.415-1.078-3.96-1.04-2.04.027-3.91 1.183-4.961
  /// 3.014-2.117 3.675-.546 9.103 1.519 12.09 1.013 1.454 2.208 3.09 3.792
  /// 3.039 1.52-.065 2.09-.987 3.935-.987 1.831 0 2.35.987 3.96.948 1.637-.026
  /// 2.676-1.48 3.676-2.948 1.156-1.688 1.636-3.325 1.662-3.415-.039-.013
  /// -3.182-1.221-3.22-4.857-.026-3.04 2.48-4.494 2.597-4.559-1.429-2.09
  /// -3.623-2.324-4.39-2.376-2-.156-3.675 1.09-4.61 1.09z`
  Path _bodyPath() {
    return Path()
      ..moveTo(12.152, 6.896)
      ..relativeCubicTo(-0.948, 0, -2.415, -1.078, -3.96, -1.04)
      ..relativeCubicTo(-2.04, 0.027, -3.91, 1.183, -4.961, 3.014)
      ..relativeCubicTo(-2.117, 3.675, -0.546, 9.103, 1.519, 12.09)
      ..relativeCubicTo(1.013, 1.454, 2.208, 3.09, 3.792, 3.039)
      ..relativeCubicTo(1.52, -0.065, 2.09, -0.987, 3.935, -0.987)
      ..relativeCubicTo(1.831, 0, 2.35, 0.987, 3.96, 0.948)
      ..relativeCubicTo(1.637, -0.026, 2.676, -1.48, 3.676, -2.948)
      ..relativeCubicTo(1.156, -1.688, 1.636, -3.325, 1.662, -3.415)
      ..relativeCubicTo(-0.039, -0.013, -3.182, -1.221, -3.22, -4.857)
      ..relativeCubicTo(-0.026, -3.04, 2.48, -4.494, 2.597, -4.559)
      ..relativeCubicTo(-1.429, -2.09, -3.623, -2.324, -4.39, -2.376)
      ..relativeCubicTo(-2, -0.156, -3.675, 1.09, -4.61, 1.09)
      ..close();
  }

  /// Petite feuille/tige en haut à droite de la pomme — voir [AppleLogo].
  ///
  /// `M15.53 3.83c.843-1.012 1.4-2.427 1.245-3.83-1.207.052-2.662.805-3.532
  /// 1.818-.78.896-1.454 2.338-1.273 3.714 1.338.104 2.715-.688 3.559-1.701`
  Path _leafPath() {
    return Path()
      ..moveTo(15.53, 3.83)
      ..relativeCubicTo(0.843, -1.012, 1.4, -2.427, 1.245, -3.83)
      ..relativeCubicTo(-1.207, 0.052, -2.662, 0.805, -3.532, 1.818)
      ..relativeCubicTo(-0.78, 0.896, -1.454, 2.338, -1.273, 3.714)
      ..relativeCubicTo(1.338, 0.104, 2.715, -0.688, 3.559, -1.701)
      ..close();
  }
}
