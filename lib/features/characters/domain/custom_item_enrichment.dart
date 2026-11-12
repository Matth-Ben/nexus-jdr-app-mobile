/// Caractéristiques enrichies d'un objet personnalisé (P7) : type d'objet,
/// bonus magique, poids, harmonisation, catégorie/portée d'arme (et, réservés
/// à la PR 3, CA de base/catégorie d'armure). Ce sont les colonnes `custom_*`
/// de `character_inventory` ajoutées par la migration P7 du dépôt web.
///
/// Ce fichier porte les **valeurs admises** et leur **validation stricte**,
/// appliquée à l'enfilage ET au rejeu de la file hors ligne
/// (`offline_inventory_writes.dart`) : une valeur hors ensemble serait refusée
/// par les `CHECK` de la table et bloquerait la file.
abstract final class CustomItemKinds {
  static const weapon = 'arme';
  static const armor = 'armure';
  static const shield = 'bouclier';
  static const other = 'autre';

  static const Set<String> all = {weapon, armor, shield, other};

  /// Types qui acceptent un bonus magique (`CHECK` : non nul seulement pour
  /// arme/armure/bouclier).
  static const Set<String> withMagicBonus = {weapon, armor, shield};
}

abstract final class CustomWeaponCategories {
  static const common = 'courante';
  static const martial = 'guerre';
  static const Set<String> all = {common, martial};
}

abstract final class CustomWeaponRanges {
  static const melee = 'melee';
  static const ranged = 'distance';
  static const Set<String> all = {melee, ranged};
}

abstract final class CustomArmorCategories {
  static const light = 'legere';
  static const medium = 'intermediaire';
  static const heavy = 'lourde';
  static const Set<String> all = {light, medium, heavy};
}

/// Les 13 types de dégâts d'une arme personnalisée, valeur stockée en
/// français minuscule singulier (comme `weapon_properties.damage_type`) —
/// dégâts physiques d'abord.
abstract final class CustomDamageTypes {
  static const List<String> all = [
    'tranchant',
    'perforant',
    'contondant',
    'acide',
    'feu',
    'foudre',
    'froid',
    'force',
    'nécrotique',
    'poison',
    'psychique',
    'radiant',
    'tonnerre',
  ];
}

/// Bornes (identiques en saisie, à l'enfilage et au rejeu).
const int customMagicBonusMax = 3;
const int customAcBaseMax = 30;
const double customWeightMax = 9999.99;
const int customDiceCountMax = 10;

bool isValidCustomMagicBonus(Object? value) =>
    value is int && value >= 0 && value <= customMagicBonusMax;

bool isValidCustomAcBase(Object? value) =>
    value is int && value >= 0 && value <= customAcBaseMax;

/// Poids en kg par unité : nombre fini dans `0..9999,99` (`numeric(7,2)`).
bool isValidCustomWeight(Object? value) =>
    value is num &&
    value.isFinite &&
    value >= 0 &&
    value.toDouble() <= customWeightMax;

/// Enrichissement d'un objet personnalisé tel qu'écrit en base. Un champ
/// `null`/neutre n'est jamais envoyé (pas de `null` explicite, même
/// convention que le reste de l'ajout).
class CustomItemEnrichment {
  const CustomItemEnrichment({
    this.kind,
    this.magicBonus = 0,
    this.weight,
    this.requiresAttunement = false,
    this.weaponCategory,
    this.weaponRange,
    this.acBase,
    this.armorCategory,
    this.attuneNow = false,
  });

  /// `custom_kind` : voir [CustomItemKinds].
  final String? kind;

  /// `custom_magic_bonus` (0..3 ; 0 n'est pas écrit : `null` en base = 0).
  final int magicBonus;

  /// `custom_weight` (kg par unité), `null` = non renseigné.
  final double? weight;

  /// `custom_requires_attunement`.
  final bool requiresAttunement;

  /// `custom_weapon_category` : voir [CustomWeaponCategories].
  final String? weaponCategory;

  /// `custom_weapon_range` : voir [CustomWeaponRanges].
  final String? weaponRange;

  /// `custom_ac_base` : CA de base d'une armure, bonus de CA d'un bouclier.
  final int? acBase;

  /// `custom_armor_category` : catégorie d'une armure (jamais d'un bouclier).
  final String? armorCategory;

