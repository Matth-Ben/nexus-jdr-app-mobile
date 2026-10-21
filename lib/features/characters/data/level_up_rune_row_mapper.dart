import '../../../core/utils/french_text_normalizer.dart';
import '../domain/level_up_rune_option.dart';

/// Fonctions de mapping pures entre les lignes brutes `class_options`/
/// `translations` renvoyées par PostgREST et [LevelUpRuneOption], pour
/// l'étape "Runes" de la montée de niveau (Guerrier, Chevalier runique) —
/// voir `SupabaseCharacterRepository.fetchAvailableRunes`.
///
/// Duplicata volontaire de `LevelUpManeuverRowMapper` (même structure) —
/// voir sa documentation de classe pour le rationale de duplication.
abstract final class LevelUpRuneRowMapper {
  /// Identifiants (`class_options.id`) à résoudre via `translations`,
  /// normalisés en `String`.
  static Set<String> collectIds(List<Map<String, dynamic>> rows) {
    final ids = <String>{};
    for (final row in rows) {
      final id = row['id'];
      if (id != null) {
        ids.add(id.toString());
      }
    }
    return ids;
  }

  /// Construit les [LevelUpRuneOption] à partir des lignes brutes
  /// `class_options` (déjà filtrées pour exclure `min_level` non encore
  /// atteint et les runes déjà connues, voir
  /// `SupabaseCharacterRepository.fetchAvailableRunes`) et des noms/
  /// descriptions déjà résolus — triées alphabétiquement (même règle que
  /// `LevelUpManeuverRowMapper.toOptions`).
  static List<LevelUpRuneOption> toOptions(
    List<Map<String, dynamic>> rows, {
    required Map<String, String> names,
    required Map<String, String> descriptions,
  }) {
    final options = [
      for (final row in rows)
        if (row['id'] != null)
          LevelUpRuneOption(
            id: row['id'] as Object,
            name: names[row['id'].toString()] ?? 'Rune #${row['id']}',
            description: descriptions[row['id'].toString()] ?? '',
          ),
    ]..sort((a, b) => FrenchTextNormalizer.compare(a.name, b.name));
    return options;
  }
}
