import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/ability_score_rules.dart';
import '../domain/background_catalog.dart';
import '../domain/background_option.dart';
import '../domain/character_creation_draft.dart';
import '../domain/character_creation_equipment_resolver.dart';
import '../domain/character_creation_failure.dart';
import '../domain/class_catalog.dart';
import '../domain/class_option.dart';
import '../domain/equipment_choice_tab.dart';
import '../domain/final_ability_scores_resolver.dart';
import '../domain/hit_points_calculator.dart';
import '../domain/item_catalog.dart';
import '../domain/language_catalog.dart';
import '../domain/language_selection_resolver.dart';
import '../domain/race_catalog.dart';
import '../domain/skill_catalog.dart';
import '../domain/skill_proficiency_resolver.dart';
import '../domain/spell_catalog.dart';
import '../domain/spell_selection_resolver.dart';
import '../domain/tool_catalog.dart';
import '../domain/tool_proficiency_resolver.dart';
import 'background_row_mapper.dart';
import 'character_creation_error_mapper.dart';
import 'class_row_mapper.dart';
import 'item_row_mapper.dart';
import 'language_row_mapper.dart';
import 'race_row_mapper.dart';
import 'skill_row_mapper.dart';
import 'spell_row_mapper.dart';
import 'tool_row_mapper.dart';

/// Langue d'affichage des noms de race/sous-race/classe, en dur pour
/// l'instant — même rationale que `_locale` de
/// `features/characters/data/character_repository.dart`.
const String _locale = 'fr';

const String _raceCatalogErrorMessage =
    'Impossible de charger les races disponibles. Réessayez.';

const String _classCatalogErrorMessage =
    'Impossible de charger les classes disponibles. Réessayez.';

const String _backgroundCatalogErrorMessage =
    'Impossible de charger les historiques disponibles. Réessayez.';

const String _toolCatalogErrorMessage =
    'Impossible de charger les outils disponibles. Réessayez.';

const String _languageCatalogErrorMessage =
    'Impossible de charger les langues disponibles. Réessayez.';

const String _spellCatalogErrorMessage =
    'Impossible de charger les sorts disponibles. Réessayez.';

const String _itemCatalogErrorMessage =
    'Impossible de charger le catalogue d\'équipement. Réessayez.';

const String _skillCatalogErrorMessage =
    'Impossible de charger les compétences disponibles. Réessayez.';

const String _createCharacterErrorMessage =
    'Impossible de créer le personnage. Réessayez.';

/// Passerelle vers les données de l'assistant de création de personnage.
///
/// Lecture seule pour toutes les méthodes `fetchXxxCatalog` : le brouillon de
/// création (choix de race/sous-race, puis des étapes suivantes) est tenu
/// entièrement côté client, en mémoire, par
/// `presentation/providers/character_creation_draft_provider.dart` — aucune
/// ligne `characters` n'est créée ni mise à jour en base avant l'étape 9
/// "Récapitulatif". Ce choix fait suite à un problème identifié en revue sur
/// la première architecture (une ligne `characters` incomplète, sans nom,
/// était créée dès l'étape 1, visible comme personnage fantôme dans
/// `CharacterListScreen`) : voir le rapport de la tâche qui a supprimé
/// l'ancienne méthode `saveRaceStep` pour le détail.
///
/// [createCharacter] est la seule exception : l'étape 9 "Récapitulatif" est
/// la seule étape de tout l'assistant qui écrit réellement en base, une fois
/// pour toutes les tables enfants — voir sa documentation pour le détail de
/// la séquence d'écriture et du compromis assumé en cas d'échec partiel.
///
/// Abstraction (plutôt qu'une classe concrète directement injectée) pour
/// permettre aux tests de fournir un double sans jamais toucher à
/// `Supabase.instance.client` — même principe que `CharacterRepository`.
abstract class CharacterCreationRepository {
  /// Récupère l'intégralité des races et sous-races disponibles, avec leurs
  /// noms déjà résolus (`translations`, locale FR).
  Future<RaceCatalog> fetchRaceCatalog();

  /// Récupère l'intégralité des classes disponibles, avec leur nom et leur
  /// description déjà résolus (`translations`, locale FR) — étape 2/9 de
  /// l'assistant.
  Future<ClassCatalog> fetchClassCatalog();

