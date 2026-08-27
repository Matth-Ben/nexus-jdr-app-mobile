import 'character_inventory_item.dart';

/// Calcule le poids total de l'inventaire d'un personnage, pour la stat box
/// "poids" de l'onglet "Inventaire" — voir
/// `domain/inventory_stat_boxes_resolver.dart`.
abstract final class InventoryWeightCalculator {
  /// Somme des [CharacterInventoryItem.totalWeight] de [items] — une ligne
  /// au poids inconnu (`null`, voir la documentation de
  /// [CharacterInventoryItem.totalWeight]) contribue `0` au total plutôt que
  /// de rendre le total entier inconnu : un joueur avec un seul objet
  /// personnalisé sans poids connu doit quand même voir le poids de son
  /// équipement du catalogue, pas un total vide/absent.
  ///
  /// Garde-fou défensif : une ligne de `quantity` <= 0 contribue toujours
  /// `0`, quel que soit [CharacterInventoryItem.totalWeight] — `quantity`
  /// n'a aucune contrainte `CHECK` côté base (vérifié contre le schéma
  /// réel), donc pas de garantie qu'elle soit strictement positive.
  /// `CharacterInventoryRowMapper.toCharacterInventoryItems` applique déjà
  /// cette règle en amont (poids de ligne `null` dans ce cas), mais ce
  /// contrôle est répété ici pour ne jamais dépendre uniquement de la
  /// discipline de l'appelant (ex. un futur appelant qui construirait des
  /// [CharacterInventoryItem] sans passer par ce mapper).
  static double totalOf(List<CharacterInventoryItem> items) {
    var total = 0.0;
    for (final item in items) {
      if (item.quantity <= 0) continue;
      total += item.totalWeight ?? 0;
    }
    return total;
  }
}
