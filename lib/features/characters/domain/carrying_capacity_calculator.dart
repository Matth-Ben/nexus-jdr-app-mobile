/// Calcul pur de la capacité de transport, affichée sur l'onglet
/// "Inventaire" — voir `docs/cahier-des-charges/`
/// 11-fonctionnalites-a-ajouter.md, section "Onglet Inventaire" : "Capacité
/// de transport / limite de poids selon la Force, avec alerte en cas de
/// surcharge".
///
/// Règle RAW 5e (Manuel des Joueurs) : capacité de transport = score de
/// Force × 15 livres. Convertie en kilogrammes avec la même simplification
/// arrondie que le reste du schéma (1 livre ≈ 0,5 kg — voir le commentaire
/// d'unité de `20260825091000_seed_items_equipment.sql` côté dépôt web,
/// déjà utilisé pour peupler `items.weight`) : Force × 15 × 0,5 = Force ×
/// 7,5 kg, choisi pour rester cohérent avec les poids d'objets déjà affichés
/// plutôt que d'introduire une seconde conversion (précise, 1 lb ≈
/// 0,453592 kg) qui désaccorderait les deux valeurs comparées par [isOverloaded].
///
/// Ne simule pas les règles optionnelles de charge variable (encombré à
/// Force × 5, lourdement encombré à Force × 10, pénalités de vitesse) — reste
/// un simple seuil d'alerte, même principe que `character_detail.dart
/// ::isDead` ("reste un simple affichage, sans simulation des règles
/// complètes").
abstract final class CarryingCapacityCalculator {
  static const double _kgPerStrengthPoint = 7.5;

  /// Capacité de transport en kilogrammes pour [strengthScore] (score brut,
  /// pas le modificateur).
  static double capacityOf(int strengthScore) =>
      strengthScore * _kgPerStrengthPoint;

  /// `true` si [totalWeightKg] dépasse la capacité calculée depuis
  /// [strengthScore].
  static bool isOverloaded({
    required double totalWeightKg,
    required int strengthScore,
  }) => totalWeightKg > capacityOf(strengthScore);
}
