import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/reference_data_cache.dart';
import '../domain/character_creation_failure.dart';
import '../domain/lineage_choice_catalog.dart';
import 'character_creation_error_mapper.dart';
import 'class_row_mapper.dart';
import 'lineage_choice_row_mapper.dart';

/// Langue d'affichage, en dur pour l'instant — même rationale que `_locale`
/// de `subclass_choice_repository.dart`.
const String _locale = 'fr';

const String _lineageChoiceErrorMessage =
    'Impossible de charger les ascendances/lignées disponibles. Réessayez.';

/// Clé de cache et TTL alignés sur `subclass_choice_repository.dart` — une
/// entrée DISTINCTE par édition (voir [fetchLineageChoices]) : le Drakéide a
/// deux jeux d'ascendances totalement différents selon l'édition
/// (`race_lineages.lineage_group`), jamais mélangés dans la même entrée.
String _cacheKeyFor(String edition) => 'lineage_choice_catalog:$edition';
const Duration _cacheTtl = Duration(hours: 48);

/// `race_lineages.lineage_group` correspondant à [edition] — chantier
/// "différenciation 2014/2024 pour les races" (24/10/2026) : `'2024_lineage'`
/// (comportement d'avant ce chantier, inchangé) pour toute édition autre que
/// `'2014'`, `'phb_ancestry'` pour `'2014'`. Concrètement : le Drakéide a 10
/// lignes de chaque groupe (même jeu de types de dégâts, répartis
/// différemment) ; le Tieffelin/Goliath n'ont QUE des lignes `2024_lineage`
/// (pas de `phb_ancestry`) — voir la doc de classe de [fetchLineageChoices]
/// pour la conséquence (catalogue vide pour ces races en 2014, jamais un
/// crash).
String _lineageGroupFor(String edition) =>
    edition == '2014' ? 'phb_ancestry' : '2024_lineage';

/// Lecture des lignées à choisir à l'étape 1/9 "Race", pour les races qui en
/// ont un choix explicite SANS sous-race (Drakéide, Tieffelin, Goliath à ce
/// jour — voir `domain/lineage_choice_catalog.dart`).
///
/// Abstraction dédiée (plutôt qu'une méthode ajoutée à
/// `CharacterCreationRepository`) : même rationale que
/// `SubclassChoiceRepository`. Lecture seule sur des tables de référence ;
/// l'écriture de `characters.lineage_id` reste dans
/// `CharacterCreationRepository.createCharacter`.
abstract class LineageChoiceRepository {
  /// Toutes les lignées `race_lineages.lineage_group = `[_lineageGroupFor]`
  /// ([edition])` sans sous-race (`subrace_id IS NULL`), groupées par
  /// `race_id` — voir la doc de classe de `LineageChoiceCatalog` pour le
  /// rationale d'une seule requête non paramétrée par race (au-delà de
  /// [edition]).
  ///
  /// [edition] (`CharacterCreationDraft.edition`) détermine le `lineage_group`
  /// interrogé — chantier "différenciation 2014/2024 pour les races"
  /// (24/10/2026) : le Drakéide a un jeu d'ascendances RAW distinct par
  /// édition (10 couleurs de dragon chacun, répartis différemment selon le
  /// groupe) ; le Tieffelin/Goliath n'ont eux QUE des lignes
  /// `'2024_lineage'`, jamais de `'phb_ancestry'` — pour `edition == '2014'`,
  /// leur `optionsFor(raceId)` est alors simplement vide (`isConcerned`
  /// `false`), pas une erreur. Pour le Tieffelin spécifiquement, RAW 2014
  /// n'a de toute façon qu'un seul legs sans choix : `presentation
  /// /race_step_screen.dart` saute cet écran avant même d'arriver ici dans
  /// ce cas, voir sa doc de classe — mais le lookup du legs "Infernal"
  /// continue d'interroger `edition: '2024'` explicitement (seule édition où
  /// cette ligne existe), pas [edition] du personnage en cours de création.
  Future<LineageChoiceCatalog> fetchLineageChoices({required String edition});
}

