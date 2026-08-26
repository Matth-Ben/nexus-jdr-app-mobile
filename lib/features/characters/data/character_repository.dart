import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/character_detail.dart';
import '../domain/character_failure.dart';
import '../domain/character_summary.dart';
import '../domain/portrait_storage_path_resolver.dart';
import 'character_detail_row_mapper.dart';
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

  /// Récupère le détail complet d'un personnage (onglet "Personnage" de la
  /// fiche, `presentation/character_detail_screen.dart`). Lève une
  /// [CharacterFailure] si [characterId] n'existe pas ou n'appartient pas au
  /// joueur connecté (RLS) — les deux cas sont indistinguables côté client
  /// par construction (la policy RLS filtre la ligne avant qu'elle
  /// n'atteigne PostgREST), ce qui est le comportement voulu : ne jamais
  /// laisser deviner qu'un personnage existe chez un autre joueur.
  Future<CharacterDetail> fetchCharacterDetail(String characterId);

  /// Écrit directement `characters.current_hp`/`temporary_hp` — pas de
  /// brouillon local, contrairement à l'assistant de création : ce
  /// personnage existe déjà. Le calcul des nouvelles valeurs (absorption des
  /// PV temporaires, plafond à `max_hp`...) est fait en amont par
  /// `domain/hp_adjustment.dart`, cette méthode ne fait qu'écrire le
  /// résultat déjà calculé.
  Future<void> updateHp({
    required String characterId,
    required int currentHp,
    required int temporaryHp,
  });

  /// Envoie [bytes] (déjà recadrées en carré, voir
  /// `presentation/widgets/portrait_crop_screen.dart`) dans le bucket
  /// `character-portraits` (RLS écriture restreinte à `{user_id}/...`,
  /// lecture publique), puis met à jour `characters.portrait_url` avec
  /// l'URL publique résultante. Retourne cette URL.
  Future<String> uploadPortrait({
    required String characterId,
    required Uint8List bytes,
  });

  /// Supprime le fichier de portrait actuel du bucket (best-effort si
  /// [portraitUrl] ne pointe pas vers ce bucket, ex. une URL externe saisie
  /// via le flux "Utiliser une URL" — voir
  /// `domain/portrait_storage_path_resolver.dart`) puis met
  /// `characters.portrait_url` à `null`.
  Future<void> removePortrait({
    required String characterId,
    required String portraitUrl,
  });
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
    final ownerId = _requireOwnerId();

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

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) async {
    final ownerId = _requireOwnerId();

    try {
      final row = await _client
          .from('characters')
          .select('''
            id,
            name,
            portrait_url,
            xp,
            current_hp,
            max_hp,
            temporary_hp,
            race_id,
            subrace_id,
            race_custom_text,
            background_id,
            alignment_id,
            character_classes(class_id, level, is_primary, classes(saving_throw_proficiencies)),
            character_ability_scores(ability_id, score)
          ''')
          .eq('id', characterId)
          .eq('owner_id', ownerId)
          .maybeSingle();

      if (row == null) {
        throw const CharacterFailure('Personnage introuvable.');
      }

      final raceNames = await _fetchTranslatedNames(
        entityType: 'race',
        entityIds: CharacterDetailRowMapper.collectRaceIds(row),
      );
      final subraceNames = await _fetchTranslatedNames(
        entityType: 'subrace',
        entityIds: CharacterDetailRowMapper.collectSubraceIds(row),
      );
      final classNames = await _fetchTranslatedNames(
        entityType: 'class',
        entityIds: CharacterDetailRowMapper.collectClassIds(row),
      );
      final backgroundNames = await _fetchTranslatedNames(
        entityType: 'background',
        entityIds: CharacterDetailRowMapper.collectBackgroundIds(row),
      );
      final alignmentNames = await _fetchTranslatedNames(
        entityType: 'alignment',
        entityIds: CharacterDetailRowMapper.collectAlignmentIds(row),
      );

      return CharacterDetailRowMapper.toCharacterDetail(
        row,
        raceNames: raceNames,
        subraceNames: subraceNames,
        classNames: classNames,
        backgroundNames: backgroundNames,
        alignmentNames: alignmentNames,
      );
    } on CharacterFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<void> updateHp({
    required String characterId,
    required int currentHp,
    required int temporaryHp,
  }) async {
    final ownerId = _requireOwnerId();
    try {
      await _client
          .from('characters')
          .update({'current_hp': currentHp, 'temporary_hp': temporaryHp})
          .eq('id', characterId)
          .eq('owner_id', ownerId);
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<String> uploadPortrait({
    required String characterId,
    required Uint8List bytes,
  }) async {
    final ownerId = _requireOwnerId();
    // Un nom de fichier horodaté (plutôt qu'un chemin fixe par personnage)
    // évite tout problème de cache CDN/navigateur sur l'URL publique après
    // un remplacement de portrait — voir `removePortrait` pour la
    // suppression explicite de l'ancien fichier par le joueur.
    final path =
        '$ownerId/$characterId/${DateTime.now().millisecondsSinceEpoch}.png';

    try {
      await _client.storage
          .from(PortraitStoragePathResolver.bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/png',
              upsert: true,
            ),
          );
      final publicUrl = _client.storage
          .from(PortraitStoragePathResolver.bucket)
          .getPublicUrl(path);

      await _client
          .from('characters')
          .update({'portrait_url': publicUrl})
          .eq('id', characterId)
          .eq('owner_id', ownerId);

      return publicUrl;
    } on StorageException catch (error) {
      throw CharacterFailure(
        error.message.isNotEmpty
            ? error.message
            : "Impossible d'envoyer le portrait. Réessayez.",
      );
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<void> removePortrait({
    required String characterId,
    required String portraitUrl,
  }) async {
    final ownerId = _requireOwnerId();
    try {
      final path = PortraitStoragePathResolver.resolve(portraitUrl);
      if (path != null) {
        await _client.storage.from(PortraitStoragePathResolver.bucket).remove([
          path,
        ]);
      }
      await _client
          .from('characters')
          .update({'portrait_url': null})
          .eq('id', characterId)
          .eq('owner_id', ownerId);
    } on StorageException catch (error) {
      throw CharacterFailure(
        error.message.isNotEmpty
            ? error.message
            : 'Impossible de retirer le portrait. Réessayez.',
      );
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  /// Identifiant du joueur connecté, ou lève une [CharacterFailure] "session
  /// expirée" — factorisé depuis [fetchCharacters] pour être réutilisé par
  /// toutes les méthodes ajoutées pour la fiche personnage.
  String _requireOwnerId() {
    final ownerId = _client.auth.currentUser?.id;
    if (ownerId == null) {
      throw const CharacterFailure(
        'Session expirée. Reconnectez-vous pour continuer.',
      );
    }
    return ownerId;
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
