import '../domain/class_option.dart';

/// Fonctions de mapping pures entre les lignes brutes renvoyées par
/// PostgREST (`classes`, `translations`) et [ClassOption].
///
/// Dédié à l'étape 2/9 (Classe) plutôt que réutilisé depuis
/// `race_row_mapper.dart` : même principe de résolution des noms via
/// `translations` (colonnes réelles `entity_id`/`field_name`/`value`, PAS
/// `name`), mais dupliqué pour ne jamais coupler les deux étapes entre elles
/// — voir le commentaire de classe de `RaceRowMapper` pour le rationale
/// détaillé.
abstract final class ClassRowMapper {
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
  /// tout le mapping — même règle que `RaceRowMapper.parseTranslatedNames`.
  /// Réutilisé à la fois pour `field_name='name'` et `field_name='description'`
  /// (deux requêtes séparées côté dépôt, voir
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

  /// Construit une [ClassOption] à partir d'une ligne brute `classes` et des
  /// noms/descriptions déjà résolus (`names`/`descriptions`, clés en
  /// `String`, voir [collectIds]). Un id sans nom résolu retombe sur un
  /// libellé générique ("Classe #12") plutôt que de crasher ou d'afficher
  /// `null` ; une description manquante retombe sur une chaîne vide (même
  /// règle que `RaceRowMapper.parseTraits` pour une description de trait
  /// manquante).
  static ClassOption toClassOption(
    Map<String, dynamic> row, {
    required Map<String, String> names,
    required Map<String, String> descriptions,
  }) {
    final id = (row['id'] as num).toInt();
    return ClassOption(
      id: id,
      name: names[id.toString()] ?? 'Classe #$id',
      description: descriptions[id.toString()] ?? '',
      hitDie: (row['hit_die'] as num).toInt(),
    );
  }
}
