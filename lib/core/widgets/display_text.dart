import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

/// Palier de plafonnement de [DisplayText] (décision du 10/11/2026) : pas de
/// facteur numérique libre à l'appel.
enum DisplayTier {
  /// Titres, marque, badges de statut : plafond
  /// [AppTypography.maxDisplayScaleFactor] (x1,3).
  title(AppTypography.maxDisplayScaleFactor),

  /// Libellés de boutons, onglets, segments : plafond
  /// [AppTypography.maxControlScaleFactor] (x1,5). Le conteneur doit absorber
  /// le retour à la ligne (`maxLines` 2, hauteur élastique, `minHeight` et
  /// jamais de hauteur fixe) ; sinon rester à [title] et le justifier.
  control(AppTypography.maxControlScaleFactor);

  const DisplayTier(this.maxScaleFactor);

  final double maxScaleFactor;
}

/// `Text` en police pixel [AppTypography.display] dont l'agrandissement dû à
/// la taille de police du système est plafonné selon son [tier] (x1,3 pour
/// [DisplayTier.title] par défaut, x1,5 pour [DisplayTier.control]).
///
/// Le plafond s'applique à ce seul `Text` (jamais au sous-arbre) : le texte
/// courant ([AppTypography.body]) reste entièrement agrandissable. Si un
/// plafond plus bas est déjà posé plus haut (`MediaQuery
/// .withClampedTextScaling`), le plus bas des deux s'applique.
///
/// Un `TextScaler` s'applique à tout le `Text` : ne pas mélanger `display` et
/// `body` dans un [DisplayText.rich], séparer en deux widgets.
class DisplayText extends StatelessWidget {
  const DisplayText(
    this.data, {
    super.key,
    this.tier = DisplayTier.title,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
    this.textDirection,
    this.strutStyle,
  }) : textSpan = null;

  const DisplayText.rich(
    this.textSpan, {
    super.key,
    this.tier = DisplayTier.title,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
    this.textDirection,
    this.strutStyle,
  }) : data = null;

  final DisplayTier tier;
  final String? data;
  final InlineSpan? textSpan;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final String? semanticsLabel;
  final TextDirection? textDirection;
  final StrutStyle? strutStyle;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: tier.maxScaleFactor);
    if (textSpan != null) {
      return Text.rich(
        textSpan!,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
        semanticsLabel: semanticsLabel,
        textDirection: textDirection,
        strutStyle: strutStyle,
        textScaler: scaler,
      );
    }
    if (tier == DisplayTier.control) {
      // Repli "mot entier" : dans un bouton étroit (demi-largeur), un mot
      // long à x1,5 serait coupé en plein mot ; on réduit alors l'échelle
      // jusqu'à ce que le mot le plus long tienne, sans jamais passer sous la
      // taille de base (x1,0, donc jamais sous 11 px en display). Sans effet
      // si les mots tiennent déjà (rendu identique), ou si la largeur est
      // non bornée. Pas de support des dimensions intrinsèques
      // (`LayoutBuilder`) : ne pas placer sous `IntrinsicHeight`/`Width`.
      return LayoutBuilder(
        builder: (context, constraints) =>
            _text(_fitLongestWord(context, scaler, constraints.maxWidth)),
      );
    }
    return _text(scaler);
  }

  Widget _text(TextScaler scaler) => Text(
    data!,
    style: style,
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: overflow,
    softWrap: softWrap,
    semanticsLabel: semanticsLabel,
    textDirection: textDirection,
    strutStyle: strutStyle,
    textScaler: scaler,
  );

  TextScaler _fitLongestWord(
    BuildContext context,
    TextScaler scaler,
    double maxWidth,
  ) {
    if (!maxWidth.isFinite) return scaler;
    final effective = DefaultTextStyle.of(context).style.merge(style);
    final base = effective.fontSize ?? 14;
    final words = data!.split(RegExp(r'\s+'))..removeWhere((w) => w.isEmpty);
    if (words.isEmpty) return scaler;
    final longest = words.reduce((a, b) => a.length >= b.length ? a : b);
    final direction = textDirection ?? Directionality.of(context);

    double widthAt(double factor) {
      final painter = TextPainter(
        text: TextSpan(text: longest, style: effective),
        textDirection: direction,
        textScaler: TextScaler.linear(factor),
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    final current = scaler.scale(base) / base;
    if (current <= 1 || widthAt(current) <= maxWidth) return scaler;
    // Recherche dichotomique du plus grand facteur dans [1, current] qui
    // fait tenir le mot ; si même x1,0 ne tient pas, on reste à x1,0.
    var low = 1.0;
    var high = current;
    for (var i = 0; i < 10; i++) {
      final mid = (low + high) / 2;
      if (widthAt(mid) <= maxWidth) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return TextScaler.linear(low);
  }
}
