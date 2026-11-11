import '../../../core/utils/uuid_v4.dart';
import 'offline_state_writes.dart';
import 'weapon_slot.dart';

/// Ajout d'un objet personnalisé et retrait d'une ligne d'inventaire rendus
/// hors-ligne-capables (T5b-1, P15). Une ligne de file `inventoryItem` porte
/// l'**état voulu d'une ligne** `character_inventory` (`targetId` = UUID de la
/// ligne, généré côté client à l'ajout) :
///
/// - ajout, pas encore synchronisé : `{"op": "add", "customName": "...",
///   "quantity": n, + champs personnalisés non vides, + état initial
///   optionnel equipped / weaponSlot / attuned}` — c'est un `INSERT` complet :
///   équiper, placer en set ou harmoniser une ligne encore en file se
///   **fusionne** ici au lieu de créer une ligne `inventoryState` ;
/// - retrait : `{"op": "delete"}` (tombstone).
///
/// Ce fichier porte le format, sa **validation stricte** et la **fusion** des
/// écritures successives : un payload qui ne passe pas
/// [parseInventoryItemPayload] n'est JAMAIS rejoué ni superposé (la ligne est
/// supprimée de la file par le synchroniseur), sinon il bloquerait le compteur
/// de synchro, la déconnexion et la suppression de compte.
abstract final class InventoryItemPayloadKeys {
  static const op = 'op';
  static const customName = 'customName';
  static const quantity = 'quantity';
  static const customDescription = 'customDescription';
  static const customDamageDice = 'customDamageDice';
  static const customDamageType = 'customDamageType';
  static const customProperties = 'customProperties';
}

/// Longueur maximale d'un nom d'objet personnalisé accepté hors ligne : la
/// colonne est un `text` sans plafond, 200 est un garde-fou « raisonnable »
/// (le nom est affiché sur une carte) appliqué à l'enfilage ET au rejeu.
const int inventoryCustomNameMaxLength = 200;

enum InventoryItemOp { add, delete }

/// Une écriture de ligne d'inventaire : ajout d'un objet personnalisé
/// complet, ou retrait.
class InventoryItemWrite {
  const InventoryItemWrite.add({
    required String this.customName,
    required int this.quantity,
    this.customDescription,
    this.customDamageDice,
    this.customDamageType,
    this.customProperties = const [],
    this.state,
  }) : op = InventoryItemOp.add;

  const InventoryItemWrite.delete()
    : op = InventoryItemOp.delete,
      customName = null,
      quantity = null,
      customDescription = null,
      customDamageDice = null,
      customDamageType = null,
      customProperties = const [],
      state = null;

  final InventoryItemOp op;
  final String? customName;
  final int? quantity;
  final String? customDescription;
  final String? customDamageDice;
  final String? customDamageType;
  final List<String> customProperties;

  /// État initial (équipé / set d'arme / harmonisé) fusionné dans l'ajout ;
  /// `null` si aucun réglage n'a été fait depuis l'ajout.
  final InventoryStatePatch? state;

  Map<String, dynamic> toPayload() {
    if (op == InventoryItemOp.delete) {
      return {InventoryItemPayloadKeys.op: 'delete'};
    }
    return {
      InventoryItemPayloadKeys.op: 'add',
      InventoryItemPayloadKeys.customName: customName,
      InventoryItemPayloadKeys.quantity: quantity,
      InventoryItemPayloadKeys.customDescription: ?customDescription,
      InventoryItemPayloadKeys.customDamageDice: ?customDamageDice,
      InventoryItemPayloadKeys.customDamageType: ?customDamageType,
      if (customProperties.isNotEmpty)
        InventoryItemPayloadKeys.customProperties: customProperties,
      ..._statePayload(),
    };
  }

  /// Clés d'état de l'ajout : `weaponSlot` n'est écrit que s'il est non nul
  /// (un `INSERT` sans set d'arme laisse la colonne à `null`).
  Map<String, dynamic> _statePayload() {
    final s = state;
    if (s == null) return const {};
    return {
      OfflineStateKeys.equipped: ?s.equipped,
      OfflineStateKeys.weaponSlot: ?s.weaponSlot?.value,
      OfflineStateKeys.attuned: ?s.attuned,
    };
  }

