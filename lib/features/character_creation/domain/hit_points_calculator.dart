import 'dart:math' as math;

/// Calcul des points de vie de départ (niveau 1) à l'étape 9/9
/// "Récapitulatif" de l'assistant de création.
///
/// Décision utilisateur : calcul automatique RAW (Règles Absolument Comme
/// Écrites) plutôt qu'un choix "lancer les dés" vs "valeur moyenne" comme
/// proposé aux montées de niveau ultérieures (`docs/cahier-des-charges/04-fonctionnalites-app-mobile.md`
/// section 6) — au niveau 1, la règle D&D 5e est simplement "dé de vie
/// maximum + modificateur de Constitution", sans lancer de dé.
abstract final class HitPointsCalculator {
  /// `max(1, hitDie + constitutionModifier)` — le plancher à 1 couvre le cas
  /// (extrême, jamais atteint avec les méthodes de génération de
  /// caractéristiques de l'étape 4/9, qui plafonnent le score minimal à 8,
  /// modificateur -1) d'un modificateur de Constitution très négatif qui
  /// ferait autrement descendre les PV de départ à 0 ou moins.
  static int maxHpAtLevel1({
    required int hitDie,
    required int constitutionModifier,
  }) {
    return math.max(1, hitDie + constitutionModifier);
  }
}
