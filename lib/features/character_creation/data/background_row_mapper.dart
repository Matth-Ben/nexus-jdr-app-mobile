import '../domain/background_option.dart';

/// Fonctions de mapping pures entre les lignes brutes renvoyées par
/// PostgREST (`backgrounds`, `translations`) et [BackgroundOption].
///
/// Dédié à l'étape 3/9 (Historique) plutôt que réutilisé depuis
/// `race_row_mapper.dart`/`class_row_mapper.dart` : même principe de
/// résolution des valeurs via `translations` (colonnes réelles `entity_id`/
/// `field_name`/`value`, PAS de colonnes `name`/`feature_name`/
/// `feature_description` directement sur `backgrounds`), mais dupliqué pour
/// ne jamais coupler les étapes entre elles — voir le commentaire de classe
/// de `RaceRowMapper` pour le rationale détaillé.
abstract final class BackgroundRowMapper {
  /// Identifiants (`id`) à résoudre via `translations`, normalisés en
  /// `String` (les ids reviennent en `int` de PostgREST, `translations
  /// .entity_id` est `text`).
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

  /// Parse les lignes brutes de `translations` (colonnes réelles
  /// `entity_id`/`value`, PAS `name`) en `{entity_id: value}`. Une ligne sans
  /// `entity_id`/`value` exploitable est ignorée plutôt que de faire échouer
  /// tout le mapping — même règle que `ClassRowMapper.parseTranslatedValues`.
  /// Réutilisé pour les trois champs `field_name='name'`/`'feature_name'`/
  /// `'feature_description'` (trois requêtes séparées côté dépôt, voir
  /// `data/character_creation_repository.dart`).
  static Map<String, String> parseTranslatedValues(
    List<Map<String, dynamic>> rawRows,
  ) {
    final values = <String, String>{};
    for (final row in rawRows) {
      final entityId = row['entity_id'] as String?;
      final value = row['value'] as String?;
      if (entityId != null && value != null) {
        values[entityId] = value;
      }
    }
    return values;
  }

  /// Parse la colonne jsonb `skill_proficiencies` (liste de noms de
  /// compétences en français directement, ex. `["Perspicacité",
  /// "Religion"]` — pas de FK vers `skills`, aucune jointure nécessaire) en
  /// `List<String>`. `null`/type inattendu retombe sur une liste vide plutôt
  /// que de crasher ; les entrées qui ne sont pas des chaînes sont ignorées.
  static List<String> parseSkillProficiencies(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    return raw.whereType<String>().toList();
  }

  /// Construit une [BackgroundOption] à partir d'une ligne brute
  /// `backgrounds` et des valeurs déjà résolues (`names`/`featureNames`/
  /// `featureDescriptions`, clés en `String`, voir [collectIds]). Un id sans
  /// valeur résolue retombe sur un libellé générique ("Historique #12") pour
  /// le nom, ou une chaîne vide pour l'aptitude, plutôt que de crasher ou
  /// d'afficher `null` — même règle que `ClassRowMapper.toClassOption`.
  static BackgroundOption toBackgroundOption(
    Map<String, dynamic> row, {
    required Map<String, String> names,
    required Map<String, String> featureNames,
    required Map<String, String> featureDescriptions,
  }) {
    final id = (row['id'] as num).toInt();
    final key = id.toString();
    return BackgroundOption(
      id: id,
      name: names[key] ?? 'Historique #$id',
      skillProficiencies: parseSkillProficiencies(row['skill_proficiencies']),
      featureName: featureNames[key] ?? '',
      featureDescription: featureDescriptions[key] ?? '',
    );
  }
}
