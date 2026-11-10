import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/pending_character_write_queue.dart';
import '../../../core/cache/reference_data_cache.dart';
import '../../../core/crash_reporting/crash_reporter.dart';
import '../../../core/network/connectivity_checker.dart';
import '../../../core/network/transport_failure.dart';
import '../domain/character_failure.dart';
import '../domain/condition_type.dart';
import '../domain/write_outcome.dart';
import 'character_detail_cache.dart';
import 'character_error_mapper.dart';

/// Écriture des conditions d'un personnage (P6, P6b) — `characters.conditions`.
///
/// Classe dédiée plutôt qu'une méthode de `CharacterRepository` (décision de
/// P6, conservée : l'interface `CharacterRepository` n'a pas à gagner une
/// méthode de plus que tous ses doubles de test devraient implémenter).
///
/// Mode hors-ligne (P6b) : l'écriture est **mise en file**
/// ([PendingCharacterWriteKind.conditions], dernière écriture gagnante) et
/// [WriteOutcome.queued] est renvoyé, comme pour les PV. Le rejeu est fait
/// par `PendingCharacterWriteSyncer`. Un refus Postgrest (RLS, contrainte)
/// n'est jamais mis en file : il remonte comme un échec.
abstract class CharacterConditionsRepository {
  /// Remplace **entièrement** le tableau `characters.conditions` par
  /// [conditions] (clés canoniques, sans doublon).
  ///
  /// [unknownKeys] : clés non reconnues lues avec la fiche, réinjectées dans
  /// le tableau écrit (une condition d'une version plus récente n'est jamais
  /// supprimée) ; désélectionner une condition connue reste effectif.
  ///
  /// Le dépôt ne suppose jamais un accès plus large que la RLS
  /// (`auth.uid() = owner_id`) : une mise à jour qui n'affecte aucune ligne
  /// (RLS qui refuse en silence) est remontée comme un refus d'accès.
  ///
  /// Hors ligne, ou si la requête n'aboutit pas (erreur de transport) :
  /// [WriteOutcome.queued].
  Future<WriteOutcome> setConditions({
    required String characterId,
    required List<ConditionType> conditions,
    List<String> unknownKeys = const [],
  });
}

class SupabaseCharacterConditionsRepository
    implements CharacterConditionsRepository {
  SupabaseCharacterConditionsRepository(
    this._client,
    this._connectivity,
    this._pendingWrites,
    ReferenceDataCache cache,
  ) : _detailCache = CharacterDetailCache(cache);

  final SupabaseClient _client;
  final ConnectivityChecker _connectivity;
  final PendingCharacterWriteQueue _pendingWrites;
  final CharacterDetailCache _detailCache;

  static const _kind = PendingCharacterWriteKind.conditions;

  @override
  Future<WriteOutcome> setConditions({
    required String characterId,
    required List<ConditionType> conditions,
    List<String> unknownKeys = const [],
  }) async {
    final ownerId = _client.auth.currentUser?.id;
    if (ownerId == null) {
      throw const CharacterFailure(
        'Session expirée. Reconnectez-vous pour continuer.',
      );
    }
    // Tableau complet de clés, clés inconnues préservées : c'est aussi le
    // payload de la file (valeur absolue, dernière écriture gagnante).
    final storage = ConditionType.toStorage(
      conditions,
      unknownKeys: unknownKeys,
    );

    Future<WriteOutcome> enqueue() async {
      await _pendingWrites.enqueue(
        characterId: characterId,
        ownerId: ownerId,
        kind: _kind,
        targetId: '',
        payload: {'conditions': storage},
      );
      return WriteOutcome.queued;
    }

    if (!await _connectivity.hasConnection()) {
      return enqueue();
    }

    try {
      // Verrouillé : jamais en vol en même temps que le rejeu de la file
      // pour ce personnage (même rationale que `updateHp`, D33).
      await _pendingWrites.runExclusive(
        characterId: characterId,
        kind: _kind,
        targetId: '',
        action: () async {
          final superseded = await _queuedEntry(
            ownerId: ownerId,
            characterId: characterId,
          );
          final updated = await _client
              .from('characters')
              .update({'conditions': storage})
              .eq('id', characterId)
              .eq('owner_id', ownerId)
              .select('id');
          if (updated.isEmpty) {
            throw const CharacterFailure(
              "Vous n'avez pas accès à ce personnage.",
              code: CharacterErrorCode.accessDenied,
            );
          }
          // L'écriture en ligne rend l'éventuelle entrée en file périmée :
          // retrait conditionnel, puis report dans le cache de la fiche.
          if (superseded != null) {
            try {
              await _pendingWrites.removeIfUnchanged(superseded);
            } catch (_) {
              // Best-effort : l'écriture serveur a réussi.
            }
          }
          await _detailCache.applyConfirmedColumns(
            ownerId: ownerId,
            characterId: characterId,
            columns: {'conditions': storage},
          );
        },
      );
      return WriteOutcome.synced;
    } on CharacterFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (error, stackTrace) {
      if (isTransportFailure(error)) {
        // Même traitement que `updateHp` (D12/D184) : la requête n'a pas
        // abouti, rien n'indique qu'un nouvel essai échouerait.
        return enqueue();
      }
      reportNonFatal(error, stackTrace);
      throw mapUnknownCharacterError();
    }
  }

  Future<PendingCharacterWrite?> _queuedEntry({
    required String ownerId,
    required String characterId,
  }) async {
    try {
      final pending = await _pendingWrites.forCharacter(
        ownerId: ownerId,
        characterId: characterId,
      );
      for (final write in pending) {
        if (write.kind == _kind) return write;
      }
    } catch (_) {
      // Best-effort : rien ne sera retiré de la file après l'écriture.
    }
    return null;
  }
}
