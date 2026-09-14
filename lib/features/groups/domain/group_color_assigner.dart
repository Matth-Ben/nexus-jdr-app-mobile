import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Choisit une couleur stable (avatar de groupe, puces de couleur des
/// membres du tableau de bord groupe) à partir d'un identifiant — recettage
/// direction-artistique du 13/09, "Groupes — Liste" et tableau de bord
/// groupe (tâche parallèle).
///
/// **Ne représente aucune donnée métier**, contrairement au mapping
/// classe -> couleur des portraits de personnage
/// (`character_card.dart::_classThemeColor`, qui encode une correspondance
/// D&D volontaire Magicien/Guerrier/Clerc) : ici, la couleur n'est qu'une
/// variation visuelle stable par identifiant, purement décorative — deux
/// identifiants différents peuvent tomber sur la même couleur (la palette
/// est volontairement petite), et rien ne doit jamais déduire une
/// information du personnage/groupe à partir de cette couleur.
abstract final class GroupColorAssigner {
  /// Palette réduite du design système (`docs/cahier-des-charges/
  /// 10-design-system.md` section 1) — les mêmes tokens d'accent que le
  /// reste de l'app, jamais une couleur en dur.
  static const List<Color> _palette = [
    AppColors.accentTeal,
    AppColors.accentBrick,
    AppColors.accentBlue,
    AppColors.accentViolet,
    AppColors.goldEnd,
  ];

  /// Hash simple et stable (pas besoin de cryptographique) : somme des
  /// code units de [id] modulo la taille de la palette — déterministe d'un
  /// appel à l'autre et d'une plateforme à l'autre (contrairement à
  /// `Object.hashCode`, non garanti stable entre exécutions/isolats par la
  /// spec Dart).
  static Color colorFor(String id) {
    if (id.isEmpty) return _palette.first;
    final sum = id.codeUnits.fold<int>(0, (total, unit) => total + unit);
    return _palette[sum % _palette.length];
  }
}
