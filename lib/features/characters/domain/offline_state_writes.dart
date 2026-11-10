import 'weapon_slot.dart';

/// Réglages d'état **absolus** rendus hors-ligne-capables (T5a, P15) : valeurs
/// par cible (un sort, un objet) ou par personnage (inspiration, bonus de CA),
/// mises en file avec « dernière valeur gagnante ». Ce fichier porte le format
/// des trois payloads de file et leur **validation stricte** : un payload qui
/// ne passe pas ces analyseurs n'est JAMAIS rejoué ni superposé (la ligne est
/// supprimée de la file par le synchroniseur), sinon il bloquerait le compteur
/// de synchro, la déconnexion et la suppression de compte.
///
/// Règle commune : les clés connues doivent avoir le bon type ; au moins une
/// clé connue doit être présente ; les clés inconnues (version plus récente de
/// l'app) sont ignorées sans invalider la ligne.

/// Bornes (incluses) du bonus de CA manuel. La feuille d'ajustement n'impose
/// aucune borne ; au-delà de cette plage large, la valeur est considérée
/// comme corrompue et n'est jamais écrite.
const int armorClassBonusMin = -99;
const int armorClassBonusMax = 99;

/// Clés des payloads de file.
abstract final class OfflineStateKeys {
  static const prepared = 'prepared';
  static const favorite = 'favorite';
  static const equipped = 'equipped';
  static const weaponSlot = 'weaponSlot';
  static const attuned = 'attuned';
  static const inspiration = 'inspiration';
  static const armorClassBonus = 'armorClassBonus';
}

/// Changement d'un sort : préparé et/ou favori (au moins un des deux).
class SpellStatePatch {
  const SpellStatePatch({this.prepared, this.favorite});

  final bool? prepared;
  final bool? favorite;

  Map<String, dynamic> toPayload() => {
    OfflineStateKeys.prepared: ?prepared,
    OfflineStateKeys.favorite: ?favorite,
  };

  /// Fusion « dernière valeur gagnante » champ par champ.
  SpellStatePatch merge(SpellStatePatch newer) => SpellStatePatch(
    prepared: newer.prepared ?? prepared,
    favorite: newer.favorite ?? favorite,
  );
}

/// Changement d'un objet d'inventaire : équipé, set d'arme, harmonisé (au
/// moins un champ).
class InventoryStatePatch {
  const InventoryStatePatch({
    this.equipped,
    this.hasWeaponSlot = false,
    this.weaponSlot,
    this.attuned,
  });

  final bool? equipped;

  /// `true` si le set d'arme est **touché** par ce changement (y compris pour
  /// l'effacer : [weaponSlot] `null`) — distingue « ne pas toucher » de
  /// « mettre à `null` ».
  final bool hasWeaponSlot;
  final WeaponSlot? weaponSlot;
  final bool? attuned;

  Map<String, dynamic> toPayload() => {
    OfflineStateKeys.equipped: ?equipped,
    if (hasWeaponSlot) OfflineStateKeys.weaponSlot: weaponSlot?.value,
    OfflineStateKeys.attuned: ?attuned,
  };

  InventoryStatePatch merge(InventoryStatePatch newer) => InventoryStatePatch(
    equipped: newer.equipped ?? equipped,
    hasWeaponSlot: newer.hasWeaponSlot || hasWeaponSlot,
    weaponSlot: newer.hasWeaponSlot ? newer.weaponSlot : weaponSlot,
    attuned: newer.attuned ?? attuned,
  );

  /// Colonnes de `character_inventory` à écrire.
  Map<String, dynamic> toColumns() => {
    'equipped': ?equipped,
    if (hasWeaponSlot) 'weapon_slot': weaponSlot?.value,
    'is_attuned': ?attuned,
  };
}

/// Changement des réglages du personnage : inspiration et/ou bonus de CA.
class CharacterFlagsPatch {
  const CharacterFlagsPatch({this.inspiration, this.armorClassBonus});

  final bool? inspiration;
  final int? armorClassBonus;

  Map<String, dynamic> toPayload() => {
    OfflineStateKeys.inspiration: ?inspiration,
    OfflineStateKeys.armorClassBonus: ?armorClassBonus,
  };

