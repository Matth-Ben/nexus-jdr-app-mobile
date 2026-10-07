import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/pending_character_write_queue.dart';
import '../../../core/cache/reference_data_cache.dart';
import 'character_detail_cache.dart';

/// Vide, best-effort, la file d'attente [PendingCharacterWrites]
/// (`core/cache/pending_character_write_queue.dart`) en écrivant directement
/// en base chaque entrée en attente — jamais via
/// `CharacterRepository.updateHp`/`addXp`, qui referaient la vérification de
/// connectivité déjà acquise à ce stade par l'appelant (voir
/// `presentation/providers/character_write_sync_coordinator.dart`, seul
/// appelant de [sync]).
///
/// Volontairement séparée de `SupabaseCharacterRepository` (pas une méthode
/// de plus sur `CharacterRepository`) : cette synchro n'est jamais déclenchée
/// depuis un écran (qui dépend de l'abstraction `CharacterRepository` pour
/// pouvoir être testé avec un double), seulement depuis le coordinateur de
/// synchro — ajouter cette méthode à l'interface aurait forcé tous les
/// doubles de test de ce dépôt à l'implémenter pour rien.
///
/// Isolation par utilisateur : ne considère jamais que les entrées de
/// [ownerId] du joueur actuellement connecté (voir
/// `PendingCharacterWriteQueue.allForOwner`) — même garantie que le reste de
/// `SupabaseCharacterRepository`.
class PendingCharacterWriteSyncer {
  PendingCharacterWriteSyncer(
    this._client,
    this._pendingWrites,
    ReferenceDataCache cache,
  ) : _detailCache = CharacterDetailCache(cache);

  final SupabaseClient _client;
  final PendingCharacterWriteQueue _pendingWrites;
  final CharacterDetailCache _detailCache;

  /// Tente d'écrire en base chaque entrée en attente du joueur actuellement
  /// connecté (aucune tentative si personne n'est connecté). Une entrée dont
  /// l'écriture échoue est laissée telle quelle pour une prochaine tentative
  /// — [sync] ne lève jamais d'exception, chaque échec individuel est
  /// silencieusement absorbé (best-effort, cohérent avec le reste du
  /// mécanisme de cache/synchro de ce dépôt).
  ///
  /// Chaque entrée est relue juste avant son envoi (elle a pu être retirée
  /// ou remplacée depuis le relevé initial, voir le corps de la boucle).
  ///
  /// Une entrée dont l'écriture réussit :
  /// - est reportée dans le cache de la fiche
  ///   (`CharacterDetailCache.applyConfirmedColumns`) : la synchro passe
  ///   souvent fiche fermée (démarrage de l'app, retour du réseau), personne
  ///   ne relit alors la fiche et le cache resterait sur l'état serveur
  ///   d'avant ;
  /// - n'est retirée de la file que si elle y est encore telle qu'elle a été
  ///   lue (`PendingCharacterWriteQueue.removeIfUnchanged`) : une valeur
  ///   plus récente mise en file pendant l'écriture réseau reste en file
  ///   pour la prochaine synchro, au lieu d'être supprimée sans jamais avoir
  ///   été envoyée.
  ///
  /// Retourne l'ensemble des identifiants de personnage synchronisés avec
  /// succès, pour que l'appelant puisse invalider
  /// `characterDetailProvider(characterId)` pour chacun d'eux (voir
  /// `character_write_sync_coordinator.dart`) — [PendingCharacterWriteSyncer]
  /// lui-même ne connaît rien de Riverpod.
  Future<Set<String>> sync() async {
    final ownerId = _client.auth.currentUser?.id;
    if (ownerId == null) {
      return const {};
    }

    final pending = await _pendingWrites.allForOwner(ownerId);
    final synced = <String>{};

    for (final listed in pending) {
      try {
        // [pending] est un relevé pris avant le premier envoi : pendant les
        // envois précédents de cette boucle, l'entrée a pu être retirée
        // (écriture en ligne plus récente du même type) ou remplacée
        // (nouvelle mise en file). Elle est donc relue juste avant son
        // propre envoi : absente, on passe ; remplacée, c'est la version
        // relue qui part — et qui est ensuite retirée si elle n'a pas
        // rechangé. Envoyer le relevé d'origine écraserait une valeur plus
        // récente déjà confirmée par le serveur.
        final write = await _currentVersionOf(listed);
        if (write == null) continue;

        final columns = _columnsOf(write);
        await _client
            .from('characters')
            .update(columns)
            .eq('id', write.characterId)
            .eq('owner_id', ownerId);
        // Cache d'abord, retrait ensuite (ordre inverse de celui de
        // `SupabaseCharacterRepository._recordConfirmedWrite`) : si l'app
        // est tuée entre les deux, l'entrée restée en file est égale à la
        // valeur serveur et sera simplement rejouée sans effet.
        await _detailCache.applyConfirmedColumns(
          ownerId: ownerId,
          characterId: write.characterId,
          columns: columns,
        );
        await _pendingWrites.removeIfUnchanged(write);
        synced.add(write.characterId);
      } catch (_) {
        // Laisse l'entrée pour la prochaine tentative — voir la doc de
        // [sync].
      }
    }

    return synced;
  }

  /// Version actuellement en file de l'entrée [listed] (même compte, même
  /// personnage, même type), ou `null` si elle n'y est plus.
  Future<PendingCharacterWrite?> _currentVersionOf(
    PendingCharacterWrite listed,
  ) async {
    final current = await _pendingWrites.forCharacter(
      ownerId: listed.ownerId,
      characterId: listed.characterId,
    );
    for (final write in current) {
      if (write.kind == listed.kind) return write;
    }
    return null;
  }

  /// Colonnes de `characters` écrites pour [write] — à la fois le corps de
  /// l'`UPDATE` envoyé au serveur et ce qui est reporté dans le cache de la
  /// fiche une fois cet `UPDATE` réussi.
  Map<String, dynamic> _columnsOf(PendingCharacterWrite write) {
    switch (write.kind) {
      case PendingCharacterWriteKind.hp:
        return {
          'current_hp': (write.payload['currentHp'] as num).toInt(),
          'temporary_hp': (write.payload['temporaryHp'] as num).toInt(),
        };
      case PendingCharacterWriteKind.xp:
        return {'xp': (write.payload['newXp'] as num).toInt()};
    }
  }
}
