import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

/// `Text` en police pixel [AppTypography.display] dont l'agrandissement dû à
/// la taille de police du système est plafonné à
/// [AppTypography.maxDisplayScaleFactor] (x1,3, décision du 10/11/2026).
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
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
    this.textDirection,
    this.strutStyle,
  }) : data = null;

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
        .clamp(maxScaleFactor: AppTypography.maxDisplayScaleFactor);
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
