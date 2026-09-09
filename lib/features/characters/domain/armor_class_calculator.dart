import '../../character_creation/domain/ability_score_rules.dart';
import 'character_inventory_item.dart';

/// Calcul pur de la Classe d'Armure (CA), affichée sur l'onglet "Personnage"
/// (`presentation/widgets/character_stat_pills_row.dart`) — voir
/// `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md` section "Onglet
/// Personnage" : "Vitesse de déplacement et Classe d'Armure affichées
/// clairement sur cet onglet".
///
/// Jamais stockée en base : entièrement dérivée de [CharacterInventoryItem]
/// équipés + du modificateur de Dextérité, à la volée à chaque affichage —
/// aucune colonne `characters.armor_class` n'existe ni n'est nécessaire.
///
/// Réutilise `AbilityScoreRules.abilityModifier` tel quel, même exception
/// documentée que `saving_throw_calculator.dart`/`skill_bonus_calculator.dart`
/// (utilitaire pur sans état propre à l'assistant de création).
///
/// Règles 5e couvertes (voir le commentaire de seed
/// `20260825091000_seed_items_equipment.sql` côté dépôt web pour le
/// rationale de stockage du bouclier) :
/// - Sans armure équipée : `10 + modificateur de Dextérité` (illimité).
/// - Avec une armure de catégorie 'armure' équipée : `armor_properties
///   .ac_base` de cette armure, plus le modificateur de Dextérité selon
///   `ac_dex_bonus` ('aucun' = +0, 'max_2' = plafonné à +2, 'illimite' =
///   sans plafond).
/// - Un bouclier (catégorie 'bouclier') équipé ajoute son `ac_base` (+2 en
///   pratique) en plus, jamais affecté par le Dex — un bouclier ne
///   remplace jamais la base, il s'additionne toujours.
///
/// Non couvert (hors périmètre de cette tâche, "reste un simple affichage",
/// même principe que le statut "mort" qui ne simule pas les règles
/// complètes) : pénalité de vitesse/désavantage Discrétion d'une armure trop
/// lourde pour la Force du personnage, objets magiques modifiant la CA en
/// dehors d'`armor_properties`, plusieurs armures/boucliers équipés
/// simultanément (donnée incohérente, seul le premier trouvé de chaque
/// catégorie compte).
abstract final class ArmorClassCalculator {
  static int compute({
    required Map<String, int> abilityScores,
    required List<CharacterInventoryItem> inventory,
  }) {
    final dexModifier = AbilityScoreRules.abilityModifier(
      abilityScores['dex'] ?? 10,
    );

    final equippedArmor = _firstEquippedWithArmorProperties(
      inventory,
      category: 'armure',
    );
    final baseAc = equippedArmor == null
        ? 10 + dexModifier
        : equippedArmor.acBase + _dexBonusFor(equippedArmor.acDexBonus, dexModifier);

    final equippedShield = _firstEquippedWithArmorProperties(
      inventory,
      category: 'bouclier',
    );
    final shieldBonus = equippedShield?.acBase ?? 0;

    return baseAc + shieldBonus;
  }

  static CharacterInventoryArmorProperties? _firstEquippedWithArmorProperties(
    List<CharacterInventoryItem> inventory, {
    required String category,
  }) {
    for (final item in inventory) {
      if (item.equipped &&
          item.category == category &&
          item.armorProperties != null) {
        return item.armorProperties;
      }
    }
    return null;
  }

  static int _dexBonusFor(String acDexBonus, int dexModifier) => switch (
    acDexBonus
  ) {
    'aucun' => 0,
    'max_2' => dexModifier > 2 ? 2 : dexModifier,
    'illimite' => dexModifier,
    // Ne devrait pas arriver (valeur contrainte côté base) — traité comme
    // 'aucun' plutôt que de crasher sur une donnée inattendue.
    _ => 0,
  };
}
