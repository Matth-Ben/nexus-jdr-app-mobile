import '../domain/skill_option.dart';

/// Fonctions de mapping pures entre les lignes brutes renvoyées par
/// PostgREST (`skills`, `translations`) et [SkillOption].
///
/// Dédié à l'étape 9/9 (Récapitulatif) plutôt que réutilisé depuis
/// `tool_row_mapper.dart`/`language_row_mapper.dart` : même principe de
/// résolution des noms via `translations` (colonnes réelles `entity_id`/
/// `field_name`/`value`, PAS de colonne `name` directement sur `skills`),
/// mais dupliqué pour ne jamais coupler les étapes entre elles — voir le
/// commentaire de classe de `RaceRowMapper` pour le rationale détaillé.
abstract final class SkillRowMapper {
  /// Identifiants (`id`) à résoudre via `translations`, normalisés en
  /// `String` (les ids reviennent en `int` de PostgREST, `translations
  /// .entity_id` est `text`) — même principe que `ToolRowMapper.collectIds`.
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
  /// tout le mapping — même règle que `ToolRowMapper.parseTranslatedValues`.
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

  /// Construit un [SkillOption] à partir d'une ligne brute `skills` et des
  /// noms déjà résolus (`names`, clés en `String`, voir [collectIds]). Un id
  /// sans nom résolu retombe sur un libellé générique ("Compétence #12")
  /// plutôt que de crasher ou d'afficher `null` ; un `ability_id` manquant
  /// retombe sur une chaîne vide — même principe que
  /// `ToolRowMapper.toToolOption`.
  static SkillOption toSkillOption(
    Map<String, dynamic> row, {
    required Map<String, String> names,
  }) {
    final id = (row['id'] as num).toInt();
    return SkillOption(
      id: id,
      name: names[id.toString()] ?? 'Compétence #$id',
      abilityId: row['ability_id'] as String? ?? '',
    );
  }
}
