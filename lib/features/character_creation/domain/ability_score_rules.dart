import 'dart:math' as math;

import 'ability_score_definitions.dart';
import 'ability_score_method.dart';

/// Logique métier pure des 3 méthodes de génération des scores de
/// caractéristiques de l'étape 4/9 "Caractéristiques"
/// (`docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` section 3
/// point 4). Ne dépend d'aucun widget Flutter ni d'aucune donnée réseau —
/// entièrement testable en isolation.
///
/// Toutes les méthodes manipulent un `Map<String, int>` clé par clé
/// d'`abilityScoreDefinitions` ('str'/'dex'/'con'/'int'/'wis'/'cha'), jamais
/// modifié en place : chaque fonction retourne une nouvelle map (cohérent
/// avec le reste du projet, qui met à jour l'état via `copyWith` plutôt que
/// par mutation).
abstract final class AbilityScoreRules {
  /// Pool fixe de la méthode "Tableau standard" (règle D&D 5e officielle).
  static const List<int> standardArrayPool = [15, 14, 13, 12, 10, 8];

  /// Budget total de la méthode "Achat par points" (règle D&D 5e officielle).
  static const int pointBuyBudget = 27;

  /// Coût cumulé officiel D&D 5e pour atteindre un score depuis 8 (achat par
  /// points). Pas d'entrée au-delà de 15 : impossible à acheter en achat par
  /// points standard.
  static const Map<int, int> _pointBuyCosts = {
    8: 0,
    9: 1,
    10: 2,
    11: 3,
    12: 4,
    13: 5,
    14: 7,
    15: 9,
  };

  /// Assignation par défaut de la méthode "Tableau standard" : les 6 valeurs
  /// du pool réparties dans l'ordre décroissant sur l'ordre canonique
  /// For/Dex/Con/Int/Sag/Cha (assignation de départ arbitraire, l'important
  /// est que le pool soit entièrement réparti — voir [swapUp]/[swapDown]
  /// pour la réorganisation par le joueur).
  static Map<String, int> defaultStandardArrayScores() {
    return _assignPoolInCanonicalOrder(standardArrayPool);
  }

  /// Assignation par défaut de la méthode "Achat par points" : toutes les
  /// caractéristiques partent à 8 (aucun point dépensé).
  static Map<String, int> defaultPointBuyScores() {
    return {for (final def in abilityScoreDefinitions) def.key: 8};
  }

  /// Coût cumulé (achat par points) pour atteindre [score] depuis 8.
  static int pointBuyCost(int score) {
    final cost = _pointBuyCosts[score];
    assert(cost != null, 'Score $score hors plage achetable (8 à 15).');
    return cost ?? 0;
  }

  /// Coût cumulé total déjà dépensé pour [scores] (achat par points).
  static int pointBuyTotalCost(Map<String, int> scores) {
    return scores.values.fold(0, (sum, score) => sum + pointBuyCost(score));
  }

  /// Points restants du budget de 27 pour [scores] (achat par points).
  static int pointBuyRemaining(Map<String, int> scores) {
    return pointBuyBudget - pointBuyTotalCost(scores);
  }

  /// `true` si la caractéristique [key] peut encore être incrémentée d'1
  /// (achat par points) : pas déjà à 15, et le coût marginal ne dépasse pas
  /// le budget restant.
  static bool canIncrementPointBuy(Map<String, int> scores, String key) {
    final current = scores[key]!;
    if (current >= 15) return false;
    final marginalCost = pointBuyCost(current + 1) - pointBuyCost(current);
    return marginalCost <= pointBuyRemaining(scores);
  }

  /// `true` si la caractéristique [key] peut encore être décrémentée d'1
  /// (achat par points) : pas déjà à 8 (score minimal).
  static bool canDecrementPointBuy(Map<String, int> scores, String key) {
    return scores[key]! > 8;
  }

  /// Incrémente d'1 la caractéristique [key] (achat par points). Retourne
  /// [scores] inchangée si [canIncrementPointBuy] vaut `false` — appelant
  /// censé désactiver le bouton "+" dans ce cas, cette garde est une
  /// sécurité supplémentaire plutôt que le seul rempart.
  static Map<String, int> incrementPointBuy(
    Map<String, int> scores,
    String key,
  ) {
    if (!canIncrementPointBuy(scores, key)) return scores;
    return {...scores, key: scores[key]! + 1};
  }

  /// Décrémente d'1 la caractéristique [key] (achat par points). Même garde
  /// que [incrementPointBuy].
  static Map<String, int> decrementPointBuy(
    Map<String, int> scores,
    String key,
  ) {
    if (!canDecrementPointBuy(scores, key)) return scores;
    return {...scores, key: scores[key]! - 1};
  }

  /// `true` si la caractéristique [key] peut être échangée avec une valeur
  /// immédiatement supérieure du pool actuel (Tableau standard/Dés) : `false`
  /// si elle détient déjà la valeur maximale du pool.
  static bool canSwapUp(Map<String, int> scores, String key) {
    return _nextHigherValue(scores, key) != null;
  }

