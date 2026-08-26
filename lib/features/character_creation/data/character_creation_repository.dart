import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/background_catalog.dart';
import '../domain/class_catalog.dart';
import '../domain/race_catalog.dart';
import 'background_row_mapper.dart';
import 'character_creation_error_mapper.dart';
import 'class_row_mapper.dart';
import 'race_row_mapper.dart';

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
          .select('id, hit_die')
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
          .select('id, skill_proficiencies')
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
}