  /// « Harmoniser maintenant » : **transitoire**, jamais écrit dans une
  /// colonne `custom_*` ni dans la clé de file ; le repository le traduit en
  /// état initial `is_attuned`.
  final bool attuneNow;

  /// `true` si aucune colonne `custom_*` n'est à écrire.
  bool get isEmpty =>
      kind == null &&
      magicBonus == 0 &&
      weight == null &&
      !requiresAttunement &&
      weaponCategory == null &&
      weaponRange == null &&
      acBase == null &&
      armorCategory == null;

  /// Validité (mêmes règles que les `CHECK` de la table) : valeurs dans leurs
  /// ensembles/bornes, bonus magique seulement pour arme/armure/bouclier,
  /// catégorie/portée d'arme seulement pour une arme, armure => CA de base +
  /// catégorie, bouclier => CA de base. (`only_if_custom` : un objet du
  /// catalogue est refusé par `parseInventoryItemPayload`.)
  bool get isValid {
    if (kind != null && !CustomItemKinds.all.contains(kind)) return false;
    if (!isValidCustomMagicBonus(magicBonus)) return false;
    if (magicBonus > 0 && !CustomItemKinds.withMagicBonus.contains(kind)) {
      return false;
    }
    if (weight != null && !isValidCustomWeight(weight)) return false;
    if (weaponCategory != null &&
        !CustomWeaponCategories.all.contains(weaponCategory)) {
      return false;
    }
    if (weaponRange != null && !CustomWeaponRanges.all.contains(weaponRange)) {
      return false;
    }
    if (acBase != null && !isValidCustomAcBase(acBase)) return false;
    if (armorCategory != null &&
        !CustomArmorCategories.all.contains(armorCategory)) {
      return false;
    }
    // Contrainte `character_inventory_custom_weapon_fields_kind` : catégorie et
    // portée d'arme réservées au type « arme » (un type nul est refusé).
    if ((weaponCategory != null || weaponRange != null) &&
        kind != CustomItemKinds.weapon) {
      return false;
    }
    if (kind == CustomItemKinds.armor &&
        (acBase == null || armorCategory == null)) {
      return false;
    }
    // La catégorie d'armure (légère/intermédiaire/lourde) n'existe que pour
    // une armure : jamais écrite pour un bouclier (sa maîtrise se déduit du
    // type) ni pour un autre type.
    if (armorCategory != null && kind != CustomItemKinds.armor) return false;
    if (kind == CustomItemKinds.shield && acBase == null) return false;
    return true;
  }

  /// Clés de payload de file (uniquement les valeurs non neutres).
  Map<String, dynamic> toPayload() => {
    CustomItemPayloadKeys.kind: ?kind,
    if (magicBonus > 0) CustomItemPayloadKeys.magicBonus: magicBonus,
    CustomItemPayloadKeys.weight: ?weight,
    if (requiresAttunement) CustomItemPayloadKeys.requiresAttunement: true,
    CustomItemPayloadKeys.weaponCategory: ?weaponCategory,
    CustomItemPayloadKeys.weaponRange: ?weaponRange,
    CustomItemPayloadKeys.acBase: ?acBase,
    CustomItemPayloadKeys.armorCategory: ?armorCategory,
  };

  /// Colonnes de l'`INSERT` (valeurs non neutres seulement).
  Map<String, dynamic> toInsertColumns() => {
    'custom_kind': ?kind,
    if (magicBonus > 0) 'custom_magic_bonus': magicBonus,
    'custom_weight': ?weight,
    if (requiresAttunement) 'custom_requires_attunement': true,
    'custom_weapon_category': ?weaponCategory,
    'custom_weapon_range': ?weaponRange,
    'custom_ac_base': ?acBase,
    'custom_armor_category': ?armorCategory,
  };

  /// Colonnes de la ligne brute équivalente (superposition hors ligne) : même
  /// forme qu'une ligne renvoyée par PostgREST, lue par
  /// `CharacterInventoryRowMapper`.
  Map<String, dynamic> toRowColumns() => {
    'custom_kind': kind,
    'custom_magic_bonus': magicBonus > 0 ? magicBonus : null,
    'custom_weight': weight,
    'custom_requires_attunement': requiresAttunement,
    'custom_weapon_category': weaponCategory,
    'custom_weapon_range': weaponRange,
    'custom_ac_base': acBase,
    'custom_armor_category': armorCategory,
  };
}

