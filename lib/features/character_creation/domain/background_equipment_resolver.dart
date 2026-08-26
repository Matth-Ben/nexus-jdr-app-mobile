import 'background_equipment_entry.dart';
import 'item_catalog.dart';

/// Résout chaque chaîne de texte libre de `backgrounds.equipment` (déjà
/// débarrassée de sa ligne "Bourse (N po)", voir
/// `domain/background_equipment_parser.dart`) vers un [ItemOption] du
/// catalogue `items`, par correspondance exacte de nom traduit (FR).
///
/// Beaucoup de chaînes ne correspondent à aucun `items.name` peuplé (ex.
/// "Habits communs" — l'objet réellement peuplé s'appelle "Vêtements
/// communs" : décision du chef de projet, voir la consigne d'origine) —
/// [resolve] ne fait alors jamais échouer le mapping,
/// il produit une [BackgroundEquipmentEntry] avec `itemId`/`category` `null`
/// et `name` = la chaîne brute, rendue à l'identique d'un objet résolu par
/// `presentation/equipment_step_screen.dart`.
abstract final class BackgroundEquipmentResolver {
  static List<BackgroundEquipmentEntry> resolve({
    required List<String> equipmentLines,
    required ItemCatalog catalog,
  }) {
    final itemByName = {for (final item in catalog.items) item.name: item};

    return equipmentLines.map((line) {
      final match = itemByName[line];
      if (match == null) {
        return BackgroundEquipmentEntry(name: line);
      }
      return BackgroundEquipmentEntry(
        itemId: match.id,
        name: match.name,
        category: match.category,
      );
    }).toList();
  }
}
