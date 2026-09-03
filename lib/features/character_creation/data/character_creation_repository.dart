import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/reference_data_cache.dart';
import '../domain/ability_score_rules.dart';
import '../domain/alignment_catalog.dart';
import '../domain/alignment_option.dart';
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

const String _alignmentCatalogErrorMessage =
    'Impossible de charger les alignements disponibles. Réessayez.';

const String _createCharacterErrorMessage =
    'Impossible de créer le personnage. Réessayez.';

/// Clés de cache (`ReferenceDataCache`) des 7 catalogues non paramétrés —
/// `fetchSpellCatalog` construit la sienne dynamiquement (`'spell_catalog:$classId'`,
/// voir sa documentation), les 7 autres sont globales (une seule entrée pour
/// tous les utilisateurs/personnages, ce sont des données de référence).
const String _raceCatalogCacheKey = 'race_catalog';
const String _classCatalogCacheKey = 'class_catalog';
const String _backgroundCatalogCacheKey = 'background_catalog';
const String _toolCatalogCacheKey = 'tool_catalog';
const String _languageCatalogCacheKey = 'language_catalog';
const String _itemCatalogCacheKey = 'item_catalog';
const String _skillCatalogCacheKey = 'skill_catalog';
const String _alignmentCatalogCacheKey = 'alignment_catalog';

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

  /// Récupère l'intégralité des 9 alignements disponibles (`alignments`,
  /// colonne `name` directe, pas de résolution `translations` — voir la
  /// documentation de classe d'[AlignmentOption]) — utilisé par l'écran de
  /// vérification de l'import XML aidedd.org (`features/xml_import/`),
  /// jamais par l'assistant de création lui-même (`characters.alignment_id`
  /// y reste toujours `null`, voir [createCharacter]).
  Future<AlignmentCatalog> fetchAlignmentCatalog();

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
///
/// ## Cache hors-ligne des catalogues (`fetchXxxCatalog`)
///
/// Stratégie à deux niveaux (le second ajouté par la tâche de performance
/// perçue qui a introduit [_catalogCacheTtl] ; le premier est la stratégie
/// d'origine, inchangée) :
///
/// 1. **"Cache d'abord si frais"** : si une entrée de cache existe pour la
///    clé de ce catalogue et a moins de [_catalogCacheTtl], elle est
///    retournée directement (voir [_mappedFromFreshCache]) — **aucun appel
///    réseau**. Sûr spécifiquement parce que ces catalogues sont des données
///    de référence D&D en lecture seule, jamais modifiées côté client (voir
///    la doc de classe de [CharacterCreationRepository]) : contrairement à
///    la fiche personnage (`CharacterRepository.fetchCharacterDetail`, qui
///    reste volontairement réseau-d'abord), aucun risque de servir une
///    valeur obsolète qu'un autre utilisateur/appareil aurait modifiée entre
///    temps.
/// 2. **"Réseau d'abord, cache en secours"** (décision chef de projet, voir
///    la tâche qui a introduit [_cache]) : si aucune entrée fraîche
///    n'existe (absente, ou plus vieille que [_catalogCacheTtl]), chaque
///    méthode `fetchXxxCatalog` tente d'abord la requête réseau comme avant ;
///    si elle réussit, les **lignes brutes** (`List<Map<String, dynamic>>`,
///    avant tout mapping) sont aussi écrites dans [_cache] (best-effort, voir
///    [_writeCacheBestEffort], avec un nouveau `cachedAt`), en plus d'être
///    mappées et retournées comme aujourd'hui. Si le réseau échoue
///    (`PostgrestException` ou n'importe quelle autre exception), une entrée
///    de cache existante — même périmée au sens de [_catalogCacheTtl] — est
///    relue et passée par le **même mapper** que le chemin réseau (voir
///    [_mappedFromCache]) — jamais de logique de parsing dupliquée entre les
///    deux chemins. Si aucune entrée de cache n'existe non plus, l'erreur
///    d'origine est relancée (comportement inchangé par rapport à avant
///    l'introduction du cache).
///
/// Pas de vérification de version au-delà de ce TTL : un upsert à chaque
/// succès réseau suffit à garder le cache raisonnablement à jour (volume de
/// données de référence trop faible pour justifier davantage — voir la
/// consigne de la tâche). Aucune file de synchro d'écritures ici : ces 9
/// catalogues sont en lecture seule côté client (voir la doc de classe de
/// [CharacterCreationRepository]).
class SupabaseCharacterCreationRepository
    implements CharacterCreationRepository {
  const SupabaseCharacterCreationRepository(this._client, this._cache);

  final SupabaseClient _client;
  final ReferenceDataCache _cache;

  /// Durée de fraîcheur d'une entrée de cache de catalogue avant de retenter
  /// le réseau en priorité (voir la doc de classe, point 1) — 48h, valeur
  /// demandée par la tâche de performance perçue qui a introduit ce TTL :
  /// ces données de référence D&D changent rarement, un cache d'un jour ou
  /// deux reste largement acceptable pour l'assistant de création.
  static const Duration _catalogCacheTtl = Duration(hours: 48);

  @override
  Future<RaceCatalog> fetchRaceCatalog() async {
    final freshCached = await _mappedFromFreshCache(
      _raceCatalogCacheKey,
      _mapRaceCatalogPayload,
    );
    if (freshCached != null) return freshCached;
    try {
      final raceRows = await _client
          .from('races')
          .select('id, ability_bonuses, traits')
          .order('id', ascending: true);
      final subraceRows = await _client
          .from('subraces')
          .select('id, race_id, ability_bonuses, traits')
          .order('id', ascending: true);
      final raceNameRows = await _fetchTranslationRows(
        entityType: 'race',
        entityIds: RaceRowMapper.collectIds(raceRows),
      );
      final subraceNameRows = await _fetchTranslationRows(
        entityType: 'subrace',
        entityIds: RaceRowMapper.collectIds(subraceRows),
      );

      final payload = <String, dynamic>{
        'races': raceRows,
        'subraces': subraceRows,
        'raceNames': raceNameRows,
        'subraceNames': subraceNameRows,
      };
      await _writeCacheBestEffort(_raceCatalogCacheKey, payload);
      return _mapRaceCatalogPayload(payload);
    } on PostgrestException catch (error) {
      final cached = await _mappedFromCache(
        _raceCatalogCacheKey,
        _mapRaceCatalogPayload,
      );
      if (cached != null) return cached;
      throw mapCharacterCreationError(
        error,
        fallbackMessage: _raceCatalogErrorMessage,
      );
    } catch (_) {
      final cached = await _mappedFromCache(
        _raceCatalogCacheKey,
        _mapRaceCatalogPayload,
      );
      if (cached != null) return cached;
      throw mapUnknownCharacterCreationError();
    }
  }

  RaceCatalog _mapRaceCatalogPayload(Map<String, dynamic> payload) {
    final raceNames = RaceRowMapper.parseTranslatedNames(
      _rowsOf(payload['raceNames']),
    );
    final subraceNames = RaceRowMapper.parseTranslatedNames(
      _rowsOf(payload['subraceNames']),
    );
    return RaceCatalog(
      races: _rowsOf(payload['races'])
          .map((row) => RaceRowMapper.toRaceOption(row, names: raceNames))
          .toList(),
      subraces: _rowsOf(payload['subraces'])
          .map((row) => RaceRowMapper.toSubraceOption(row, names: subraceNames))
          .toList(),
    );
  }

  @override
  Future<ClassCatalog> fetchClassCatalog() async {
    final freshCached = await _mappedFromFreshCache(
      _classCatalogCacheKey,
      _mapClassCatalogPayload,
    );
    if (freshCached != null) return freshCached;
    try {
      final classRows = await _client
          .from('classes')
          .select('id, hit_die, skill_choices, tool_proficiencies')
          .order('id', ascending: true);

      final classIds = ClassRowMapper.collectIds(classRows);
      final nameRows = await _fetchTranslationRows(
        entityType: 'class',
        entityIds: classIds,
      );
      final descriptionRows = await _fetchTranslationRows(
        entityType: 'class',
        entityIds: classIds,
        fieldName: 'description',
      );

      final payload = <String, dynamic>{
        'classes': classRows,
        'classNames': nameRows,
        'classDescriptions': descriptionRows,
      };
      await _writeCacheBestEffort(_classCatalogCacheKey, payload);
      return _mapClassCatalogPayload(payload);
    } on PostgrestException catch (error) {
      final cached = await _mappedFromCache(
        _classCatalogCacheKey,
        _mapClassCatalogPayload,
      );
      if (cached != null) return cached;
      throw mapCharacterCreationError(
        error,
        fallbackMessage: _classCatalogErrorMessage,
      );
    } catch (_) {
      final cached = await _mappedFromCache(
        _classCatalogCacheKey,
        _mapClassCatalogPayload,
      );
      if (cached != null) return cached;
      throw mapUnknownCharacterCreationError();
    }
  }

  ClassCatalog _mapClassCatalogPayload(Map<String, dynamic> payload) {
    final names = ClassRowMapper.parseTranslatedValues(
      _rowsOf(payload['classNames']),
    );
    final descriptions = ClassRowMapper.parseTranslatedValues(
      _rowsOf(payload['classDescriptions']),
    );
    return ClassCatalog(
      classes: _rowsOf(payload['classes'])
          .map(
            (row) => ClassRowMapper.toClassOption(
              row,
              names: names,
              descriptions: descriptions,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<BackgroundCatalog> fetchBackgroundCatalog() async {
    final freshCached = await _mappedFromFreshCache(
      _backgroundCatalogCacheKey,
      _mapBackgroundCatalogPayload,
    );
    if (freshCached != null) return freshCached;
    try {
      final backgroundRows = await _client
          .from('backgrounds')
          .select(
            'id, skill_proficiencies, tool_or_language_choices, equipment',
          )
          .order('id', ascending: true);

      final backgroundIds = BackgroundRowMapper.collectIds(backgroundRows);
      final nameRows = await _fetchTranslationRows(
        entityType: 'background',
        entityIds: backgroundIds,
      );
      final featureNameRows = await _fetchTranslationRows(
        entityType: 'background',
        entityIds: backgroundIds,
        fieldName: 'feature_name',
      );
      final featureDescriptionRows = await _fetchTranslationRows(
        entityType: 'background',
        entityIds: backgroundIds,
        fieldName: 'feature_description',
      );

      final payload = <String, dynamic>{
        'backgrounds': backgroundRows,
        'backgroundNames': nameRows,
        'featureNames': featureNameRows,
        'featureDescriptions': featureDescriptionRows,
      };
      await _writeCacheBestEffort(_backgroundCatalogCacheKey, payload);
      return _mapBackgroundCatalogPayload(payload);
    } on PostgrestException catch (error) {
      final cached = await _mappedFromCache(
        _backgroundCatalogCacheKey,
        _mapBackgroundCatalogPayload,
      );
      if (cached != null) return cached;
      throw mapCharacterCreationError(
        error,
        fallbackMessage: _backgroundCatalogErrorMessage,
      );
    } catch (_) {
      final cached = await _mappedFromCache(
        _backgroundCatalogCacheKey,
        _mapBackgroundCatalogPayload,
      );
      if (cached != null) return cached;
      throw mapUnknownCharacterCreationError();
    }
  }

  BackgroundCatalog _mapBackgroundCatalogPayload(Map<String, dynamic> payload) {
    final names = BackgroundRowMapper.parseTranslatedValues(
      _rowsOf(payload['backgroundNames']),
    );
    final featureNames = BackgroundRowMapper.parseTranslatedValues(
      _rowsOf(payload['featureNames']),
    );
    final featureDescriptions = BackgroundRowMapper.parseTranslatedValues(
      _rowsOf(payload['featureDescriptions']),
    );
    return BackgroundCatalog(
      backgrounds: _rowsOf(payload['backgrounds'])
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
  }

  @override
  Future<ToolCatalog> fetchToolCatalog() async {
    final freshCached = await _mappedFromFreshCache(
      _toolCatalogCacheKey,
      _mapToolCatalogPayload,
    );
    if (freshCached != null) return freshCached;
    try {
      final toolRows = await _client
          .from('tools')
          .select('id, category')
          .order('id', ascending: true);

      final nameRows = await _fetchTranslationRows(
        entityType: 'tool',
        entityIds: ToolRowMapper.collectIds(toolRows),
      );

      final payload = <String, dynamic>{
        'tools': toolRows,
        'toolNames': nameRows,
      };
      await _writeCacheBestEffort(_toolCatalogCacheKey, payload);
      return _mapToolCatalogPayload(payload);
    } on PostgrestException catch (error) {
      final cached = await _mappedFromCache(
        _toolCatalogCacheKey,
        _mapToolCatalogPayload,
      );
      if (cached != null) return cached;
      throw mapCharacterCreationError(
        error,
        fallbackMessage: _toolCatalogErrorMessage,
      );
    } catch (_) {
      final cached = await _mappedFromCache(
        _toolCatalogCacheKey,
        _mapToolCatalogPayload,
      );
      if (cached != null) return cached;
      throw mapUnknownCharacterCreationError();
    }
  }

  ToolCatalog _mapToolCatalogPayload(Map<String, dynamic> payload) {
    final names = ToolRowMapper.parseTranslatedValues(
      _rowsOf(payload['toolNames']),
    );
    return ToolCatalog(
      tools: _rowsOf(payload['tools'])
          .map((row) => ToolRowMapper.toToolOption(row, names: names))
          .toList(),
    );
  }

  @override
  Future<LanguageCatalog> fetchLanguageCatalog() async {
    final freshCached = await _mappedFromFreshCache(
      _languageCatalogCacheKey,
      _mapLanguageCatalogPayload,
    );
    if (freshCached != null) return freshCached;
    try {
      final languageRows = await _client
          .from('languages')
          .select('id, type')
          .order('id', ascending: true);

      final nameRows = await _fetchTranslationRows(
        entityType: 'language',
        entityIds: LanguageRowMapper.collectIds(languageRows),
      );

      final payload = <String, dynamic>{
        'languages': languageRows,
        'languageNames': nameRows,
      };
      await _writeCacheBestEffort(_languageCatalogCacheKey, payload);
      return _mapLanguageCatalogPayload(payload);
    } on PostgrestException catch (error) {
      final cached = await _mappedFromCache(
        _languageCatalogCacheKey,
        _mapLanguageCatalogPayload,
      );
      if (cached != null) return cached;
      throw mapCharacterCreationError(
        error,
        fallbackMessage: _languageCatalogErrorMessage,
      );
    } catch (_) {
      final cached = await _mappedFromCache(
        _languageCatalogCacheKey,
        _mapLanguageCatalogPayload,
      );
      if (cached != null) return cached;
      throw mapUnknownCharacterCreationError();
    }
  }

  LanguageCatalog _mapLanguageCatalogPayload(Map<String, dynamic> payload) {
    final names = LanguageRowMapper.parseTranslatedValues(
      _rowsOf(payload['languageNames']),
    );
    return LanguageCatalog(
      languages: _rowsOf(payload['languages'])
          .map((row) => LanguageRowMapper.toLanguageOption(row, names: names))
          .toList(),
    );
  }

  @override
  Future<SpellCatalog> fetchSpellCatalog({required int classId}) async {
    // Paramétrée par classId (contrairement aux 7 autres catalogues,
    // globaux) : une entrée de cache distincte par classe, voir la doc de
    // classe de `SupabaseCharacterCreationRepository`.
    final cacheKey = 'spell_catalog:$classId';
    final freshCached = await _mappedFromFreshCache(
      cacheKey,
      _mapSpellCatalogPayload,
    );
    if (freshCached != null) return freshCached;
    try {
      final spellClassRows = await _client
          .from('spell_classes')
          .select('spell_id')
          .eq('class_id', classId);

      final spellIds = SpellRowMapper.collectSpellIds(spellClassRows);

      var spellRows = const <Map<String, dynamic>>[];
      var spellNameRows = const <Map<String, dynamic>>[];
      if (spellIds.isNotEmpty) {
        spellRows = await _client
            .from('spells')
            .select('id, level, school, casting_time')
            .inFilter('id', spellIds.toList())
            .order('id', ascending: true);
        spellNameRows = await _fetchTranslationRows(
          entityType: 'spell',
          entityIds: SpellRowMapper.collectIds(spellRows),
        );
      }

      final payload = <String, dynamic>{
        'spells': spellRows,
        'spellNames': spellNameRows,
      };
      await _writeCacheBestEffort(cacheKey, payload);
      return _mapSpellCatalogPayload(payload);
    } on PostgrestException catch (error) {
      final cached = await _mappedFromCache(cacheKey, _mapSpellCatalogPayload);
      if (cached != null) return cached;
      throw mapCharacterCreationError(
        error,
        fallbackMessage: _spellCatalogErrorMessage,
      );
    } catch (_) {
      final cached = await _mappedFromCache(cacheKey, _mapSpellCatalogPayload);
      if (cached != null) return cached;
      throw mapUnknownCharacterCreationError();
    }
  }

  SpellCatalog _mapSpellCatalogPayload(Map<String, dynamic> payload) {
    final names = SpellRowMapper.parseTranslatedValues(
      _rowsOf(payload['spellNames']),
    );
    final spells =
        _rowsOf(payload['spells'])
            .map((row) => SpellRowMapper.toSpellOption(row, names: names))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return SpellCatalog(spells: spells);
  }

  @override
  Future<ItemCatalog> fetchItemCatalog() async {
    final freshCached = await _mappedFromFreshCache(
      _itemCatalogCacheKey,
      _mapItemCatalogPayload,
    );
    if (freshCached != null) return freshCached;
    try {
      final itemRows = await _client
          .from('items')
          .select('id, category, cost')
          .order('id', ascending: true);

      final nameRows = await _fetchTranslationRows(
        entityType: 'item',
        entityIds: ItemRowMapper.collectIds(itemRows),
      );

      final payload = <String, dynamic>{
        'items': itemRows,
        'itemNames': nameRows,
      };
      await _writeCacheBestEffort(_itemCatalogCacheKey, payload);
      return _mapItemCatalogPayload(payload);
    } on PostgrestException catch (error) {
      final cached = await _mappedFromCache(
        _itemCatalogCacheKey,
        _mapItemCatalogPayload,
      );
      if (cached != null) return cached;
      throw mapCharacterCreationError(
        error,
        fallbackMessage: _itemCatalogErrorMessage,
      );
    } catch (_) {
      final cached = await _mappedFromCache(
        _itemCatalogCacheKey,
        _mapItemCatalogPayload,
      );
      if (cached != null) return cached;
      throw mapUnknownCharacterCreationError();
    }
  }

  ItemCatalog _mapItemCatalogPayload(Map<String, dynamic> payload) {
    final names = ItemRowMapper.parseTranslatedValues(
      _rowsOf(payload['itemNames']),
    );
    return ItemCatalog(
      items: _rowsOf(payload['items'])
          .map((row) => ItemRowMapper.toItemOption(row, names: names))
          .toList(),
    );
  }

  @override
  Future<SkillCatalog> fetchSkillCatalog() async {
    final freshCached = await _mappedFromFreshCache(
      _skillCatalogCacheKey,
      _mapSkillCatalogPayload,
    );
    if (freshCached != null) return freshCached;
    try {
      final skillRows = await _client
          .from('skills')
          .select('id, ability_id')
          .order('id', ascending: true);

      final nameRows = await _fetchTranslationRows(
        entityType: 'skill',
        entityIds: SkillRowMapper.collectIds(skillRows),
      );

      final payload = <String, dynamic>{
        'skills': skillRows,
        'skillNames': nameRows,
      };
      await _writeCacheBestEffort(_skillCatalogCacheKey, payload);
      return _mapSkillCatalogPayload(payload);
    } on PostgrestException catch (error) {
      final cached = await _mappedFromCache(
        _skillCatalogCacheKey,
        _mapSkillCatalogPayload,
      );
      if (cached != null) return cached;
      throw mapCharacterCreationError(
        error,
        fallbackMessage: _skillCatalogErrorMessage,
      );
    } catch (_) {
      final cached = await _mappedFromCache(
        _skillCatalogCacheKey,
        _mapSkillCatalogPayload,
      );
      if (cached != null) return cached;
      throw mapUnknownCharacterCreationError();
    }
  }

  SkillCatalog _mapSkillCatalogPayload(Map<String, dynamic> payload) {
    final names = SkillRowMapper.parseTranslatedValues(
      _rowsOf(payload['skillNames']),
    );
    return SkillCatalog(
      skills: _rowsOf(payload['skills'])
          .map((row) => SkillRowMapper.toSkillOption(row, names: names))
          .toList(),
    );
  }

  @override
  Future<AlignmentCatalog> fetchAlignmentCatalog() async {
    final freshCached = await _mappedFromFreshCache(
      _alignmentCatalogCacheKey,
      _mapAlignmentCatalogPayload,
    );
    if (freshCached != null) return freshCached;
    try {
      final alignmentRows = await _client
          .from('alignments')
          .select('id, name')
          .order('id', ascending: true);

      final payload = <String, dynamic>{'alignments': alignmentRows};
      await _writeCacheBestEffort(_alignmentCatalogCacheKey, payload);
      return _mapAlignmentCatalogPayload(payload);
    } on PostgrestException catch (error) {
      final cached = await _mappedFromCache(
        _alignmentCatalogCacheKey,
        _mapAlignmentCatalogPayload,
      );
      if (cached != null) return cached;
      throw mapCharacterCreationError(
        error,
        fallbackMessage: _alignmentCatalogErrorMessage,
      );
    } catch (_) {
      final cached = await _mappedFromCache(
        _alignmentCatalogCacheKey,
        _mapAlignmentCatalogPayload,
      );
      if (cached != null) return cached;
      throw mapUnknownCharacterCreationError();
    }
  }

  AlignmentCatalog _mapAlignmentCatalogPayload(Map<String, dynamic> payload) {
    return AlignmentCatalog(
      alignments: _rowsOf(payload['alignments'])
          .map(
            (row) => AlignmentOption(
              id: (row['id'] as num).toInt(),
              name: row['name'] as String? ?? '',
            ),
          )
          .toList(),
    );
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

  /// Récupère les lignes brutes de `translations` (colonnes réelles
  /// `entity_id`/`value`, PAS `name`) pour [entityType]/[fieldName] (`name`
  /// par défaut, `description`/`feature_name`/`feature_description` pour
  /// classes/historiques) dont l'identifiant est dans [entityIds]. Retourne
  /// une liste vide sans requête si [entityIds] est vide.
  ///
  /// Ne parse plus la réponse en `{entity_id: value}` (contrairement à
  /// avant l'introduction du cache) : cette étape de parsing fait
  /// maintenant partie du mapper `XRowMapper.parseTranslatedValues`, appelé
  /// depuis les méthodes `_mapXxxCatalogPayload`, pour rester le point
  /// unique de mapping partagé entre le chemin réseau et le chemin cache
  /// (voir la doc de classe de `SupabaseCharacterCreationRepository`).
  Future<List<Map<String, dynamic>>> _fetchTranslationRows({
    required String entityType,
    required Set<String> entityIds,
    String fieldName = 'name',
  }) async {
    if (entityIds.isEmpty) {
      return const [];
    }

    return await _client
        .from('translations')
        .select('entity_id, value')
        .eq('entity_type', entityType)
        .eq('field_name', fieldName)
        .eq('locale', _locale)
        .inFilter('entity_id', entityIds.toList());
  }

  /// Écrit [payload] (lignes brutes structurées, voir chaque
  /// `_mapXxxCatalogPayload`) dans [_cache] sous [key]. Best-effort : une
  /// écriture cache en échec (ex. disque plein) ne doit jamais faire
  /// échouer un fetch réseau qui a lui-même réussi — avalée silencieusement,
  /// même principe que [_cleanupPartialCharacter].
  Future<void> _writeCacheBestEffort(
    String key,
    Map<String, dynamic> payload,
  ) async {
    try {
      await _cache.put(key, payload);
    } catch (_) {
      // Best-effort : voir la documentation de cette méthode.
    }
  }

  /// Relit [key] depuis [_cache] et la passe par [mapPayload] (l'une des
  /// méthodes `_mapXxxCatalogPayload`, le même mapper que le chemin réseau)
  /// si une entrée existe. Retourne `null` si aucune entrée de cache
  /// n'existe, ou si la lecture/le mapping échoue (cache corrompu, format
  /// inattendu) — traité comme "pas de cache" par l'appelant, qui relance
  /// alors l'erreur réseau d'origine plutôt que de propager une erreur de
  /// cache qui masquerait la vraie cause.
  Future<T?> _mappedFromCache<T>(
    String key,
    T Function(Map<String, dynamic> payload) mapPayload,
  ) async {
    try {
      final cached = await _cache.get(key);
      if (cached is Map<String, dynamic>) {
        return mapPayload(cached);
      }
    } catch (_) {
      // Traité comme "pas de cache" — voir la documentation de cette
      // méthode.
    }
    return null;
  }

  /// Relit [key] depuis [_cache] via [ReferenceDataCache.getFresh]
  /// ([_catalogCacheTtl]) et la passe par [mapPayload] si une entrée fraîche
  /// existe — voir la doc de classe, point 1 ("cache d'abord si frais").
  /// Retourne `null` si aucune entrée fraîche n'existe (absente ou périmée)
  /// ou si la lecture/le mapping échoue (même traitement défensif que
  /// [_mappedFromCache]) : dans tous ces cas, l'appelant retombe simplement
  /// sur son comportement réseau-d'abord habituel, inchangé.
  Future<T?> _mappedFromFreshCache<T>(
    String key,
    T Function(Map<String, dynamic> payload) mapPayload,
  ) async {
    try {
      final cached = await _cache.getFresh(key, maxAge: _catalogCacheTtl);
      if (cached is Map<String, dynamic>) {
        return mapPayload(cached);
      }
    } catch (_) {
      // Traité comme "pas de cache frais" — voir la documentation de cette
      // méthode.
    }
    return null;
  }

  /// Normalise une valeur potentiellement issue de `jsonDecode` (types
  /// `dynamic` non garantis, notamment sur les maps imbriquées) ou
  /// directement d'une réponse PostgREST (`List<Map<String, dynamic>>` déjà
  /// bien typée) en `List<Map<String, dynamic>>`. Une valeur absente ou d'un
  /// type inattendu retombe sur une liste vide plutôt que de crasher — même
  /// principe défensif que les `XRowMapper.parseXxx` de ce dépôt.
  static List<Map<String, dynamic>> _rowsOf(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<Object>()
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }
}
