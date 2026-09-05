import 'dart:math' as math;

import 'hit_die_method.dart';
import 'level_up_hit_points_calculator.dart';

/// Calcul du gain de PV pour la règle RAW 5e "dépenser un dé de vie" au
/// repos court (`presentation/widgets/rest_sheet.dart`, branche
/// `RestType.short` de `_RestHelpBlock`).
///
/// Réutilise [LevelUpHitPointsCalculator.rollHitDie]/
/// [LevelUpHitPointsCalculator.averageValue] tels quels pour le tirage/la
/// valeur moyenne d'un dé individuel (voir [rollDice]) — seule la
/// combinaison finale diffère de [LevelUpHitPointsCalculator.hpGain] : ici,
/// le plancher "jamais négatif" s'applique **par dé** (RAW : chaque dé
/// dépensé rapporte `max(0, valeur + modificateur de Constitution)`, jamais
/// moins que 0), alors que [LevelUpHitPointsCalculator.hpGain] plafonne à 1
/// le gain d'un niveau entier (un personnage gagne toujours au moins 1 PV
/// par niveau, règle différente qui ne s'applique pas à un lot de dés de
/// vie).
abstract final class HitDiceSpendCalculator {
  /// Un jet (mode [HitDieMethod.roll]) ou la valeur moyenne (mode
  /// [HitDieMethod.average]) par dé dépensé, [diceCount] valeurs au total.
  /// [random] injectable pour les tests (déterminisme), `null` par défaut
  /// utilise une graine aléatoire réelle — voir
  /// [LevelUpHitPointsCalculator.rollHitDie].
  static List<int> rollDice({
    required int hitDie,
    required int diceCount,
    required HitDieMethod method,
    math.Random? random,
  }) {
    return [
      for (var i = 0; i < diceCount; i++)
        method == HitDieMethod.roll
            ? LevelUpHitPointsCalculator.rollHitDie(hitDie, random)
            : LevelUpHitPointsCalculator.averageValue(hitDie),
    ];
  }

  /// Gain de PV brut (avant plafonnement à `maxHp`, voir [appliedGain]) pour
  /// un lot de dés dépensés : somme, par dé, de sa valeur ([rollDice]) +
  /// [constitutionModifier], chaque terme individuellement jamais inférieur
  /// à 0 — voir la documentation de classe pour la différence avec
  /// [LevelUpHitPointsCalculator.hpGain].
  static int rawGain({
    required List<int> rolledOrAverageValues,
    required int constitutionModifier,
  }) {
    var total = 0;
    for (final value in rolledOrAverageValues) {
      total += math.max(0, value + constitutionModifier);
    }
    return total;
  }

  /// Delta de PV réellement appliqué une fois plafonné à [maxHp] — jamais
  /// [rawGain] tel quel si celui-ci dépasserait le maximum (spec visuelle
  /// direction-artistique : le `GainRow`/`SnackBar` de la sheet "Repos"
  /// doivent refléter ce delta réel, jamais la somme brute des dés).
  static int appliedGain({
    required int currentHp,
    required int maxHp,
    required int rawGain,
  }) {
    final headroom = maxHp - currentHp;
    if (headroom <= 0) return 0;
    return math.min(rawGain, headroom);
  }
}
