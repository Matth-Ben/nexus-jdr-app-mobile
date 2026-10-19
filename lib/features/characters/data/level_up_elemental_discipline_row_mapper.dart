import '../../../core/utils/french_text_normalizer.dart';
import '../domain/level_up_elemental_discipline_option.dart';

/// Fonctions de mapping pures entre les lignes brutes `class_options`/
/// `translations` renvoyées par PostgREST et
/// [LevelUpElementalDisciplineOption], pour l'étape "Disciplines
/// élémentaires" de la montée de niveau (Moine, Voie des quatre éléments) —
/// voir `SupabaseCharacterRepository.fetchAvailableElementalDisciplines`.
///
/// Duplicata volontaire de `LevelUpInvocationRowMapper` (même structure,
/// simplifiée : pas de prérequis structurés) — voir sa documentation de
/// classe pour le rationale de duplication.
abstract final class LevelUpElementalDisciplineRowMapper {
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

  /// Construit les [LevelUpElementalDisciplineOption] à partir des lignes
  /// brutes `class_options` (déjà filtrées pour exclure `min_level` non
  /// encore atteint et les disciplines déjà connues, voir
  /// `SupabaseCharacterRepository.fetchAvailableElementalDisciplines`) et des
  /// noms/descriptions déjà résolus — triées alphabétiquement (même règle
  /// que `LevelUpInvocationRowMapper.toInvocationOptions`).
  static List<LevelUpElementalDisciplineOption> toOptions(
    List<Map<String, dynamic>> rows, {
    required Map<String, String> names,
    required Map<String, String> descriptions,
  }) {
    final options = [
      for (final row in rows)
        if (row['id'] != null)
          LevelUpElementalDisciplineOption(
            id: row['id'] as Object,
            name: names[row['id'].toString()] ?? 'Discipline #${row['id']}',
            description: descriptions[row['id'].toString()] ?? '',
          ),
    ]..sort((a, b) => FrenchTextNormalizer.compare(a.name, b.name));
    return options;
  }
}