abstract final class CustomItemPayloadKeys {
  static const kind = 'customKind';
  static const magicBonus = 'customMagicBonus';
  static const weight = 'customWeight';
  static const requiresAttunement = 'customRequiresAttunement';
  static const weaponCategory = 'customWeaponCategory';
  static const weaponRange = 'customWeaponRange';
  static const acBase = 'customAcBase';
  static const armorCategory = 'customArmorCategory';

  static const List<String> all = [
    kind,
    magicBonus,
    weight,
    requiresAttunement,
    weaponCategory,
    weaponRange,
    acBase,
    armorCategory,
  ];
}

/// Résultat de [parseCustomItemEnrichment].
class ParsedCustomItemEnrichment {
  const ParsedCustomItemEnrichment._(this.isValid, this.value);

  static const invalid = ParsedCustomItemEnrichment._(false, null);

  /// `false` : une clé présente est d'un mauvais type/hors ensemble.
  final bool isValid;

  /// `null` si aucune clé d'enrichissement n'est présente (ancien payload).
  final CustomItemEnrichment? value;
}

/// Lit les clés d'enrichissement d'un payload d'ajout de file. Aucune clé :
/// valide, [ParsedCustomItemEnrichment.value] `null` (ancien payload rejoué
/// tel quel). Une clé présente doit être du bon type et dans son ensemble ;
/// la cohérence ([CustomItemEnrichment.isValid]) est aussi exigée.
ParsedCustomItemEnrichment parseCustomItemEnrichment(
  Map<dynamic, dynamic> raw,
) {
  if (!CustomItemPayloadKeys.all.any(raw.containsKey)) {
    return const ParsedCustomItemEnrichment._(true, null);
  }
  String? text(String key, Set<String> allowed) {
    if (!raw.containsKey(key)) return null;
    final value = raw[key];
    if (value is! String || !allowed.contains(value)) {
      throw const FormatException('invalid');
    }
    return value;
  }

  try {
    final kind = text(CustomItemPayloadKeys.kind, CustomItemKinds.all);
    final weaponCategory = text(
      CustomItemPayloadKeys.weaponCategory,
      CustomWeaponCategories.all,
    );
    final weaponRange = text(
      CustomItemPayloadKeys.weaponRange,
      CustomWeaponRanges.all,
    );
    final armorCategory = text(
      CustomItemPayloadKeys.armorCategory,
      CustomArmorCategories.all,
    );

    var magicBonus = 0;
    if (raw.containsKey(CustomItemPayloadKeys.magicBonus)) {
      final value = raw[CustomItemPayloadKeys.magicBonus];
      if (!isValidCustomMagicBonus(value)) {
        return ParsedCustomItemEnrichment.invalid;
      }
      magicBonus = value as int;
    }
    int? acBase;
    if (raw.containsKey(CustomItemPayloadKeys.acBase)) {
      final value = raw[CustomItemPayloadKeys.acBase];
      if (!isValidCustomAcBase(value)) {
        return ParsedCustomItemEnrichment.invalid;
      }
      acBase = value as int;
    }
    double? weight;
    if (raw.containsKey(CustomItemPayloadKeys.weight)) {
      final value = raw[CustomItemPayloadKeys.weight];
      if (!isValidCustomWeight(value)) {
        return ParsedCustomItemEnrichment.invalid;
      }
      weight = (value as num).toDouble();
    }
    var requiresAttunement = false;
    if (raw.containsKey(CustomItemPayloadKeys.requiresAttunement)) {
      final value = raw[CustomItemPayloadKeys.requiresAttunement];
      if (value is! bool) return ParsedCustomItemEnrichment.invalid;
      requiresAttunement = value;
    }

    final enrichment = CustomItemEnrichment(
      kind: kind,
      magicBonus: magicBonus,
      weight: weight,
      requiresAttunement: requiresAttunement,
      weaponCategory: weaponCategory,
      weaponRange: weaponRange,
      acBase: acBase,
      armorCategory: armorCategory,
    );
    if (!enrichment.isValid) return ParsedCustomItemEnrichment.invalid;
    return ParsedCustomItemEnrichment._(true, enrichment);
  } on FormatException {
    return ParsedCustomItemEnrichment.invalid;
  }
}
