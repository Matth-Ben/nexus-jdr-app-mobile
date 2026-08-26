/// Méthode de génération des scores de caractéristiques choisie à l'étape
/// 4/9 de l'assistant de création
/// (`docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` section 3
/// point 4 : "saisie manuelle des scores (jet de dés, achat par points, ou
/// tableau standard — méthode au choix du joueur)"), bascule segmentée
/// "TABLEAU / POINTS / DÉS" de la maquette
/// `05_étape_4_caractéristiques.png`.
///
/// Voir `ability_score_rules.dart` pour la logique de chaque méthode.
enum AbilityScoreMethod {
  /// Tableau standard : pool fixe `{15, 14, 13, 12, 10, 8}` à répartir par
  /// permutation entre les 6 caractéristiques
  /// (voir `AbilityScoreRules.standardArrayPool`/`swapUp`/`swapDown`).
  standardArray,

  /// Achat par points : budget de 27 points, coûts marginaux officiels D&D
  /// 5e (voir `AbilityScoreRules.pointBuyCost`).
  pointBuy,

  /// Lancer de dés : 4d6 en gardant la somme des 3 meilleurs, une fois par
  /// caractéristique, puis répartition par permutation comme pour
  /// [standardArray] (voir `AbilityScoreRules.rollDiceScores`).
  diceRoll,
}
