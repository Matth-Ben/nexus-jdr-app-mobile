import '../../../core/utils/uuid_v4.dart';
import 'custom_item_enrichment.dart';
import 'offline_state_writes.dart';
import 'weapon_slot.dart';

/// Ajout d'un objet (personnalisé : T5b-1 ; du catalogue : T5b-2) et retrait
/// d'une ligne d'inventaire rendus hors-ligne-capables (P15). Une ligne de
/// file `inventoryItem` porte l'**état voulu d'une ligne** `character_inventory`
/// (`targetId` = UUID de la ligne, généré côté client à l'ajout) :
///
/// - ajout, pas encore synchronisé : `{"op": "add", "itemId": n` (objet du
///   catalogue) et/ou `"customName": "..."` (objet personnalisé ; au moins
///   l'un des deux, comme le CHECK de la table), `"quantity": n, + champs
///   personnalisés non vides, + état initial
///   optionnel equipped / weaponSlot / attuned}` — c'est un `INSERT` complet :
///   équiper, placer en set ou harmoniser une ligne encore en file se
///   **fusionne** ici au lieu de créer une ligne `inventoryState` ;
/// - retrait : `{"op": "delete"}` (tombstone) ;
/// - usage d'un objet d'une ligne **serveur** (T5b-3) : `{"op": "quantity",
///   "quantity": n, "base": b}` — quantité **absolue** voulue (`n` >= 0 ; 0 est
///   rejoué comme un retrait) et `base` optionnelle : quantité serveur connue
///   au **premier** enfilage, pour la détection de modification concurrente au
///   rejeu. `base` absente ou invalide : écriture sans détection (jamais un
///   payload invalide). Usage d'une ligne dont l'**ajout** est en file : la
///   `quantity` du payload d'ajout est modifiée (un seul `INSERT`) ; à 0 c'est
///   un tombstone ([planInventoryUse]) ;
///
/// - modification d'un objet personnalisé existant (P7 PR 4) : `{"op":
///   "updateCustom", "customName": "...", + **instantané complet** des champs
///   personnalisés non vides (une clé absente = colonne remise à `NULL`),
///   + `quantity`/`base` optionnels}` — dernière écriture gagnante, une seule
///   écriture par ligne (la seconde remplace la première). Les clés
///   `quantity`/`base` ne sont présentes que si un **usage** (`quantity`) de la
///   même ligne était en file : la file n'a qu'une entrée `inventoryItem` par
///   ligne, la fusion garde donc les deux effets. Modifier une ligne dont
///   l'**ajout** est encore en file réécrit le payload d'ajout
///   ([planInventoryCustomUpdate]) ;
///
/// Ce fichier porte le format, sa **validation stricte** et la **fusion** des
/// écritures successives : un payload qui ne passe pas
/// [parseInventoryItemPayload] n'est JAMAIS rejoué ni superposé (la ligne est
/// supprimée de la file par le synchroniseur), sinon il bloquerait le compteur
/// de synchro, la déconnexion et la suppression de compte.
abstract final class InventoryItemPayloadKeys {
  static const op = 'op';
  static const itemId = 'itemId';
  static const customName = 'customName';
  static const quantity = 'quantity';
  static const base = 'base';
  static const customDescription = 'customDescription';
  static const customDamageDice = 'customDamageDice';
  static const customDamageType = 'customDamageType';
  static const customProperties = 'customProperties';
}

/// Longueur maximale d'un nom d'objet personnalisé accepté hors ligne : la
/// colonne est un `text` sans plafond, 200 est un garde-fou « raisonnable »
/// (le nom est affiché sur une carte) appliqué à l'enfilage ET au rejeu.
const int inventoryCustomNameMaxLength = 200;

enum InventoryItemOp { add, delete, quantity, updateCustom }

/// Une écriture de ligne d'inventaire : ajout d'un objet complet, retrait, ou
/// nouvelle quantité absolue (usage d'un objet).
class InventoryItemWrite {
  const InventoryItemWrite.add({
    this.itemId,
    this.customName,
    required int this.quantity,
    this.customDescription,
    this.customDamageDice,
    this.customDamageType,
    this.customProperties = const [],
    this.enrichment,
    this.state,
  }) : assert(
         itemId != null || customName != null,
         'Un ajout porte un itemId ou un customName.',
       ),
       op = InventoryItemOp.add,
       base = null;

