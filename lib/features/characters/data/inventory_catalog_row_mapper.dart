import '../domain/inventory_catalog_item.dart';

/// Fonctions de mapping pures entre les lignes brutes `items`/`translations`
/// renvoyées par PostgREST et [InventoryCatalogItem] — sheet "Depuis le
/// catalogue" de l'onglet "Inventaire" (`presentation/widgets
/// /add_item_flow.dart`).
///
/// Dédié à cet écran plutôt que réutilisé depuis
/// `character_creation/data/item_row_mapper.dart` (`ItemRowMapper`) : même
/// principe de résolution des noms via `translations`, mais dupliqué pour ne
/// jamais coupler les deux features entre elles — voir le commentaire de
/// classe de `RaceRowMapper` pour le rationale détaillé.
abstract final class InventoryCatalogRowMapper {
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

  /// Extrait le montant de la colonne jsonb `cost` (`{"amount", "currency"}`)
  /// en `double`. `null`/type inattendu ou clé `"amount"` absente retombe
  /// sur `0` plutôt que de crasher — même règle que
  /// `character_creation/data/item_row_mapper.dart::ItemRowMapper
  /// .parseCostAmount` (un objet du catalogue d'ajout a toujours un coût
  /// affichable, contrairement à `CharacterInventoryRowMapper.parseCostAmount`
  /// qui, lui, retombe sur `null`).
  static double parseCostAmount(dynamic raw) {
    if (raw is! Map) return 0;
    final amount = raw['amount'];
    return amount is num ? amount.toDouble() : 0;
  }

  /// Extrait `weight` (colonne `numeric`, en kilogrammes) en `double?` —
  /// `null` si non renseigné en base, jamais `0`.
  static double? parseWeight(dynamic raw) => raw is num ? raw.toDouble() : null;

  /// Construit un [InventoryCatalogItem] à partir d'une ligne brute `items`
  /// et des noms déjà résolus (`names`, clés en `String`, voir
  /// [collectIds]). Un id sans nom résolu retombe sur un libellé générique
  /// ("Objet #12") ; une catégorie manquante/inattendue retombe sur
  /// `'equipement_general'` (catégorie la plus générique du check
  /// `items_category_check`) — même principe que `ItemRowMapper
  /// .toItemOption`.
  static InventoryCatalogItem toInventoryCatalogItem(
    Map<String, dynamic> row, {
    required Map<String, String> names,
  }) {
    final id = (row['id'] as num).toInt();
    return InventoryCatalogItem(
      id: id,
      name: names[id.toString()] ?? 'Objet #$id',
      category: row['category'] as String? ?? 'equipement_general',
      costAmount: parseCostAmount(row['cost']),
      weight: parseWeight(row['weight']),
    );
  }

  static List<InventoryCatalogItem> toInventoryCatalogItems(
    List<Map<String, dynamic>> rows, {
    required Map<String, String> names,
  }) {
    return [
      for (final row in rows) toInventoryCatalogItem(row, names: names),
    ];
  }
}
