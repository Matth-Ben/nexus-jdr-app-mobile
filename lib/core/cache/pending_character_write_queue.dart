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
/// [PendingCharacterWriteQueue.allForOwner].
class PendingCharacterWrite {
  const PendingCharacterWrite({
    required this.characterId,
    required this.ownerId,
    required this.kind,
    required this.payload,
  });

  final String characterId;
  final String ownerId;
  final PendingCharacterWriteKind kind;

  /// `{"currentHp": ..., "temporaryHp": ...}` pour [PendingCharacterWriteKind.hp],
  /// `{"newXp": ...}` pour [PendingCharacterWriteKind.xp] — voir
  /// `SupabaseCharacterRepository.updateHp`/`addXp`.
  final Map<String, dynamic> payload;
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
  Future<void> enqueue({
    required String characterId,
    required String ownerId,
    required PendingCharacterWriteKind kind,
    required Map<String, dynamic> payload,
  }) async {
    await _db
        .into(_db.pendingCharacterWrites)
        .insertOnConflictUpdate(
          PendingCharacterWritesCompanion.insert(
            characterId: characterId,
            ownerId: ownerId,
            kind: kind.storageKey,
            payload: jsonEncode(payload),
            queuedAt: DateTime.now(),
          ),
        );
  }

  /// Supprime l'entrée `(characterId, kind)` — appelé après une
  /// synchronisation réussie (`PendingCharacterWriteSyncer.sync`). Ne fait
  /// rien si aucune entrée n'existait déjà pour cette clé.
  Future<void> remove({
    required String characterId,
    required PendingCharacterWriteKind kind,
  }) async {
    await (_db.delete(_db.pendingCharacterWrites)..where(
          (row) =>
              row.characterId.equals(characterId) &
              row.kind.equals(kind.storageKey),
        ))
        .go();
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
        ),
    ];
  }
}
