import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/reference_data_cache.dart';
import '../domain/character_creation_failure.dart';
import '../domain/subclass_choice_catalog.dart';
import 'character_creation_error_mapper.dart';
import 'class_row_mapper.dart';
import 'subclass_choice_row_mapper.dart';

/// Langue d'affichage, en dur pour l'instant (même rationale que
/// `_locale` de `character_creation_repository.dart`).
const String _locale = 'fr';

const String _subclassChoiceErrorMessage =
    'Impossible de charger les sous-classes disponibles. Réessayez.';

/// Clé de cache et TTL alignés sur les autres catalogues de
/// `character_creation_repository.dart`.
const String _cacheKey = 'subclass_choice_catalog';
const Duration _cacheTtl = Duration(hours: 48);

/// Lecture des sous-classes à choisir au niveau 1 (étape 2/9 « Classe »).
///
/// Abstraction dédiée (plutôt qu'une méthode ajoutée à
/// `CharacterCreationRepository`, implémenté par une douzaine de doubles de
/// test) — même choix que `WarlockPactSpellRepository`. Lecture seule sur des
/// tables de référence ; l'écriture de `character_classes.subclass_id` reste
/// dans `CharacterCreationRepository.createCharacter`.
abstract class SubclassChoiceRepository {
  /// Classes qui choisissent leur sous-classe au niveau 1 (déterminées par
  /// les données) avec leurs sous-classes disponibles.
  Future<SubclassChoiceCatalog> fetchLevelOneSubclassChoices();
}

/// Même stratégie que les catalogues de `SupabaseCharacterCreationRepository` :
/// cache frais (< 48 h) d'abord, sinon réseau (résultat écrit au cache), et
/// en cas d'échec réseau le cache même périmé ; erreur seulement si aucun
/// cache n'existe non plus.
class SupabaseSubclassChoiceRepository implements SubclassChoiceRepository {
  const SupabaseSubclassChoiceRepository(this._client, this._cache);

  final SupabaseClient _client;
  final ReferenceDataCache _cache;

  @override
  Future<SubclassChoiceCatalog> fetchLevelOneSubclassChoices() async {
    final fresh = await _fromCache(fresh: true);
    if (fresh != null) return fresh;
    try {
      final featureRows = await _client
          .from('class_features')
          .select('class_id, level, choice_type, subclass_id')
          .eq('level', 1)
          .eq('choice_type', 'sous_classe')
          .isFilter('subclass_id', null);
      final classIds = SubclassChoiceRowMapper.collectConcernedClassIds(
        featureRows,
      );
      var subclassRows = const <Map<String, dynamic>>[];
      var nameRows = const <Map<String, dynamic>>[];
      var descriptionRows = const <Map<String, dynamic>>[];
      if (classIds.isNotEmpty) {
        subclassRows = await _client
            .from('subclasses')
            .select('id, class_id, available_from_level')
            .inFilter('class_id', classIds.toList())
            .eq('available_from_level', 1)
            .order('id', ascending: true);
        final ids = SubclassChoiceRowMapper.collectSubclassIds(subclassRows);
        if (ids.isNotEmpty) {
          nameRows = await _fetchTranslated(ids, 'name');
          descriptionRows = await _fetchTranslated(ids, 'description');
        }
      }
      final payload = <String, dynamic>{
        'features': featureRows,
        'subclasses': subclassRows,
        'names': nameRows,
        'descriptions': descriptionRows,
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
          fallbackMessage: _subclassChoiceErrorMessage,
        );
      }
      if (error is CharacterCreationFailure) rethrow;
      throw mapUnknownCharacterCreationError();
    }
  }

  Future<SubclassChoiceCatalog?> _fromCache({required bool fresh}) async {
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

  SubclassChoiceCatalog _map(Map<String, dynamic> payload) {
    return SubclassChoiceRowMapper.toCatalog(
      concernedClassIds: SubclassChoiceRowMapper.collectConcernedClassIds(
        _rows(payload['features']),
      ),
      subclassRows: _rows(payload['subclasses']),
      names: ClassRowMapper.parseTranslatedValues(_rows(payload['names'])),
      descriptions: ClassRowMapper.parseTranslatedValues(
        _rows(payload['descriptions']),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchTranslated(
    Set<String> ids,
    String fieldName,
  ) async {
    return await _client
        .from('translations')
        .select('entity_id, value')
        .eq('entity_type', 'subclass')
        .eq('field_name', fieldName)
        .eq('locale', _locale)
        .inFilter('entity_id', ids.toList());
  }
}
