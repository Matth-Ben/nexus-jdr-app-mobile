import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';

/// Taille de police système à partir de laquelle une étape de l'assistant
/// passe en mode « tout défile » (D192).
const double creationStepCompactTextScale = AppTypography.largeTextScale;

/// `true` quand la taille de police système atteint
/// [creationStepCompactTextScale] : les mises en page à deux colonnes
/// repassent sur une seule colonne et le pied de page défile avec le contenu.
bool creationStepIsCompact(BuildContext context) =>
    AppTypography.isLargeText(context);

/// Corps d'une étape de l'assistant de création, sous le bandeau bois :
/// éléments fixes en tête ([top]), liste défilante ([items]) et pied de
/// page Retour/Suivant ([footer]).
///
/// Taille de police normale : disposition historique (tête fixe, liste
/// `Expanded`, pied de page fixe, toujours visible).
///
/// Grande police (>= [creationStepCompactTextScale]) : à x2,0 ou x3,0 sur un
/// petit écran, le pied de page (boutons et ligne « Brouillon sauvegardé »)
/// et la tête occupent à eux seuls toute la hauteur et la `Column` déborde.
/// Tout (tête, liste, pied de page) vit alors dans un seul `ListView` :
/// les boutons Retour/Suivant restent atteignables en défilant.
class CreationStepBody extends StatelessWidget {
  const CreationStepBody({
    required this.items,
    required this.footer,
    this.top = const [],
    this.listPadding = const EdgeInsets.fromLTRB(24, 16, 24, 16),
    super.key,
  });

  /// Éléments fixes au-dessus de la liste (texte d'introduction, recherche...).
  final List<Widget> top;

  /// Contenu défilant de l'étape.
  final List<Widget> items;

  /// Marge du contenu défilant.
  final EdgeInsets listPadding;

  /// Pied de page (boutons de navigation, abandon).
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    if (!creationStepIsCompact(context)) {
      return Column(
        children: [
          ...top,
          Expanded(
            child: ListView(padding: listPadding, children: items),
          ),
          footer,
        ],
      );
    }
    final side = EdgeInsets.only(
      left: listPadding.left,
      right: listPadding.right,
    );
    return ListView(
      children: [
        ...top,
        SizedBox(height: listPadding.top),
        for (final child in items) Padding(padding: side, child: child),
        SizedBox(height: listPadding.bottom),
        footer,
      ],
    );
  }
}

/// Corps d'un état de chargement ou d'erreur d'une étape ([body]) au-dessus de
/// son pied de page ([footer]) : même logique que [CreationStepBody] (le pied
/// de page défile avec le message en grande police au lieu de faire déborder).
class CreationStatusBody extends StatelessWidget {
  const CreationStatusBody({
    required this.body,
    required this.footer,
    super.key,
  });

  final Widget body;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    if (!creationStepIsCompact(context)) {
      return Column(
        children: [
          Expanded(child: body),
          footer,
        ],
      );
    }
    return ListView(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 160),
          child: body,
        ),
        footer,
      ],
    );
  }
}
