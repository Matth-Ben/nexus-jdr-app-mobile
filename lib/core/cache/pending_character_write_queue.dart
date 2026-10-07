import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import 'app_database.dart';

/// Les deux types d'écriture rendus hors-ligne-capables — voir la doc de
/// classe de [PendingCharacterWrites]. Périmètre volontairement restreint
/// (décision chef de projet) : `applyRest`/`applyLevelUp`/`uploadPortrait`/
/// `removePortrait` restent des appels réseau directs, jamais mis en file.
enum PendingCharacterWriteKind {
  hp('hp'),
  xp('xp');

  const PendingCharacterWriteKind(this.storageKey);

  /// Valeur stockée telle quelle dans `PendingCharacterWrites.kind`.
  final String storageKey;

  static PendingCharacterWriteKind fromStorageKey(String value) =>
      PendingCharacterWriteKind.values.firstWhere(
        (kind) => kind.storageKey == value,
        orElse: () => throw ArgumentError.value(
          value,
          'value',
          'Kind de PendingCharacterWrites inconnu.',
        ),
      );
}

/// Une ligne de [PendingCharacterWrites] déjà décodée — voir
/// [PendingCharacterWriteQueue.allForOwner]/[PendingCharacterWriteQueue.forCharacter].
class PendingCharacterWrite {
  const PendingCharacterWrite({
    required this.characterId,
    required this.ownerId,
    required this.kind,
    required this.payload,
    required this.rawPayload,
    required this.queuedAt,
  });

  final String characterId;
  final String ownerId;
  final PendingCharacterWriteKind kind;

  /// `{"currentHp": ..., "temporaryHp": ...}` pour [PendingCharacterWriteKind.hp],
  /// `{"newXp": ...}` pour [PendingCharacterWriteKind.xp] — voir
  /// `SupabaseCharacterRepository.updateHp`/`addXp`.
  final Map<String, dynamic> payload;

  /// [payload] tel que stocké (texte JSON exact de la colonne `payload`) et
  /// horodatage de mise en file tel que stocké (précision : la seconde) —
  /// ensemble, ils identifient cette version précise de l'entrée, voir
  /// [PendingCharacterWriteQueue.removeIfUnchanged].
  final String rawPayload;
  final DateTime queuedAt;
}

/// Petite abstraction de lecture/écriture au-dessus du DAO drift généré
/// (`AppDatabase`/`PendingCharacterWrites`), même principe que
/// `ReferenceDataCache` au-dessus de `CachedReferenceEntries` : les
/// consommateurs (`SupabaseCharacterRepository`,
/// `PendingCharacterWriteSyncer`) n'ont jamais à connaître le détail de la
/// table drift sous-jacente.
class PendingCharacterWriteQueue {
  PendingCharacterWriteQueue(this._db);

  final AppDatabase _db;

  /// Seuil de refus non rejouables **consécutifs** (D34 du registre de dette
  /// technique) avant d'abandonner une entrée plutôt que de la retenter
  /// indéfiniment — voir [recordNonRetryableFailure].
  ///
  /// Choix de 5, documenté ici plutôt que deviné en silence : la synchro est
  /// déclenchée à chaque démarrage de l'app et à chaque retour de
  /// connectivité (`CharacterWriteSyncCoordinator`), donc un réseau instable
  /// peut produire plusieurs tentatives en quelques minutes sans qu'aucune
  /// ne soit un vrai nouvel essai indépendant. 5 laisse largement le temps de
  /// distinguer un refus réellement non rejouable (contrainte, RLS — qui, par
  /// nature, échoue de façon identique à chaque tentative) d'un faux positif
  /// de classification, sans pour autant laisser une entrée invalide masquer
  /// indéfiniment la valeur serveur dans la fiche (voir
  /// `SupabaseCharacterRepository._withPendingWrites`).
  static const int abandonAfterConsecutiveFailures = 5;

