/// Un objet du catalogue `items`, pour la sheet "Depuis le catalogue" de
/// l'onglet "Inventaire" (`presentation/widgets/add_item_flow.dart`) — voir
/// `data/inventory_catalog_row_mapper.dart` pour sa résolution.
///
/// Dédié à cet écran plutôt que réutilisé depuis
/// `character_creation/domain/item_option.dart` (`ItemOption`) : même
/// principe de résolution (nom via `translations`), mais avec [weight] en
/// plus (sous-titre "{coût} po · {poids} kg" de la spec visuelle, absent du
/// besoin de l'étape 7/9 de l'assistant de création) — voir le commentaire
/// de classe de `RaceRowMapper` pour le rationale de cette duplication
/// systématique dans ce dépôt.
///
/// Volontairement une classe simple (pas `freezed`), même précédent que
/// [ItemOption]/`CharacterInventoryItem`.
class InventoryCatalogItem {
  const InventoryCatalogItem({
    required this.id,
    required this.name,
    required this.category,
    required this.costAmount,
    this.weight,
  });

  final int id;
  final String name;

  /// `items.category` — jamais nul ici (contrairement à
  /// `CharacterInventoryItem.category`) : chaque ligne vient bien d'une
  /// ligne `items` réelle, ce champ n'a de sens "objet personnalisé" nulle
  /// part dans ce catalogue.
  final String category;

  final double costAmount;

  /// `items.weight`, `null` si non renseigné en base — même convention que
  /// `CharacterInventoryItem.totalWeight` (rien affiché plutôt qu'un poids
  /// trompeur).
  final double? weight;
}
