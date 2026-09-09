import 'character_inventory_item.dart';

/// Filtre "Tout"/"Armes"/"Consomm." de l'onglet Inventaire — voir
/// `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md` section 3,
/// "Tri / filtre de l'inventaire par type", et la maquette "Fiche —
/// Inventaire" (`09-maquettes-captures.md`, bascule segmentée sous les stat
/// boxes de monnaie).
///
/// Seulement 3 segments (pas les 4 évoqués par le cahier des charges —
/// "armes, armures, consommables, divers") : la maquette n'en montre que 3
/// (`Tout`/`Armes`/`Consomm.`) dans une bascule segmentée
/// (`core/widgets/segmented_toggle.dart`, conçue pour 2-3 segments), et
/// c'est elle qui prime pour la fidélité visuelle — écart assumé plutôt que
/// deviné, à discuter si "Armures"/"Divers" s'avèrent nécessaires en
/// pratique.
enum InventoryCategoryFilter {
  all('Tout'),
  weapons('Armes'),
  consumables('Consomm.');

  const InventoryCategoryFilter(this.label);

  final String label;

  /// `items.category == 'arme'` pour [weapons] ;
  /// `CharacterInventoryItem.consumable` pour [consumables] — un objet
  /// consommable ET de catégorie 'arme' (aucun cas réel connu à ce jour)
  /// n'apparaîtrait alors que sous [weapons], jamais sous les deux à la
  /// fois : chaque segment applique son propre test indépendamment, aucune
  /// hiérarchie de priorité entre eux n'est nécessaire puisqu'un seul
  /// segment est actif à la fois (bascule à choix unique).
  bool matches(CharacterInventoryItem item) => switch (this) {
    InventoryCategoryFilter.all => true,
    InventoryCategoryFilter.weapons => item.category == 'arme',
    InventoryCategoryFilter.consumables => item.consumable,
  };

  static List<CharacterInventoryItem> apply(
    List<CharacterInventoryItem> items,
    InventoryCategoryFilter filter,
  ) {
    if (filter == InventoryCategoryFilter.all) return items;
    return items.where(filter.matches).toList(growable: false);
  }
}
