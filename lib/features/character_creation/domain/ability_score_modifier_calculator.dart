import 'ability_score_rules.dart';
import 'race_catalog.dart';

/// Calcule le "Modificateur +X" affiché à l'étape 4/9 "Caractéristiques"
/// pour une caractéristique donnée : `score_final = score_de_base_assigné +
/// bonus_racial + bonus_sous-racial`, modificateur =
/// `AbilityScoreRules.abilityModifier(score_final)`.
///
/// Séparé d'`ability_score_rules.dart` (qui reste indépendant de tout
/// catalogue de données) : ce fichier dépend de `RaceCatalog`.
abstract final class AbilityScoreModifierCalculator {
  /// Bonus racial pour la caractéristique [abilityKey] : additionne le bonus
  /// de la race ET de la sous-race si les deux en ont un pour cette
  /// caractéristique (les bonus de sous-race s'ajoutent à ceux de la race en
  /// D&D 5e). Ignore la clé spéciale `choice_others` (bonus à
  /// caractéristiques au choix, ex. Demi-elfe — même rationale que
  /// `RaceSummaryFormatter`, hors périmètre ici).
  ///
  /// Retourne 0 si [raceId] est `null` (race personnalisée choisie à
  /// l'étape 1 : aucune donnée mécanique) ou si l'identifiant ne correspond
  /// plus à une entrée de [catalog].
  static int racialBonusFor({
    required String abilityKey,
    required RaceCatalog catalog,
    required int? raceId,
    required int? subraceId,
  }) {
    if (raceId == null) return 0;

    var bonus = 0;
    for (final race in catalog.races) {
      if (race.id == raceId) {
        bonus += _abilityBonusValue(race.abilityBonuses, abilityKey);
        break;
      }
    }
    if (subraceId != null) {
      for (final subrace in catalog.subraces) {
        if (subrace.id == subraceId) {
          bonus += _abilityBonusValue(subrace.abilityBonuses, abilityKey);
          break;
        }
      }
    }
    return bonus;
  }

  /// Modificateur final affiché pour un score de base et un bonus racial
  /// déjà déterminé (voir [racialBonusFor]).
  static int modifierFor({required int baseScore, required int racialBonus}) {
    return AbilityScoreRules.abilityModifier(baseScore + racialBonus);
  }

  /// Clé spéciale du jsonb `ability_bonuses` (bonus à caractéristiques au
  /// choix, ex. Demi-elfe) — jamais un abilityKey réel (voir
  /// `ability_score_definitions.dart`), mais gardée à l'écart explicitement
  /// ici en toute robustesse plutôt que de compter uniquement sur le fait
  /// qu'elle n'est normalement jamais interrogée.
  static const String _choiceOthersKey = 'choice_others';

  static int _abilityBonusValue(
    Map<String, dynamic> abilityBonuses,
    String key,
  ) {
    if (key == _choiceOthersKey) return 0;
    final value = abilityBonuses[key];
    return value is num ? value.toInt() : 0;
  }
}