  /// Récupère l'intégralité des historiques disponibles, avec leur nom et
  /// leur aptitude (nom + description) déjà résolus (`translations`, locale
  /// FR) — étape 3/9 de l'assistant.
  Future<BackgroundCatalog> fetchBackgroundCatalog();

  /// Récupère l'intégralité des outils/instruments disponibles, avec leur
  /// nom déjà résolu (`translations`, locale FR) — étape 5/9 de l'assistant
  /// ("Compétences et outils"), utilisé pour proposer les candidats d'un
  /// choix interactif d'outils de classe (`ClassOption.toolChoice`).
  Future<ToolCatalog> fetchToolCatalog();

  /// Récupère l'intégralité des langues disponibles, avec leur nom déjà
  /// résolu (`translations`, locale FR) — étape 5/9 de l'assistant
  /// ("Compétences et outils"), utilisé pour proposer les candidats du choix
  /// de langues d'historique (`BackgroundOption.languageChoiceCount`).
  Future<LanguageCatalog> fetchLanguageCatalog();

  /// Récupère les sorts (mineurs ET niveau 1 mélangés, voir
  /// `domain/spell_catalog.dart`) accessibles à la classe [classId]
  /// (`spell_classes`), avec leur nom déjà résolu (`translations`, locale
  /// FR) — étape 6/9 de l'assistant ("Sorts"). Retourne un catalogue vide
  /// sans requête sur `spells`/`translations` si la classe n'a aucune ligne
  /// `spell_classes` (classe non lanceuse — ne devrait normalement jamais
  /// être appelé pour une telle classe, voir
  /// `SpellcastingRules.isSpellcastingClass`, mais reste sûr si c'est le cas
  /// malgré tout).
  Future<SpellCatalog> fetchSpellCatalog({required int classId});

  /// Récupère l'intégralité des objets disponibles, avec leur nom déjà
  /// résolu (`translations`, locale FR) — étape 7/9 de l'assistant
  /// ("Équipement de départ"), utilisé à la fois pour résoudre les chaînes
  /// de `backgrounds.equipment` (onglet "Historique",
  /// `domain/background_equipment_resolver.dart`) et pour peupler le
  /// catalogue d'achat libre (onglet "Acheter").
  Future<ItemCatalog> fetchItemCatalog();

  /// Récupère l'intégralité des 18 compétences disponibles, avec leur nom
  /// déjà résolu (`translations`, locale FR) — étape 9/9 de l'assistant
  /// ("Récapitulatif"), utilisé pour résoudre `CharacterCreationDraft
  /// .classSkillChoices`/`BackgroundOption.skillProficiencies` (des noms)
  /// vers de vrais `skill_id` avant écriture dans
  /// `character_skill_proficiencies` (voir [createCharacter]).
  Future<SkillCatalog> fetchSkillCatalog();

  /// Crée le personnage complet à partir du brouillon [draft] et des
  /// catalogues déjà résolus (déjà chargés par l'écran "Récapitulatif" pour
  /// construire son affichage, réutilisés ici plutôt que rechargés) — seul
  /// point d'écriture de tout l'assistant de création (voir la documentation
  /// de classe). Retourne l'identifiant du personnage créé.
  ///
  /// Séquence d'écriture : `characters` d'abord (récupère son `id` généré),
  /// puis toutes les tables enfants dans un ordre libre entre elles
  /// (`character_classes`, `character_level_hp`, `character_ability_scores`,
  /// `character_skill_proficiencies`, `character_tool_proficiencies`,
  /// `character_languages`, `character_spells`, `character_inventory`).
  ///
  /// **Compromis assumé (décision utilisateur) : pas de RPC Postgres
  /// atomique pour cette itération.** Ces inserts sont séquentiels côté
  /// client, pas enveloppés dans une vraie transaction — si l'un des inserts
  /// de table enfant échoue après que `characters` a déjà réussi,
  /// [createCharacter] supprime au mieux ("best effort") la ligne
  /// `characters` fraîchement créée avant de remonter l'erreur (le `on
  /// delete cascade` de toutes les FK enfants nettoie alors le reste), pour
  /// éviter de laisser un personnage fantôme partiellement créé visible dans
  /// `CharacterListScreen`. Si cette suppression de nettoyage échoue elle
  /// aussi (ex. perte réseau juste après l'insert initial), le personnage
  /// fantôme reste visible : cas limite non couvert par cette itération, une
  /// RPC atomique aurait évité ce risque mais a été écartée par décision du
  /// chef de projet pour rester au plus simple à ce stade.
  Future<String> createCharacter({
    required CharacterCreationDraft draft,
    required String characterName,
    required RaceCatalog raceCatalog,
    required ClassOption classOption,
    required BackgroundOption backgroundOption,
    required SkillCatalog skillCatalog,
    required ToolCatalog toolCatalog,
    required LanguageCatalog languageCatalog,
    required SpellCatalog spellCatalog,
    required ItemCatalog itemCatalog,
  });
}

