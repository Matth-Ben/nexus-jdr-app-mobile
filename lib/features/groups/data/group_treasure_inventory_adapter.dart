import '../../characters/data/character_inventory_row_mapper.dart';
import '../../characters/domain/character_inventory_item.dart';
import '../../characters/domain/currency_kind.dart';
import '../../characters/domain/offline_inventory_writes.dart';
import '../domain/group_treasure_item.dart';

/// Adaptateur entre une entrée du butin commun ([GroupTreasureItem]) et une
/// ligne d'inventaire ([CharacterInventoryItem]) : la carte de la liste, la
/// fiche et le formulaire de modification du butin réutilisent ainsi les
/// composants de l'onglet « Inventaire » (décision 91), et l'attribution
/// recopie toutes les données de l'entrée dans `character_inventory`.
///
/// Passe par la ligne brute `character_inventory` équivalente et par
/// [CharacterInventoryRowMapper] (exactement les mêmes règles de mapping
/// qu'une ligne du serveur), plutôt que de reconstruire l'objet à la main.
abstract final class GroupTreasureInventoryAdapter {
  /// Ligne `character_inventory` brute équivalente à [item] : **non équipée,
  /// non harmonisée** (aucun personnage). [itemRow] : ligne `items` complète
  /// d'un objet du catalogue (fiche, voir
  /// `GroupRepository.fetchTreasureItemDetails`) ; à défaut, l'instantané
  /// catégorie/poids de l'entrée.
  static Map<String, dynamic> toInventoryRow(
    GroupTreasureItem item, {
    Map<String, dynamic>? itemRow,
  }) => {
    'id': item.entryId ?? '',
    'item_id': item.itemId,
    'custom_name': item.isCustom ? item.customName ?? item.displayName : null,
    'quantity': item.quantity,
    'equipped': false,
    'is_attuned': false,
    'notes': null,
    'weapon_slot': null,
    // Surcharge de prix (spec du prix d'un objet modifiable) : lue
    // indépendamment de `item_id`, posable sur une entrée du catalogue
    // comme sur une entrée personnalisée.
    'price_override_amount': item.priceOverrideAmount,
    'price_override_currency': item.priceOverrideCurrency?.code,
    if (item.isCustom) ...{
      'custom_description': item.customDescription,
      'custom_damage_dice': item.customDamageDice,
      'custom_damage_type': item.customDamageType,
      'custom_properties': item.customProperties.isEmpty
          ? null
          : item.customProperties,
      ...?item.enrichment?.toRowColumns(),
    },
    'items':
        itemRow ??
        (item.isCustom
            ? null
            : {'category': item.category, 'weight': item.weight}),
  };

  /// [item] vu comme une ligne d'inventaire. [description] : description
  /// traduite d'un objet du catalogue (lue par `item_id`) ; celle d'un objet
  /// personnalisé est portée par l'entrée elle-même.
  static CharacterInventoryItem toInventoryItem(
    GroupTreasureItem item, {
    Map<String, dynamic>? itemRow,
    String? description,
  }) {
    final key = '${item.itemId}';
    return CharacterInventoryRowMapper.toCharacterInventoryItems(
      [toInventoryRow(item, itemRow: itemRow)],
      names: {if (!item.isCustom) key: item.displayName},
      descriptions: {
        if (!item.isCustom && description != null) key: description,
      },
    ).single;
  }

  /// Corps de l'`INSERT` `character_inventory` d'une attribution : [claimed]
  /// (quantité prise) avec **toutes** ses données d'objet personnalisé
  /// (description, dégâts, propriétés, colonnes `custom_*`), mêmes règles
  /// que l'ajout dans l'inventaire ([InventoryItemWrite.add]). Un objet du
  /// catalogue n'emporte que son `item_id` (contrainte
  /// `character_inventory_custom_fields_only_if_custom`). Un enrichissement
  /// incohérent (jsonb modifié à la main) n'est pas recopié plutôt que de
  /// faire échouer l'`INSERT` sur une contrainte `CHECK`.
  static Map<String, dynamic> toInsertColumns(
    GroupTreasureItem claimed, {
    required String characterId,
    required String inventoryId,
  }) {
    final enrichment = claimed.enrichment;
    final write = claimed.isCustom
        ? InventoryItemWrite.add(
            customName: claimed.customName ?? claimed.displayName,
            quantity: claimed.quantity,
            customDescription: claimed.customDescription,
            customDamageDice: claimed.customDamageDice,
            customDamageType: claimed.customDamageType,
            customProperties: claimed.customProperties,
            enrichment:
                enrichment != null && enrichment.isValid && !enrichment.isEmpty
                ? enrichment
                : null,
          )
        : InventoryItemWrite.add(
            itemId: claimed.itemId,
            quantity: claimed.quantity,
          );
    return {
      ...write.toInsertColumns(
        inventoryId: inventoryId,
        characterId: characterId,
      ),
      // Surcharge de prix (spec du prix d'un objet modifiable) : recopiée à
      // l'attribution comme `category`/`weight` d'un objet du catalogue,
      // pour ne pas la perdre — `InventoryItemWrite.toInsertColumns` ne la
      // porte que pour un objet personnalisé (via `enrichment`), jamais pour
      // un objet du catalogue (`item_id` seul) ; réécrite ici dans les deux
      // cas plutôt que dans `enrichment`, qui reste réservé aux colonnes
      // `custom_*`.
      if (claimed.priceOverrideAmount != null) ...{
        'price_override_amount': claimed.priceOverrideAmount,
        'price_override_currency': claimed.priceOverrideCurrency?.code,
      },
    };
  }
}
