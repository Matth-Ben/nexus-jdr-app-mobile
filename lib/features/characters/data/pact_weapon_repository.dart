import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/reference_data_cache.dart';
import '../../../core/network/connectivity_checker.dart';
import '../domain/character_failure.dart';
import '../domain/pact_weapon_option.dart';
import '../domain/write_outcome.dart';
import 'character_error_mapper.dart';
import 'pact_weapon_row_mapper.dart';

/// Langue d'affichage des noms d'armes, en dur pour l'instant — même
/// rationale que `_locale` de `character_repository.dart`.
const String _locale = 'fr';

const String _optionsCacheKey = 'pact_weapon_options';

/// Arme de pacte de l'Occultiste (Pacte de la lame) : liste des formes
/// possibles (lecture de référence) et écriture de la forme courante
/// (`character_pact_weapons`, une ligne par personnage, RLS propriétaire).
///
/// Abstraction dédiée (plutôt que méthodes ajoutées à `CharacterRepository`)
/// : même rationale que `WarlockPactSpellRepository`, cela évite d'imposer
/// ces méthodes aux doubles de test de tous les autres écrans. La lecture de
/// la forme COURANTE, elle, fait partie du chargement de la fiche
/// (`CharacterRepository.fetchCharacterDetail`, donc de son cache
/// hors-ligne).
abstract class PactWeaponRepository {
  /// Armes éligibles, triées par nom. Réseau d'abord, dernière lecture
  /// réussie en secours.
  Future<List<PactWeaponOption>> fetchEligibleWeapons();

  /// Enregistre [itemId] comme forme courante (upsert). Hors-ligne : aucune
  /// écriture, renvoie [WriteOutcome.queued] (pas de file d'attente pour les
  /// écritures d'inventaire, voir `CharacterRepository`).
  Future<WriteOutcome> setPactWeapon({
    required String characterId,
    required int itemId,
  });
}

class SupabasePactWeaponRepository implements PactWeaponRepository {
  const SupabasePactWeaponRepository(
    this._client,
    this._connectivityChecker, [
    this._cache,
  ]);

  final SupabaseClient _client;
  final ConnectivityChecker _connectivityChecker;
  final ReferenceDataCache? _cache;

  @override
  Future<List<PactWeaponOption>> fetchEligibleWeapons() async {
    try {
      final rows = await _client
          .from('items')
          .select(
            'id, category, '
            'weapon_properties(damage_dice, damage_type, properties)',
          )
          .eq('category', 'arme')
          .order('id', ascending: true);
      final nameRows = await _fetchNameRows(
        PactWeaponRowMapper.collectIds(rows),
      );
      final payload = <String, dynamic>{'items': rows, 'names': nameRows};
      try {
        await _cache?.put(_optionsCacheKey, payload);
      } catch (_) {
        // Best-effort.
      }
      return _parse(payload);
    } catch (error) {
      try {
        final cached = await _cache?.get(_optionsCacheKey);
        if (cached is Map<String, dynamic>) return _parse(cached);
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
        .eq('entity_type', 'item')
        .eq('field_name', 'name')
        .eq('locale', _locale)
        .inFilter('entity_id', ids.toList());
  }

  static List<Map<String, dynamic>> _rows(Object? value) => value is List
      ? [for (final row in value) Map<String, dynamic>.from(row as Map)]
      : const [];

  static List<PactWeaponOption> _parse(Map<String, dynamic> payload) {
    final names = <String, String>{
      for (final row in _rows(payload['names']))
        if (row['entity_id'] != null && row['value'] is String)
          row['entity_id'].toString(): row['value'] as String,
    };
    return PactWeaponRowMapper.toEligibleOptions(
      _rows(payload['items']),
      names: names,
    );
  }

  @override
  Future<WriteOutcome> setPactWeapon({
    required String characterId,
    required int itemId,
  }) async {
    if (!await _connectivityChecker.hasConnection()) {
      return WriteOutcome.queued;
    }
    try {
      await _client.from('character_pact_weapons').upsert({
        'character_id': characterId,
        'item_id': itemId,
      }, onConflict: 'character_id');
      return WriteOutcome.synced;
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } on CharacterFailure {
      rethrow;
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }
}
