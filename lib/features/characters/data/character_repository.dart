import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/character_class_feature.dart';
import '../domain/character_detail.dart';
import '../domain/character_failure.dart';
import '../domain/character_inventory_item.dart';
import '../domain/character_skill_row.dart';
import '../domain/character_spell_entry.dart';
import '../domain/character_summary.dart';
import '../domain/portrait_storage_path_resolver.dart';
import 'character_detail_row_mapper.dart';
import 'character_error_mapper.dart';
import 'character_inventory_row_mapper.dart';
import 'character_row_mapper.dart';
import 'character_skill_row_mapper.dart';
import 'character_spell_row_mapper.dart';
import 'class_feature_row_mapper.dart';

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
            currency_gp,
            currency_pp,
            currency_ep,
            currency_sp,
            currency_cp,
            appearance_text,
            traits_text,
            ideals_text,
            bonds_text,
            flaws_text,
            backstory_text,
            allies_text,
            features_text,
            treasure_text,
            character_classes(class_id, level, is_primary, classes(saving_throw_proficiencies)),
            character_ability_scores(ability_id, score),
            character_skill_proficiencies(skill_id, proficiency),
            character_tool_proficiencies(tool_id, custom_text),
            character_languages(language_id),
            character_spells(spell_id, status),
            character_spell_slots(slot_level, slots_total, slots_used),
            character_feature_uses(class_feature_id, uses_remaining),
            character_inventory(id, item_id, custom_name, quantity, equipped, items(category, weight))
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

      final skills = await _fetchSkills(row);
      final classFeatures = await _fetchClassFeatures(row);
      final toolProficiencyNames = await _fetchToolProficiencyNames(row);
      final knownLanguageNames = await _fetchLanguageNames(row);
      final spells = await _fetchSpells(row);
      final inventory = await _fetchInventory(row);

      return CharacterDetailRowMapper.toCharacterDetail(
        row,
        raceNames: raceNames,
        subraceNames: subraceNames,
        classNames: classNames,
        backgroundNames: backgroundNames,
        alignmentNames: alignmentNames,
        skills: skills,
        classFeatures: classFeatures,
        toolProficiencyNames: toolProficiencyNames,
        knownLanguageNames: knownLanguageNames,
        spells: spells,
        spellSlots: CharacterDetailRowMapper.parseSpellSlots(row),
        inventory: inventory,
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

  /// Les 18 [CharacterSkillRow] de l'onglet "Compétences" : `skills` est une
  /// table de référence à peuplement fixe (pas liée à `characters`), donc
  /// interrogée intégralement ici plutôt qu'embarquée dans le `select`
  /// principal — contrairement à `character_skill_proficiencies`, qui l'est
  /// (relation réelle vers `characters`).
  Future<List<CharacterSkillRow>> _fetchSkills(Map<String, dynamic> row) async {
    // `ascending: true` explicite : le package `postgrest` (2.9.1) a un
    // défaut `ascending: false` contre-intuitif pour `.order(...)` — bug
    // trouvé en corrigeant le même défaut sur `_fetchClassFeatures`
    // ci-dessous (revue QA) : sans ce paramètre, les 18 compétences
    // ressortaient dans l'ordre alphabétique français *inversé* plutôt que
    // l'ordre attendu (voir la maquette de
    // `character_skills_card.dart`).
    final skillRows = await _client
        .from('skills')
        .select('id, ability_id')
        .order('id', ascending: true);

    final skillNames = await _fetchTranslatedNames(
      entityType: 'skill',
      entityIds: CharacterSkillRowMapper.collectIds(skillRows),
    );

    final proficiencies = CharacterSkillRowMapper.parseProficiencies(
      CharacterDetailRowMapper.skillProficiencyRowsOf(row),
    );

    return CharacterSkillRowMapper.toCharacterSkillRows(
      skillRows,
      names: skillNames,
      proficiencies: proficiencies,
    );
  }

  /// Aptitudes de classe déjà atteintes par le niveau actuel du personnage,
  /// carte "APTITUDES DE CLASSE" — `class_features` n'est pas liée
  /// directement à `characters` (seulement via `classes`), donc interrogée
  /// séparément, filtrée sur les `class_id` du personnage. Retourne une
  /// liste vide sans requête si le personnage n'a aucune classe (brouillon
  /// incomplet).
  Future<List<CharacterClassFeature>> _fetchClassFeatures(
    Map<String, dynamic> row,
  ) async {
    final classIds = CharacterDetailRowMapper.collectClassIdsRaw(row);
    if (classIds.isEmpty) {
      return const [];
    }

    // `.order('level', ascending: true)` : affichage déterministe, important
    // pour un personnage multiclassé où plusieurs `class_id` (donc plusieurs
    // jeux d'aptitudes) sont mélangés dans une même requête — sans quoi
    // PostgREST ne garantit aucun ordre particulier. Signalé en revue QA.
    // `ascending: true` explicite, pas la valeur par défaut : le package
    // `postgrest` (2.9.1) défaut sur `ascending: false` pour `.order(...)`,
    // contre-intuitif — repéré ici via le test d'intégration ajouté pour
    // cette correction, qui a échoué avec un ordre descendant avant l'ajout
    // du paramètre explicite (voir aussi `_fetchSkills` ci-dessus, même
    // correctif appliqué au même défaut du package).
    final featureRows = await _client
        .from('class_features')
        .select('id, class_id, level, uses_per_rest')
        .inFilter('class_id', classIds.toList())
        .order('level', ascending: true);

    final attainedRows = ClassFeatureRowMapper.filterAttained(
      featureRows,
      classLevels: CharacterDetailRowMapper.collectClassLevels(row),
    );

    final featureNames = await _fetchTranslatedNames(
      entityType: 'class_feature',
      entityIds: ClassFeatureRowMapper.collectIds(attainedRows),
    );

    final usesRemaining = ClassFeatureRowMapper.parseUsesRemaining(
      CharacterDetailRowMapper.featureUsesRowsOf(row),
    );

    return [
      for (final featureRow in attainedRows)
        ClassFeatureRowMapper.toCharacterClassFeature(
          featureRow,
          names: featureNames,
          usesRemaining: usesRemaining,
        ),
    ];
  }

  /// Noms de maîtrise d'outils, carte "MAÎTRISES D'OUTILS" —
  /// `character_tool_proficiencies` est déjà embarquée dans le `select`
  /// principal (relation réelle vers `characters`), seuls les noms d'outils
  /// du catalogue restent à résoudre via `translations`.
  Future<List<String>> _fetchToolProficiencyNames(
    Map<String, dynamic> row,
  ) async {
    final toolRows = CharacterDetailRowMapper.toolProficiencyRowsOf(row);
    final toolNames = await _fetchTranslatedNames(
      entityType: 'tool',
      entityIds: CharacterDetailRowMapper.collectToolIds(toolRows)
          .map((id) => id.toString())
          .toSet(),
    );
    return CharacterDetailRowMapper.parseToolProficiencyNames(
      toolRows,
      toolNames: toolNames,
    );
  }

  /// Noms de langues connues, carte "LANGUES CONNUES" — même principe que
  /// [_fetchToolProficiencyNames].
  Future<List<String>> _fetchLanguageNames(Map<String, dynamic> row) async {
    final languageRows = CharacterDetailRowMapper.languageRowsOf(row);
    final languageNames = await _fetchTranslatedNames(
      entityType: 'language',
      entityIds: CharacterDetailRowMapper.collectLanguageIds(languageRows)
          .map((id) => id.toString())
          .toSet(),
    );
    return CharacterDetailRowMapper.parseLanguageNames(
      languageRows,
      languageNames: languageNames,
    );
  }

  /// Sorts connus/préparés, section "SORTS" — `character_spells` est déjà
  /// embarquée dans le `select` principal, seuls `spells.level`/`school` et
  /// les noms restent à résoudre. Retourne une liste vide sans requête si le
  /// personnage n'a aucun sort.
  Future<List<CharacterSpellEntry>> _fetchSpells(
    Map<String, dynamic> row,
  ) async {
    final characterSpellRows = CharacterDetailRowMapper.characterSpellRowsOf(
      row,
    );
    final spellIds = CharacterSpellRowMapper.collectSpellIds(
      characterSpellRows,
    );
    if (spellIds.isEmpty) {
      return const [];
    }

    final spellRows = await _client
        .from('spells')
        .select('id, level, school')
        .inFilter('id', spellIds.toList());

    final spellNames = await _fetchTranslatedNames(
      entityType: 'spell',
      entityIds: spellIds.map((id) => id.toString()).toSet(),
    );

    return CharacterSpellRowMapper.toCharacterSpellEntries(
      spellRows,
      names: spellNames,
      statuses: CharacterSpellRowMapper.parseStatuses(characterSpellRows),
    );
  }

  /// Inventaire résolu, onglet "Inventaire" — `character_inventory` est déjà
  /// embarquée dans le `select` principal, `items` avec elle (relation de
  /// clé étrangère réelle `character_inventory.item_id -> items.id`,
  /// contrairement à `translations`, table polymorphe que PostgREST ne peut
  /// jamais embarquer automatiquement) : seuls les noms d'objets du
  /// catalogue restent à résoudre via `translations`
  /// (`entity_type = 'item'`). Retourne une liste vide sans requête
  /// `translations` si le personnage n'a que des objets personnalisés (ou
  /// aucun objet).
  ///
  /// Pas de `.order(...)` sur `character_inventory` : contrairement à
  /// `skills`/`class_features`, cette table n'a aucune colonne de tri
  /// naturelle (ni `created_at`, ni équivalent — vérifié contre le schéma
  /// réel, `20260825090400_create_character_tables.sql` côté dépôt web) ;
  /// les objets sont donc affichés dans l'ordre renvoyé par PostgREST, sans
  /// garantie particulière ni regroupement/tri applicatif à cette itération
  /// (voir la documentation de classe de
  /// `presentation/widgets/character_inventory_tab_body.dart`).
  Future<List<CharacterInventoryItem>> _fetchInventory(
    Map<String, dynamic> row,
  ) async {
    final inventoryRows = CharacterInventoryRowMapper.rowsOf(row);
    final itemNames = await _fetchTranslatedNames(
      entityType: 'item',
      entityIds: CharacterInventoryRowMapper.collectItemIds(inventoryRows),
    );
    return CharacterInventoryRowMapper.toCharacterInventoryItems(
      inventoryRows,
      names: itemNames,
    );
  }
}