  const InventoryItemWrite.delete()
    : op = InventoryItemOp.delete,
      base = null,
      itemId = null,
      customName = null,
      quantity = null,
      customDescription = null,
      customDamageDice = null,
      customDamageType = null,
      customProperties = const [],
      enrichment = null,
      state = null;

  /// Usage d'un objet : quantité absolue [quantity] (>= 0), [base] = quantité
  /// serveur connue au premier enfilage (`null` : pas de détection).
  const InventoryItemWrite.quantity({required int this.quantity, this.base})
    : op = InventoryItemOp.quantity,
      itemId = null,
      customName = null,
      customDescription = null,
      customDamageDice = null,
      customDamageType = null,
      customProperties = const [],
      enrichment = null,
      state = null;

  /// Modification complète d'un objet personnalisé existant (P7 PR 4) :
  /// instantané de toutes les colonnes `custom_*` ([customName], description,
  /// dé/type de dégâts, propriétés, [enrichment]). [quantity]/[base] : usage
  /// de la même ligne déjà en file, fusionné ici (jamais saisi par l'édition).
  const InventoryItemWrite.updateCustom({
    required String this.customName,
    this.customDescription,
    this.customDamageDice,
    this.customDamageType,
    this.customProperties = const [],
    required CustomItemEnrichment this.enrichment,
    this.quantity,
    this.base,
  }) : op = InventoryItemOp.updateCustom,
       itemId = null,
       state = null;

  final InventoryItemOp op;

  /// Base de la détection de conflit d'une écriture `quantity` (voir le
  /// constructeur) ; `null` pour les autres opérations.
  final int? base;

  /// `items.id` d'un objet du catalogue (`character_inventory.item_id`), `null`
  /// pour un objet personnalisé.
  final int? itemId;
  final String? customName;
  final int? quantity;
  final String? customDescription;
  final String? customDamageDice;
  final String? customDamageType;
  final List<String> customProperties;

  /// Colonnes `custom_*` enrichies (P7) d'un objet personnalisé ; `null` pour
  /// un objet du catalogue et pour un ancien ajout (forme simple).
  final CustomItemEnrichment? enrichment;

  /// État initial (équipé / set d'arme / harmonisé) fusionné dans l'ajout ;
  /// `null` si aucun réglage n'a été fait depuis l'ajout.
  final InventoryStatePatch? state;

