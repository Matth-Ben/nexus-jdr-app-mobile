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
  const PendingCharacterWriteQueue(this._db);

  final AppDatabase _db;

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
  Future<List<PendingCharacterWrite>> forCharacter({
    required String ownerId,
    required String characterId,
  }) async {
    final rows =
        await (_db.select(_db.pendingCharacterWrites)..where(
              (row) =>
                  row.ownerId.equals(ownerId) &
                  row.characterId.equals(characterId),
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
  /// [PendingCharacterWrites] pour le rationale de ce filtre).
  Future<List<PendingCharacterWrite>> allForOwner(String ownerId) async {
    final rows = await (_db.select(
      _db.pendingCharacterWrites,
    )..where((row) => row.ownerId.equals(ownerId))).get();

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
}
