import '../domain/language_option.dart';

/// Fonctions de mapping pures entre les lignes brutes renvoyées par
/// PostgREST (`languages`, `translations`) et [LanguageOption].
///
/// Dédié à l'étape 5/9 (Compétences et outils), même principe dupliqué que
/// `ToolRowMapper` — voir le commentaire de classe de `RaceRowMapper` pour
/// le rationale détaillé de cette duplication systématique.
abstract final class LanguageRowMapper {
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

  /// Construit une [LanguageOption] à partir d'une ligne brute `languages`
  /// et des noms déjà résolus (`names`, clés en `String`, voir
  /// [collectIds]). Un id sans nom résolu retombe sur un libellé générique
  /// ("Langue #12") plutôt que de crasher ou d'afficher `null` ; un type
  /// manquant/inattendu retombe sur `'standard'` (valeur la plus courante en
  /// base, voir
  /// `supabase/migrations/20260825090500_seed_reference_core_data.sql` du
  /// dépôt web).
  static LanguageOption toLanguageOption(
    Map<String, dynamic> row, {
    required Map<String, String> names,
  }) {
    final id = (row['id'] as num).toInt();
    return LanguageOption(
      id: id,
      name: names[id.toString()] ?? 'Langue #$id',
      type: row['type'] as String? ?? 'standard',
    );
  }
}
