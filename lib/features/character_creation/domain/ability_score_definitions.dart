import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Définition statique d'une caractéristique D&D 5e affichée à l'étape 4/9
/// "Caractéristiques" de l'assistant de création : libellé, icône, couleur
/// d'accent. Ne porte aucune logique de calcul (voir `ability_score_rules.dart`
/// et `ability_score_modifier_calculator.dart` pour ça).
class AbilityScoreDefinition {
  const AbilityScoreDefinition({
    required this.key,
    required this.label,
    required this.icon,
    required this.accentColor,
  });

  /// Clé utilisée dans `CharacterCreationDraft.abilityScores` et dans
  /// `RaceOption.abilityBonuses`/`SubraceOption.abilityBonuses`
  /// ('str', 'dex', 'con', 'int', 'wis', 'cha' — même convention que
  /// `RaceSummaryFormatter`).
  final String key;

  /// Libellé affiché ("Force", "Dextérité"...).
  final String label;

  /// Icône Material affichée dans le badge coloré à gauche de la ligne.
  final IconData icon;

  /// Couleur d'accent du badge, dédiée à cette caractéristique.
  final Color accentColor;
}

/// Les 6 caractéristiques, dans l'ordre canonique For/Dex/Con/Int/Sag/Cha —
/// identique à celui de `RaceSummaryFormatter._abilityAbbreviations` et aux
/// clés `ability_bonuses` du catalogue de races
/// (`docs/cahier-des-charges/02-modele-donnees.md`).
///
/// Mapping couleur choisi en reproduisant exactement les teintes mesurées au
/// pixel sur la maquette validée `05_étape_4_caractéristiques.png` (voir le
/// rapport de la tâche qui a produit ce fichier pour le détail de la mesure) :
/// - Force et Charisme partagent `accent.brick` — cohérent avec
///   `docs/cahier-des-charges/10-design-system.md` section 1, qui les
///   associe explicitement ("icônes Force/Charisme").
/// - Dextérité est en `accent.teal` (design système : "icônes
///   Dextérité/Intelligence liée nature").
/// - Intelligence est en `accent.blue` (design système : "icônes
///   Intelligence, accents froids") — la maquette tranche ainsi l'ambiguïté
///   du design système, qui mentionne Intelligence à la fois pour `teal` et
///   `blue`.
/// - Sagesse est en `accent.violet` (design système : "icônes Sagesse").
/// - Constitution n'est mentionnée nulle part dans le design système ; la
///   maquette la montre en `accent.gold-end` plutôt qu'une 5e teinte
///   inventée ou une réutilisation d'un accent déjà pris — c'est ce choix
///   qui est repris ici.
///
/// Icônes Material choisies au plus proche des pictogrammes de la maquette
/// (étoile, chevron, maison, cible, losange, cœur) : aucun asset pixel art
/// dédié par caractéristique n'existe encore
/// (`10-design-system.md` section 5 les liste comme encore à produire) —
/// même dette de polish DA que documentée sur `AccentIconBadge`.
const List<AbilityScoreDefinition> abilityScoreDefinitions = [
  AbilityScoreDefinition(
    key: 'str',
    label: 'Force',
    icon: Icons.star_rounded,
    accentColor: AppColors.accentBrick,
  ),
  AbilityScoreDefinition(
    key: 'dex',
    label: 'Dextérité',
    icon: Icons.expand_less_rounded,
    accentColor: AppColors.accentTeal,
  ),
  AbilityScoreDefinition(
    key: 'con',
    label: 'Constitution',
    icon: Icons.home_rounded,
    accentColor: AppColors.goldEnd,
  ),
  AbilityScoreDefinition(
    key: 'int',
    label: 'Intelligence',
    icon: Icons.track_changes_rounded,
    accentColor: AppColors.accentBlue,
  ),
  AbilityScoreDefinition(
    key: 'wis',
    label: 'Sagesse',
    icon: Icons.diamond_rounded,
    accentColor: AppColors.accentViolet,
  ),
  AbilityScoreDefinition(
    key: 'cha',
    label: 'Charisme',
    icon: Icons.favorite_rounded,
    accentColor: AppColors.accentBrick,
  ),
];