  /// Verrou en mémoire par `(characterId, kind)`, partagé entre
  /// `SupabaseCharacterRepository.updateHp`/`addXp` (écriture en ligne) et
  /// `PendingCharacterWriteSyncer.sync` (écriture de la file) — D33 du
  /// registre de dette technique.
  ///
  /// Sans lui, les deux chemins peuvent envoyer au serveur, au même instant,
  /// un `PATCH` du même type pour le même personnage (ex. réseau revenu
  /// pendant que le joueur ajuste ses PV en ligne alors que la synchro de la
  /// file est aussi en vol) : l'ordre d'arrivée réseau n'étant pas garanti,
  /// celui qui arrive en second écrase celui qui arrive en premier même s'il
  /// est plus ancien, et la valeur affichée peut régresser silencieusement.
  ///
  /// [runExclusive] sérialise les appels concurrents pour une même clé :
  /// pendant qu'un appel est en cours pour `(characterId, kind)`, tout
  /// nouvel appel pour la même clé attend qu'il se termine (succès ou échec)
  /// avant de démarrer à son tour — jamais deux écritures du même type en vol
  /// en même temps pour le même personnage. Deux clés différentes
  /// (personnage ou type différents) ne s'attendent jamais entre elles.
  ///
  /// Verrou **en mémoire seulement** (une simple `Map`, pas une table drift) :
  /// il ne protège que les appels concurrents au sein du même processus —
  /// déjà suffisant ici, puisque le dépôt et le synchroniseur partagent
  /// toujours la même instance de cette file (voir les providers `keepAlive`
  /// de `character_providers.dart`/`cache_providers.dart`), donc le même
  /// isolat principal de l'app.
  final Map<String, Future<void>> _writeLocks = {};

  /// Exécute [action] en exclusivité pour la clé `(characterId, kind)` — voir
  /// la documentation de [_writeLocks]. Les appels concurrents pour la même
  /// clé sont mis en file (ordre d'appel, FIFO) ; un appel qui échoue libère
  /// quand même le verrou pour le suivant (ni blocage, ni perte de l'erreur :
  /// elle continue de remonter normalement à l'appelant de [runExclusive]).
  Future<T> runExclusive<T>({
    required String characterId,
    required PendingCharacterWriteKind kind,
    required Future<T> Function() action,
  }) async {
    final key = '$characterId|${kind.storageKey}';
    final previous = _writeLocks[key];
    final gate = Completer<void>();
    _writeLocks[key] = gate.future;
    try {
      if (previous != null) {
        await previous;
      }
      return await action();
    } finally {
      gate.complete();
      // Ne retire l'entrée que si personne n'a pris la suite entre-temps —
      // sinon on supprimerait la référence que le prochain appelant attend.
      if (identical(_writeLocks[key], gate.future)) {
        _writeLocks.remove(key);
      }
    }
  }

  /// Upsert sur `(characterId, kind)` : le mécanisme de coalescing —
  /// [payload] déjà mis en attente pour ce personnage/type est remplacé,
  /// jamais accumulé. `updateHp`/`addXp` écrivent déjà des valeurs absolues
  /// (pas des deltas), donc seule la toute dernière valeur en attente a
  /// besoin d'être un jour synchronisée.
  ///
  /// `queuedAt` sert aussi de numéro de version de l'entrée (voir
  /// [removeIfUnchanged]) : il est stocké à la seconde, donc un remplacement
  /// fait dans la même seconde que la mise en file précédente garderait le
  /// même horodatage. Chaque remplacement le fait donc avancer d'au moins
  /// une seconde par rapport à l'entrée remplacée (lecture + écriture dans
  /// une même transaction) — quitte à le placer légèrement dans le futur,
  /// sans conséquence : il n'est lu nulle part ailleurs.
  Future<void> enqueue({
    required String characterId,
    required String ownerId,
    required PendingCharacterWriteKind kind,
    required Map<String, dynamic> payload,
  }) async {
    await _db.transaction(() async {
      final existing =
          await (_db.select(_db.pendingCharacterWrites)..where(
                (row) =>
                    row.characterId.equals(characterId) &
                    row.kind.equals(kind.storageKey),
              ))
              .getSingleOrNull();

      var queuedAt = DateTime.now();
      if (existing != null) {
        final earliest = existing.queuedAt.add(const Duration(seconds: 1));
        if (queuedAt.isBefore(earliest)) {
          queuedAt = earliest;
        }
      }

      await _db
          .into(_db.pendingCharacterWrites)
          .insertOnConflictUpdate(
            PendingCharacterWritesCompanion.insert(
              characterId: characterId,
              ownerId: ownerId,
              kind: kind.storageKey,
              payload: jsonEncode(payload),
              queuedAt: queuedAt,
              // Remet à zéro le compteur d'échecs (D34) : une entrée mise en
              // file ici est une **nouvelle** valeur saisie par le joueur
              // (même upsert que [existing] remplacée ci-dessus), jamais un
              // simple renvoi de la même valeur — elle mérite un budget de
              // tentatives neuf, même si l'entrée qu'elle remplace avait déjà
              // été abandonnée. Sans ce reset explicite,
              // `insertOnConflictUpdate` laisserait `failureCount`/`abandoned`
              // de l'ancienne ligne tels quels (colonnes absentes de ce
              // companion) : la nouvelle valeur du joueur serait alors
              // ignorée pour toujours par `forCharacter`/`allForOwner`
              // (filtrées sur `abandoned`), sans jamais repartir.
              failureCount: const Value(0),
              abandoned: const Value(false),
              lastFailureMessage: const Value(null),
            ),
          );
    });
  }

