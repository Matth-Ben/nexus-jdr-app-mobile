import 'currency_kind.dart';
import 'custom_item_enrichment.dart' show isValidPriceOverrideAmount;
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

/// Plage (incluse) d'un `integer` Postgres : seule contrainte de
/// `characters.armor_class_bonus` (`integer not null default 0`, sans autre
/// plage). Validée à l'enfilage ET au rejeu.
const int postgresIntMin = -2147483648;
const int postgresIntMax = 2147483647;

/// Clés des payloads de file.
abstract final class OfflineStateKeys {
  static const prepared = 'prepared';
  static const equipped = 'equipped';
  static const weaponSlot = 'weaponSlot';
  static const attuned = 'attuned';
  static const inspiration = 'inspiration';
  static const armorClassBonus = 'armorClassBonus';
  static const priceOverrideAmount = 'priceOverrideAmount';
  static const priceOverrideCurrency = 'priceOverrideCurrency';
}

/// Changement d'un sort : son état préparé. Les anciennes lignes de file qui
/// portaient aussi un `favorite` (système de favoris retiré) l'ignorent.
class SpellStatePatch {
  const SpellStatePatch({this.prepared});

  final bool? prepared;

  Map<String, dynamic> toPayload() => {OfflineStateKeys.prepared: ?prepared};

  /// Fusion « dernière valeur gagnante ».
  SpellStatePatch merge(SpellStatePatch newer) =>
      SpellStatePatch(prepared: newer.prepared ?? prepared);
}

/// Changement d'un objet d'inventaire : équipé, set d'arme, harmonisé, ou
/// surcharge de prix (au moins un champ).
///
/// [hasPriceOverride]/[priceOverrideAmount]/[priceOverrideCurrency] : spec du
/// prix d'un objet modifiable, §2b/§2d — réglage d'état absolu de
/// `price_override_amount`/`price_override_currency`, posable sur **tout**
/// objet d'inventaire (catalogue ou personnalisé, contrairement aux colonnes
/// `custom_*` de `custom_item_enrichment.dart`, réservées à un objet
/// personnalisé via la file `inventoryItem`) : même mécanisme que
/// [attuned]/[equipped], qui fonctionnent déjà sur les deux, voir
/// `CharacterRepository.setInventoryItemPriceOverride`.
class InventoryStatePatch {
  const InventoryStatePatch({
    this.equipped,
    this.hasWeaponSlot = false,
    this.weaponSlot,
    this.attuned,
    this.hasPriceOverride = false,
    this.priceOverrideAmount,
    this.priceOverrideCurrency,
  });

  final bool? equipped;

  /// `true` si le set d'arme est **touché** par ce changement (y compris pour
  /// l'effacer : [weaponSlot] `null`) — distingue « ne pas toucher » de
  /// « mettre à `null` ».
  final bool hasWeaponSlot;
  final WeaponSlot? weaponSlot;
  final bool? attuned;

  /// `true` si la surcharge de prix est **touchée** par ce changement (y
  /// compris pour la retirer : [priceOverrideAmount]/[priceOverrideCurrency]
  /// `null`) — même distinction que [hasWeaponSlot].
  final bool hasPriceOverride;
  final num? priceOverrideAmount;
  final CurrencyKind? priceOverrideCurrency;

  Map<String, dynamic> toPayload() => {
    OfflineStateKeys.equipped: ?equipped,
    if (hasWeaponSlot) OfflineStateKeys.weaponSlot: weaponSlot?.value,
    OfflineStateKeys.attuned: ?attuned,
    if (hasPriceOverride) ...{
      OfflineStateKeys.priceOverrideAmount: priceOverrideAmount,
      OfflineStateKeys.priceOverrideCurrency: priceOverrideCurrency?.code,
    },
  };

