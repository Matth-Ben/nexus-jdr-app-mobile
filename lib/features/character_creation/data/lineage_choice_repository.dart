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

/// Clé de cache et TTL alignés sur `subclass_choice_repository.dart`.
const String _cacheKey = 'lineage_choice_catalog';
const Duration _cacheTtl = Duration(hours: 48);

/// Lecture des lignées 2024 à choisir à l'étape 1/9 "Race", pour les races
/// qui en ont un choix explicite SANS sous-race (Drakéide, Tieffelin,
/// Goliath à ce jour — voir `domain/lineage_choice_catalog.dart`).
///
/// Abstraction dédiée (plutôt qu'une méthode ajoutée à
/// `CharacterCreationRepository`) : même rationale que
/// `SubclassChoiceRepository`. Lecture seule sur des tables de référence ;
/// l'écriture de `characters.lineage_id` reste dans
/// `CharacterCreationRepository.createCharacter`.
abstract class LineageChoiceRepository {
  /// Toutes les lignées `race_lineages.lineage_group = '2024_lineage'` sans
  /// sous-race (`subrace_id IS NULL`), groupées par `race_id` — voir la doc
  /// de classe de `LineageChoiceCatalog` pour le rationale d'une seule
  /// requête non paramétrée par race.
  Future<LineageChoiceCatalog> fetchLineageChoices();
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
  Future<LineageChoiceCatalog> fetchLineageChoices() async {
    final fresh = await _fromCache(fresh: true);
    if (fresh != null) return fresh;
    try {
      final lineageRows = await _client
          .from('race_lineages')
          .select('id, race_id, damage_type')
          .eq('lineage_group', '2024_lineage')
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
        await _cache.put(_cacheKey, payload);
      } catch (_) {
        // Best-effort : une écriture de cache ratée ne fait pas échouer la
        // lecture.
      }
      return _map(payload);
    } catch (error) {
      final cached = await _fromCache(fresh: false);
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

  Future<LineageChoiceCatalog?> _fromCache({required bool fresh}) async {
    try {
      final cached = fresh
          ? await _cache.getFresh(_cacheKey, maxAge: _cacheTtl)
          : await _cache.get(_cacheKey);
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
