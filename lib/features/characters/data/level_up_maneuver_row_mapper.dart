import '../../../core/utils/french_text_normalizer.dart';
import '../domain/level_up_maneuver_option.dart';

/// Fonctions de mapping pures entre les lignes brutes `class_options`/
/// `translations` renvoyées par PostgREST et [LevelUpManeuverOption], pour
/// l'étape "Manœuvres" de la montée de niveau (Guerrier, Maître de guerre) —
/// voir `SupabaseCharacterRepository.fetchAvailableManeuvers`.
///
/// Duplicata volontaire de `LevelUpElementalDisciplineRowMapper` (même
/// structure) — voir sa documentation de classe pour le rationale de
/// duplication.
abstract final class LevelUpManeuverRowMapper {
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

  /// Construit les [LevelUpManeuverOption] à partir des lignes brutes
  /// `class_options` (déjà filtrées pour exclure `min_level` non encore
  /// atteint et les manœuvres déjà connues, voir
  /// `SupabaseCharacterRepository.fetchAvailableManeuvers`) et des noms/
  /// descriptions déjà résolus — triées alphabétiquement (même règle que
  /// `LevelUpElementalDisciplineRowMapper.toOptions`).
  static List<LevelUpManeuverOption> toOptions(
    List<Map<String, dynamic>> rows, {
    required Map<String, String> names,
    required Map<String, String> descriptions,
  }) {
    final options = [
      for (final row in rows)
        if (row['id'] != null)
          LevelUpManeuverOption(
            id: row['id'] as Object,
            name: names[row['id'].toString()] ?? 'Manœuvre #${row['id']}',
            description: descriptions[row['id'].toString()] ?? '',
          ),
    ]..sort((a, b) => FrenchTextNormalizer.compare(a.name, b.name));
    return options;
  }
}
