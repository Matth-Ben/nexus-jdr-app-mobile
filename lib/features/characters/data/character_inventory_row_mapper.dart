import '../domain/character_inventory_item.dart';

/// Fonctions de mapping pures entre les lignes brutes `character_inventory`
/// (avec `items` embarqué via une vraie relation de clé étrangère,
/// contrairement à `translations`) renvoyées par PostgREST et
/// [CharacterInventoryItem], pour l'onglet "Inventaire".
///
/// Dédié à cet onglet plutôt que réutilisé depuis
/// `character_creation/data/item_row_mapper.dart` (`ItemRowMapper`) : même
/// principe de résolution du nom via `translations`, mais un besoin
/// différent (ligne d'inventaire = jointure `character_inventory` + `items`
/// avec quantité/équipé/poids, pas un simple catalogue de choix) — voir le
/// commentaire de classe de `RaceRowMapper`
/// (`character_creation/data/race_row_mapper.dart`) pour le rationale
/// détaillé de cette duplication systématique dans ce dépôt.
abstract final class CharacterInventoryRowMapper {
  static List<Map<String, dynamic>> rowsOf(Map<String, dynamic> row) {
    final raw = row['character_inventory'] as List<dynamic>?;
    return raw?.cast<Map<String, dynamic>>() ?? const [];
  }

  /// Identifiants (`item_id`) à résoudre via `translations`
  /// (`entity_type = 'item'`), normalisés en `String` — une ligne d'objet
  /// personnalisé (`item_id` nul) n'a rien à résoudre et est donc ignorée.
  static Set<String> collectItemIds(List<Map<String, dynamic>> rows) {
    final ids = <String>{};
    for (final row in rows) {
      final itemId = row['item_id'];
      if (itemId != null) {
        ids.add(itemId.toString());
      }
    }
    return ids;
  }

  /// Extrait `items.weight` (colonne `numeric`, en kilogrammes — voir
  /// `domain/character_inventory_item.dart::totalWeight`) de la relation
  /// `items` embarquée sous une ligne `character_inventory`. `null`/type
  /// inattendu retombe sur `null` plutôt que sur `0`, pour distinguer "poids
  /// réellement nul" (ne devrait pas arriver côté contenu peuplé) de "poids
  /// inconnu" en aval (voir [InventoryWeightCalculator]).
  static double? parseUnitWeight(Map<String, dynamic>? itemRow) {
    final weight = itemRow?['weight'];
    return weight is num ? weight.toDouble() : null;
  }

  /// Construit les [CharacterInventoryItem] à partir des lignes brutes
  /// `character_inventory` (avec `items(category, weight)` embarqué) et des
  /// noms déjà résolus (`names`, voir [collectItemIds]). Une ligne sans `id`
  /// exploitable (ne devrait pas arriver, `character_inventory.id` est la
  /// clé primaire) est ignorée plutôt que de faire échouer tout le mapping.
  ///
  /// Un `item_id` non nul sans traduction résolue retombe sur un libellé
  /// générique ("Objet #12"), même règle que les autres mappers de ce
  /// dépôt ; un objet personnalisé (`item_id` nul) affiche `custom_name`, ou
  /// à défaut un libellé générique neutre ("Objet personnalisé" — ne
  /// devrait normalement pas arriver, contrainte
  /// `character_inventory_item_or_custom` côté base garantissant l'un des
  /// deux).
  static List<CharacterInventoryItem> toCharacterInventoryItems(
    List<Map<String, dynamic>> rows, {
    required Map<String, String> names,
  }) {
    final result = <CharacterInventoryItem>[];
    for (final row in rows) {
      final id = row['id'] as String?;
      if (id == null) continue;

      final rawItemId = row['item_id'];
      final itemId = rawItemId is num ? rawItemId.toInt() : null;
      final quantity = (row['quantity'] as num?)?.toInt() ?? 1;
      final itemRow = row['items'] as Map<String, dynamic>?;
      final unitWeight = parseUnitWeight(itemRow);

      final String name;
      if (itemId != null) {
        name = names[itemId.toString()] ?? 'Objet #$itemId';
      } else {
        name = (row['custom_name'] as String?) ?? 'Objet personnalisé';
      }

      // `quantity` <= 0 -> poids de ligne inconnu (`null`), pas `0`/négatif :
      // `character_inventory.quantity` n'a aucune contrainte `CHECK` côté
      // base (vérifié contre le schéma réel), une valeur à 0 ou négative
      // n'est donc pas à exclure défensivement. Sans ce garde-fou, une
      // quantité négative produirait un `totalWeight` négatif qui fausserait
      // silencieusement `InventoryWeightCalculator.totalOf`, et une
      // quantité à 0 afficherait "0 kg" sur la carte malgré la règle
      // documentée sur `CharacterInventoryItem.totalWeight` ("rien n'est
      // affiché plutôt qu'un poids trompeur").
      final hasKnownWeight = unitWeight != null && quantity > 0;

      result.add(
        CharacterInventoryItem(
          id: id,
          itemId: itemId,
          name: name,
          category: itemRow?['category'] as String?,
          quantity: quantity,
          equipped: row['equipped'] == true,
          totalWeight: hasKnownWeight ? unitWeight * quantity : null,
        ),
      );
    }
    return result;
  }
}