/// Implémentation réelle, basée sur `Supabase.instance.client`.
class SupabaseCharacterCreationRepository
    implements CharacterCreationRepository {
  const SupabaseCharacterCreationRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<RaceCatalog> fetchRaceCatalog() async {
    try {
      final raceRows = await _client
          .from('races')
          .select('id, ability_bonuses, traits')
          .order('id');
      final subraceRows = await _client
          .from('subraces')
          .select('id, race_id, ability_bonuses, traits')
          .order('id');

      final raceNames = await _fetchTranslatedNames(
        entityType: 'race',
        entityIds: RaceRowMapper.collectIds(raceRows),
      );
      final subraceNames = await _fetchTranslatedNames(
        entityType: 'subrace',
        entityIds: RaceRowMapper.collectIds(subraceRows),
      );

      return RaceCatalog(
        races: raceRows
            .map((row) => RaceRowMapper.toRaceOption(row, names: raceNames))
            .toList(),
        subraces: subraceRows
            .map(
              (row) => RaceRowMapper.toSubraceOption(row, names: subraceNames),
            )
            .toList(),
      );
    } on PostgrestException catch (error) {
      throw mapCharacterCreationError(
        error,
        fallbackMessage: _raceCatalogErrorMessage,
      );
    } catch (_) {
      throw mapUnknownCharacterCreationError();
    }
  }

  @override
  Future<ClassCatalog> fetchClassCatalog() async {
    try {
      final classRows = await _client
          .from('classes')
          .select('id, hit_die, skill_choices, tool_proficiencies')
          .order('id');

      final classIds = ClassRowMapper.collectIds(classRows);
      final names = await _fetchClassTranslatedValues(
        fieldName: 'name',
        entityIds: classIds,
      );
      final descriptions = await _fetchClassTranslatedValues(
        fieldName: 'description',
        entityIds: classIds,
      );

      return ClassCatalog(
        classes: classRows
            .map(
              (row) => ClassRowMapper.toClassOption(
                row,
                names: names,
                descriptions: descriptions,
              ),
            )
            .toList(),
      );
    } on PostgrestException catch (error) {
      throw mapCharacterCreationError(
        error,
        fallbackMessage: _classCatalogErrorMessage,
      );
    } catch (_) {
      throw mapUnknownCharacterCreationError();
    }
  }

  @override
  Future<BackgroundCatalog> fetchBackgroundCatalog() async {
    try {
      final backgroundRows = await _client
          .from('backgrounds')
          .select(
            'id, skill_proficiencies, tool_or_language_choices, equipment',
          )
          .order('id');

      final backgroundIds = BackgroundRowMapper.collectIds(backgroundRows);
      final names = await _fetchBackgroundTranslatedValues(
        fieldName: 'name',
        entityIds: backgroundIds,
      );
      final featureNames = await _fetchBackgroundTranslatedValues(
        fieldName: 'feature_name',
        entityIds: backgroundIds,
      );
      final featureDescriptions = await _fetchBackgroundTranslatedValues(
        fieldName: 'feature_description',
        entityIds: backgroundIds,
      );

      return BackgroundCatalog(
        backgrounds: backgroundRows
            .map(
              (row) => BackgroundRowMapper.toBackgroundOption(
                row,
                names: names,
                featureNames: featureNames,
                featureDescriptions: featureDescriptions,
              ),
            )
            .toList(),
      );
    } on PostgrestException catch (error) {
      throw mapCharacterCreationError(
        error,
        fallbackMessage: _backgroundCatalogErrorMessage,
      );
    } catch (_) {
      throw mapUnknownCharacterCreationError();
    }
  }

  @override
  Future<ToolCatalog> fetchToolCatalog() async {
    try {
      final toolRows = await _client
          .from('tools')
          .select('id, category')
          .order('id');

      final names = await _fetchToolTranslatedNames(
        entityIds: ToolRowMapper.collectIds(toolRows),
      );

      return ToolCatalog(
        tools: toolRows
            .map((row) => ToolRowMapper.toToolOption(row, names: names))
            .toList(),
      );
    } on PostgrestException catch (error) {
      throw mapCharacterCreationError(
        error,
        fallbackMessage: _toolCatalogErrorMessage,
      );
    } catch (_) {
      throw mapUnknownCharacterCreationError();
    }
  }

  @override
  Future<LanguageCatalog> fetchLanguageCatalog() async {
    try {
      final languageRows = await _client
          .from('languages')
          .select('id, type')
          .order('id');

      final names = await _fetchLanguageTranslatedNames(
        entityIds: LanguageRowMapper.collectIds(languageRows),
      );

      return LanguageCatalog(
        languages: languageRows
            .map((row) => LanguageRowMapper.toLanguageOption(row, names: names))
            .toList(),
      );
    } on PostgrestException catch (error) {
      throw mapCharacterCreationError(
        error,
        fallbackMessage: _languageCatalogErrorMessage,
      );
    } catch (_) {
      throw mapUnknownCharacterCreationError();
    }
  }

  @override
  Future<SpellCatalog> fetchSpellCatalog({required int classId}) async {
    try {
      final spellClassRows = await _client
          .from('spell_classes')
          .select('spell_id')
          .eq('class_id', classId);

      final spellIds = SpellRowMapper.collectSpellIds(spellClassRows);
      if (spellIds.isEmpty) {
        return const SpellCatalog(spells: []);
      }

      final spellRows = await _client
          .from('spells')
          .select('id, level, school, casting_time')
          .inFilter('id', spellIds.toList())
          .order('id');

      final names = await _fetchSpellTranslatedNames(
        entityIds: SpellRowMapper.collectIds(spellRows),
      );

      final spells =
          spellRows
              .map((row) => SpellRowMapper.toSpellOption(row, names: names))
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));

      return SpellCatalog(spells: spells);
    } on PostgrestException catch (error) {
      throw mapCharacterCreationError(
        error,
        fallbackMessage: _spellCatalogErrorMessage,
      );
    } catch (_) {
      throw mapUnknownCharacterCreationError();
    }
  }

  @override
  Future<ItemCatalog> fetchItemCatalog() async {
    try {
      final itemRows = await _client
          .from('items')
          .select('id, category, cost')
          .order('id');

      final names = await _fetchItemTranslatedNames(
        entityIds: ItemRowMapper.collectIds(itemRows),
      );

      return ItemCatalog(
        items: itemRows
            .map((row) => ItemRowMapper.toItemOption(row, names: names))
            .toList(),
      );
    } on PostgrestException catch (error) {
      throw mapCharacterCreationError(
        error,
        fallbackMessage: _itemCatalogErrorMessage,
      );
    } catch (_) {
      throw mapUnknownCharacterCreationError();
    }
  }

  @override
  Future<SkillCatalog> fetchSkillCatalog() async {
    try {
      final skillRows = await _client
          .from('skills')
          .select('id, ability_id')
          .order('id');

      final names = await _fetchSkillTranslatedNames(
        entityIds: SkillRowMapper.collectIds(skillRows),
      );

      return SkillCatalog(
        skills: skillRows
            .map((row) => SkillRowMapper.toSkillOption(row, names: names))
            .toList(),
      );
    } on PostgrestException catch (error) {
      throw mapCharacterCreationError(
        error,
        fallbackMessage: _skillCatalogErrorMessage,
      );
    } catch (_) {
      throw mapUnknownCharacterCreationError();
    }
  }

  @override
  Future<String> createCharacter({
    required CharacterCreationDraft draft,
    required String characterName,
    required RaceCatalog raceCatalog,
    required ClassOption classOption,
    required BackgroundOption backgroundOption,
    required SkillCatalog skillCatalog,
    required ToolCatalog toolCatalog,
    required LanguageCatalog languageCatalog,
    required SpellCatalog spellCatalog,
    required ItemCatalog itemCatalog,
  }) async {
    final ownerId = _client.auth.currentUser?.id;
    if (ownerId == null) {
      throw const CharacterCreationFailure(
        'Session expirée. Reconnectez-vous pour créer un personnage.',
      );
    }

    final finalAbilityScores = FinalAbilityScoresResolver.resolve(
      baseScores: draft.abilityScores ?? const {},
      raceCatalog: raceCatalog,
      raceId: draft.raceId,
      subraceId: draft.subraceId,
    );
    final constitutionModifier = AbilityScoreRules.abilityModifier(
      finalAbilityScores['con'] ?? 10,
    );
    final maxHp = HitPointsCalculator.maxHpAtLevel1(
      hitDie: classOption.hitDie,
      constitutionModifier: constitutionModifier,
    );

    final equipmentResolution = CharacterCreationEquipmentResolver.resolve(
      tab: draft.equipmentChoiceTab ?? EquipmentChoiceTab.background,
      backgroundOption: backgroundOption,
      purchasedEquipment: draft.purchasedEquipment,
      itemCatalog: itemCatalog,
    );

    String? characterId;
    try {
      final characterRow = await _client
          .from('characters')
          .insert({
            'owner_id': ownerId,
            'name': characterName,
            'race_id': draft.raceId,
            'subrace_id': draft.subraceId,
            'race_custom_text': draft.raceCustomText,
            'background_id': draft.backgroundId,
            'alignment_id': null,
            'xp': 0,
            'max_hp': maxHp,
            'current_hp': maxHp,
            'temporary_hp': 0,
            'sexe': null,
            'age': null,
            'height': null,
            'weight': null,
            'eyes': null,
            'skin': null,
            'hair': null,
            'portrait_url': null,
            // `characters.*_text` sont `not null default ''` en base (vérifié
            // par le test d'intégration `createCharacter` : un premier essai
            // avec `draft.appearanceText` tel quel, potentiellement `null`,
            // a échoué avec "null value in column appearance_text violates
            // not-null constraint" — la doc locale `02-modele-donnees.md` ne
            // le précisait pas explicitement, contrairement à d'autres
            // colonnes marquées "nullable"). Coalescé vers `''` comme
            // `characters.name`, plutôt que de changer le brouillon lui-même
            // (qui garde `null` = "jamais renseigné" tant que l'étape 8 n'a
            // pas été validée, une distinction utile jusqu'à ce point).
            'appearance_text': draft.appearanceText ?? '',
            'traits_text': draft.traitsText ?? '',
            'ideals_text': draft.idealsText ?? '',
            'bonds_text': draft.bondsText ?? '',
            'flaws_text': draft.flawsText ?? '',
            'backstory_text': draft.backstoryText ?? '',
            'allies_text': draft.alliesText ?? '',
            'features_text': draft.featuresText ?? '',
            'treasure_text': draft.treasureText ?? '',
            'currency_gp': equipmentResolution.currencyGp,
            'currency_pp': 0,
            'currency_ep': 0,
            'currency_sp': 0,
            'currency_cp': 0,
          })
          .select('id')
          .single();
      characterId = characterRow['id'] as String;

      await _client.from('character_classes').insert({
        'character_id': characterId,
        'class_id': classOption.id,
        'subclass_id': null,
        'level': 1,
        'is_primary': true,
      });

      await _client.from('character_level_hp').insert({
        'character_id': characterId,
        'level': 1,
        'hp_rolled': classOption.hitDie,
        // 'moyenne' plutôt que 'lance' : il n'existe pas de vraie 3e valeur
        // "maximum au niveau 1" dans le check `('lance', 'moyenne')` de
        // `character_level_hp.method` — 'moyenne' est la valeur la plus
        // proche sémantiquement d'un résultat non aléatoire (voir
        // `domain/hit_points_calculator.dart` : le calcul RAW niveau 1 est
        // déterministe, jamais un lancer de dé). Choix documenté ici plutôt
        // qu'ajouté silencieusement.
        'method': 'moyenne',
      });

      if (finalAbilityScores.isNotEmpty) {
        await _client.from('character_ability_scores').insert([
          for (final entry in finalAbilityScores.entries)
            {
              'character_id': characterId,
              'ability_id': entry.key,
              'score': entry.value,
            },
        ]);
      }

      final skillRows = SkillProficiencyResolver.resolve(
        classSkillNames: draft.classSkillChoices,
        backgroundSkillNames: backgroundOption.skillProficiencies,
        catalog: skillCatalog,
      );
      if (skillRows.isNotEmpty) {
        await _client.from('character_skill_proficiencies').insert([
          for (final row in skillRows)
            {
              'character_id': characterId,
              'skill_id': row.skillId,
              'proficiency': row.proficiency,
            },
        ]);
      }

      final toolRows = ToolProficiencyResolver.resolve(
        classToolNames: draft.classToolChoices,
        classGrantedToolNames: classOption.grantedToolNames,
        backgroundGrantedToolTexts: backgroundOption.toolOrLanguageGrantedTools,
        catalog: toolCatalog,
      );
      if (toolRows.isNotEmpty) {
        await _client.from('character_tool_proficiencies').insert([
          for (final row in toolRows)
            {
              'character_id': characterId,
              'tool_id': row.toolId,
              'custom_text': row.customText,
            },
        ]);
      }

      final languageIds = LanguageSelectionResolver.resolve(
        languageNames: draft.backgroundLanguageChoices,
        catalog: languageCatalog,
      );
      if (languageIds.isNotEmpty) {
        await _client.from('character_languages').insert([
          for (final languageId in languageIds)
            {'character_id': characterId, 'language_id': languageId},
        ]);
      }

      final spellRows = SpellSelectionResolver.resolve(
        cantripNames: draft.classCantripChoices,
        levelOneSpellNames: draft.classLevelOneSpellChoices,
        catalog: spellCatalog,
        className: classOption.name,
      );
      if (spellRows.isNotEmpty) {
        await _client.from('character_spells').insert([
          for (final row in spellRows)
            {
              'character_id': characterId,
              'spell_id': row.spellId,
              'status': row.status,
              'source_class_id': draft.classId,
            },
        ]);
      }

      if (equipmentResolution.inventory.isNotEmpty) {
        await _client.from('character_inventory').insert([
          for (final line in equipmentResolution.inventory)
            {
              'character_id': characterId,
              'item_id': line.itemId,
              'custom_name': line.customName,
              'quantity': line.quantity,
              'equipped': false,
              'notes': null,
            },
        ]);
      }

      return characterId;
    } on PostgrestException catch (error) {
      await _cleanupPartialCharacter(characterId);
      throw mapCharacterCreationError(
        error,
        fallbackMessage: _createCharacterErrorMessage,
      );
    } catch (_) {
      await _cleanupPartialCharacter(characterId);
      throw mapUnknownCharacterCreationError();
    }
  }

  /// Nettoyage best-effort après un échec d'insert de table enfant survenu
  /// après que `characters` a déjà été créée — voir la documentation de
  /// [createCharacter] pour le rationale complet de ce compromis. Avale
  /// silencieusement une éventuelle erreur de suppression : elle ne doit
  /// jamais masquer l'erreur d'origine déjà en cours de propagation par
  /// l'appelant.
  Future<void> _cleanupPartialCharacter(String? characterId) async {
    if (characterId == null) return;
    try {
      await _client.from('characters').delete().eq('id', characterId);
    } catch (_) {
      // Best-effort : voir la documentation de [createCharacter].
    }
  }

  /// Récupère `{entity_id: name}` pour toutes les traductions `race`/`subrace`
  /// dont l'identifiant est dans [entityIds]. Retourne une map vide sans
  /// requête si [entityIds] est vide.
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

    return RaceRowMapper.parseTranslatedNames(rows);
  }

  /// Récupère `{entity_id: value}` pour le champ `class`/[fieldName] (`name`
  /// ou `description`) dont l'identifiant est dans [entityIds]. Retourne une
  /// map vide sans requête si [entityIds] est vide — même principe que
  /// [_fetchTranslatedNames], distinct pour ne pas modifier le comportement
  /// déjà en place pour races/sous-races.
  Future<Map<String, String>> _fetchClassTranslatedValues({
    required String fieldName,
    required Set<String> entityIds,
  }) async {
    if (entityIds.isEmpty) {
      return const {};
    }

    final rows = await _client
        .from('translations')
        .select('entity_id, value')
        .eq('entity_type', 'class')
        .eq('field_name', fieldName)
        .eq('locale', _locale)
        .inFilter('entity_id', entityIds.toList());

    return ClassRowMapper.parseTranslatedValues(rows);
  }

  /// Récupère `{entity_id: value}` pour le champ `background`/[fieldName]
  /// (`name`, `feature_name` ou `feature_description`) dont l'identifiant est
  /// dans [entityIds]. Retourne une map vide sans requête si [entityIds] est
  /// vide — même principe que [_fetchClassTranslatedValues], distinct pour ne
  /// pas modifier le comportement déjà en place pour races/sous-races/classes.
  Future<Map<String, String>> _fetchBackgroundTranslatedValues({
    required String fieldName,
    required Set<String> entityIds,
  }) async {
    if (entityIds.isEmpty) {
      return const {};
    }

    final rows = await _client
        .from('translations')
        .select('entity_id, value')
        .eq('entity_type', 'background')
        .eq('field_name', fieldName)
        .eq('locale', _locale)
        .inFilter('entity_id', entityIds.toList());

    return BackgroundRowMapper.parseTranslatedValues(rows);
  }

  /// Récupère `{entity_id: name}` pour toutes les traductions `tool` dont
  /// l'identifiant est dans [entityIds]. Retourne une map vide sans requête
  /// si [entityIds] est vide — même principe que
  /// [_fetchBackgroundTranslatedValues], distinct pour ne pas coupler
  /// l'étape 5/9 aux étapes précédentes.
  Future<Map<String, String>> _fetchToolTranslatedNames({
    required Set<String> entityIds,
  }) async {
    if (entityIds.isEmpty) {
      return const {};
    }

    final rows = await _client
        .from('translations')
        .select('entity_id, value')
        .eq('entity_type', 'tool')
        .eq('field_name', 'name')
        .eq('locale', _locale)
        .inFilter('entity_id', entityIds.toList());

    return ToolRowMapper.parseTranslatedValues(rows);
  }

  /// Récupère `{entity_id: name}` pour toutes les traductions `language`
  /// dont l'identifiant est dans [entityIds] — même principe que
  /// [_fetchToolTranslatedNames].
  Future<Map<String, String>> _fetchLanguageTranslatedNames({
    required Set<String> entityIds,
  }) async {
    if (entityIds.isEmpty) {
      return const {};
    }

    final rows = await _client
        .from('translations')
        .select('entity_id, value')
        .eq('entity_type', 'language')
        .eq('field_name', 'name')
        .eq('locale', _locale)
        .inFilter('entity_id', entityIds.toList());

    return LanguageRowMapper.parseTranslatedValues(rows);
  }

  /// Récupère `{entity_id: name}` pour toutes les traductions `spell` dont
  /// l'identifiant est dans [entityIds] — même principe que
  /// [_fetchLanguageTranslatedNames].
  Future<Map<String, String>> _fetchSpellTranslatedNames({
    required Set<String> entityIds,
  }) async {
    if (entityIds.isEmpty) {
      return const {};
    }

    final rows = await _client
        .from('translations')
        .select('entity_id, value')
        .eq('entity_type', 'spell')
        .eq('field_name', 'name')
        .eq('locale', _locale)
        .inFilter('entity_id', entityIds.toList());

    return SpellRowMapper.parseTranslatedValues(rows);
  }

  /// Récupère `{entity_id: name}` pour toutes les traductions `item` dont
  /// l'identifiant est dans [entityIds] — même principe que
  /// [_fetchSpellTranslatedNames].
  Future<Map<String, String>> _fetchItemTranslatedNames({
    required Set<String> entityIds,
  }) async {
    if (entityIds.isEmpty) {
      return const {};
    }

    final rows = await _client
        .from('translations')
        .select('entity_id, value')
        .eq('entity_type', 'item')
        .eq('field_name', 'name')
        .eq('locale', _locale)
        .inFilter('entity_id', entityIds.toList());

    return ItemRowMapper.parseTranslatedValues(rows);
  }

  /// Récupère `{entity_id: name}` pour toutes les traductions `skill` dont
  /// l'identifiant est dans [entityIds] — même principe que
  /// [_fetchItemTranslatedNames].
  Future<Map<String, String>> _fetchSkillTranslatedNames({
    required Set<String> entityIds,
  }) async {
    if (entityIds.isEmpty) {
      return const {};
    }

    final rows = await _client
        .from('translations')
        .select('entity_id, value')
        .eq('entity_type', 'skill')
        .eq('field_name', 'name')
        .eq('locale', _locale)
        .inFilter('entity_id', entityIds.toList());

    return SkillRowMapper.parseTranslatedValues(rows);
  }
}
