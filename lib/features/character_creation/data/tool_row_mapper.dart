import '../domain/tool_option.dart';

/// Fonctions de mapping pures entre les lignes brutes renvoyées par
/// PostgREST (`tools`, `translations`) et [ToolOption].
///
/// Dédié à l'étape 5/9 (Compétences et outils) plutôt que réutilisé depuis
/// `class_row_mapper.dart`/`background_row_mapper.dart` : même principe de
/// résolution des noms via `translations` (colonnes réelles `entity_id`/
/// `field_name`/`value`, PAS de colonne `name` directement sur `tools`),
/// mais dupliqué pour ne jamais coupler les étapes entre elles — voir le
/// commentaire de classe de `RaceRowMapper` pour le rationale détaillé.
abstract final class ToolRowMapper {
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

  /// Construit un [ToolOption] à partir d'une ligne brute `tools` et des
  /// noms déjà résolus (`names`, clés en `String`, voir [collectIds]). Un id
  /// sans nom résolu retombe sur un libellé générique ("Outil #12") plutôt
  /// que de crasher ou d'afficher `null` ; une catégorie manquante/inattendue
  /// retombe sur `'autre'` (catégorie fourre-tout déjà présente en base pour
  /// les outils qui ne rentrent dans aucune des trois autres, voir
  /// `supabase/migrations/20260825090500_seed_reference_core_data.sql` du
  /// dépôt web).
  static ToolOption toToolOption(
    Map<String, dynamic> row, {
    required Map<String, String> names,
  }) {
    final id = (row['id'] as num).toInt();
    return ToolOption(
      id: id,
      name: names[id.toString()] ?? 'Outil #$id',
      category: row['category'] as String? ?? 'autre',
    );
  }
}
