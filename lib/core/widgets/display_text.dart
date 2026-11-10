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
    return Text(
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
  }
}
