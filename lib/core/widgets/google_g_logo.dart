import 'package:flutter/material.dart';

/// Logomark officiel "G" de Google (branding guidelines Google Identity),
/// reproduit tel quel (mêmes tracés vectoriels, mêmes couleurs officielles
/// `#4285F4`/`#34A853`/`#FBBC05`/`#EA4335`, jamais recoloré) — voir
/// [SocialAuthButton].
///
/// Dessiné via [CustomPainter] (même pattern que [DashedBorderPainter]/
/// [DiceTypeBadge]/`WoodPlankPainter` de ce dépôt) plutôt qu'un asset
/// PNG/SVG : ce dépôt n'a pas de dépendance de rendu SVG (`flutter_svg`), et
/// un tracé vectoriel reproduit le logo avec la même fidélité qu'un fichier
/// source sans ajouter de dépendance ni d'asset binaire. Écart volontaire par
/// rapport à la piste "SVG/PNG dans `assets/`" envisagée par la spec de la
/// tâche d'origine — signalé au chef de projet plutôt que présenté comme la
/// seule option.
///
/// Les tracés viennent du SVG officiel 18x18 du logo (quatre blocs de
/// couleur distincts, viewBox `0 0 18 18`), redimensionnés à [size] à
/// l'affichage.
class GoogleGLogo extends StatelessWidget {
  const GoogleGLogo({this.size = 20, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGLogoPainter()),
    );
  }
}

/// Dimension du viewBox source du logo officiel — voir [GoogleGLogo].
const double _viewBoxSize = 18;

class _GoogleGLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _viewBoxSize, size.height / _viewBoxSize);

    canvas.drawPath(_bluePath(), Paint()..color = const Color(0xFF4285F4));
    canvas.drawPath(_greenPath(), Paint()..color = const Color(0xFF34A853));
    canvas.drawPath(_yellowPath(), Paint()..color = const Color(0xFFFBBC05));
    canvas.drawPath(_redPath(), Paint()..color = const Color(0xFFEA4335));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  /// `M17.64 9.2045c0-.6381-.0573-1.2518-.1636-1.8409H9v3.4818h4.8436
  /// c-.2086 1.125-.8427 2.0782-1.7959 2.7164v2.2581h2.9087
  /// c1.7018-1.5668 2.6836-3.874 2.6836-6.6154z`
  Path _bluePath() {
    return Path()
      ..moveTo(17.64, 9.2045)
      ..cubicTo(17.64, 8.5664, 17.5827, 7.9527, 17.4764, 7.3636)
      ..lineTo(9, 7.3636)
      ..lineTo(9, 10.8454)
      ..lineTo(13.8436, 10.8454)
      ..cubicTo(13.635, 11.9704, 13.0009, 12.9236, 12.0477, 13.5618)
      ..lineTo(12.0477, 15.8199)
      ..lineTo(14.9564, 15.8199)
      ..cubicTo(16.6582, 14.2531, 17.64, 11.9459, 17.64, 9.2045)
      ..close();
  }

  /// `M9 18c2.43 0 4.4673-.8059 5.9564-2.1805l-2.9087-2.2581
  /// c-.8059.5409-1.8368.8604-3.0477.8604-2.3445 0-4.3282-1.5831-5.0359-3.7105
  /// H.9574v2.3318C2.4382 15.9832 5.4818 18 9 18z`
  Path _greenPath() {
    return Path()
      ..moveTo(9, 18)
      ..cubicTo(11.43, 18, 13.4673, 17.1941, 14.9564, 15.8195)
      ..lineTo(12.0477, 13.5614)
      ..cubicTo(11.2418, 14.1023, 10.2109, 14.4218, 9, 14.4218)
      ..cubicTo(6.6555, 14.4218, 4.6718, 12.8387, 3.9641, 10.7113)
      ..lineTo(0.9574, 10.7113)
      ..lineTo(0.9574, 13.0431)
      ..cubicTo(2.4382, 15.9832, 5.4818, 18, 9, 18)
      ..close();
  }

  /// `M3.9641 10.71c-.18-.5409-.2822-1.1182-.2822-1.71s.1023-1.1691
  /// .2822-1.71V4.9582H.9573A8.9965 8.9965 0 000 9c0 1.4523.3477 2.8268
  /// .9573 4.0418L3.9641 10.71z`
  Path _yellowPath() {
    return Path()
      ..moveTo(3.9641, 10.71)
      ..cubicTo(3.7841, 10.1691, 3.6819, 9.5918, 3.6819, 9.0)
      ..cubicTo(3.6819, 8.4082, 3.7842, 7.8309, 3.9641, 7.29)
      ..lineTo(3.9641, 4.9582)
      ..lineTo(0.9573, 4.9582)
      ..arcToPoint(
        const Offset(0, 9),
        radius: const Radius.circular(8.9965),
        clockwise: false,
      )
      ..cubicTo(0, 10.4523, 0.3477, 11.8268, 0.9573, 13.0418)
      ..lineTo(3.9641, 10.71)
      ..close();
  }

  /// `M9 3.5795c1.3214 0 2.5077.4541 3.4405 1.346l2.5813-2.5814
  /// C13.4632.8918 11.426 0 9 0 5.4818 0 2.4382 2.0168.9573 4.9582
  /// L3.964 7.29C4.6718 5.1627 6.6555 3.5795 9 3.5795z`
  Path _redPath() {
    return Path()
      ..moveTo(9, 3.5795)
      ..cubicTo(10.3214, 3.5795, 11.5077, 4.0336, 12.4405, 4.9255)
      ..lineTo(15.0218, 2.3441)
      ..cubicTo(13.4632, 0.8918, 11.426, 0, 9, 0)
      ..cubicTo(5.4818, 0, 2.4382, 2.0168, 0.9573, 4.9582)
      ..lineTo(3.964, 7.29)
      ..cubicTo(4.6718, 5.1627, 6.6555, 3.5795, 9, 3.5795)
      ..close();
  }
}
