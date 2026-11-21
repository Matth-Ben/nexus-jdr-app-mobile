import 'character_failure.dart';
import 'character_inventory_item.dart';

/// Emplacement d'armure occupé par un objet équipé : une armure ou un
/// bouclier, jamais deux de chaque (décision n° 37 du 20/11/2026,
/// `docs/api-refonte/00-decisions-et-vision.md`).
enum ArmorSlot {
  armor('armure'),
  shield('bouclier');

  const ArmorSlot(this.value);

  /// Valeur de `armor_properties.slot` (ou de `items.category`).
  final String value;
}

/// Règle unique « cet objet est une armure / un bouclier », partagée par le
/// calcul de CA (`ArmorClassCalculator`) et le refus d'équiper une seconde
/// armure ou un second bouclier (décision n° 37) : les deux lisent
/// **exactement** le même emplacement, comme `private.character_armor_class`
/// côté DeepCore.
///
/// - Emplacement = `armor_properties.slot`, à défaut `items.category`.
/// - L'objet doit porter des propriétés d'armure. Pour un objet personnalisé,
///   le mapper ne les construit que si `custom_ac_base` est renseigné avec
///   `custom_kind = 'bouclier'`, ou `'armure'` et une catégorie `legere`,
///   `intermediaire` ou `lourde` (voir `custom_armor_properties.dart`) : la
///   même règle s'applique donc au catalogue et aux objets personnalisés.
abstract final class ArmorSlotRules {
  /// Emplacement de [item], `null` s'il n'est ni une armure ni un bouclier
  /// (anneau, cape, « Armure +N » sans propriétés d'armure...). L'état
  /// équipé n'est pas lu.
  static ArmorSlot? slotOf(CharacterInventoryItem item) {
    final properties = item.armorProperties;
    if (properties == null) return null;
    return switch (properties.slot ?? item.category) {
      'armure' => ArmorSlot.armor,
      'bouclier' => ArmorSlot.shield,
      _ => null,
    };
  }

  /// Objet **équipé**, autre que [candidate], qui occupe déjà l'emplacement
  /// de [candidate] dans [inventory] (le premier dans l'ordre de la liste),
  /// `null` si l'emplacement est libre ou si [candidate] n'est ni une armure
  /// ni un bouclier.
  static CharacterInventoryItem? occupantFor({
    required List<CharacterInventoryItem> inventory,
    required CharacterInventoryItem candidate,
  }) {
    final slot = slotOf(candidate);
    if (slot == null) return null;
    for (final item in inventory) {
      if (item.id != candidate.id && item.equipped && slotOf(item) == slot) {
        return item;
      }
    }
    return null;
  }

  /// Refus d'équiper la ligne [inventoryId] de [inventory] (décision n° 37) :
  /// [CharacterFailure] de code [CharacterErrorCode.armorAlreadyEquipped] ou
  /// [CharacterErrorCode.shieldAlreadyEquipped] si une autre armure / un
  /// autre bouclier est déjà équipé, `null` si l'équipement est permis
  /// (emplacement libre, objet qui n'est ni armure ni bouclier, ou ligne
  /// absente de [inventory]). Une armure et un bouclier ensemble restent
  /// permis.
  static CharacterFailure? equipConflict({
    required List<CharacterInventoryItem> inventory,
    required String inventoryId,
  }) {
    CharacterInventoryItem? candidate;
    for (final item in inventory) {
      if (item.id == inventoryId) {
        candidate = item;
        break;
      }
    }
    if (candidate == null) return null;
    if (occupantFor(inventory: inventory, candidate: candidate) == null) {
      return null;
    }
    return switch (slotOf(candidate)!) {
      ArmorSlot.armor => const CharacterFailure(
        'Vous portez déjà une armure : déséquipez-la d\'abord pour en '
        'équiper une autre.',
        code: CharacterErrorCode.armorAlreadyEquipped,
      ),
      ArmorSlot.shield => const CharacterFailure(
        'Vous portez déjà un bouclier : déséquipez-le d\'abord pour en '
        'équiper un autre.',
        code: CharacterErrorCode.shieldAlreadyEquipped,
      ),
    };
  }
}