  /// Colonnes de l'état initial pour `INSERT`/`UPDATE` de réalignement.
  Map<String, dynamic> _stateColumns() {
    final s = state;
    if (s == null) return const {};
    return {
      'equipped': ?s.equipped,
      'weapon_slot': ?s.weaponSlot?.value,
      'is_attuned': ?s.attuned,
    };
  }

  /// Corps de l'`INSERT` sur `character_inventory` : `id` client, personnage,
  /// champs personnalisés **non vides** seulement (jamais de `null` explicite,
  /// même convention que l'ajout en ligne historique) et état initial.
  Map<String, dynamic> toInsertColumns({
    required String inventoryId,
    required String characterId,
  }) => {
    'id': inventoryId,
    'character_id': characterId,
    'custom_name': customName,
    'quantity': quantity,
    'custom_description': ?customDescription,
    'custom_damage_dice': ?customDamageDice,
    'custom_damage_type': ?customDamageType,
    if (customProperties.isNotEmpty) 'custom_properties': customProperties,
    ..._stateColumns(),
  };

  /// Colonnes de l'`UPDATE` de réalignement après un `23505` (la ligne existe
  /// déjà, réponse d'un envoi précédent perdue) : nom et état initial, pas la
  /// quantité (elle a pu être consommée depuis le premier envoi).
  Map<String, dynamic> toRealignColumns() => {
    'custom_name': customName,
    ..._stateColumns(),
  };

  /// Ligne `character_inventory` brute équivalente (forme renvoyée par
  /// PostgREST) : alimente la superposition ([CharacterInventoryRowMapper]) et
  /// le cache de la fiche, avec exactement les mêmes règles de mapping qu'une
  /// ligne du serveur.
  Map<String, dynamic> toRow({
    required String inventoryId,
    required String characterId,
  }) => {
    'id': inventoryId,
    'character_id': characterId,
    'item_id': null,
    'custom_name': customName,
    'quantity': quantity,
    'equipped': state?.equipped ?? false,
    'notes': null,
    'is_attuned': state?.attuned ?? false,
    'weapon_slot': state?.weaponSlot?.value,
    'custom_description': customDescription,
    'custom_damage_dice': customDamageDice,
    'custom_damage_type': customDamageType,
    'custom_properties': customProperties.isEmpty ? null : customProperties,
  };
}

/// Un nom d'objet personnalisé valide est non vide une fois les espaces
/// retirés et de longueur raisonnable ([inventoryCustomNameMaxLength]).
bool isValidInventoryCustomName(Object? name) =>
    name is String &&
    name.trim().isNotEmpty &&
    name.length <= inventoryCustomNameMaxLength;

/// Une quantité valide est un entier ≥ 1 dans la plage `integer` Postgres
/// (`character_inventory.quantity` : `integer not null`).
bool isValidInventoryQuantity(Object? quantity) =>
    quantity is int && quantity >= 1 && quantity <= postgresIntMax;

/// Un `targetId` de file `inventoryItem` doit être un UUID (la ligne est créée
/// avec un `id` généré côté client).
bool isValidInventoryItemTargetId(String targetId) => isUuid(targetId);

