import '../../../core/utils/french_text_normalizer.dart';
import '../domain/level_up_metamagic_option.dart';

/// Fonctions de mapping pures entre les lignes brutes `class_options`/
/// `translations` renvoyées par PostgREST et [LevelUpMetamagicOption], pour
/// l'étape "Métamagie" de la montée de niveau (Ensorceleur) — voir
/// `SupabaseCharacterRepository.fetchAvailableMetamagicOptions`.
///
/// Duplicata volontaire de `LevelUpInfusionRowMapper` (même structure
/// `prerequisites` jsonb, clé `'cost'` au lieu de `'text'`) — voir sa
/// documentation de classe pour le rationale de duplication.
abstract final class LevelUpMetamagicRowMapper {
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

  /// Extrait `prerequisites->>'cost'` d'une ligne `class_options` brute —
  /// `null` si la clé `cost` est absente, vide, ou si `prerequisites` n'est
  /// pas un objet JSON.
  static String? costTextFor(Map<String, dynamic> row) {
    final prerequisites = row['prerequisites'];
    if (prerequisites is Map) {
      final cost = prerequisites['cost'];
      if (cost is String && cost.isNotEmpty) {
        return cost;
      }
    }
    return null;
  }

  /// Construit les [LevelUpMetamagicOption] à partir des lignes brutes
  /// `class_options` (déjà filtrées pour exclure les options déjà connues,
  /// voir `SupabaseCharacterRepository.fetchAvailableMetamagicOptions`) et
  /// des noms/descriptions déjà résolus — triées alphabétiquement (même
  /// règle que `LevelUpInfusionRowMapper.toOptions`).
  static List<LevelUpMetamagicOption> toOptions(
    List<Map<String, dynamic>> rows, {
    required Map<String, String> names,
    required Map<String, String> descriptions,
  }) {
    final options = [
      for (final row in rows)
        if (row['id'] != null)
          LevelUpMetamagicOption(
            id: row['id'] as Object,
            name: names[row['id'].toString()] ?? 'Métamagie #${row['id']}',
            description: descriptions[row['id'].toString()] ?? '',
            costText: costTextFor(row),
          ),
    ]..sort((a, b) => FrenchTextNormalizer.compare(a.name, b.name));
    return options;
  }
}
