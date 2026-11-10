import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/connectivity_checker.dart';
import '../domain/character_failure.dart';
import '../domain/condition_type.dart';
import '../domain/write_outcome.dart';
import 'character_error_mapper.dart';

/// Écriture des conditions d'un personnage (P6) — `characters.conditions`.
///
/// Classe dédiée plutôt qu'une méthode de `CharacterRepository` : la tranche
/// hors-ligne T1 (file d'écriture, schéma drift) remanie ce dépôt en
/// parallèle, et la mise en file des conditions viendra dans une PR
/// ultérieure (P6b) — elle pourra alors rapatrier cette méthode.
///
/// Mode hors-ligne : [WriteOutcome.rejectedOffline], rien n'est écrit ni mis
/// en file (l'appelant affiche `characterOfflineNotPersistedMessage` et
/// conserve la sélection saisie).
abstract class CharacterConditionsRepository {
  /// Remplace **entièrement** le tableau `characters.conditions` par
  /// [conditions] (clés canoniques, sans doublon).
  ///
  /// Le dépôt ne suppose jamais un accès plus large que la RLS
  /// (`auth.uid() = owner_id`) : une mise à jour qui n'affecte aucune ligne
  /// (RLS qui refuse en silence) est remontée comme un refus d'accès.
  Future<WriteOutcome> setConditions({
    required String characterId,
    required List<ConditionType> conditions,
  });
}

class SupabaseCharacterConditionsRepository
    implements CharacterConditionsRepository {
  SupabaseCharacterConditionsRepository(this._client, this._connectivity);

  final SupabaseClient _client;
  final ConnectivityChecker _connectivity;

  @override
  Future<WriteOutcome> setConditions({
    required String characterId,
    required List<ConditionType> conditions,
  }) async {
    final ownerId = _client.auth.currentUser?.id;
    if (ownerId == null) {
      throw const CharacterFailure(
        'Session expirée. Reconnectez-vous pour continuer.',
      );
    }
    if (!await _connectivity.hasConnection()) {
      return WriteOutcome.rejectedOffline;
    }

    try {
      final updated = await _client
          .from('characters')
          .update({'conditions': ConditionType.toStorage(conditions)})
          .eq('id', characterId)
          .eq('owner_id', ownerId)
          .select('id');
      if (updated.isEmpty) {
        throw const CharacterFailure(
          "Vous n'avez pas accès à ces personnages.",
          code: CharacterErrorCode.accessDenied,
        );
      }
      return WriteOutcome.synced;
    } on CharacterFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }
}
