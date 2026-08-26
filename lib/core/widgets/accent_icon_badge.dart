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
    required this.index,
    required this.icon,
    this.neutralIcon,
    super.key,
  });

  /// Index de l'option dans sa liste, pour cycler sur les couleurs d'accent.
  /// `-1` (ex. "Race personnalisée") est rendu dans un ton neutre plutôt que
  /// cyclé, avec [neutralIcon] si fourni.
  final int index;

  /// Icône affichée pour `index >= 0`.
  final IconData icon;

  /// Icône affichée pour `index < 0`, si différente de [icon]. Retombe sur
  /// [icon] si `null`.
  final IconData? neutralIcon;

  static const List<Color> _accentCycle = [
    AppColors.accentTeal,
    AppColors.accentBrick,
    AppColors.accentBlue,
    AppColors.accentViolet,
  ];

  @override
  Widget build(BuildContext context) {
    final color = index < 0
        ? AppColors.textMuted
        : _accentCycle[index % _accentCycle.length];

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
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