  Map<String, dynamic> toPayload() {
    if (op == InventoryItemOp.delete) {
      return {InventoryItemPayloadKeys.op: 'delete'};
    }
    if (op == InventoryItemOp.quantity) {
      return {
        InventoryItemPayloadKeys.op: 'quantity',
        InventoryItemPayloadKeys.quantity: quantity,
        InventoryItemPayloadKeys.base: ?base,
      };
    }
    if (op == InventoryItemOp.updateCustom) {
      return {
        InventoryItemPayloadKeys.op: 'updateCustom',
        InventoryItemPayloadKeys.customName: customName,
        InventoryItemPayloadKeys.customDescription: ?customDescription,
        InventoryItemPayloadKeys.customDamageDice: ?customDamageDice,
        InventoryItemPayloadKeys.customDamageType: ?customDamageType,
        if (customProperties.isNotEmpty)
          InventoryItemPayloadKeys.customProperties: customProperties,
        ...?enrichment?.toPayload(),
        InventoryItemPayloadKeys.quantity: ?quantity,
        InventoryItemPayloadKeys.base: ?base,
      };
    }
    return {
      InventoryItemPayloadKeys.op: 'add',
      InventoryItemPayloadKeys.itemId: ?itemId,
      InventoryItemPayloadKeys.customName: ?customName,
      InventoryItemPayloadKeys.quantity: quantity,
      InventoryItemPayloadKeys.customDescription: ?customDescription,
      InventoryItemPayloadKeys.customDamageDice: ?customDamageDice,
      InventoryItemPayloadKeys.customDamageType: ?customDamageType,
      if (customProperties.isNotEmpty)
        InventoryItemPayloadKeys.customProperties: customProperties,
      ...?enrichment?.toPayload(),
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
    'item_id': ?itemId,
    'custom_name': ?customName,
    'quantity': quantity,
    'custom_description': ?customDescription,
    'custom_damage_dice': ?customDamageDice,
    'custom_damage_type': ?customDamageType,
    if (customProperties.isNotEmpty) 'custom_properties': customProperties,
    ...?enrichment?.toInsertColumns(),
    ..._stateColumns(),
  };

  /// Corps de l'`UPDATE` d'une modification d'objet personnalisé : **toutes**
  /// les colonnes `custom_*`, avec des `null` **explicites** pour les champs
  /// devenus sans objet (jamais omis : un `UPDATE` partiel laisserait par
  /// exemple `custom_ac_base` sur une armure devenue arme et violerait les
  /// `CHECK` de la table). Un objet qui ne requiert plus l'harmonisation est
  /// aussi remis à non harmonisé (`is_attuned = false`) dans la même requête ;
  /// l'inverse n'harmonise jamais. [quantity] n'est écrite que si un usage
  /// de la ligne a été fusionné.
  Map<String, dynamic> toUpdateColumns() {
    final e = enrichment ?? const CustomItemEnrichment();
    return {
      'custom_name': customName,
      'custom_description': customDescription,
      'custom_damage_dice': customDamageDice,
      'custom_damage_type': customDamageType,
      'custom_properties': customProperties.isEmpty ? null : customProperties,
      ...e.toRowColumns(),
      if (!e.requiresAttunement) 'is_attuned': false,
      'quantity': ?quantity,
    };
  }

  /// Superpose cette modification à une ligne brute existante [row]
  /// (superposition hors ligne, cache de la fiche).
  Map<String, dynamic> applyToRow(Map<String, dynamic> row) => {
    ...row,
    ...toUpdateColumns(),
  };

  /// Colonnes de l'`UPDATE` de réalignement après un `23505` (la ligne existe
  /// déjà, réponse d'un envoi précédent perdue) : nom, quantité et état
  /// initial. Depuis T5b-3 la quantité du payload d'ajout est la quantité
  /// **effective** (un usage hors ligne la modifie dans l'ajout en file) : elle
  /// doit être réalignée, sinon un usage fait entre un `INSERT` à réponse perdue
  /// et son rejeu serait perdu.
  ///
  /// Un objet du catalogue sans nom ni état à réaligner réécrit `item_id` à la
  /// même valeur : un `UPDATE` au corps vide serait un no-op dont la réponse
  /// vide serait prise pour « zéro ligne affectée ».
  Map<String, dynamic> toRealignColumns() => {
    'custom_name': ?customName,
    'quantity': quantity,
    if (customName == null) 'item_id': itemId,
    ..._stateColumns(),
  };

  /// Ligne `character_inventory` brute équivalente (forme renvoyée par
  /// PostgREST) : alimente la superposition ([CharacterInventoryRowMapper]) et
  /// le cache de la fiche, avec exactement les mêmes règles de mapping qu'une
  /// ligne du serveur.
  ///
  /// [itemRow] : ligne `items` du catalogue (en cache) embarquée sous `items`
  /// pour un objet du catalogue — sans elle (objet absent du cache), la ligne
  /// reste partielle (nom générique, pas de poids ni de CA) mais valide.
  Map<String, dynamic> toRow({
    required String inventoryId,
    required String characterId,
    Map<String, dynamic>? itemRow,
  }) => {
    'id': inventoryId,
    'character_id': characterId,
    'item_id': itemId,
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
    ...?enrichment?.toRowColumns(),
    'items': ?itemRow,
  };
}

/// Un nom d'objet personnalisé valide est non vide une fois les espaces
/// retirés et de longueur raisonnable ([inventoryCustomNameMaxLength]).
bool isValidInventoryCustomName(Object? name) =>
    name is String &&
    name.trim().isNotEmpty &&
    name.length <= inventoryCustomNameMaxLength;

/// Un `item_id` valide est un entier ≥ 1 dans la plage `integer` Postgres
/// (`items.id` : `int`). Refuse 0, négatifs, flottants (`3.0`), chaînes.
bool isValidInventoryItemId(Object? itemId) =>
    itemId is int && itemId >= 1 && itemId <= postgresIntMax;

/// Une quantité valide est un entier ≥ 1 dans la plage `integer` Postgres
/// (`character_inventory.quantity` : `integer not null`).
bool isValidInventoryQuantity(Object? quantity) =>
    quantity is int && quantity >= 1 && quantity <= postgresIntMax;

/// Quantité d'une écriture `quantity` (usage) : entier dans `0..int4` (0 =
/// la ligne est retirée au rejeu, jamais une quantité 0 conservée).
bool isValidInventoryUseQuantity(Object? quantity) =>
    quantity is int && quantity >= 0 && quantity <= postgresIntMax;

/// Un `targetId` de file `inventoryItem` doit être un UUID (la ligne est créée
/// avec un `id` généré côté client).
bool isValidInventoryItemTargetId(String targetId) => isUuid(targetId);

/// Analyse stricte d'un payload `inventoryItem` ; `null` s'il est invalide
/// (pas un objet, `op` absente ou inconnue, `quantity` d'un usage non entière
/// ou hors `0..int4`, ni `itemId` ni `customName`,
/// `itemId` non entier ou ≤ 0, nom vide/trop long/non texte,
/// quantité non entière ou hors plage, champs personnalisés d'un mauvais type,
/// `customProperties` autre qu'une liste de textes, état d'un mauvais type,
/// set d'arme inconnu ou donné pour un objet explicitement non équipé). Les
/// clés inconnues sont ignorées.
InventoryItemWrite? parseInventoryItemPayload(Object? raw) {
  if (raw is! Map) return null;
  final op = raw[InventoryItemPayloadKeys.op];
  if (op == 'delete') return const InventoryItemWrite.delete();
  if (op == 'quantity') {
    final quantity = raw[InventoryItemPayloadKeys.quantity];
    if (!isValidInventoryUseQuantity(quantity)) return null;
    final base = raw[InventoryItemPayloadKeys.base];
    return InventoryItemWrite.quantity(
      quantity: quantity as int,
      base: isValidInventoryUseQuantity(base) ? base as int : null,
    );
  }
  if (op == 'updateCustom') return _parseUpdateCustomPayload(raw);
  if (op != 'add') return null;

  // Au moins un `itemId` (catalogue) ou un `customName` (personnalisé), comme
  // le CHECK `item_id` OU `custom_name` de la table ; une clé présente doit
  // être valide.
  int? itemId;
  if (raw.containsKey(InventoryItemPayloadKeys.itemId)) {
    final rawItemId = raw[InventoryItemPayloadKeys.itemId];
    if (!isValidInventoryItemId(rawItemId)) return null;
    itemId = rawItemId as int;
  }
  String? name;
  if (raw.containsKey(InventoryItemPayloadKeys.customName)) {
    final rawName = raw[InventoryItemPayloadKeys.customName];
    if (!isValidInventoryCustomName(rawName)) return null;
    name = rawName as String;
  }
  if (itemId == null && name == null) return null;
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
  // Enrichissement P7 : clés optionnelles ; réservées à un objet personnalisé
  // (les colonnes `custom_*` sont nulles pour un objet du catalogue).
  final parsedEnrichment = parseCustomItemEnrichment(raw);
  if (!parsedEnrichment.isValid) return null;
  if (itemId != null && parsedEnrichment.value != null) return null;
  final hasState = equipped != null || attuned != null || weaponSlot != null;
  return InventoryItemWrite.add(
    itemId: itemId,
    customName: name,
    quantity: quantity as int,
    customDescription: description,
    customDamageDice: dice,
    customDamageType: type,
    customProperties: properties,
    enrichment: parsedEnrichment.value,
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

/// Analyse stricte d'un payload `updateCustom` : nom valide (non vide, <= 200),
/// textes optionnels non vides, propriétés = liste de textes, enrichissement
/// cohérent ([CustomItemEnrichment.isValid]), `quantity` optionnelle >= 1,
/// `base` optionnelle ignorée si invalide. Aucune clé d'enrichissement :
/// toutes les colonnes `custom_*` sont remises à `NULL`.
InventoryItemWrite? _parseUpdateCustomPayload(Map<dynamic, dynamic> raw) {
  if (!isValidInventoryCustomName(raw[InventoryItemPayloadKeys.customName])) {
    return null;
  }
  if (raw.containsKey(InventoryItemPayloadKeys.itemId)) return null;
  bool textOk(String key) =>
      !raw.containsKey(key) || (raw[key] is String && raw[key] != '');
  if (!textOk(InventoryItemPayloadKeys.customDescription) ||
      !textOk(InventoryItemPayloadKeys.customDamageDice) ||
      !textOk(InventoryItemPayloadKeys.customDamageType)) {
    return null;
  }
  var properties = const <String>[];
  if (raw.containsKey(InventoryItemPayloadKeys.customProperties)) {
    final rawProperties = raw[InventoryItemPayloadKeys.customProperties];
    if (rawProperties is! List || rawProperties.any((e) => e is! String)) {
      return null;
    }
    properties = List<String>.from(rawProperties);
  }
  int? quantity;
  if (raw.containsKey(InventoryItemPayloadKeys.quantity)) {
    final rawQuantity = raw[InventoryItemPayloadKeys.quantity];
    if (!isValidInventoryQuantity(rawQuantity)) return null;
    quantity = rawQuantity as int;
  }
  final base = raw[InventoryItemPayloadKeys.base];
  final parsedEnrichment = parseCustomItemEnrichment(raw);
  if (!parsedEnrichment.isValid) return null;
  return InventoryItemWrite.updateCustom(
    customName: raw[InventoryItemPayloadKeys.customName] as String,
    customDescription:
        raw[InventoryItemPayloadKeys.customDescription] as String?,
    customDamageDice: raw[InventoryItemPayloadKeys.customDamageDice] as String?,
    customDamageType: raw[InventoryItemPayloadKeys.customDamageType] as String?,
    customProperties: properties,
    enrichment: parsedEnrichment.value ?? const CustomItemEnrichment(),
    quantity: quantity,
    base: quantity != null && isValidInventoryUseQuantity(base)
        ? base as int
        : null,
  );
}

/// Résultat de la fusion d'une modification d'objet personnalisé avec
/// l'écriture déjà en file pour la même ligne ([planInventoryCustomUpdate]).
class InventoryCustomUpdatePlan {
  const InventoryCustomUpdatePlan._({
    this.write,
    this.mergedIntoPendingAdd = false,
  });

  /// Modification impossible : un tombstone est en file, la ligne est retirée.
  static const rejected = InventoryCustomUpdatePlan._();

  /// Écriture à mettre en file (ou à écrire en ligne) ; `null` si [rejected].
  final InventoryItemWrite? write;

  /// `true` : l'ajout de la ligne est encore en file, [write] est cet ajout
  /// modifié (un seul `INSERT`, jamais d'`UPDATE` sur une ligne absente du
  /// serveur).
  final bool mergedIntoPendingAdd;

  bool get isRejected => write == null;
}

/// Plan d'une modification [requested] (op `updateCustom`) selon l'écriture
/// [pending] déjà en file pour la ligne (`null` si aucune ou illisible) :
///
/// - tombstone : [InventoryCustomUpdatePlan.rejected] ;
/// - ajout en file : l'ajout est **réécrit** avec les nouveaux champs (nom,
///   description, dégâts, enrichissement) en gardant sa quantité et son état
///   initial ; un objet qui ne requiert plus l'harmonisation perd son
///   harmonisation initiale ;
/// - usage (`quantity`) en file : la modification reprend sa quantité et sa
///   base (une seule entrée `inventoryItem` par ligne, aucune donnée perdue) ;
/// - modification déjà en file : **remplacée** (dernière écriture gagnante),
///   usage éventuel conservé ;
/// - sinon : la modification telle quelle.
InventoryCustomUpdatePlan planInventoryCustomUpdate({
  required InventoryItemWrite? pending,
  required InventoryItemWrite requested,
}) {
  final enrichment = requested.enrichment ?? const CustomItemEnrichment();
  InventoryItemWrite update({int? quantity, int? base}) =>
      InventoryItemWrite.updateCustom(
        customName: requested.customName!,
        customDescription: requested.customDescription,
        customDamageDice: requested.customDamageDice,
        customDamageType: requested.customDamageType,
        customProperties: requested.customProperties,
        enrichment: enrichment,
        quantity: quantity,
        base: base,
      );
  switch (pending?.op) {
    case InventoryItemOp.delete:
      return InventoryCustomUpdatePlan.rejected;
    case InventoryItemOp.add:
      final state = pending!.state;
      final dropAttunement =
          !enrichment.requiresAttunement && state?.attuned == true;
      return InventoryCustomUpdatePlan._(
        mergedIntoPendingAdd: true,
        write: InventoryItemWrite.add(
          customName: requested.customName,
          quantity: pending.quantity!,
          customDescription: requested.customDescription,
          customDamageDice: requested.customDamageDice,
          customDamageType: requested.customDamageType,
          customProperties: requested.customProperties,
          enrichment: enrichment.isEmpty ? null : enrichment,
          state: dropAttunement
              ? state!.merge(const InventoryStatePatch(attuned: false))
              : state,
        ),
      );
    case InventoryItemOp.quantity:
    case InventoryItemOp.updateCustom:
      return InventoryCustomUpdatePlan._(
        write: update(quantity: pending!.quantity, base: pending.base),
      );
    case null:
      return InventoryCustomUpdatePlan._(write: update());
  }
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
    itemId: pendingAdd.itemId,
    customName: pendingAdd.customName,
    quantity: pendingAdd.quantity!,
    customDescription: pendingAdd.customDescription,
    customDamageDice: pendingAdd.customDamageDice,
    customDamageType: pendingAdd.customDamageType,
    customProperties: pendingAdd.customProperties,
    enrichment: pendingAdd.enrichment,
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

/// Un ajout d'objet à mettre en file avec son UUID de ligne client (butin avec
/// objets, T5b-2).
class PendingInventoryAdd {
  const PendingInventoryAdd({required this.inventoryId, required this.write});

  final String inventoryId;
  final InventoryItemWrite write;
}

/// Résultat de la fusion d'un usage d'objet avec l'écriture déjà en file pour
/// la même ligne ([planInventoryUse]).
class InventoryUsePlan {
  const InventoryUsePlan._({this.write, this.mergedIntoPendingAdd = false});

  /// Usage impossible : un tombstone est en file, la ligne est déjà retirée.
  static const rejected = InventoryUsePlan._();

  /// Écriture à mettre en file (ou à écrire en ligne) pour la ligne ; `null`
  /// uniquement pour [rejected].
  final InventoryItemWrite? write;

  /// `true` : l'ajout de la ligne est encore en file, [write] est cet ajout
  /// à la quantité mise à jour (ou un tombstone si elle tombe à 0). Jamais
  /// écrit en ligne par un `UPDATE` (la ligne n'existe pas côté serveur) : mis
  /// en file, il part avec le rejeu de l'`INSERT`.
  final bool mergedIntoPendingAdd;

  bool get isRejected => write == null;
}

/// Plan d'un usage d'objet de nouvelle quantité absolue [newQuantity] ([pending]
/// : écriture déjà en file pour cette ligne, `null` si aucune ou illisible ;
/// [serverQuantity] : quantité serveur connue, base de la détection de
/// conflit).
///
/// - tombstone en file : [InventoryUsePlan.rejected] ;
/// - [newQuantity] <= 0 : tombstone (la ligne est retirée), qui remplace tout
///   ajout ou usage en file (comme [planInventoryRemoval]) ;
/// - ajout en file : l'ajout à la nouvelle quantité (un seul `INSERT`) ;
/// - usage déjà en file : nouvelle quantité absolue, **base du premier
///   enfilage conservée** ;
/// - sinon : usage avec [serverQuantity] pour base.
InventoryUsePlan planInventoryUse({
  required InventoryItemWrite? pending,
  required int newQuantity,
  int? serverQuantity,
}) {
  if (pending?.op == InventoryItemOp.delete) return InventoryUsePlan.rejected;
  final isAddPending = pending?.op == InventoryItemOp.add;
  if (newQuantity <= 0) {
    return InventoryUsePlan._(
      write: const InventoryItemWrite.delete(),
      mergedIntoPendingAdd: isAddPending,
    );
  }
  if (isAddPending) {
    return InventoryUsePlan._(
      write: InventoryItemWrite.add(
        itemId: pending!.itemId,
        customName: pending.customName,
        quantity: newQuantity,
        customDescription: pending.customDescription,
        customDamageDice: pending.customDamageDice,
        customDamageType: pending.customDamageType,
        customProperties: pending.customProperties,
        enrichment: pending.enrichment,
        state: pending.state,
      ),
      mergedIntoPendingAdd: true,
    );
  }
  if (pending?.op == InventoryItemOp.updateCustom) {
    // Modification en file : l'usage s'y fusionne (une seule entrée par
    // ligne) ; base du premier usage conservée si un usage y était déjà.
    return InventoryUsePlan._(
      write: InventoryItemWrite.updateCustom(
        customName: pending!.customName!,
        customDescription: pending.customDescription,
        customDamageDice: pending.customDamageDice,
        customDamageType: pending.customDamageType,
        customProperties: pending.customProperties,
        enrichment: pending.enrichment!,
        quantity: newQuantity,
        base: pending.quantity != null ? pending.base : serverQuantity,
      ),
    );
  }
  return InventoryUsePlan._(
    write: InventoryItemWrite.quantity(
      quantity: newQuantity,
      base: pending?.op == InventoryItemOp.quantity
          ? pending!.base
          : serverQuantity,
    ),
  );
}
