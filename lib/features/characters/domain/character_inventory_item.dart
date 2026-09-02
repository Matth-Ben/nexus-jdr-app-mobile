/// Une ligne `character_inventory` résolue pour l'onglet "Inventaire" —
/// `presentation/widgets/character_inventory_tab_body.dart`. Voir
/// `data/character_inventory_row_mapper.dart` pour la résolution depuis
/// `character_inventory`/`items`/`translations`/`weapon_properties`/
/// `armor_properties`.
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
    this.unitWeight,
    this.costAmount,
    this.description,
    this.rarity,
    this.requiresAttunement = false,
    this.consumable = false,
    this.notes,
    this.weaponProperties,
    this.armorProperties,
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

  /// Poids unitaire brut `items.weight` (avant multiplication par
  /// [quantity], contrairement à [totalWeight]) — panneau "Infos", ligne
  /// "Poids unitaire" (`presentation/widgets/item_info_panel.dart`). `null`
  /// pour un objet personnalisé ou si `items.weight` est nul en base, même
  /// convention que [totalWeight] (jamais "0 kg" trompeur), mais **sans** le
  /// garde-fou `quantity > 0` de [totalWeight] : un poids unitaire reste
  /// significatif même pour une ligne à quantité nulle/négative (donnée
  /// incohérente ne devrait pas arriver, voir
  /// `data/character_inventory_row_mapper.dart`).
  final double? unitWeight;

  /// Montant unitaire de `items.cost` (jsonb `{amount, currency}`, `currency`
  /// toujours "gp" — même hypothèse que
  /// `character_creation/domain/item_option.dart`), `null` pour un objet
  /// personnalisé (aucune ligne `items`) ou si `items.cost` lui-même est nul
  /// en base — jamais `0`, même philosophie que [totalWeight] ("rien affiché
  /// plutôt qu'un montant trompeur"), voir `presentation/widgets
  /// /item_info_panel.dart`.
  final double? costAmount;

  /// Description résolue via `translations` (`entity_type = 'item'`,
  /// `field_name = 'description'`) — `null` pour un objet personnalisé
  /// (aucune ligne `items`) ou si aucune traduction n'existe pour cet objet.
  final String? description;

  /// `items.rarity` (text, nullable, aucune valeur peuplée dans le contenu
  /// actuel — colonne prête pour de futurs objets magiques, voir le
  /// commentaire de classe de `data/character_inventory_row_mapper.dart`)
  /// — `null` pour un objet personnalisé ou un objet du catalogue non
  /// magique.
  final String? rarity;

  /// `items.requires_attunement` — toujours `false` pour un objet
  /// personnalisé (aucune ligne `items`).
  final bool requiresAttunement;

  /// `items.consumable` — conditionne l'affichage de l'action "Utiliser"
  /// (voir `presentation/widgets/item_action_sheet.dart`). Toujours `false`
  /// pour un objet personnalisé (aucune ligne `items`), même pour un objet
  /// visiblement consommable saisi en texte libre — pas d'information
  /// structurée à exploiter dans ce cas.
  final bool consumable;

  /// `character_inventory.notes` (text, nullable) — existe pour tout objet,
  /// catalogue ou personnalisé (colonne directe sur `character_inventory`,
  /// pas sur `items`).
  final String? notes;

  /// Caractéristiques d'arme (`weapon_properties`, jointe par `item_id`),
  /// `null` pour tout objet qui n'est pas une arme du catalogue (objet
  /// personnalisé, ou catégorie différente de 'arme').
  final CharacterInventoryWeaponProperties? weaponProperties;

  /// Caractéristiques d'armure/bouclier (`armor_properties`, jointe par
  /// `item_id`), `null` pour tout objet qui n'est pas une armure/un bouclier
  /// du catalogue.
  final CharacterInventoryArmorProperties? armorProperties;

  /// Vrai pour un objet hors catalogue (`item_id` nul) — affiché avec un
  /// badge en pointillés plutôt qu'une icône de catégorie, voir
  /// `presentation/widgets/character_inventory_item_card.dart`.
  bool get isCustom => itemId == null;
}

/// Caractéristiques d'arme (`public.weapon_properties`) d'un
/// [CharacterInventoryItem] — voir le panneau "Infos"
/// (`presentation/widgets/item_info_panel.dart`), section "Dégâts"/
/// "Propriétés"/"Portée", affichée uniquement pour `category == 'arme'`.
///
/// Volontairement une classe simple (pas `freezed`), même précédent que le
/// reste de ce fichier.
class CharacterInventoryWeaponProperties {
  const CharacterInventoryWeaponProperties({
    required this.damageDice,
    required this.damageType,
    required this.properties,
    this.rangeNormal,
    this.rangeMax,
  });

  /// `weapon_properties.damage_dice` (ex. "1d8"), `null` pour une arme sans
  /// dé de dégâts direct (ex. le filet, contenu peuplé vérifié).
  final String? damageDice;

  /// `weapon_properties.damage_type` (ex. "tranchant"), même règle que
  /// [damageDice].
  final String? damageType;

  /// `weapon_properties.properties` (jsonb, liste de propriétés en français
  /// — ex. "légère", "finesse", "polyvalente(1d8)") déjà normalisée en
  /// `List<String>`, jointe par l'appelant avec ", " pour l'affichage (voir
  /// la spec visuelle de la tâche).
  final List<String> properties;

  /// `weapon_properties.range->>'normal'` (mètres) — `null` pour une arme de
  /// corps à corps sans portée (la plupart des armes de mêlée, contenu
  /// peuplé vérifié).
  final double? rangeNormal;

  /// `weapon_properties.range->>'max'`, même règle que [rangeNormal].
  final double? rangeMax;
}

/// Caractéristiques d'armure/bouclier (`public.armor_properties`) d'un
/// [CharacterInventoryItem] — voir le panneau "Infos", section "CA de
/// base"/"Bonus Dex"/"Force requise"/"Désavantage discrétion", affichée
/// uniquement pour `category` ∈ {'armure', 'bouclier'}.
class CharacterInventoryArmorProperties {
  const CharacterInventoryArmorProperties({
    required this.acBase,
    required this.acDexBonus,
    this.strengthRequirement,
    required this.stealthDisadvantage,
  });

  /// `armor_properties.ac_base` — pour un bouclier, un bonus (+2) plutôt
  /// qu'une CA de base à proprement parler (voir le commentaire de la
  /// migration de seed côté dépôt web), affiché tel quel sans distinction
  /// particulière (spec de la tâche : "CA de base" pour toute armure/
  /// bouclier).
  final int acBase;

  /// `armor_properties.ac_dex_bonus` ('aucun'/'max_2'/'illimite') — voir
  /// `domain/inventory_armor_dex_bonus_formatter.dart` pour son libellé FR.
  final String acDexBonus;

  /// `armor_properties.strength_requirement`, `null` si aucune force
  /// minimale requise — omis du panneau "Infos" dans ce cas (spec de la
  /// tâche).
  final int? strengthRequirement;

  final bool stealthDisadvantage;
}
