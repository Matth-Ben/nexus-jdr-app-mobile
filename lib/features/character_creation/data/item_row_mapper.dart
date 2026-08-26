import '../domain/item_option.dart';

/// Fonctions de mapping pures entre les lignes brutes renvoyées par
/// PostgREST (`items`, `translations`) et [ItemOption].
///
/// Dédié à l'étape 7/9 (Équipement de départ) plutôt que réutilisé depuis
/// `tool_row_mapper.dart`/`spell_row_mapper.dart` : même principe de
/// résolution des noms via `translations` (`entity_id`/`field_name`/
/// `value`), mais dupliqué pour ne jamais coupler les étapes entre elles —
/// voir le commentaire de classe de `RaceRowMapper` pour le rationale
/// détaillé.
abstract final class ItemRowMapper {
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

  /// Extrait le montant de la colonne jsonb `cost` (`{"amount", "currency"}`
  /// — `currency` toujours `"gp"` pour ce MVP, voir `domain/item_option.dart`)
  /// en `double`. `null`/type inattendu ou clé `"amount"` absente retombe sur
  /// `0` plutôt que de crasher.
  static double parseCostAmount(dynamic raw) {
    if (raw is! Map) {
      return 0;
    }
    final amount = raw['amount'];
    return amount is num ? amount.toDouble() : 0;
  }

  /// Construit un [ItemOption] à partir d'une ligne brute `items` et des
  /// noms déjà résolus (`names`, clés en `String`, voir [collectIds]). Un id
  /// sans nom résolu retombe sur un libellé générique ("Objet #12") plutôt
  /// que de crasher ou d'afficher `null` ; une catégorie manquante/inattendue
  /// retombe sur `'equipement_general'` (catégorie la plus générique du
  /// check `items_category_check`) — même principe que
  /// `ToolRowMapper.toToolOption`.
  static ItemOption toItemOption(
    Map<String, dynamic> row, {
    required Map<String, String> names,
  }) {
    final id = (row['id'] as num).toInt();
    return ItemOption(
      id: id,
      name: names[id.toString()] ?? 'Objet #$id',
      category: row['category'] as String? ?? 'equipement_general',
      costAmount: parseCostAmount(row['cost']),
    );
  }
}
