import 'character_inventory_item.dart';
import 'custom_item_enrichment.dart';

/// Règles de l'édition d'un objet personnalisé existant (P7 PR 4) : quelle
/// action proposer, valeurs de départ du formulaire, et garde-fou « type
/// d'un objet équipé ».
enum CustomItemEditMode {
  /// Objet personnalisé typé (`custom_kind` renseigné) : action « Modifier ».
  edit,

  /// Ancien objet personnalisé sans type (`custom_kind` nul) : action
  /// « Enrichir », le formulaire s'ouvre à l'étape « Type d'objet » avec le
  /// type déduit présélectionné.
  enrich,
}

/// Mode d'édition de [item] : `null` pour un objet du catalogue (jamais
/// modifiable : ses colonnes `custom_*` sont nulles par contrainte).
CustomItemEditMode? customItemEditModeOf(CharacterInventoryItem item) {
  if (!item.isCustom) return null;
  return item.customKind == null
      ? CustomItemEditMode.enrich
      : CustomItemEditMode.edit;
}

/// Type effectif de [item] pour le garde-fou ci-dessous : son type résolu
/// (`custom_kind`, ou « arme » pour un ancien objet à dé de dégâts), sinon
/// « autre ».
String effectiveCustomKind(CharacterInventoryItem item) =>
    item.resolvedCustomKind ?? CustomItemKinds.other;

/// `true` si passer [item] au type [newKind] est **interdit** : un objet
/// équipé ne change pas de type (décision P7 PR 4). La CA dépend du type
/// (armure/bouclier équipés), l'emplacement d'arme (`weapon_slot`) aussi :
/// changer le type en laissant `equipped` à vrai donnerait une CA ou un set
/// d'armes incohérents, alors que déséquiper automatiquement modifierait la CA
/// sans que le joueur l'ait demandé. Le joueur doit déséquiper d'abord.
bool isCustomKindChangeBlocked(CharacterInventoryItem item, String newKind) =>
    isCustomKindChangeBlockedFor(
      equipped: item.equipped,
      currentKind: item.resolvedCustomKind,
      newKind: newKind,
    );

/// Même règle que [isCustomKindChangeBlocked] sur des valeurs brutes
/// ([currentKind] `null` : « autre »).
bool isCustomKindChangeBlockedFor({
  required bool equipped,
  required String? currentKind,
  required String newKind,
}) => equipped && (currentKind ?? CustomItemKinds.other) != newKind;

/// Valeurs de départ du formulaire d'édition, relues de l'objet existant.
class CustomItemInitialValues {
  const CustomItemInitialValues({
    required this.name,
    required this.kind,
    required this.equipped,
    required this.mode,
    this.description,
    this.diceCount = 1,
    this.diceSides = 6,
    this.damageType,
    this.properties = const [],
    this.weaponCategory,
    this.weaponRange,
    this.magicBonus = 0,
    this.acBase,
    this.armorCategory,
    this.weight,
    this.requiresAttunement = false,
  });

  final CustomItemEditMode mode;
  final String name;

  /// Type résolu (`null` : ancien objet sans type et sans dé de dégâts, aucune
  /// tuile présélectionnée).
  final String? kind;

  /// L'objet est équipé : son type ne peut pas changer.
  final bool equipped;
  final String? description;
  final int diceCount;
  final int diceSides;
  final String? damageType;
  final List<String> properties;
  final String? weaponCategory;
  final String? weaponRange;
  final int magicBonus;
  final int? acBase;
  final String? armorCategory;

  /// Poids unitaire en kg (`null` : non renseigné).
  final double? weight;
  final bool requiresAttunement;
}

final RegExp _dicePattern = RegExp(r'^(\d+)d(\d+)$');

/// Valeurs de départ pour [item] (objet personnalisé, voir
/// [customItemEditModeOf]). Dé « NdM » illisible : valeurs par défaut (1d6).
CustomItemInitialValues customItemInitialValuesOf(CharacterInventoryItem item) {
  final weapon = item.weaponProperties;
  var diceCount = 1;
  var diceSides = 6;
  final match = _dicePattern.firstMatch(weapon?.damageDice ?? '');
  if (match != null) {
    final count = int.parse(match.group(1)!);
    final sides = int.parse(match.group(2)!);
    if (count >= 1 && sides >= 2) {
      diceCount = count;
      diceSides = sides;
    }
  }
  final description = item.description;
  return CustomItemInitialValues(
    mode: customItemEditModeOf(item) ?? CustomItemEditMode.edit,
    name: item.name,
    kind: item.resolvedCustomKind,
    equipped: item.equipped,
    description: description == null || description.isEmpty
        ? null
        : description,
    diceCount: diceCount,
    diceSides: diceSides,
    damageType: weapon?.damageType,
    properties: weapon?.properties ?? const [],
    weaponCategory: item.customWeaponCategory,
    weaponRange: item.customWeaponRange,
    magicBonus: item.magicBonus,
    acBase: item.customAcBase,
    armorCategory: item.customArmorCategory,
    weight: item.unitWeight,
    requiresAttunement: item.customRequiresAttunement,
  );
}
