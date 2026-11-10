import '../../../core/cache/reference_data_cache.dart';
import '../../../core/rules/spell_status.dart';
import '../domain/offline_state_writes.dart';

/// Point unique de connaissance de l'entrée de cache de la fiche personnage
/// (`SupabaseCharacterRepository.fetchCharacterDetail`) : sa clé, et
/// l'emplacement de la ligne `characters` brute dans son payload.
///
/// Partagé par `SupabaseCharacterRepository` (lecture/écriture du cache,
/// écritures PV/XP en ligne) et `PendingCharacterWriteSyncer` (écritures
/// PV/XP synchronisées au retour du réseau), pour que ni l'un ni l'autre ne
/// duplique la forme de ce payload.
class CharacterDetailCache {
  const CharacterDetailCache(this._cache);

  final ReferenceDataCache _cache;

  /// Clé du payload sous laquelle est rangée la ligne `characters` brute
  /// (colonnes PostgREST telles quelles : `current_hp`, `temporary_hp`,
  /// `xp`...) — voir `SupabaseCharacterRepository._buildCharacterDetailPayload`.
  static const String rowKey = 'row';

  /// Clé de cache de la fiche [characterId] du compte [ownerId]. Scopée par
  /// `ownerId` : voir la documentation de classe de
  /// `SupabaseCharacterRepository` ("Isolation par utilisateur").
  static String keyFor({
    required String ownerId,
    required String characterId,
  }) => 'character_detail:$ownerId:$characterId';

  /// Reporte dans la fiche en cache les colonnes de `characters` qu'un
  /// `UPDATE` vient d'écrire **avec succès** côté serveur ([columns] est le
  /// corps même de cet `UPDATE`, ex. `{'current_hp': 7, 'temporary_hp': 0}`).
  ///
  /// Le cache reste ainsi le "dernier état serveur connu" même quand
  /// personne ne relit la fiche après l'écriture : synchronisation faite
  /// fiche fermée (le provider `autoDispose` invalidé par le coordinateur
  /// n'est alors écouté par personne), ou écriture en ligne réussie dont la
  /// relecture échoue. Sans ce report, la fiche rouverte hors ligne
  /// réaffichait la valeur d'avant l'écriture, et l'ajustement suivant en
  /// repartait.
  ///
  /// Jamais appelé pour une valeur seulement mise en file : seule une valeur
  /// confirmée par le serveur entre dans le cache.
  ///
  /// Ne fait rien si la fiche n'est pas en cache (rien à corriger) ou si son
  /// payload n'a pas la forme attendue ; ne touche à aucune autre partie du
  /// payload. Best-effort : l'écriture serveur a déjà réussi, une erreur ici
  /// n'est jamais remontée.
  Future<void> applyConfirmedColumns({
    required String ownerId,
    required String characterId,
    required Map<String, dynamic> columns,
  }) async {
    try {
      await _cache.updateIfPresent(
        keyFor(ownerId: ownerId, characterId: characterId),
        (payload) {
          if (payload is! Map) return null;
          final row = payload[rowKey];
          if (row is! Map) return null;
          return <String, dynamic>{
            ...Map<String, dynamic>.from(payload),
            rowKey: <String, dynamic>{
              ...Map<String, dynamic>.from(row),
              ...columns,
            },
          };
        },
      );
    } catch (_) {
      // Best-effort : voir la documentation de cette méthode.
    }
  }

  /// Reporte dans la fiche en cache un changement **confirmé** d'une relation
  /// enfant de la ligne `characters` ([relation] : `character_spells`,
  /// `character_inventory`...). [transform] reçoit les lignes en cache de la
  /// relation et renvoie les lignes à stocker (T5a). Mêmes garanties que
  /// [applyConfirmedColumns] : rien si la fiche (ou la relation) n'est pas en
  /// cache, best-effort, jamais pour une valeur seulement mise en file.
  Future<void> applyConfirmedRelation({
    required String ownerId,
    required String characterId,
    required String relation,
    required List<Map<String, dynamic>> Function(
      List<Map<String, dynamic>> rows,
    )
    transform,
  }) async {
    try {
      await _cache.updateIfPresent(
        keyFor(ownerId: ownerId, characterId: characterId),
        (payload) {
          if (payload is! Map) return null;
          final row = payload[rowKey];
          if (row is! Map) return null;
          final raw = row[relation];
          if (raw is! List) return null;
          final rows = [
            for (final entry in raw)
              if (entry is Map) Map<String, dynamic>.from(entry),
          ];
          return <String, dynamic>{
            ...Map<String, dynamic>.from(payload),
            rowKey: <String, dynamic>{
              ...Map<String, dynamic>.from(row),
              relation: transform(rows),
            },
          };
        },
      );
    } catch (_) {
      // Best-effort : voir la documentation de cette méthode.
    }
  }

