import 'armor_class_calculator.dart';
import 'character_inventory_item.dart';

/// Point d'entrée unique de la Classe d'Armure « finale » (calcul RAW +
/// ajustement manuel `characters.armor_class_bonus`) pour tout appelant qui
/// dispose déjà de données typées : `CharacterDetail.armorClass` (fiche),
/// et, via `data/armor_class_row_resolver.dart` (lignes PostgREST brutes),
/// `GroupMemberRowMapper` (onglet « Membres ») et la liste des personnages
/// (P18). Une seule implémentation du passage
/// « noms de classe / sous-classe / styles de combat → [ArmorClassCalculator] »,
/// jamais recopiée.
abstract final class ArmorClassResolver {
  /// [bonus] : ajustement manuel (0 par défaut). La fiche l'affiche à part
  /// (`CharacterDetail.armorClass` n'inclut pas le bonus), le groupe et la
  /// liste affichent `calcul + bonus`.
  static int resolve({
    required Map<String, int> abilityScores,
    required List<CharacterInventoryItem> inventory,
    required Set<String> classNames,
    required Set<String> subclassNames,
    required Set<String> fightingStyles,
    int bonus = 0,
  }) {
    return ArmorClassCalculator.compute(
          abilityScores: abilityScores,
          inventory: inventory,
          classNames: classNames,
          subclassNames: subclassNames,
          fightingStyles: fightingStyles,
        ) +
        bonus;
  }
}
