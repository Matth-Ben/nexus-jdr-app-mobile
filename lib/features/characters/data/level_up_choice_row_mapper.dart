import '../domain/level_up_subclass_option.dart';

/// Fonctions de mapping pures entre les lignes brutes `subclasses`/
/// `translations` renvoyées par PostgREST et [LevelUpSubclassOption], pour
/// l'étape "Choix à faire" de la montée de niveau (increment 2) — voir
/// `SupabaseCharacterRepository.fetchLevelUpLevelData`.
abstract final class LevelUpChoiceRowMapper {
  /// Identifiants (`subclasses.id`) à résoudre via `translations`,
  /// normalisés en `String` — même principe que
  /// `ClassFeatureRowMapper.collectIds`.
  static Set<String> collectSubclassIds(List<Map<String, dynamic>> rows) {
    final ids = <String>{};
    for (final row in rows) {
      final id = row['id'];
      if (id != null) {
        ids.add(id.toString());
      }
    }
    return ids;
  }

  /// Construit les [LevelUpSubclassOption] à partir des lignes brutes
  /// `subclasses` (déjà filtrées sur `class_id`/`available_from_level`) et
  /// des noms/descriptions déjà résolus (`names`/`descriptions`, voir
  /// [collectSubclassIds]). [descriptions] peut ne pas couvrir tous les
  /// identifiants (`description` nullable en base) : retombe sur `null`
  /// plutôt que sur un texte de repli, voir la documentation de
  /// [LevelUpSubclassOption.description].
  static List<LevelUpSubclassOption> toSubclassOptions(
    List<Map<String, dynamic>> rows, {
    required Map<String, String> names,
    required Map<String, String> descriptions,
  }) {
    return [
      for (final row in rows)
        if (row['id'] != null)
          LevelUpSubclassOption(
            id: row['id'] as Object,
            name: names[row['id'].toString()] ?? 'Sous-classe #${row['id']}',
            description: descriptions[row['id'].toString()],
          ),
    ];
  }
}
