import '../domain/spell_option.dart';

/// Fonctions de mapping pures entre les lignes brutes renvoyées par
/// PostgREST (`spells`, `spell_classes`, `translations`) et [SpellOption].
///
/// Dédié à l'étape 6/9 (Sorts) plutôt que réutilisé depuis
/// `tool_row_mapper.dart` : même principe de résolution des noms via
/// `translations` (`entity_id`/`field_name`/`value`), mais dupliqué pour ne
/// jamais coupler les étapes entre elles — voir le commentaire de classe de
/// `RaceRowMapper` pour le rationale détaillé.
abstract final class SpellRowMapper {
  /// Identifiants de sorts (`spell_classes.spell_id`) à conserver pour une
  /// classe donnée, dédupliqués. Distinct de [collectIds] : celui-ci lit une
  /// colonne `int` brute pour interroger `spells.id` ensuite (`.inFilter`),
  /// [collectIds] normalise en `String` pour interroger `translations
  /// .entity_id`.
  static Set<int> collectSpellIds(List<Map<String, dynamic>> spellClassRows) {
    final ids = <int>{};
    for (final row in spellClassRows) {
      final spellId = row['spell_id'];
      if (spellId is num) {
        ids.add(spellId.toInt());
      }
    }
    return ids;
  }

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
  /// `entity_id`/`value`) en `{entity_id: value}`. Une ligne sans
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

  /// Construit un [SpellOption] à partir d'une ligne brute `spells` et des
  /// noms déjà résolus (`names`, clés en `String`, voir [collectIds]). Un id
  /// sans nom résolu retombe sur un libellé générique ("Sort #12") plutôt
  /// que de crasher ou d'afficher `null` — même principe que
  /// `ToolRowMapper.toToolOption`.
  static SpellOption toSpellOption(
    Map<String, dynamic> row, {
    required Map<String, String> names,
  }) {
    final id = (row['id'] as num).toInt();
    return SpellOption(
      id: id,
      name: names[id.toString()] ?? 'Sort #$id',
      level: (row['level'] as num?)?.toInt() ?? 0,
      school: row['school'] as String? ?? '',
      castingTime: row['casting_time'] as String? ?? '',
    );
  }
}
