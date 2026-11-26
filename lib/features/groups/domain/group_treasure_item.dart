import 'dart:convert';

import '../../characters/domain/custom_item_enrichment.dart';

/// Clés jsonb d'une entrée de `group_treasure.items`. Les champs d'un objet
/// personnalisé portent **les mêmes noms que les colonnes de
/// `character_inventory`** (décision 91 : l'attribution les recopie telles
/// quelles) ; `category`/`weight` reprennent ceux de `items` (instantané du
/// catalogue pris à l'ajout, pour la carte de la liste).
abstract final class GroupTreasureItemKeys {
  static const entryId = 'entry_id';
  static const itemId = 'item_id';
  static const customName = 'custom_name';
  static const displayName = 'display_name';
  static const quantity = 'quantity';
  static const category = 'category';
  static const weight = 'weight';
  static const customDescription = 'custom_description';
  static const customDamageDice = 'custom_damage_dice';
  static const customDamageType = 'custom_damage_type';
  static const customProperties = 'custom_properties';
  static const customKind = 'custom_kind';
  static const customMagicBonus = 'custom_magic_bonus';
  static const customWeight = 'custom_weight';
  static const customRequiresAttunement = 'custom_requires_attunement';
  static const customWeaponCategory = 'custom_weapon_category';
  static const customWeaponRange = 'custom_weapon_range';
  static const customAcBase = 'custom_ac_base';
  static const customArmorCategory = 'custom_armor_category';

  /// Toutes les clés lues par cette version ; les autres sont conservées
  /// telles quelles ([GroupTreasureItem.fromJson]).
  static const Set<String> known = {
    entryId,
    itemId,
    customName,
    displayName,
    quantity,
    category,
    weight,
    customDescription,
    customDamageDice,
    customDamageType,
    customProperties,
    customKind,
    customMagicBonus,
    customWeight,
    customRequiresAttunement,
    customWeaponCategory,
    customWeaponRange,
    customAcBase,
    customArmorCategory,
  };
}

/// Une entrée d'objet du butin commun (`group_treasure.items`, jsonb) — voir
/// `data/group_repository.dart` pour la lecture et l'écriture de ce tableau,
/// et `group_treasure_items.dart` pour les règles d'édition.
///
/// Volontairement une classe simple (pas `freezed`), même précédent que
/// `RewardItemDraft`/`InventoryCatalogItem` : donnée déjà résolue,
/// sérialisée telle quelle dans le jsonb.
///
/// **Identité** : [entryId] (UUID client stable, décision 91), attribué aux
/// entrées anciennes à la première écriture du tableau
/// (`GroupTreasureItems.withEntryIds`). Le nom ne sert plus d'identifiant :
/// renommer un objet personnalisé ne doit pas le « perdre ».
///
/// [displayName] est dénormalisé (jamais résolu à la lecture via une
/// jointure `translations`) : le nom est figé au moment de l'ajout. La
/// description et les détails d'un objet **du catalogue** ne sont pas
/// recopiés : ils sont relus par [itemId] à l'ouverture de sa fiche.
///
/// **Compatibilité** : une entrée ancienne (`{item_id?, custom_name?,
/// display_name, quantity}`) se lit, s'affiche et s'attribue comme avant ; une
/// clé inconnue (version plus récente de l'app) est conservée à la réécriture
/// ([extra]) plutôt que perdue.
class GroupTreasureItem {
  const GroupTreasureItem({
    this.entryId,
    this.itemId,
    this.customName,
    required this.displayName,
    required this.quantity,
    this.category,
    this.weight,
    this.customDescription,
    this.customDamageDice,
    this.customDamageType,
    this.customProperties = const [],
    this.enrichment,
    this.extra = const {},
  });

  /// Objet du catalogue : [category]/[weight] sont l'instantané de `items`
  /// (badge et poids de la carte), jamais recopiés à l'attribution.
  const GroupTreasureItem.catalog({
    required int this.itemId,
    required this.displayName,
    required this.quantity,
    this.category,
    this.weight,
  }) : entryId = null,
       customName = null,
       customDescription = null,
       customDamageDice = null,
       customDamageType = null,
       customProperties = const [],
       enrichment = null,
       extra = const {};

  /// Objet personnalisé : mêmes champs que l'ajout dans l'inventaire
  /// (`CharacterRepository.addCustomInventoryItem`). Les textes vides sont
  /// ramenés à `null` ; un [enrichment] sans aucune valeur n'est pas gardé.
  factory GroupTreasureItem.custom({
    String? entryId,
    required String name,
    required int quantity,
    String? description,
    String? damageDice,
    String? damageType,
    List<String> properties = const [],
    CustomItemEnrichment? enrichment,
    Map<String, dynamic> extra = const {},
  }) {
    String? nonEmpty(String? value) =>
        value == null || value.trim().isEmpty ? null : value;
    final kept = enrichment == null || enrichment.isEmpty
        ? null
        // « Harmoniser maintenant » n'a pas de sens sans personnage : jamais
        // gardé (transitoire, voir `CustomItemEnrichment.attuneNow`).
        : CustomItemEnrichment(
            kind: enrichment.kind,
            magicBonus: enrichment.magicBonus,
            weight: enrichment.weight,
            requiresAttunement: enrichment.requiresAttunement,
            weaponCategory: enrichment.weaponCategory,
            weaponRange: enrichment.weaponRange,
            acBase: enrichment.acBase,
            armorCategory: enrichment.armorCategory,
          );
    return GroupTreasureItem(
      entryId: entryId,
      customName: name,
      displayName: name,
      quantity: quantity,
      customDescription: nonEmpty(description),
      customDamageDice: nonEmpty(damageDice),
      customDamageType: nonEmpty(damageType),
      customProperties: properties,
      enrichment: kept,
      extra: extra,
    );
  }

