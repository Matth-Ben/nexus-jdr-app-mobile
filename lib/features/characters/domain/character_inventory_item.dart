/// Une ligne `character_inventory` résolue pour l'onglet "Inventaire" —
/// `presentation/widgets/character_inventory_tab_body.dart`. Voir
/// `data/character_inventory_row_mapper.dart` pour la résolution depuis
/// `character_inventory`/`items`/`translations`.
///
/// Volontairement une classe simple (pas `freezed`), même précédent que
/// `CharacterSpellEntry`/`CharacterClassFeature`/`CharacterDetailClassRow` :
/// donnée en lecture seule affichée telle quelle, aucune égalité
/// structurelle fine nécessaire.
class CharacterInventoryItem {
  const CharacterInventoryItem({
    required this.id,
    this.itemId,
    required this.name,
    this.category,
    required this.quantity,
    required this.equipped,
    this.totalWeight,
  });

  /// `character_inventory.id` (uuid).
  final String id;

  /// `character_inventory.item_id`, `null` pour un objet personnalisé (texte
  /// libre, `custom_name` renseigné côté base) — voir [isCustom].
  final int? itemId;

  /// Nom affiché : résolu via `translations` (`entity_type = 'item'`) pour
  /// un objet du catalogue, ou `character_inventory.custom_name` pour un
  /// objet personnalisé.
  final String name;

  /// `items.category` ('arme'/'armure'/'bouclier'/'outil'/
  /// 'equipement_general'/'objet_magique'/'monture_vehicule'), `null` pour
  /// un objet personnalisé — aucune catégorie n'existe alors à résoudre (pas
  /// de ligne `items` du tout, voir [isCustom]). Ne pas confondre avec le
  /// `null`/catégorie inconnue de `character_creation/domain
  /// /equipment_category_rules.dart` (qui retombe sur un libellé générique
  /// "Équipement") : ici `null` signifie précisément "objet personnalisé",
  /// affiché avec son propre libellé dédié — voir
  /// `domain/inventory_category_rules.dart`.
  final String? category;

  final int quantity;

  final bool equipped;

  /// Poids total de la ligne (poids unitaire `items.weight` × [quantity]),
  /// déjà multiplié par l'appelant (voir
  /// `CharacterInventoryRowMapper.toCharacterInventoryItems`) — `null` si
  /// inconnu : soit un objet personnalisé (aucune ligne `items`, donc aucun
  /// poids stocké nulle part côté schéma actuel — écart avec la maquette,
  /// qui affiche un poids même pour un objet personnalisé, voir le
  /// commentaire de classe de `character_inventory_tab_body.dart`), soit un
  /// objet du catalogue dont `items.weight` est lui-même `null` en base.
  ///
  /// Exprimé en kilogrammes, pas en livres : `items.weight` est stocké en kg
  /// côté base (voir le commentaire d'unité de
  /// `20260825091000_seed_items_equipment.sql` dans le dépôt web), alors que
  /// la maquette de cet onglet affiche "LBS" — écart de convention d'unité
  /// entre la maquette (probablement calquée sur le SRD anglophone) et le
  /// schéma réel, tranché en faveur du schéma réel plutôt que d'introduire
  /// une conversion approximative kg -> lb. Voir aussi
  /// `domain/inventory_stat_boxes_resolver.dart`.
  final double? totalWeight;

  /// Vrai pour un objet hors catalogue (`item_id` nul) — affiché avec un
  /// badge en pointillés plutôt qu'une icône de catégorie, voir
  /// `presentation/widgets/character_inventory_item_card.dart`.
  bool get isCustom => itemId == null;
}
