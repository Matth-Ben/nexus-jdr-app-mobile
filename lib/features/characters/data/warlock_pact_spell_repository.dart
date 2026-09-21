import 'package:supabase_flutter/supabase_flutter.dart';

import '../../character_creation/data/spell_row_mapper.dart';
import '../../character_creation/domain/spell_option.dart';
import '../domain/character_failure.dart';
import 'character_error_mapper.dart';

/// Langue d'affichage des noms de sorts, en dur pour l'instant — même
/// rationale que `_locale` de `character_repository.dart`.
const String _locale = 'fr';

/// Nom français (`translations`, champ `name`) du sort accordé par le pacte
/// de la chaîne. Retrouvé par son nom plutôt que par un identifiant codé en
/// dur : les `spells.id` dépendent du peuplement de chaque environnement.
const String familiarSpellFrenchName = 'Appel de familier';

/// Lectures de référence propres à la faveur de pacte de l'Occultiste
/// (montée de niveau 3) — lecture seule sur des tables de référence
/// (`spells`, `translations`), jamais d'écriture : les sorts obtenus sont
/// écrits par `CharacterRepository.applyLevelUp`.
///
/// Abstraction (plutôt que méthodes ajoutées à `CharacterRepository`) : ces
/// deux lectures ne servent qu'à ce flux, et cela évite d'imposer ces
/// méthodes aux doubles de test de tous les autres écrans.
abstract class WarlockPactSpellRepository {
  /// Tous les sorts mineurs (niveau 0) du catalogue, TOUTES classes
  /// confondues (Livre des ombres : "n'importe quelle classe"), placeholders
  /// d'import incomplets exclus, triés par nom.
  Future<List<SpellOption>> fetchAllCantrips();

  /// `spells.id` de Appel de familier, `null` si le sort n'existe pas
  /// (ou pas en français) dans le catalogue de cet environnement.
  Future<int?> findFamiliarSpellId();
}

class SupabaseWarlockPactSpellRepository implements WarlockPactSpellRepository {
  const SupabaseWarlockPactSpellRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<SpellOption>> fetchAllCantrips() async {
    try {
      final spellRows = await _client
          .from('spells')
          .select('id, level, school, casting_time, is_incomplete')
          .eq('level', 0)
          .eq('is_incomplete', false)
          .order('id', ascending: true);
      final ids = SpellRowMapper.collectIds(spellRows);
      if (ids.isEmpty) return const [];

      final nameRows = await _client
          .from('translations')
          .select('entity_id, value')
          .eq('entity_type', 'spell')
          .eq('field_name', 'name')
          .eq('locale', _locale)
          .inFilter('entity_id', ids.toList());
      final names = SpellRowMapper.parseTranslatedValues(nameRows);

      return [
        for (final row in spellRows)
          SpellRowMapper.toSpellOption(row, names: names),
      ]..sort((a, b) => a.name.compareTo(b.name));
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } on CharacterFailure {
      rethrow;
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }

  @override
  Future<int?> findFamiliarSpellId() async {
    try {
      final rows = await _client
          .from('translations')
          .select('entity_id')
          .eq('entity_type', 'spell')
          .eq('field_name', 'name')
          .eq('locale', _locale)
          .ilike('value', familiarSpellFrenchName);
      for (final row in rows) {
        final id = int.tryParse('${row['entity_id']}');
        if (id != null) return id;
      }
      return null;
    } on PostgrestException catch (error) {
      throw mapCharacterError(error);
    } catch (_) {
      throw mapUnknownCharacterError();
    }
  }
}
