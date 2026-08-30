import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/pending_character_write_queue.dart';

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
  const PendingCharacterWriteSyncer(this._client, this._pendingWrites);

  final SupabaseClient _client;
  final PendingCharacterWriteQueue _pendingWrites;

  /// Tente d'écrire en base chaque entrée en attente du joueur actuellement
  /// connecté (aucune tentative si personne n'est connecté). Une entrée dont
  /// l'écriture réussit est supprimée de la file ; une entrée dont
  /// l'écriture échoue est laissée telle quelle pour une prochaine tentative
  /// — [sync] ne lève jamais d'exception, chaque échec individuel est
  /// silencieusement absorbé (best-effort, cohérent avec le reste du
  /// mécanisme de cache/synchro de ce dépôt).
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

    for (final write in pending) {
      try {
        await _writeDirectly(write, ownerId: ownerId);
        await _pendingWrites.remove(
          characterId: write.characterId,
          kind: write.kind,
        );
        synced.add(write.characterId);
      } catch (_) {
        // Laisse l'entrée pour la prochaine tentative — voir la doc de
        // [sync].
      }
    }

    return synced;
  }

  Future<void> _writeDirectly(
    PendingCharacterWrite write, {
    required String ownerId,
  }) {
    switch (write.kind) {
      case PendingCharacterWriteKind.hp:
        return _client
            .from('characters')
            .update({
              'current_hp': (write.payload['currentHp'] as num).toInt(),
              'temporary_hp': (write.payload['temporaryHp'] as num).toInt(),
            })
            .eq('id', write.characterId)
            .eq('owner_id', ownerId);
      case PendingCharacterWriteKind.xp:
        return _client
            .from('characters')
            .update({'xp': (write.payload['newXp'] as num).toInt()})
            .eq('id', write.characterId)
            .eq('owner_id', ownerId);
    }
  }
}