  CharacterFlagsPatch merge(CharacterFlagsPatch newer) => CharacterFlagsPatch(
    inspiration: newer.inspiration ?? inspiration,
    armorClassBonus: newer.armorClassBonus ?? armorClassBonus,
  );

  /// Colonnes de `characters` à écrire.
  Map<String, dynamic> toColumns() => {
    'inspiration': ?inspiration,
    'armor_class_bonus': ?armorClassBonus,
  };
}

/// `spellId` d'un `targetId` de file `spellState`, `null` si ce n'est pas un
/// entier strictement positif.
int? parseSpellTargetId(String targetId) {
  final id = int.tryParse(targetId);
  if (id == null || id <= 0 || id.toString() != targetId) return null;
  return id;
}

/// Un `targetId` d'objet d'inventaire (identifiant de ligne) doit être non vide.
bool isValidInventoryTargetId(String targetId) => targetId.trim().isNotEmpty;

/// Analyse stricte d'un payload `spellState` ; `null` s'il est invalide.
SpellStatePatch? parseSpellStatePayload(Object? raw) {
  if (raw is! Map) return null;
  final prepared = raw[OfflineStateKeys.prepared];
  final favorite = raw[OfflineStateKeys.favorite];
  if (raw.containsKey(OfflineStateKeys.prepared) && prepared is! bool) {
    return null;
  }
  if (raw.containsKey(OfflineStateKeys.favorite) && favorite is! bool) {
    return null;
  }
  if (prepared == null && favorite == null) return null;
  return SpellStatePatch(
    prepared: prepared as bool?,
    favorite: favorite as bool?,
  );
}

/// Analyse stricte d'un payload `inventoryState` ; `null` s'il est invalide
/// (type incorrect, set d'arme inconnu, ou set d'arme non nul alors que
/// l'objet est explicitement non équipé).
InventoryStatePatch? parseInventoryStatePayload(Object? raw) {
  if (raw is! Map) return null;
  final equipped = raw[OfflineStateKeys.equipped];
  final attuned = raw[OfflineStateKeys.attuned];
  if (raw.containsKey(OfflineStateKeys.equipped) && equipped is! bool) {
    return null;
  }
  if (raw.containsKey(OfflineStateKeys.attuned) && attuned is! bool) {
    return null;
  }
  final hasWeaponSlot = raw.containsKey(OfflineStateKeys.weaponSlot);
  WeaponSlot? weaponSlot;
  if (hasWeaponSlot) {
    final rawSlot = raw[OfflineStateKeys.weaponSlot];
    if (rawSlot != null) {
      if (rawSlot is! String) return null;
      weaponSlot = WeaponSlot.fromValue(rawSlot);
      if (weaponSlot == null) return null;
      if (equipped == false) return null;
    }
  }
  if (equipped == null && attuned == null && !hasWeaponSlot) return null;
  return InventoryStatePatch(
    equipped: equipped as bool?,
    hasWeaponSlot: hasWeaponSlot,
    weaponSlot: weaponSlot,
    attuned: attuned as bool?,
  );
}

/// Analyse stricte d'un payload `characterFlags` ; `null` s'il est invalide
/// (type incorrect, bonus de CA hors de [armorClassBonusMin]..
/// [armorClassBonusMax]).
CharacterFlagsPatch? parseCharacterFlagsPayload(Object? raw) {
  if (raw is! Map) return null;
  final inspiration = raw[OfflineStateKeys.inspiration];
  final bonus = raw[OfflineStateKeys.armorClassBonus];
  if (raw.containsKey(OfflineStateKeys.inspiration) && inspiration is! bool) {
    return null;
  }
  if (raw.containsKey(OfflineStateKeys.armorClassBonus)) {
    if (bonus is! int ||
        bonus < armorClassBonusMin ||
        bonus > armorClassBonusMax) {
      return null;
    }
  }
  if (inspiration == null && bonus == null) return null;
  return CharacterFlagsPatch(
    inspiration: inspiration as bool?,
    armorClassBonus: bonus as int?,
  );
}