  /// `true` si la caractéristique [key] peut être échangée avec une valeur
  /// immédiatement inférieure du pool actuel (Tableau standard/Dés) : `false`
  /// si elle détient déjà la valeur minimale du pool.
  static bool canSwapDown(Map<String, int> scores, String key) {
    return _nextLowerValue(scores, key) != null;
  }

  /// Échange la valeur de [key] avec la valeur immédiatement supérieure du
  /// pool actuel, quelle que soit l'autre caractéristique qui la détient
  /// (Tableau standard/Dés) : le pool des 6 valeurs reste toujours entier,
  /// jamais dupliqué ni perdu. Ne fait rien si [canSwapUp] vaut `false`.
  static Map<String, int> swapUp(Map<String, int> scores, String key) {
    final target = _nextHigherValue(scores, key);
    if (target == null) return scores;
    return _swapWithValue(scores, key, target);
  }

  /// Échange la valeur de [key] avec la valeur immédiatement inférieure du
  /// pool actuel. Symétrique de [swapUp].
  static Map<String, int> swapDown(Map<String, int> scores, String key) {
    final target = _nextLowerValue(scores, key);
    if (target == null) return scores;
    return _swapWithValue(scores, key, target);
  }

  /// Lance les 6 caractéristiques de la méthode "Dés" (4d6 en gardant la
  /// somme des 3 meilleurs, une fois par caractéristique — méthode standard
  /// "4d6 drop lowest"), assignées dans l'ordre canonique
  /// For/Dex/Con/Int/Sag/Cha (assignation de départ arbitraire, comme
  /// [defaultStandardArrayScores] : réorganisable ensuite via
  /// [swapUp]/[swapDown]).
  ///
  /// [random] injectable pour les tests (déterminisme) ; `null` par défaut
  /// utilise une graine aléatoire réelle, comme il se doit pour un vrai
  /// lancer de dés en jeu.
  static Map<String, int> rollDiceScores([math.Random? random]) {
    final rng = random ?? math.Random();
    final rolls = List.generate(
      abilityScoreDefinitions.length,
      (_) => _roll4d6DropLowest(rng),
    );
    return _assignPoolInCanonicalOrder(rolls);
  }

  /// Assignation par défaut pour [method] : voir
  /// [defaultStandardArrayScores]/[defaultPointBuyScores]/[rollDiceScores].
  /// Utilisée lors d'un changement de méthode (bascule segmentée) pour
  /// repartir sur une base cohérente avec la nouvelle méthode plutôt que de
  /// conserver des scores qui n'y sont pas valides (ex. un 18 obtenu aux dés
  /// ne peut pas être conservé en basculant sur "Tableau", qui plafonne à
  /// 15).
  static Map<String, int> defaultScoresFor(
    AbilityScoreMethod method, [
    math.Random? random,
  ]) {
    return switch (method) {
      AbilityScoreMethod.standardArray => defaultStandardArrayScores(),
      AbilityScoreMethod.pointBuy => defaultPointBuyScores(),
      AbilityScoreMethod.diceRoll => rollDiceScores(random),
    };
  }

  /// Modificateur D&D 5e standard pour un score final donné :
  /// `floor((score - 10) / 2)`.
  static int abilityModifier(int finalScore) {
    return ((finalScore - 10) / 2).floor();
  }

  static Map<String, int> _assignPoolInCanonicalOrder(List<int> pool) {
    assert(pool.length == abilityScoreDefinitions.length);
    return {
      for (var i = 0; i < abilityScoreDefinitions.length; i++)
        abilityScoreDefinitions[i].key: pool[i],
    };
  }

  static int? _nextHigherValue(Map<String, int> scores, String key) {
    final current = scores[key]!;
    final target = <int>[];
    for (final value in scores.values) {
      if (value > current) target.add(value);
    }
    if (target.isEmpty) return null;
    return target.reduce(math.min);
  }

  static int? _nextLowerValue(Map<String, int> scores, String key) {
    final current = scores[key]!;
    final target = <int>[];
    for (final value in scores.values) {
      if (value < current) target.add(value);
    }
    if (target.isEmpty) return null;
    return target.reduce(math.max);
  }

  static Map<String, int> _swapWithValue(
    Map<String, int> scores,
    String key,
    int targetValue,
  ) {
    final current = scores[key]!;
    final otherKey = scores.entries
        .firstWhere((entry) => entry.key != key && entry.value == targetValue)
        .key;
    return {...scores, key: targetValue, otherKey: current};
  }

  static int _roll4d6DropLowest(math.Random random) {
    final rolls = List.generate(4, (_) => random.nextInt(6) + 1)..sort();
    // Les indices 1, 2, 3 sont les 3 meilleurs après tri croissant (l'indice
    // 0, le plus bas, est celui qu'on jette).
    return rolls[1] + rolls[2] + rolls[3];
  }
}
