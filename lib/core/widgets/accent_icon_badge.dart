import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Badge carré 40×40 à gauche d'une [SelectableOptionTile] (races, classes...
/// de l'assistant de création), avec une icône Material et une couleur
/// d'accent cyclée sur [index].
///
/// Extrait de `_RaceIconBadge` (étape 1/9 "Race") pour être réutilisé tel
/// quel à l'étape 2/9 "Classe" plutôt que dupliqué : aucun asset pixel art
/// dédié par race/classe n'existe encore
/// (`docs/cahier-des-charges/10-design-system.md` section 5 liste ces
/// icônes comme encore à produire) — dette de polish DA à traiter avec
/// l'agent `direction-artistique`, identique pour les deux étapes.
class AccentIconBadge extends StatelessWidget {
  const AccentIconBadge({
    this.index = 0,
    required this.icon,
    this.neutralIcon,
    this.color,
    super.key,
  });

  /// Index de l'option dans sa liste, pour cycler sur les couleurs d'accent
  /// quand [color] n'est pas fourni. `-1` (ex. "Race personnalisée") est
  /// rendu dans un ton neutre plutôt que cyclé, avec [neutralIcon] si
  /// fourni. Ignoré si [color] est fourni (hormis pour le choix de
  /// [neutralIcon]). Vaut `0` par défaut : les appelants qui fournissent
  /// [color] (couleur d'accent dédiée, ex. une caractéristique) n'ont pas à
  /// s'en préoccuper.
  final int index;

  /// Icône affichée pour `index >= 0`.
  final IconData icon;

  /// Icône affichée pour `index < 0`, si différente de [icon]. Retombe sur
  /// [icon] si `null`.
  final IconData? neutralIcon;

  /// Couleur d'accent explicite, prioritaire sur le cycle basé sur [index]
  /// — pour les usages qui ont une couleur dédiée par option plutôt qu'un
  /// simple cycle générique (ex. une couleur par caractéristique à l'étape
  /// 4/9 "Caractéristiques", voir `domain/ability_score_definitions.dart`).
  final Color? color;

  static const List<Color> _accentCycle = [
    AppColors.accentTeal,
    AppColors.accentBrick,
    AppColors.accentBlue,
    AppColors.accentViolet,
  ];

  @override
  Widget build(BuildContext context) {
    final resolvedColor =
        color ??
        (index < 0
            ? AppColors.textMuted
            : _accentCycle[index % _accentCycle.length]);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: resolvedColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(
        index < 0 ? (neutralIcon ?? icon) : icon,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}
