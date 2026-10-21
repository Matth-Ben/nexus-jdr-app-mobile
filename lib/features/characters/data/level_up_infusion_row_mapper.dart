import '../../../core/utils/french_text_normalizer.dart';
import '../domain/level_up_infusion_option.dart';

/// Fonctions de mapping pures entre les lignes brutes `class_options`/
/// `translations` renvoyées par PostgREST et [LevelUpInfusionOption], pour
/// l'étape "Infusions" de la montée de niveau (Artificier) — voir
/// `SupabaseCharacterRepository.fetchAvailableInfusions`.
///
/// Duplicata volontaire de `LevelUpManeuverRowMapper`/`LevelUpFeatRowMapper`
/// (même structure `prerequisites` jsonb que ce dernier) — voir leur
/// documentation de classe pour le rationale de duplication.
abstract final class LevelUpInfusionRowMapper {
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

  /// Extrait `prerequisites->>'text'` d'une ligne `class_options` brute —
  /// `null` si la clé `text` est absente, vide, ou si `prerequisites` n'est
  /// pas un objet JSON — même logique que
  /// `LevelUpFeatRowMapper.prerequisiteTextFor`.
  static String? prerequisiteTextFor(Map<String, dynamic> row) {
    final prerequisites = row['prerequisites'];
    if (prerequisites is Map) {
      final text = prerequisites['text'];
      if (text is String && text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  /// Construit les [LevelUpInfusionOption] à partir des lignes brutes
  /// `class_options` (déjà filtrées pour exclure `min_level` non encore
  /// atteint et les infusions déjà connues, voir
  /// `SupabaseCharacterRepository.fetchAvailableInfusions`) et des noms/
  /// descriptions déjà résolus — triées alphabétiquement (même règle que
  /// `LevelUpManeuverRowMapper.toOptions`).
  static List<LevelUpInfusionOption> toOptions(
    List<Map<String, dynamic>> rows, {
    required Map<String, String> names,
    required Map<String, String> descriptions,
  }) {
    final options = [
      for (final row in rows)
        if (row['id'] != null)
          LevelUpInfusionOption(
            id: row['id'] as Object,
            name: names[row['id'].toString()] ?? 'Infusion #${row['id']}',
            description: descriptions[row['id'].toString()] ?? '',
            prerequisiteText: prerequisiteTextFor(row),
          ),
    ]..sort((a, b) => FrenchTextNormalizer.compare(a.name, b.name));
    return options;
  }
}