  /// Retire [write] de la file **seulement si elle y est encore telle
  /// qu'elle a été lue** (même compte, même horodatage de mise en file, même
  /// contenu) — en une seule instruction SQL, donc sans fenêtre entre la
  /// vérification et la suppression. Retourne `true` si une ligne a été
  /// retirée.
  ///
  /// Seule façon de retirer une entrée : entre la lecture d'une entrée et
  /// son retrait, l'appelant attend toujours une réponse réseau
  /// (`PendingCharacterWriteSyncer.sync` écrit l'entrée lue ;
  /// `SupabaseCharacterRepository.updateHp`/`addXp` écrivent en ligne une
  /// valeur qui la rend périmée), pendant laquelle le joueur peut mettre en
  /// file une nouvelle valeur pour la même clé. Un retrait sur la seule clé
  /// `(characterId, kind)` supprimerait alors cette valeur plus récente,
  /// jamais envoyée : ajustement perdu sans message.
  ///
  /// [ownerId] fait partie du filtre bien qu'il ne fasse pas partie de la
  /// clé primaire : un compte ne retire jamais l'entrée en attente d'un
  /// autre compte du même appareil.
  Future<bool> removeIfUnchanged(PendingCharacterWrite write) async {
    final removed =
        await (_db.delete(_db.pendingCharacterWrites)..where(
              (row) =>
                  row.characterId.equals(write.characterId) &
                  row.ownerId.equals(write.ownerId) &
                  row.kind.equals(write.kind.storageKey) &
                  row.queuedAt.equals(write.queuedAt) &
                  row.payload.equals(write.rawPayload),
            ))
            .go();
    return removed > 0;
  }

  /// Écritures en attente de [ownerId] pour le seul personnage [characterId]
  /// — au plus une par [PendingCharacterWriteKind] (clé primaire
  /// `(characterId, kind)`). Lu par
  /// `SupabaseCharacterRepository.fetchCharacterDetail`, qui les superpose à
  /// la fiche relue (serveur ou cache) : tant qu'une écriture n'est pas
  /// synchronisée, c'est elle, pas la valeur serveur, que le joueur doit
  /// voir et dont tout nouvel ajustement doit repartir.
  ///
  /// Même cloisonnement par compte que [allForOwner]. Contrairement à
  /// [allForOwner], une ligne dont le `kind` est inconnu de cette version de
  /// l'app est ignorée au lieu de lever une erreur : elle ne peut de toute
  /// façon pas être superposée, et ne doit jamais empêcher d'afficher la
  /// fiche.
  ///
  /// Une entrée abandonnée (D34, voir la doc de classe de
  /// [PendingCharacterWrites]) n'est jamais renvoyée ici : elle ne doit plus
  /// masquer la valeur serveur dans la fiche une fois qu'elle a cessé d'être
  /// retentée.
  Future<List<PendingCharacterWrite>> forCharacter({
    required String ownerId,
    required String characterId,
  }) async {
    final rows =
        await (_db.select(_db.pendingCharacterWrites)..where(
              (row) =>
                  row.ownerId.equals(ownerId) &
                  row.characterId.equals(characterId) &
                  row.abandoned.equals(false),
            ))
            .get();

    final knownKinds = {
      for (final kind in PendingCharacterWriteKind.values)
        kind.storageKey: kind,
    };
    final writes = <PendingCharacterWrite>[];
    for (final row in rows) {
      final kind = knownKinds[row.kind];
      if (kind == null) continue;
      writes.add(
        PendingCharacterWrite(
          characterId: row.characterId,
          ownerId: row.ownerId,
          kind: kind,
          payload: Map<String, dynamic>.from(jsonDecode(row.payload) as Map),
          rawPayload: row.payload,
          queuedAt: row.queuedAt,
        ),
      );
    }
    return writes;
  }

