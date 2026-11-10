import '../../../core/cache/app_database.dart';
import '../../../core/cache/pending_character_write_queue.dart';
import '../../../core/cache/sync_alert_store.dart';
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

  Future<void> recordConflict({
    required String ownerId,
    required ServerValueConflict conflict,
  }) async {
    final row = await _detailCache.readRow(
      ownerId: ownerId,
      characterId: conflict.characterId,
    );
    await _alerts.add(
      ownerId: ownerId,
      kind: SyncAlertKind.conflict,
      characterId: conflict.characterId,
      characterName: (row?['name'] as String?) ?? '',
      dataKind: conflict.kind.storageKey,
      // Monnaies : totaux serveur trouvés au rejeu (pas d'UI avant T8, le
      // bandeau retombe sur son texte de repli).
      serverValue: conflict.kind == PendingCharacterWriteKind.currency
          ? Map<String, dynamic>.from(conflict.serverValue)
          : {
              'currentHp': conflict.serverValue['currentHp'],
              'maxHp': (row?['max_hp'] as num?)?.toInt(),
            },
    );
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