  /// Reporte dans le cache l'état d'un sort confirmé par le serveur (T5a) :
  /// statut sur les lignes ordinaires (jamais une ligne 'inné'), favori sur
  /// toutes les lignes du sort ; une préparation sans aucune ligne en crée une.
  Future<void> applyConfirmedSpellState({
    required String ownerId,
    required String characterId,
    required int spellId,
    required SpellStatePatch patch,
  }) => applyConfirmedRelation(
    ownerId: ownerId,
    characterId: characterId,
    relation: 'character_spells',
    transform: (rows) {
      final hasRow = rows.any((row) => row['spell_id'] == spellId);
      final result = [
        for (final row in rows)
          if (row['spell_id'] != spellId)
            row
          else
            {
              ...row,
              if (patch.prepared != null &&
                  row['status'] != SpellStatus.innate.value)
                'status':
                    (patch.prepared! ? SpellStatus.prepared : SpellStatus.known)
                        .value,
              if (patch.favorite != null) 'is_favorite': patch.favorite,
            },
      ];
      if (!hasRow && patch.prepared == true) {
        result.add({
          'spell_id': spellId,
          'status': SpellStatus.prepared.value,
          'is_favorite': false,
          'source_class_id': null,
          'innate_uses_spent': 0,
        });
      }
      return result;
    },
  );

  /// Reporte dans le cache l'état d'un objet d'inventaire confirmé par le
  /// serveur (T5a).
  Future<void> applyConfirmedInventoryState({
    required String ownerId,
    required String characterId,
    required String inventoryId,
    required InventoryStatePatch patch,
  }) => applyConfirmedRelation(
    ownerId: ownerId,
    characterId: characterId,
    relation: 'character_inventory',
    transform: (rows) => [
      for (final row in rows)
        if (row['id'] == inventoryId) {...row, ...patch.toColumns()} else row,
    ],
  );

  /// Ligne `characters` brute en cache (dernier état serveur connu), `null`
  /// si la fiche n'est pas en cache ou de forme inattendue. Sert à composer
  /// les alertes de synchro (nom du personnage, valeur serveur).
  Future<Map<String, dynamic>?> readRow({
    required String ownerId,
    required String characterId,
  }) async {
    try {
      final payload = await _cache.get(
        keyFor(ownerId: ownerId, characterId: characterId),
      );
      if (payload is! Map) return null;
      final row = payload[rowKey];
      if (row is! Map) return null;
      return Map<String, dynamic>.from(row);
    } catch (_) {
      return null;
    }
  }

  /// PV (courants, temporaires) de la ligne `characters` en cache, c'est-à-
  /// dire la dernière valeur **confirmée par le serveur** connue de l'app
  /// (le cache ne reçoit jamais une valeur seulement mise en file) — base de
  /// comparaison de la détection de modification concurrente (F19/D178).
  /// `null` si la fiche n'est pas en cache ou si les colonnes manquent.
  Future<({int currentHp, int temporaryHp})?> readHp({
    required String ownerId,
    required String characterId,
  }) async {
    try {
      final payload = await _cache.get(
        keyFor(ownerId: ownerId, characterId: characterId),
      );
      if (payload is! Map) return null;
      final row = payload[rowKey];
      if (row is! Map) return null;
      final current = row['current_hp'];
      final temporary = row['temporary_hp'];
      if (current is! num || temporary is! num) return null;
      return (currentHp: current.toInt(), temporaryHp: temporary.toInt());
    } catch (_) {
      return null;
    }
  }

  /// Reporte dans la fiche en cache un `slots_used` confirmé par le serveur
  /// pour un emplacement de sort (D185) : `character_spell_slots` (liste de
  /// lignes, une par niveau) ou `character_pact_slots` (objet unique, ou
  /// liste à un élément — voir `CharacterDetailRowMapper.parsePactSpellSlot`).
  /// Mêmes garanties que [applyConfirmedColumns] (rien si la fiche n'est pas
  /// en cache, best-effort, jamais pour une valeur seulement mise en file).
  Future<void> applyConfirmedSpellSlot({
    required String ownerId,
    required String characterId,
    required int slotLevel,
    required int slotsUsed,
    required bool isPactSlot,
  }) async {
    final column = isPactSlot
        ? 'character_pact_slots'
        : 'character_spell_slots';
    Map<String, dynamic> patched(Map<dynamic, dynamic> slotRow) {
      final copy = Map<String, dynamic>.from(slotRow);
      if ((copy['slot_level'] as num?)?.toInt() == slotLevel) {
        copy['slots_used'] = slotsUsed;
      }
      return copy;
    }

    try {
      await _cache.updateIfPresent(
        keyFor(ownerId: ownerId, characterId: characterId),
        (payload) {
          if (payload is! Map) return null;
          final row = payload[rowKey];
          if (row is! Map) return null;
          final raw = row[column];
          final Object updated;
          if (raw is List) {
            updated = [
              for (final entry in raw) entry is Map ? patched(entry) : entry,
            ];
          } else if (raw is Map) {
            updated = patched(raw);
          } else {
            return null;
          }
          return <String, dynamic>{
            ...Map<String, dynamic>.from(payload),
            rowKey: <String, dynamic>{
              ...Map<String, dynamic>.from(row),
              column: updated,
            },
          };
        },
      );
    } catch (_) {
      // Best-effort : voir la documentation de cette méthode.
    }
  }
}