  InventoryStatePatch merge(InventoryStatePatch newer) => InventoryStatePatch(
    equipped: newer.equipped ?? equipped,
    hasWeaponSlot: newer.hasWeaponSlot || hasWeaponSlot,
    weaponSlot: newer.hasWeaponSlot ? newer.weaponSlot : weaponSlot,
    attuned: newer.attuned ?? attuned,
    hasPriceOverride: newer.hasPriceOverride || hasPriceOverride,
    priceOverrideAmount: newer.hasPriceOverride
        ? newer.priceOverrideAmount
        : priceOverrideAmount,
    priceOverrideCurrency: newer.hasPriceOverride
        ? newer.priceOverrideCurrency
        : priceOverrideCurrency,
  );

  /// Colonnes de `character_inventory` à écrire.
  Map<String, dynamic> toColumns() => {
    'equipped': ?equipped,
    if (hasWeaponSlot) 'weapon_slot': weaponSlot?.value,
    'is_attuned': ?attuned,
    if (hasPriceOverride) ...{
      'price_override_amount': priceOverrideAmount,
      'price_override_currency': priceOverrideCurrency?.code,
    },
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
  if (raw.containsKey(OfflineStateKeys.prepared) && prepared is! bool) {
    return null;
  }
  // Une ligne sans aucun champ connu (ex. ancienne `{favorite: …}` seule) est
  // invalide : le synchroniseur la supprime sans rien écrire.
  if (prepared == null) return null;
  return SpellStatePatch(prepared: prepared as bool?);
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
  final hasPriceOverride =
      raw.containsKey(OfflineStateKeys.priceOverrideAmount) ||
      raw.containsKey(OfflineStateKeys.priceOverrideCurrency);
  num? priceOverrideAmount;
  CurrencyKind? priceOverrideCurrency;
  if (hasPriceOverride) {
    final rawAmount = raw[OfflineStateKeys.priceOverrideAmount];
    final rawCurrency = raw[OfflineStateKeys.priceOverrideCurrency];
    // L'un est nul si et seulement si l'autre l'est (même contrainte que la
    // colonne) ; un montant non nul doit être valide.
    if ((rawAmount == null) != (rawCurrency == null)) return null;
    if (rawAmount != null) {
      if (!isValidPriceOverrideAmount(rawAmount)) return null;
      priceOverrideAmount = rawAmount as num;
      if (rawCurrency is! String) return null;
      priceOverrideCurrency = currencyKindFromCode(rawCurrency);
      if (priceOverrideCurrency == null) return null;
    }
  }
  if (equipped == null &&
      attuned == null &&
      !hasWeaponSlot &&
      !hasPriceOverride) {
    return null;
  }
  return InventoryStatePatch(
    equipped: equipped as bool?,
    hasWeaponSlot: hasWeaponSlot,
    weaponSlot: weaponSlot,
    attuned: attuned as bool?,
    hasPriceOverride: hasPriceOverride,
    priceOverrideAmount: priceOverrideAmount,
    priceOverrideCurrency: priceOverrideCurrency,
  );
}

/// Analyse stricte d'un payload `characterFlags` ; `null` s'il est invalide
/// (type incorrect, bonus de CA hors de la plage `integer` Postgres).
CharacterFlagsPatch? parseCharacterFlagsPayload(Object? raw) {
  if (raw is! Map) return null;
  final inspiration = raw[OfflineStateKeys.inspiration];
  final bonus = raw[OfflineStateKeys.armorClassBonus];
  if (raw.containsKey(OfflineStateKeys.inspiration) && inspiration is! bool) {
    return null;
  }
  if (raw.containsKey(OfflineStateKeys.armorClassBonus)) {
    if (bonus is! int || bonus < postgresIntMin || bonus > postgresIntMax) {
      return null;
    }
  }
  if (inspiration == null && bonus == null) return null;
  return CharacterFlagsPatch(
    inspiration: inspiration as bool?,
    armorClassBonus: bonus as int?,
  );
}
