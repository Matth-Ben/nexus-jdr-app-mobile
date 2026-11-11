import '../../../core/cache/app_database.dart';
import '../../../core/cache/pending_character_write_queue.dart';
import '../../../core/cache/sync_alert_store.dart';
import '../../../core/sync/sync_alert_payload.dart';
import 'character_detail_cache.dart';
import 'pending_character_write_syncer.dart';

/// Transforme un abandon d'écriture ou un conflit F19 en [SyncAlert]
/// persistée (T2 du chantier hors-ligne), en y joignant le nom du personnage
/// et la **dernière valeur serveur connue** — lue dans le cache de la fiche
/// ([CharacterDetailCache.readRow], jamais de requête réseau ici : l'alerte
/// doit pouvoir être enregistrée même si le réseau retombe).
///
/// Limite assumée (C1 de la relecture de #254, jugé trop invasif de lire la
/// valeur dans le syncer : la course avec l'invalidation de la fiche resterait
/// possible) : les textes parlent de « dernière valeur connue ». Pour un abandon, cette valeur est celle du dernier état
/// confirmé par le serveur que l'app a vu (la fiche, relue juste après,
/// affichera la valeur serveur réelle). `PendingCharacterWriteKind.innateSpell`/
/// `classFeature`/`rest` n'ont pas de valeur simple à citer : alerte de repli
/// (sans valeur).
class SyncAlertRecorder {
  SyncAlertRecorder(this._db, this._queue, this._alerts, this._detailCache);

  final AppDatabase _db;
  final PendingCharacterWriteQueue _queue;
  final SyncAlertStore _alerts;
  final CharacterDetailCache _detailCache;

  /// Consomme les entrées abandonnées de [ownerId] ET les enregistre comme
  /// alertes **dans une même transaction** : l'app tuée entre les deux ne
  /// peut ni perdre le message ni le dupliquer. Renvoie les entrées
  /// consommées (le coordinateur en invalide les fiches).
  Future<List<AbandonedWrite>> recordAbandoned(String ownerId) {
    return _db.transaction(() async {
      final abandoned = await _queue.consumeAbandoned(ownerId: ownerId);
      for (final entry in abandoned) {
        final row = await _detailCache.readRow(
          ownerId: ownerId,
          characterId: entry.characterId,
        );
        await _alerts.add(
          ownerId: ownerId,
          kind: SyncAlertKind.abandon,
          characterId: entry.characterId,
          characterName: (row?['name'] as String?) ?? '',
          dataKind: entry.kindKey,
          serverValue: _serverValueOf(
            row,
            kindKey: entry.kindKey,
            payload: entry.payload,
          ),
        );
      }
      return abandoned;
    });
  }

  /// Enregistre un conflit F19 (T8) : alerte **non bloquante** (l'écriture est
  /// déjà partie). Si une alerte de conflit non fermée existe pour le même
  /// (compte, personnage, `dataKind`), elle est **mise à jour** (plus ancienne
  /// valeur serveur, plus récente valeur appliquée — voir
  /// [mergeConflictValue]) au lieu d'être doublée : c'est aussi ce qui regroupe
  /// plusieurs objets du même personnage d'une passe de rejeu en une alerte.
  Future<void> recordConflict({
    required String ownerId,
    required ServerValueConflict conflict,
  }) async {
    final row = await _detailCache.readRow(
      ownerId: ownerId,
      characterId: conflict.characterId,
    );
    final itemName = conflict.kind == PendingCharacterWriteKind.inventoryItem
        ? await _detailCache.readInventoryItemName(
            ownerId: ownerId,
            characterId: conflict.characterId,
            inventoryId: conflict.targetId,
          )
        : null;
    final incoming = _conflictValue(conflict, row: row, itemName: itemName);
    final dataKind = conflict.kind.storageKey;
    final name = (row?['name'] as String?) ?? '';
    await _db.transaction(() async {
      final existing = await _alerts.findOpenConflict(
        ownerId: ownerId,
        characterId: conflict.characterId,
        dataKind: dataKind,
      );
      if (existing == null) {
        await _alerts.add(
          ownerId: ownerId,
          kind: SyncAlertKind.conflict,
          characterId: conflict.characterId,
          characterName: name,
          dataKind: dataKind,
          serverValue: incoming,
        );
        return;
      }
      await _alerts.updateValue(
        ownerId: ownerId,
        id: existing.id,
        characterName: name.isEmpty ? existing.characterName : name,
        serverValue: mergeConflictValue(
          dataKind,
          existing.serverValue,
          incoming,
        ),
      );
    });
  }

  static Map<String, dynamic> _conflictValue(
    ServerValueConflict conflict, {
    required Map<String, dynamic>? row,
    required String? itemName,
  }) {
    final server = conflict.serverValue;
    final queued = conflict.queuedValue;
    switch (conflict.kind) {
      case PendingCharacterWriteKind.hp:
        return {
          SyncAlertKeys.currentHp: server['currentHp'],
          SyncAlertKeys.temporaryHp: server['temporaryHp'],
          SyncAlertKeys.maxHp: (row?['max_hp'] as num?)?.toInt(),
          SyncAlertKeys.queued: {
            SyncAlertKeys.currentHp: queued['currentHp'],
            SyncAlertKeys.temporaryHp: queued['temporaryHp'],
          },
        };
      case PendingCharacterWriteKind.currency:
        return {
          ...server,
          SyncAlertKeys.queued: Map<String, dynamic>.from(queued),
        };
      case PendingCharacterWriteKind.inventoryItem:
        return {
          SyncAlertKeys.items: [
            {
              SyncAlertKeys.itemId: conflict.targetId,
              SyncAlertKeys.itemName: itemName,
              SyncAlertKeys.itemServer: server['quantity'],
              SyncAlertKeys.itemQueued: queued['quantity'],
            },
          ],
        };
      case PendingCharacterWriteKind.xp:
        return {
          SyncAlertKeys.xp: server['xp'],
          SyncAlertKeys.queued: queued['xp'],
        };
      default:
        return Map<String, dynamic>.from(server);
    }
  }

  static Map<String, dynamic>? _serverValueOf(
    Map<String, dynamic>? row, {
    required String kindKey,
    required Map<String, dynamic> payload,
  }) {
    if (row == null) return null;
    if (kindKey == PendingCharacterWriteKind.hp.storageKey) {
      final current = (row['current_hp'] as num?)?.toInt();
      final max = (row['max_hp'] as num?)?.toInt();
      if (current == null || max == null) return null;
      return {'currentHp': current, 'maxHp': max};
    }
    if (kindKey == PendingCharacterWriteKind.xp.storageKey) {
      final xp = (row['xp'] as num?)?.toInt();
      return xp == null ? null : {'xp': xp};
    }
    if (kindKey == PendingCharacterWriteKind.spellSlot.storageKey) {
      final level = (payload['slotLevel'] as num?)?.toInt();
      if (level == null) return null;
      final pact = payload['isPactSlot'] == true;
      final raw = row[pact ? 'character_pact_slots' : 'character_spell_slots'];
      final slotRows = raw is List ? raw : (raw is Map ? [raw] : const []);
      for (final slot in slotRows) {
        if (slot is Map && (slot['slot_level'] as num?)?.toInt() == level) {
          final total = (slot['slots_total'] as num?)?.toInt();
          final used = (slot['slots_used'] as num?)?.toInt();
          if (total == null || used == null) return null;
          return {'level': level, 'remaining': total - used, 'max': total};
        }
      }
    }
    return null;
  }
}
