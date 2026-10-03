import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/reference_data_cache.dart';
import '../domain/racial_innate_spell_grant.dart';
import 'character_error_mapper.dart';
import 'racial_innate_spell_row_mapper.dart';

/// Langue d'affichage des noms de sorts, en dur pour l'instant — même
/// rationale que `_locale` de `character_repository.dart`.
const String _locale = 'fr';

/// Lecture de référence de `racial_innate_spells` : sorts innés accordés
/// automatiquement par la race/sous-race d'un personnage à certains niveaux
/// TOTAUX (ex. Tieffelin : Thaumaturgie niveau 1, Représailles infernales
/// niveau 3, Ténèbres niveau 5).
///
/// Périmètre volontairement restreint aux lignes **sans choix de lignée**
/// (`lineage_id IS NULL`) — les races/variantes dont le sort dépend d'un
/// choix de lignée/ascendance que le joueur ne fait pas encore à la création
/// (Drakéide, variantes 2024 d'Elfe/Gnome/Tieffelin) sont hors périmètre,
/// traitées séparément plus tard avec un écran de choix dédié. Une ligne dont
/// `spell_id` est nul (pas de sort à ce palier pour cette race/sous-race,
/// ex. la plupart des sous-races d'Elfe) n'est jamais résolue en
/// [RacialInnateSpellGrant].
///
/// Lecture seule sur des tables de référence (`racial_innate_spells`,
/// `translations`), jamais d'écriture : les sorts accordés sont écrits par
/// `CharacterCreationRepository.createCharacter` (à la création) et
/// `CharacterRepository.applyLevelUp` (à la montée de niveau).
///
/// Abstraction dédiée (plutôt que méthodes ajoutées à `CharacterRepository`/
/// `CharacterCreationRepository`) : même rationale que
/// `WarlockPactSpellRepository`, cela évite d'imposer cette méthode aux
/// doubles de test de tous les autres écrans.
abstract class RacialInnateSpellRepository {
  /// Sorts innés accordés par la race [raceId] (et sa sous-race [subraceId],
  /// `null` si le personnage n'en a pas) à un niveau TOTAL de personnage au
  /// plus [maxCharacterLevel] — triés par
  /// [RacialInnateSpellGrant.characterLevel] croissant. Réseau d'abord,
  /// dernière lecture réussie en secours.
  Future<List<RacialInnateSpellGrant>> fetchApplicableGrants({
    required int raceId,
    int? subraceId,
    required int maxCharacterLevel,
  });
}

class SupabaseRacialInnateSpellRepository
    implements RacialInnateSpellRepository {
  const SupabaseRacialInnateSpellRepository(this._client, [this._cache]);

  final SupabaseClient _client;
  final ReferenceDataCache? _cache;

  @override
  Future<List<RacialInnateSpellGrant>> fetchApplicableGrants({
    required int raceId,
    int? subraceId,
    required int maxCharacterLevel,
  }) async {
    final cacheKey =
        'racial_innate_spells:$raceId:${subraceId ?? '-'}:$maxCharacterLevel';
    try {
      final rows = await _client
          .from('racial_innate_spells')
          .select('spell_id, subrace_id, character_level')
          .eq('race_id', raceId)
          .isFilter('lineage_id', null)
          .not('spell_id', 'is', null)
          .lte('character_level', maxCharacterLevel);
      final nameRows = await _fetchNameRows(
        RacialInnateSpellRowMapper.collectSpellIds(rows),
      );
      final payload = <String, dynamic>{'rows': rows, 'names': nameRows};
      try {
        await _cache?.put(cacheKey, payload);
      } catch (_) {
        // Best-effort.
      }
      return _parse(payload, subraceId: subraceId);
    } catch (error) {
      try {
        final cached = await _cache?.get(cacheKey);
        if (cached is Map<String, dynamic>) {
          return _parse(cached, subraceId: subraceId);
        }
      } catch (_) {
        // Cache illisible : on relance l'erreur d'origine.
      }
      if (error is PostgrestException) throw mapCharacterError(error);
      throw mapUnknownCharacterError();
    }
  }

  Future<List<Map<String, dynamic>>> _fetchNameRows(Set<String> ids) async {
    if (ids.isEmpty) return const [];
    return _client
        .from('translations')
        .select('entity_id, value')
        .eq('entity_type', 'spell')
        .eq('field_name', 'name')
        .eq('locale', _locale)
        .inFilter('entity_id', ids.toList());
  }

  static List<Map<String, dynamic>> _rows(Object? value) => value is List
      ? [for (final row in value) Map<String, dynamic>.from(row as Map)]
      : const [];

  List<RacialInnateSpellGrant> _parse(
    Map<String, dynamic> payload, {
    required int? subraceId,
  }) {
    final names = <String, String>{
      for (final row in _rows(payload['names']))
        if (row['entity_id'] != null && row['value'] is String)
          row['entity_id'].toString(): row['value'] as String,
    };
    return RacialInnateSpellRowMapper.parse(
      rows: _rows(payload['rows']),
      subraceId: subraceId,
      names: names,
    );
  }
}
