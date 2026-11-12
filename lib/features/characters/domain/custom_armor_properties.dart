import 'character_inventory_item.dart';
import 'custom_item_enrichment.dart';

/// Construit les [CharacterInventoryArmorProperties] d'un objet personnalisé
/// de type armure ou bouclier (P7), pour que [ArmorClassCalculator], la liste
/// des personnages (P18), les groupes et la maîtrise d'armure (P10) le traitent
/// exactement comme une armure du catalogue (un seul chemin de calcul).
///
/// - Armure : `acBase = custom_ac_base`, `acDexBonus` selon la catégorie
///   (légère `illimite`, intermédiaire `max_2`, lourde `aucun`, mêmes valeurs
///   que `armor_properties.ac_dex_bonus`), emplacement `armure`.
/// - Bouclier : `acBase = custom_ac_base` (c'est un bonus, comme le +2 d'un
///   bouclier du catalogue), jamais de Dextérité, emplacement `bouclier`. La
///   catégorie d'armure n'existe pas pour un bouclier et n'est pas lue.
///
/// Retourne `null` si les données ne suffisent pas (type autre qu'armure/
/// bouclier, CA de base absente, catégorie d'armure absente ou inconnue pour
/// une armure) : le code ne devine jamais, l'objet n'entre alors pas dans la
/// CA et sa maîtrise reste indécidable.
CharacterInventoryArmorProperties? customArmorPropertiesOf({
  required String? kind,
  required int? acBase,
  required String? armorCategory,
}) {
  if (acBase == null) return null;
  if (kind == CustomItemKinds.shield) {
    return CharacterInventoryArmorProperties(
      acBase: acBase,
      acDexBonus: 'aucun',
      stealthDisadvantage: false,
      slot: 'bouclier',
    );
  }
  if (kind != CustomItemKinds.armor) return null;
  final dexBonus = switch (armorCategory) {
    CustomArmorCategories.light => 'illimite',
    CustomArmorCategories.medium => 'max_2',
    CustomArmorCategories.heavy => 'aucun',
    _ => null,
  };
  if (dexBonus == null) return null;
  return CharacterInventoryArmorProperties(
    acBase: acBase,
    acDexBonus: dexBonus,
    stealthDisadvantage: false,
    slot: 'armure',
  );
}