/// Même stratégie que `SupabaseSubclassChoiceRepository` : cache frais
/// (< 48 h) d'abord, sinon réseau (résultat écrit au cache), et en cas
/// d'échec réseau le cache même périmé ; erreur seulement si aucun cache
/// n'existe non plus.
class SupabaseLineageChoiceRepository implements LineageChoiceRepository {
  const SupabaseLineageChoiceRepository(this._client, this._cache);

  final SupabaseClient _client;
  final ReferenceDataCache _cache;

  @override
  Future<LineageChoiceCatalog> fetchLineageChoices({
    required String edition,
  }) async {
    final cacheKey = _cacheKeyFor(edition);
    final fresh = await _fromCache(cacheKey, fresh: true);
    if (fresh != null) return fresh;
    try {
      final lineageRows = await _client
          .from('race_lineages')
          .select('id, race_id, damage_type')
          .eq('lineage_group', _lineageGroupFor(edition))
          .isFilter('subrace_id', null);
      final ids = LineageChoiceRowMapper.collectLineageIds(lineageRows);
      var nameRows = const <Map<String, dynamic>>[];
      var innateSpellRows = const <Map<String, dynamic>>[];
      if (ids.isNotEmpty) {
        nameRows = await _client
            .from('translations')
            .select('entity_id, value')
            .eq('entity_type', 'race_lineage')
            .eq('field_name', 'name')
            .eq('locale', _locale)
            .inFilter('entity_id', ids.toList());
        // Détermine, parmi ces lignées, lesquelles ont des sorts innés
        // (Tieffelin) — voir `LineageChoiceRowMapper.subtitleOf`, qui ne
        // sait rien de la race elle-même, seulement de cette présence.
        innateSpellRows = await _client
            .from('racial_innate_spells')
            .select('lineage_id')
            .inFilter('lineage_id', [for (final id in ids) int.parse(id)]);
      }
      final payload = <String, dynamic>{
        'lineages': lineageRows,
        'names': nameRows,
        'innate_spells': innateSpellRows,
      };
      try {
        await _cache.put(cacheKey, payload);
      } catch (_) {
        // Best-effort : une écriture de cache ratée ne fait pas échouer la
        // lecture.
      }
      return _map(payload);
    } catch (error) {
      final cached = await _fromCache(cacheKey, fresh: false);
      if (cached != null) return cached;
      if (error is PostgrestException) {
        throw mapCharacterCreationError(
          error,
          fallbackMessage: _lineageChoiceErrorMessage,
        );
      }
      if (error is CharacterCreationFailure) rethrow;
      throw mapUnknownCharacterCreationError();
    }
  }

  Future<LineageChoiceCatalog?> _fromCache(
    String cacheKey, {
    required bool fresh,
  }) async {
    try {
      final cached = fresh
          ? await _cache.getFresh(cacheKey, maxAge: _cacheTtl)
          : await _cache.get(cacheKey);
      if (cached is Map<String, dynamic>) return _map(cached);
    } catch (_) {
      // Cache absent ou corrompu : traité comme « pas de cache ».
    }
    return null;
  }

  static List<Map<String, dynamic>> _rows(Object? value) => value is List
      ? [for (final row in value) Map<String, dynamic>.from(row as Map)]
      : const [];

  LineageChoiceCatalog _map(Map<String, dynamic> payload) {
    final lineageIdsWithInnateSpells = <int>{
      for (final row in _rows(payload['innate_spells']))
        if (row['lineage_id'] case final num id) id.toInt(),
    };
    return LineageChoiceRowMapper.toCatalog(
      lineageRows: _rows(payload['lineages']),
      names: ClassRowMapper.parseTranslatedValues(_rows(payload['names'])),
      lineageIdsWithInnateSpells: lineageIdsWithInnateSpells,
    );
  }
}
