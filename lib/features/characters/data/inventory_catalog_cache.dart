import '../../../core/cache/reference_data_cache.dart';
import 'character_row_mapper.dart';

/// Forme et lecture du cache du catalogue d'objets de l'onglet « Inventaire »
/// (`SupabaseCharacterRepository.fetchInventoryCatalog`, T5b-2/F20), rangé
/// dans [ReferenceDataCache] sous [key].
///
/// Le payload garde les lignes `items` **brutes** (catégorie, poids, coût,
/// rareté, harmonisation, consommable, bonus de CA, propriétés d'arme et
/// d'armure) et les lignes `translations` brutes (noms et descriptions) : c'est
/// exactement ce qu'il faut pour construire, hors ligne, une ligne
/// d'inventaire **complète** (même mapper que pour une ligne du serveur,
/// `CharacterInventoryRowMapper`) pour un objet ajouté hors ligne.
///
/// Donnée de référence publique : jamais purgée à la déconnexion par un
/// cloisonnement par compte (la purge totale de `ReferenceDataCache.clear`
/// la vide comme tout le reste, sans conséquence au-delà d'un re-fetch).
abstract final class InventoryCatalogCache {
  /// Clé unique (le catalogue est le même pour tous les comptes ; la langue de
  /// l'app est fixe, comme pour `item_catalog`).
  static const String key = 'inventory_catalog';

  /// Version du payload : 2 = champs élargis de T5b-2 (rareté, CA, propriétés
  /// d'arme/armure, descriptions). Un payload sans cette clé, ou d'une
  /// version antérieure, n'est jamais considéré frais ([isCurrent]) : refetch
  /// si l'appareil est en ligne, repli tolérant (objets partiels) sinon.
  static const int payloadVersion = 2;

  static Map<String, dynamic> buildPayload({
    required List<Map<String, dynamic>> itemRows,
    required List<Map<String, dynamic>> nameRows,
    required List<Map<String, dynamic>> descriptionRows,
  }) => {
    'version': payloadVersion,
    'items': itemRows,
    'itemNames': nameRows,
    'itemDescriptions': descriptionRows,
  };

  /// `true` si [payload] est au format courant.
  static bool isCurrent(Object? payload) =>
      payload is Map && payload['version'] == payloadVersion;

  /// Lit le catalogue en cache, quel que soit son âge ; `null` si absent ou
  /// illisible. Jamais d'exception (best-effort : un cache corrompu est un
  /// cache absent).
  static Future<InventoryCatalogSnapshot?> read(
    ReferenceDataCache cache,
  ) async {
    try {
      return InventoryCatalogSnapshot.fromPayload(await cache.get(key));
    } catch (_) {
      return null;
    }
  }
}

/// Catalogue décodé du cache : lignes `items` par identifiant, noms et
/// descriptions résolus.
class InventoryCatalogSnapshot {
  const InventoryCatalogSnapshot({
    required this.itemRows,
    required this.names,
    required this.descriptions,
  });

  /// Décode [payload] ; `null` si ce n'est pas une map. Tolérant : une clé
  /// absente (cache d'une version antérieure) donne des collections vides, une
  /// ligne sans `id` entier est ignorée.
  static InventoryCatalogSnapshot? fromPayload(Object? payload) {
    if (payload is! Map) return null;
    final rows = <int, Map<String, dynamic>>{};
    final rawItems = payload['items'];
    if (rawItems is List) {
      for (final entry in rawItems) {
        if (entry is! Map) continue;
        final row = Map<String, dynamic>.from(entry);
        final id = row['id'];
        if (id is num) rows[id.toInt()] = row;
      }
    }
    return InventoryCatalogSnapshot(
      itemRows: rows,
      names: _translations(payload['itemNames']),
      descriptions: _translations(payload['itemDescriptions']),
    );
  }

  static Map<String, String> _translations(Object? raw) {
    if (raw is! List) return const {};
    return CharacterRowMapper.parseTranslatedNames([
      for (final entry in raw)
        if (entry is Map) Map<String, dynamic>.from(entry),
    ]);
  }

  /// Lignes `items` brutes, par `items.id`.
  final Map<int, Map<String, dynamic>> itemRows;

  /// Noms et descriptions, clés = `items.id` en chaîne.
  final Map<String, String> names;
  final Map<String, String> descriptions;
}
