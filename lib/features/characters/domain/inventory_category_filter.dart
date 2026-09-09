import 'character_inventory_item.dart';

/// Filtre "Tout"/"Armes"/"Armures"/"Consomm."/"Divers" de l'onglet
/// Inventaire — voir `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md`
/// section 3, "Tri / filtre de l'inventaire par type", et la maquette
/// "Fiche — Inventaire" (`09-maquettes-captures.md`, bascule segmentée sous
/// les stat boxes de monnaie).
///
/// Les 4 segments du cahier des charges ("armes, armures, consommables,
/// divers"), pas seulement les 3 montrés par la maquette (`Tout`/`Armes`/
/// `Consomm.`) — écart précédemment assumé, levé maintenant que le tri par
/// catégorie est explicitement demandé. `core/widgets/segmented_toggle.dart`
/// n'impose aucune limite de segments (voir sa documentation de classe).
enum InventoryCategoryFilter {
  all('Tout'),
  weapons('Armes'),
  armor('Armures'),
  consumables('Consomm.'),
  misc('Divers');

  const InventoryCategoryFilter(this.label);

  final String label;

  /// `items.category == 'arme'` pour [weapons] ; `category` ∈
  /// {'armure', 'bouclier'} pour [armor] ;
  /// `CharacterInventoryItem.consumable` pour [consumables] ; ce qui ne
  /// correspond à aucun des trois précédents pour [misc] (`outil`,
  /// `equipement_general`, `objet_magique` non consommable,
  /// `monture_vehicule`, et tout objet personnalisé) — chaque segment
  /// applique son propre test indépendamment (sauf [misc], qui exclut
  /// explicitement les trois autres) : un objet consommable ET de catégorie
  /// 'arme' (aucun cas réel connu à ce jour) apparaîtrait alors sous
  /// [weapons] ET [consumables], jamais sous [misc], aucune hiérarchie de
  /// priorité n'étant nécessaire puisqu'un seul segment est actif à la fois
  /// (bascule à choix unique).
  bool matches(CharacterInventoryItem item) => switch (this) {
    InventoryCategoryFilter.all => true,
    InventoryCategoryFilter.weapons => item.category == 'arme',
    InventoryCategoryFilter.armor =>
      item.category == 'armure' || item.category == 'bouclier',
    InventoryCategoryFilter.consumables => item.consumable,
    InventoryCategoryFilter.misc =>
      item.category != 'arme' &&
          item.category != 'armure' &&
          item.category != 'bouclier' &&
          !item.consumable,
  };

  static List<CharacterInventoryItem> apply(
    List<CharacterInventoryItem> items,
    InventoryCategoryFilter filter,
  ) {
    if (filter == InventoryCategoryFilter.all) return items;
    return items.where(filter.matches).toList(growable: false);
  }
}
