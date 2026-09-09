import 'dart:math';

/// Tirage pur d'un d20 — "mini lancer de dé virtuel" des jets de
/// compétences/caractéristiques de la fiche personnage, voir
/// `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md`, section
/// "Onglet Compétences".
///
/// [random] injectable (défaut `Random()`, non déterministe) pour rester
/// testable — un test qui appellerait `Random()` directement ne pourrait
/// jamais vérifier une valeur précise, seulement un intervalle.
abstract final class DiceRoller {
  /// Résultat entre 1 et 20 inclus.
  static int rollD20({Random? random}) => (random ?? Random()).nextInt(20) + 1;
}