  /// Identifiant stable de l'entrée (`entry_id`) ; `null` pour une entrée
  /// ancienne pas encore réécrite.
  final String? entryId;
  final int? itemId;
  final String? customName;
  final String displayName;
  final int quantity;

  /// `items.category` d'un objet du catalogue (instantané pris à l'ajout),
  /// `null` pour un objet personnalisé ou une entrée ancienne.
  final String? category;

  /// `items.weight` d'un objet du catalogue (kg par unité, instantané pris à
  /// l'ajout), `null` si inconnu.
  final double? weight;

  final String? customDescription;
  final String? customDamageDice;
  final String? customDamageType;
  final List<String> customProperties;

  /// Colonnes `custom_*` enrichies (type, bonus magique, poids,
  /// harmonisation, arme, armure) ; `null` pour un objet du catalogue ou un
  /// objet personnalisé sans type.
  final CustomItemEnrichment? enrichment;

  /// Valeurs jsonb réécrites telles quelles : clés inconnues de cette version
  /// **et** valeurs d'une clé connue d'un type inattendu ou hors de leur
  /// ensemble (ex. futur type d'objet), ignorées à l'affichage (voir
  /// [fromJson]). Une telle valeur brute reste écrite tant que l'app ne donne
  /// pas une vraie valeur à ce champ.
  final Map<String, dynamic> extra;

  /// Seulement les clés inconnues de [extra] : ce qu'une modification
  /// complète de l'objet (formulaire) garde, les champs connus étant alors
  /// tous ressaisis.
  Map<String, dynamic> get unknownFields => {
    for (final entry in extra.entries)
      if (!GroupTreasureItemKeys.known.contains(entry.key))
        entry.key: entry.value,
  };

  bool get isCustom => itemId == null;

  GroupTreasureItem copyWith({int? quantity, String? entryId}) =>
      GroupTreasureItem(
        entryId: entryId ?? this.entryId,
        itemId: itemId,
        customName: customName,
        displayName: displayName,
        quantity: quantity ?? this.quantity,
        category: category,
        weight: weight,
        customDescription: customDescription,
        customDamageDice: customDamageDice,
        customDamageType: customDamageType,
        customProperties: customProperties,
        enrichment: enrichment,
        extra: extra,
      );

  /// Même contenu que [other], hors [entryId] et [quantity] : deux ajouts du
  /// même objet se fusionnent (`GroupTreasureItems.merge`).
  bool sameContentAs(GroupTreasureItem other) =>
      _canonical(withIdentity: false) == other._canonical(withIdentity: false);

  Map<String, dynamic> toJson() => _toJson(withIdentity: true);

  Map<String, dynamic> _toJson({required bool withIdentity}) {
    final e = enrichment;
    final known = <String, dynamic>{
      GroupTreasureItemKeys.entryId: ?entryId,
      GroupTreasureItemKeys.itemId: ?itemId,
      GroupTreasureItemKeys.customName: ?customName,
      GroupTreasureItemKeys.displayName: displayName,
      GroupTreasureItemKeys.quantity: quantity,
      GroupTreasureItemKeys.category: ?category,
      GroupTreasureItemKeys.weight: ?weight,
      GroupTreasureItemKeys.customDescription: ?customDescription,
      GroupTreasureItemKeys.customDamageDice: ?customDamageDice,
      GroupTreasureItemKeys.customDamageType: ?customDamageType,
      if (customProperties.isNotEmpty)
        GroupTreasureItemKeys.customProperties: customProperties,
      if (e != null) ...{
        GroupTreasureItemKeys.customKind: ?e.kind,
        if (e.magicBonus > 0)
          GroupTreasureItemKeys.customMagicBonus: e.magicBonus,
        GroupTreasureItemKeys.customWeight: ?e.weight,
        if (e.requiresAttunement)
          GroupTreasureItemKeys.customRequiresAttunement: true,
        GroupTreasureItemKeys.customWeaponCategory: ?e.weaponCategory,
        GroupTreasureItemKeys.customWeaponRange: ?e.weaponRange,
        GroupTreasureItemKeys.customAcBase: ?e.acBase,
        GroupTreasureItemKeys.customArmorCategory: ?e.armorCategory,
      },
    };
    final json = <String, dynamic>{
      ...extra,
      for (final entry in known.entries)
        if (!_keepsRawValue(entry.key, entry.value)) entry.key: entry.value,
    };
    if (!withIdentity) {
      json
        ..remove(GroupTreasureItemKeys.entryId)
        ..remove(GroupTreasureItemKeys.quantity);
    }
    return json;
  }

