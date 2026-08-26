import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/background_catalog.dart';
import '../domain/class_catalog.dart';
import '../domain/item_catalog.dart';
import '../domain/language_catalog.dart';
import '../domain/race_catalog.dart';
import '../domain/spell_catalog.dart';
import '../domain/tool_catalog.dart';
import 'background_row_mapper.dart';
import 'character_creation_error_mapper.dart';
import 'class_row_mapper.dart';
import 'item_row_mapper.dart';
import 'language_row_mapper.dart';
import 'race_row_mapper.dart';
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

/// Passerelle vers les données de l'assistant de création de personnage.
///
/// Lecture seule pour l'instant : le brouillon de création (choix de
/// race/sous-race, puis des étapes suivantes) est tenu entièrement côté
/// client, en mémoire, par
/// `presentation/providers/character_creation_draft_provider.dart` — aucune
/// ligne `characters` n'est créée ni mise à jour en base avant l'étape 9
/// "Récapitulatif" (pas encore implémentée), qui sera la première à
/// utiliser ce dépôt pour écrire quoi que ce soit. Ce choix fait suite à un
/// problème identifié en revue sur la première architecture (une ligne
/// `characters` incomplète, sans nom, était créée dès l'étape 1, visible
/// comme personnage fantôme dans `CharacterListScreen`) : voir le rapport de
/// la tâche qui a supprimé l'ancienne méthode `saveRaceStep` pour le détail.
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
}