/// Analyse stricte d'un payload `inventoryItem` ; `null` s'il est invalide
/// (pas un objet, `op` absente ou inconnue, nom vide/trop long/non texte,
/// quantité non entière ou hors plage, champs personnalisés d'un mauvais type,
/// `customProperties` autre qu'une liste de textes, état d'un mauvais type,
/// set d'arme inconnu ou donné pour un objet explicitement non équipé). Les
/// clés inconnues sont ignorées.
InventoryItemWrite? parseInventoryItemPayload(Object? raw) {
  if (raw is! Map) return null;
  final op = raw[InventoryItemPayloadKeys.op];
  if (op == 'delete') return const InventoryItemWrite.delete();
  if (op != 'add') return null;

  final name = raw[InventoryItemPayloadKeys.customName];
  if (!isValidInventoryCustomName(name)) return null;
  final quantity = raw[InventoryItemPayloadKeys.quantity];
  if (!isValidInventoryQuantity(quantity)) return null;

  // Champ texte optionnel : absent ou non vide ; toute autre valeur (vide,
  // nulle, non texte) invalide la ligne.
  bool textOk(String key) =>
      !raw.containsKey(key) || (raw[key] is String && raw[key] != '');
  if (!textOk(InventoryItemPayloadKeys.customDescription) ||
      !textOk(InventoryItemPayloadKeys.customDamageDice) ||
      !textOk(InventoryItemPayloadKeys.customDamageType)) {
    return null;
  }
  final description =
      raw[InventoryItemPayloadKeys.customDescription] as String?;
  final dice = raw[InventoryItemPayloadKeys.customDamageDice] as String?;
  final type = raw[InventoryItemPayloadKeys.customDamageType] as String?;

  var properties = const <String>[];
  if (raw.containsKey(InventoryItemPayloadKeys.customProperties)) {
    final rawProperties = raw[InventoryItemPayloadKeys.customProperties];
    if (rawProperties is! List || rawProperties.any((e) => e is! String)) {
      return null;
    }
    properties = List<String>.from(rawProperties);
  }

  // État initial : mêmes règles que `parseInventoryStatePayload`, mais l'absence
  // de toute clé est valide (aucun réglage depuis l'ajout).
  final equipped = raw[OfflineStateKeys.equipped];
  final attuned = raw[OfflineStateKeys.attuned];
  if (raw.containsKey(OfflineStateKeys.equipped) && equipped is! bool) {
    return null;
  }
  if (raw.containsKey(OfflineStateKeys.attuned) && attuned is! bool) {
    return null;
  }
  WeaponSlot? weaponSlot;
  if (raw.containsKey(OfflineStateKeys.weaponSlot)) {
    final rawSlot = raw[OfflineStateKeys.weaponSlot];
    if (rawSlot is! String) return null;
    weaponSlot = WeaponSlot.fromValue(rawSlot);
    if (weaponSlot == null || equipped == false) return null;
  }
  final hasState = equipped != null || attuned != null || weaponSlot != null;
  return InventoryItemWrite.add(
    customName: name as String,
    quantity: quantity as int,
    customDescription: description,
    customDamageDice: dice,
    customDamageType: type,
    customProperties: properties,
    state: hasState
        ? InventoryStatePatch(
            equipped: equipped as bool?,
            hasWeaponSlot: weaponSlot != null,
            weaponSlot: weaponSlot,
            attuned: attuned as bool?,
          )
        : null,
  );
}

/// Fusionne un réglage d'état [patch] (équiper, set d'arme, harmoniser) dans
/// l'ajout en attente [pendingAdd] : l'ajout reste un `INSERT` complet à l'état
/// final, dernière valeur gagnante champ par champ. Déséquiper (`equipped:
/// false` + set effacé) retire le set d'arme de l'ajout.
InventoryItemWrite mergeStateIntoPendingAdd(
  InventoryItemWrite pendingAdd,
  InventoryStatePatch patch,
) {
  final merged = pendingAdd.state == null
      ? patch
      : pendingAdd.state!.merge(patch);
  return InventoryItemWrite.add(
    customName: pendingAdd.customName!,
    quantity: pendingAdd.quantity!,
    customDescription: pendingAdd.customDescription,
    customDamageDice: pendingAdd.customDamageDice,
    customDamageType: pendingAdd.customDamageType,
    customProperties: pendingAdd.customProperties,
    state: merged,
  );
}

/// Résultat de la fusion d'un retrait avec l'écriture déjà en file pour la
/// même ligne.
class InventoryRemovalPlan {
  const InventoryRemovalPlan._({required this.alreadyRemoved});

  /// `true` : un tombstone est déjà en file, le retrait est idempotent (rien à
  /// mettre en file ni à écrire).
  final bool alreadyRemoved;
}

/// Plan d'un retrait hors ligne ([pending] : écriture déjà en file pour cette
/// ligne, `null` si aucune ou illisible).
///
/// Retrait d'un **ajout en attente** : un tombstone remplace l'ajout, il n'est
/// PAS simplement retiré de la file. Raison : une tentative de rejeu a pu
/// atteindre le serveur sans que sa réponse revienne (l'`INSERT` est alors
/// appliqué, la ligne existe côté serveur, la file l'ignore) ; retirer la
/// ligne de file la laisserait réapparaître au prochain chargement. Le coût du
/// tombstone est un `DELETE` idempotent (zéro ligne = succès) quand l'ajout
/// n'est jamais parti. Retrait d'une ligne serveur : tombstone ; d'une ligne
/// déjà en tombstone : idempotent.
InventoryRemovalPlan planInventoryRemoval({
  required InventoryItemWrite? pending,
}) => InventoryRemovalPlan._(
  alreadyRemoved: pending?.op == InventoryItemOp.delete,
);
