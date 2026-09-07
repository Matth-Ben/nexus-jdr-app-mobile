import 'package:supabase_flutter/supabase_flutter.dart';

import '../../characters/data/character_error_mapper.dart';
import '../../characters/domain/character_detail.dart';
import '../../characters/domain/character_failure.dart';
import '../domain/shared_character_mapper.dart';

/// Passerelle vers le partage en lecture seule d'un personnage
/// (`docs/cahier-des-charges/12-partage-et-groupes.md` section 1) — trois
/// opérations, toutes portées côté base par les migrations
/// `supabase/migrations/20260908*` du dépôt web :
/// - [regenerateShareToken] : génère (et écrase) `characters.share_token`
///   pour le personnage du propriétaire connecté.
/// - [disableShareToken] : le repasse à `null` (désactive le partage).
/// - [fetchSharedCharacter] : consultation en lecture seule, sans
///   authentification, par n'importe quel détenteur du token.
abstract class CharacterSharingRepository {
  /// Régénère et retourne le nouveau `share_token` du personnage
  /// [characterId] — invalide l'ancien de fait (une seule colonne,
  /// écrasée). Lève une [CharacterFailure] si [characterId] n'existe pas ou
  /// n'appartient pas à l'utilisateur connecté (`public
  /// .regenerate_character_share_token`, code Postgres `P0002`).
  Future<String> regenerateShareToken(String characterId);

  /// Désactive le partage : repasse `share_token` à `null`. Sans effet
  /// (silencieux) si le partage était déjà désactivé.
  Future<void> disableShareToken(String characterId);

  /// Consulte la fiche complète en lecture seule associée à [token] — sans
  /// authentification, n'importe quel détenteur du token peut appeler cette
  /// méthode. Retourne `null` si [token] ne correspond à aucun personnage
  /// dont le partage est actif (token révoqué, jamais généré, ou mal
  /// recopié) : à distinguer par l'appelant d'une erreur réseau (celle-ci
  /// lève une [CharacterFailure], `null` est un résultat légitime).
  Future<CharacterDetail?> fetchSharedCharacter(String token);
}

class SupabaseCharacterSharingRepository implements CharacterSharingRepository {
  const SupabaseCharacterSharingRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<String> regenerateShareToken(String characterId) async {
    try {
      final result = await _client.rpc(
        'regenerate_character_share_token',
        params: {'p_character_id': characterId},
      );
      return result as String;
    } on PostgrestException catch (error) {
      // `public.regenerate_character_share_token` lève cette exception
      // applicative (voir sa doc de classe côté migration) quand
      // [characterId] n'existe pas ou n'appartient pas à l'utilisateur
      // connecté — message dédié plutôt que le générique de
      // [mapCharacterError] (qui ne connaît que le code RLS `42501`,
      // jamais atteint ici : cette fonction est `security invoker`, donc
      // l'`UPDATE` interne échoue silencieusement — 0 ligne — avant de
      // lever P0002 elle-même, jamais un refus RLS brut).
      if (error.code == 'P0002') {
        return Future.error(
          const CharacterFailure(
            'Ce personnage est introuvable ou ne vous appartient plus.',
          ),
        );
      }
      return Future.error(mapCharacterError(error));
    } catch (_) {
      return Future.error(mapUnknownCharacterError());
    }
  }

  @override
  Future<void> disableShareToken(String characterId) async {
    // `.eq('owner_id', ...)` explicite en plus du filtre `id` : redondant
    // avec la policy RLS "Owner can update their characters" (déjà seule
    // responsable d'empêcher qu'un joueur désactive le partage du
    // personnage d'un autre), mais gardé pour la clarté et pour ne jamais
    // dépendre implicitement d'une policy qu'on ne voit pas depuis ce
    // dépôt — même convention que `SupabaseCharacterRepository.setDead`.
    final ownerId = _client.auth.currentUser?.id;
    if (ownerId == null) {
      throw const CharacterFailure('Session expirée. Reconnectez-vous.');
    }

    try {
      await _client
          .from('characters')
          .update({'share_token': null})
          .eq('id', characterId)
          .eq('owner_id', ownerId);
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<CharacterDetail?> fetchSharedCharacter(String token) async {
    try {
      final result = await _client.rpc(
        'get_shared_character',
        params: {'p_token': token},
      );
      if (result == null) return null;
      return mapSharedCharacterJson(result as Map<String, dynamic>);
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }
}
