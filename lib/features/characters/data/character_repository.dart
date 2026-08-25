import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/character_failure.dart';
import '../domain/character_summary.dart';
import 'character_error_mapper.dart';
import 'character_row_mapper.dart';

/// Langue d'affichage des noms de race/classe, en dur pour l'instant : l'app
/// démarre en français uniquement (`docs/cahier-des-charges/07-source-donnees-i18n.md`),
/// aucune gestion de locale n'existe encore côté client. À remplacer par une
/// vraie préférence de langue le jour où l'anglais est introduit.
const String _locale = 'fr';

/// Passerelle vers les personnages du joueur connecté.
///
/// Abstraction (plutôt qu'une classe concrète directement injectée) pour
/// permettre aux tests de fournir un double sans jamais toucher à
/// `Supabase.instance.client` — même principe que `AuthRepository`
/// (`features/auth/data/auth_repository.dart`).
abstract class CharacterRepository {
  /// Récupère tous les personnages du joueur connecté, dans leur ordre de
  /// création.
  Future<List<CharacterSummary>> fetchCharacters();
}

/// Implémentation réelle, basée sur `Supabase.instance.client`.
///
/// La table `characters` est protégée par RLS (`owner_id = auth.uid()`,
/// voir `02-modele-donnees.md`) : le filtre explicite sur `owner_id`
/// ci-dessous est donc redondant avec la policy serveur, mais gardé pour la
/// clarté de la requête (et pour ne jamais dépendre implicitement d'une
/// policy qu'on ne voit pas depuis ce dépôt).
///
/// Note : les noms de race/classe sont résolus via la table `translations`
/// (colonnes réelles `entity_type`, `entity_id`, `field_name`, `locale`,
/// `value`) plutôt que par un `select` imbriqué unique. `translations` est
/// une table
/// polymorphe (un même `entity_id` peut désigner une ligne de `races`, de
/// `classes`, etc. selon `entity_type`) : PostgREST ne peut pas déduire de
/// relation de clé étrangère pour l'embarquer automatiquement dans le
/// `select` de `characters`. On récupère donc d'abord les personnages (avec
/// leurs `race_id`/`class_id` bruts), puis on résout les noms en une requête
/// `translations` par type d'entité, filtrée sur les identifiants
/// effectivement rencontrés.
class SupabaseCharacterRepository implements CharacterRepository {
  const SupabaseCharacterRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<CharacterSummary>> fetchCharacters() async {
    final ownerId = _client.auth.currentUser?.id;
    if (ownerId == null) {
      throw const CharacterFailure(
        'Session expirée. Reconnectez-vous pour voir vos personnages.',
      );
    }

    try {
      final characterRows = await _client
          .from('characters')
          .select('''
            id,
            name,
            portrait_url,
            xp,
            race_id,
            character_classes(class_id, level, is_primary)
          ''')
          .eq('owner_id', ownerId)
          .order('created_at');

      final raceIds = CharacterRowMapper.collectRaceIds(characterRows);
      final classIds = CharacterRowMapper.collectClassIds(characterRows);

      final raceNames = await _fetchTranslatedNames(
        entityType: 'race',
        entityIds: raceIds,
      );
      final classNames = await _fetchTranslatedNames(
        entityType: 'class',
        entityIds: classIds,
      );

      return characterRows
          .map(
            (row) => CharacterRowMapper.toSummary(
              row,
              raceNames: raceNames,
              classNames: classNames,
            ),
          )
          .toList();
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  /// Récupère `{entity_id: name}` pour toutes les traductions `entityType`
  /// dont l'identifiant est dans [entityIds]. Retourne une map vide sans
  /// requête si [entityIds] est vide (rien à résoudre). Le parsing de la
  /// réponse est délégué à [CharacterRowMapper.parseTranslatedNames] (testé
  /// indépendamment du réseau).
  Future<Map<String, String>> _fetchTranslatedNames({
    required String entityType,
    required Set<String> entityIds,
  }) async {
    if (entityIds.isEmpty) {
      return const {};
    }

    final rows = await _client
        .from('translations')
        .select('entity_id, value')
        .eq('entity_type', entityType)
        .eq('field_name', 'name')
        .eq('locale', _locale)
        .inFilter('entity_id', entityIds.toList());

    return CharacterRowMapper.parseTranslatedNames(rows);
  }
}