  /// Toutes les écritures en attente appartenant à [ownerId] — jamais celles
  /// d'un autre compte, même sur le même appareil (voir la doc de classe de
  /// [PendingCharacterWrites] pour le rationale de ce filtre). Même exclusion
  /// des entrées abandonnées que [forCharacter] : `PendingCharacterWriteSyncer
  /// .sync` ne doit plus jamais les retenter une fois abandonnées.
  Future<List<PendingCharacterWrite>> allForOwner(String ownerId) async {
    final rows =
        await (_db.select(_db.pendingCharacterWrites)..where(
              (row) =>
                  row.ownerId.equals(ownerId) & row.abandoned.equals(false),
            ))
            .get();

    return [
      for (final row in rows)
        PendingCharacterWrite(
          characterId: row.characterId,
          ownerId: row.ownerId,
          kind: PendingCharacterWriteKind.fromStorageKey(row.kind),
          payload: Map<String, dynamic>.from(jsonDecode(row.payload) as Map),
          rawPayload: row.payload,
          queuedAt: row.queuedAt,
        ),
    ];
  }

  /// Compte un refus **non rejouable** (contrainte, RLS — voir
  /// `PendingCharacterWriteSyncer._isNonRetryable`) pour [write] : incrémente
  /// son compteur d'échecs et, au-delà de [abandonAfterConsecutiveFailures],
  /// marque l'entrée abandonnée avec [reason] comme message à afficher au
  /// joueur (consommé plus tard par [consumeAbandonedMessages]). Retourne
  /// `true` si cet appel vient de déclencher l'abandon.
  ///
  /// [write] doit être la version **tout juste relue** avant la tentative
  /// refusée (voir `PendingCharacterWriteSyncer.sync`,
  /// `_currentVersionOf`) : comme [removeIfUnchanged], cette méthode ne
  /// touche qu'à la ligne qui correspond encore exactement à [write] (même
  /// compte, même horodatage, même contenu) — si elle a été remplacée par une
  /// valeur plus récente entre-temps, l'échec appartient à une version déjà
  /// périmée et ne doit pas pénaliser la nouvelle valeur du joueur ; dans ce
  /// cas, ne fait rien et retourne `false`.
  Future<bool> recordNonRetryableFailure({
    required PendingCharacterWrite write,
    required String reason,
  }) {
    return _db.transaction(() async {
      final row =
          await (_db.select(_db.pendingCharacterWrites)..where(
                (row) =>
                    row.characterId.equals(write.characterId) &
                    row.ownerId.equals(write.ownerId) &
                    row.kind.equals(write.kind.storageKey) &
                    row.queuedAt.equals(write.queuedAt) &
                    row.payload.equals(write.rawPayload),
              ))
              .getSingleOrNull();
      if (row == null) return false;

      final failureCount = row.failureCount + 1;
      final abandoned = failureCount >= abandonAfterConsecutiveFailures;
      await (_db.update(_db.pendingCharacterWrites)..where(
            (row) =>
                row.characterId.equals(write.characterId) &
                row.ownerId.equals(write.ownerId) &
                row.kind.equals(write.kind.storageKey) &
                row.queuedAt.equals(write.queuedAt) &
                row.payload.equals(write.rawPayload),
          ))
          .write(
            PendingCharacterWritesCompanion(
              failureCount: Value(failureCount),
              abandoned: Value(abandoned),
              lastFailureMessage: abandoned
                  ? Value(reason)
                  : const Value.absent(),
            ),
          );
      return abandoned;
    });
  }

  /// Messages des entrées abandonnées de [ownerId] (toutes, tous personnages
  /// confondus) — à afficher **une seule fois** : chaque appel supprime
  /// définitivement les lignes renvoyées, elles ne sont donc jamais signalées
  /// deux fois (voir `CharacterWriteSyncCoordinator`, seul appelant prévu,
  /// qui les affiche par un `SnackBar` global dès qu'il en reçoit).
  Future<List<String>> consumeAbandonedMessages({required String ownerId}) {
    return _db.transaction(() async {
      final rows =
          await (_db.select(_db.pendingCharacterWrites)..where(
                (row) =>
                    row.ownerId.equals(ownerId) & row.abandoned.equals(true),
              ))
              .get();
      if (rows.isEmpty) return const <String>[];

      await (_db.delete(_db.pendingCharacterWrites)..where(
            (row) => row.ownerId.equals(ownerId) & row.abandoned.equals(true),
          ))
          .go();

      return [
        for (final row in rows)
          row.lastFailureMessage ?? _fallbackAbandonMessage,
      ];
    });
  }
}

/// Repli si [PendingCharacterWrites.lastFailureMessage] est resté vide alors
/// que la ligne est abandonnée — ne devrait jamais arriver en pratique
/// (`recordNonRetryableFailure` le renseigne toujours au moment de
/// l'abandon), gardé par robustesse plutôt que de risquer un message vide.
const _fallbackAbandonMessage =
    "Une modification restée en attente a été refusée par le serveur et n'a "
    'pas pu être enregistrée.';