  /// Les champs toujours écrits (nom affiché, quantité) gardent leur valeur
  /// brute conservée ([extra]) tant qu'ils sont à leur valeur neutre ; les
  /// autres champs neutres ne sont pas écrits, la valeur brute reste donc.
  bool _keepsRawValue(String key, Object? value) =>
      extra.containsKey(key) &&
      ((key == GroupTreasureItemKeys.displayName && value == '') ||
          (key == GroupTreasureItemKeys.quantity && value == 0));

  String _canonical({required bool withIdentity}) =>
      jsonEncode(_toJson(withIdentity: withIdentity));

  /// Lecture tolérante d'une entrée jsonb, jamais d'exception : une clé
  /// absente donne la valeur neutre ; une valeur d'un type inattendu, ou une
  /// valeur `custom_*` hors de son ensemble (ex. futur type d'objet), est
  /// ignorée pour l'affichage mais **conservée telle quelle** dans [extra]
  /// pour la réécriture, comme une clé inconnue.
  static GroupTreasureItem fromJson(Map<String, dynamic> json) {
    final extra = <String, dynamic>{
      for (final entry in json.entries)
        if (!GroupTreasureItemKeys.known.contains(entry.key))
          entry.key: entry.value,
    };

    T? read<T extends Object>(String key, T? Function(Object raw) parse) {
      final raw = json[key];
      if (raw == null) return null;
      final value = parse(raw);
      if (value == null) extra[key] = raw;
      return value;
    }

    String? text(String key) => read(key, (raw) => raw is String ? raw : null);
    String? nonEmpty(String? value) =>
        value == null || value.isEmpty ? null : value;
    String? oneOf(String key, Set<String> allowed) =>
        read(key, (raw) => raw is String && allowed.contains(raw) ? raw : null);
    int? whole(String key) =>
        read(key, (raw) => raw is num ? raw.toInt() : null);

    final enrichment = CustomItemEnrichment(
      kind: oneOf(GroupTreasureItemKeys.customKind, CustomItemKinds.all),
      magicBonus:
          read(
            GroupTreasureItemKeys.customMagicBonus,
            (raw) => isValidCustomMagicBonus(raw) ? raw as int : null,
          ) ??
          0,
      weight: read(
        GroupTreasureItemKeys.customWeight,
        (raw) => isValidCustomWeight(raw) ? (raw as num).toDouble() : null,
      ),
      requiresAttunement:
          read(
            GroupTreasureItemKeys.customRequiresAttunement,
            (raw) => raw is bool ? raw : null,
          ) ??
          false,
      weaponCategory: oneOf(
        GroupTreasureItemKeys.customWeaponCategory,
        CustomWeaponCategories.all,
      ),
      weaponRange: oneOf(
        GroupTreasureItemKeys.customWeaponRange,
        CustomWeaponRanges.all,
      ),
      acBase: read(
        GroupTreasureItemKeys.customAcBase,
        (raw) => isValidCustomAcBase(raw) ? raw as int : null,
      ),
      armorCategory: oneOf(
        GroupTreasureItemKeys.customArmorCategory,
        CustomArmorCategories.all,
      ),
    );

    return GroupTreasureItem(
      entryId: nonEmpty(text(GroupTreasureItemKeys.entryId)),
      itemId: whole(GroupTreasureItemKeys.itemId),
      customName: text(GroupTreasureItemKeys.customName),
      displayName: text(GroupTreasureItemKeys.displayName) ?? '',
      quantity: whole(GroupTreasureItemKeys.quantity) ?? 0,
      category: nonEmpty(text(GroupTreasureItemKeys.category)),
      weight: read(
        GroupTreasureItemKeys.weight,
        (raw) => raw is num ? raw.toDouble() : null,
      ),
      customDescription: nonEmpty(
        text(GroupTreasureItemKeys.customDescription),
      ),
      customDamageDice: nonEmpty(text(GroupTreasureItemKeys.customDamageDice)),
      customDamageType: nonEmpty(text(GroupTreasureItemKeys.customDamageType)),
      // Liste mêlant d'autres types : ignorée en entier pour l'affichage,
      // conservée telle quelle.
      customProperties:
          read(
            GroupTreasureItemKeys.customProperties,
            (raw) => raw is List && raw.every((value) => value is String)
                ? List<String>.from(raw)
                : null,
          ) ??
          const [],
      enrichment: enrichment.isEmpty ? null : enrichment,
      extra: extra,
    );
  }

  /// Égalité sur le contenu sérialisé complet (identité et quantité
  /// comprises) : c'est elle qui décide qu'une entrée relue « n'a pas
  /// changé » avant une écriture (`GroupTreasureItems.indexOfUnchanged`).
  @override
  bool operator ==(Object other) =>
      other is GroupTreasureItem &&
      other._canonical(withIdentity: true) == _canonical(withIdentity: true);

  @override
  int get hashCode => _canonical(withIdentity: true).hashCode;
}
