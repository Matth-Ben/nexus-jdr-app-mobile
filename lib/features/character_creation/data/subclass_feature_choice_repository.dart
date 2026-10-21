import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/reference_data_cache.dart';
import '../../../core/utils/french_text_normalizer.dart';
import '../domain/character_creation_failure.dart';
import '../domain/subclass_feature_choice.dart';
import '../domain/subclass_feature_option.dart';
import 'character_creation_error_mapper.dart';

const String _locale = 'fr';

const String _subclassFeatureChoiceErrorMessage =
    'Impossible de charger ce choix de sous-classe. Réessayez.';

/// TTL aligné sur les autres catalogues de
/// `character_creation_repository.dart`/`subclass_choice_repository.dart`.
const Duration _cacheTtl = Duration(hours: 48);

/// Résout le second choix de niveau 1 propre à une sous-classe (ex. Ancêtre
/// draconique du Lignage draconique, Ensorceleur) — correctif D99
/// (`docs/dette-technique.md`), pour
/// `presentation/widgets/subclass_feature_choice_block.dart`.
///
/// Abstraction dédiée, même rationale que `SubclassChoiceRepository` : lecture
/// seule sur des tables de référence, l'écriture de
/// `character_class_options` reste dans
/// `CharacterCreationRepository.createCharacter`.
abstract class SubclassFeatureChoiceRepository {
  /// `null` si [subclassId] n'a pas de second choix de niveau 1 (immense
  /// majorité des sous-classes), sinon le choix complet (éventuellement à
  /// options vides — voir la doc de classe de [SubclassFeatureChoice]).
  Future<SubclassFeatureChoice?> fetchFor(int subclassId);
}

class SupabaseSubclassFeatureChoiceRepository
    implements SubclassFeatureChoiceRepository {
  const SupabaseSubclassFeatureChoiceRepository(this._client, this._cache);

  final SupabaseClient _client;
  final ReferenceDataCache _cache;

  static String _cacheKeyFor(int subclassId) =>
      'subclass_feature_choice:$subclassId';

  @override
  Future<SubclassFeatureChoice?> fetchFor(int subclassId) async {
    final cacheKey = _cacheKeyFor(subclassId);
    final fresh = await _fromCache(cacheKey, fresh: true);
    if (fresh.found) return fresh.choice;
    try {
      final choice = await _fetchFromNetwork(subclassId);
      try {
        await _cache.put(cacheKey, _toPayload(choice));
      } catch (_) {
        // Best-effort : une écriture de cache ratée ne fait pas échouer la
        // lecture.
      }
      return choice;
    } catch (error) {
      final cached = await _fromCache(cacheKey, fresh: false);
      if (cached.found) return cached.choice;
      if (error is PostgrestException) {
        throw mapCharacterCreationError(
          error,
          fallbackMessage: _subclassFeatureChoiceErrorMessage,
        );
      }
      if (error is CharacterCreationFailure) rethrow;
      throw mapUnknownCharacterCreationError();
    }
  }

  Future<SubclassFeatureChoice?> _fetchFromNetwork(int subclassId) async {
    // Ligne du second choix de niveau 1, hors `'sous_classe'` (déjà couvert
    // par `SubclassChoiceBlock`) — générique, pas une liste de sous-classes
    // codée en dur, voir la doc de classe de `SubclassFeatureChoice`.
    final featureRows = await _client
        .from('class_features')
        .select('id, choice_type')
        .eq('subclass_id', subclassId)
        .eq('level', 1)
        .not('choice_type', 'is', null)
        .neq('choice_type', 'sous_classe')
        .limit(1);
    if (featureRows.isEmpty) return null;

    final classFeatureId = (featureRows.first['id'] as num).toInt();
    final choiceType = featureRows.first['choice_type'] as String;

    final featureNameRows = await _client
        .from('translations')
        .select('entity_id, value')
        .eq('entity_type', 'class_feature')
        .eq('field_name', 'name')
        .eq('locale', _locale)
        .eq('entity_id', classFeatureId.toString());
    final featureName = featureNameRows.isEmpty
        ? 'Choix de sous-classe'
        : featureNameRows.first['value'] as String;

    final optionRows = await _client
        .from('class_options')
        .select('id')
        .eq('subclass_id', subclassId)
        .eq('option_type', choiceType);
    final optionIds = [
      for (final row in optionRows)
        if (row['id'] != null) (row['id'] as num).toInt(),
    ];

    var options = const <SubclassFeatureOption>[];
    if (optionIds.isNotEmpty) {
      final ids = optionIds.map((id) => id.toString()).toSet();
      final names = await _fetchTranslated(ids, 'name');
      final descriptions = await _fetchTranslated(ids, 'description');
      options = [
        for (final id in optionIds)
          SubclassFeatureOption(
            id: id,
            name: names[id.toString()] ?? 'Option #$id',
            description: descriptions[id.toString()],
          ),
      ]..sort((a, b) => FrenchTextNormalizer.compare(a.name, b.name));
    }

    return SubclassFeatureChoice(
      classFeatureId: classFeatureId,
      featureName: featureName,
      options: options,
    );
  }

  Future<Map<String, String>> _fetchTranslated(
    Set<String> ids,
    String fieldName,
  ) async {
    final rows = await _client
        .from('translations')
        .select('entity_id, value')
        .eq('entity_type', 'class_option')
        .eq('field_name', fieldName)
        .eq('locale', _locale)
        .inFilter('entity_id', ids.toList());
    return {
      for (final row in rows)
        if (row['entity_id'] != null && row['value'] != null)
          row['entity_id'].toString(): row['value'] as String,
    };
  }

  Map<String, dynamic> _toPayload(SubclassFeatureChoice? choice) {
    if (choice == null) return const {'present': false};
    return {
      'present': true,
      'classFeatureId': choice.classFeatureId,
      'featureName': choice.featureName,
      'options': [
        for (final option in choice.options)
          {
            'id': option.id,
            'name': option.name,
            'description': option.description,
          },
      ],
    };
  }

  SubclassFeatureChoice? _fromPayload(Map<String, dynamic> payload) {
    if (payload['present'] != true) return null;
    final rawOptions = payload['options'] as List<dynamic>? ?? const [];
    return SubclassFeatureChoice(
      classFeatureId: payload['classFeatureId'] as int,
      featureName: payload['featureName'] as String,
      options: [
        for (final raw in rawOptions)
          SubclassFeatureOption(
            id: (raw as Map<String, dynamic>)['id'] as int,
            name: raw['name'] as String,
            description: raw['description'] as String?,
          ),
      ],
    );
  }

  Future<({bool found, SubclassFeatureChoice? choice})> _fromCache(
    String cacheKey, {
    required bool fresh,
  }) async {
    try {
      final cached = fresh
          ? await _cache.getFresh(cacheKey, maxAge: _cacheTtl)
          : await _cache.get(cacheKey);
      if (cached is Map<String, dynamic>) {
        return (found: true, choice: _fromPayload(cached));
      }
    } catch (_) {
      // Cache absent ou corrompu : traité comme « pas de cache ».
    }
    return (found: false, choice: null);
  }
}
