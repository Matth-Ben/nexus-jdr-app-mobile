import '../../character_creation/domain/ability_score_rules.dart';
import 'character_inventory_item.dart';

/// Calcul pur de la Classe d'Armure (CA), affichée sur l'onglet "Personnage"
/// (`presentation/widgets/character_stat_pills_row.dart`) — voir
/// `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md` section "Onglet
/// Personnage" : "Vitesse de déplacement et Classe d'Armure affichées
/// clairement sur cet onglet".
///
/// Jamais stockée en base : entièrement dérivée de [CharacterInventoryItem]
/// équipés, des caractéristiques et des aptitudes de classe, à la volée à
/// chaque affichage — aucune colonne `characters.armor_class` n'existe ni
/// n'est nécessaire.
///
/// Réutilise `AbilityScoreRules.abilityModifier` tel quel, même exception
/// documentée que `saving_throw_calculator.dart`/`skill_bonus_calculator.dart`
/// (utilitaire pur sans état propre à l'assistant de création).
///
/// Règles 5e couvertes (voir le commentaire de seed
/// `20260825091000_seed_items_equipment.sql` côté dépôt web pour le
/// rationale de stockage du bouclier) :
/// - Avec une armure de catégorie 'armure' équipée : `armor_properties
///   .ac_base` de cette armure, plus le modificateur de Dextérité selon
///   `ac_dex_bonus` ('aucun' = +0, 'max_2' = plafonné à +2, 'illimite' =
///   sans plafond), +1 avec le style de combat Défense.
/// - Sans armure équipée, la meilleure des bases disponibles :
///   - `10 + Dex` (tout personnage) ;
///   - Défense sans armure du Barbare : `10 + Dex + Con` (bouclier permis) ;
///   - Défense sans armure du Moine : `10 + Dex + Sag`, seulement sans
///     bouclier ;
///   - Résilience draconique (Ensorceleur, Lignage draconique) : `13 + Dex`.
/// - Un bouclier (catégorie 'bouclier') équipé ajoute son `ac_base` (+2 en
///   pratique) en plus, jamais affecté par le Dex — un bouclier ne
///   remplace jamais la base, il s'additionne toujours.
///
/// Objets magiques :
/// - armures et boucliers magiques de type fixe : leurs `armor_properties`
///   portent un `slot` ('armure'/'bouclier'), leur catégorie restant
///   `objet_magique` ;
/// - `items.ac_bonus` selon `ac_bonus_kind` : 'toujours' (Anneau/Cape de
///   protection, bonus magique d'une armure à harmonisation), 'avec_armure'
///   (Armure +N, s'ajoute à l'armure portée), 'sans_armure_ni_bouclier'
///   (Bracelets de défense), 'base_sans_armure' (Robe de l'archimage : base
///   `bonus + Dex` sans armure). Un objet équipé qui requiert une
///   harmonisation ne donne ce bonus que s'il est harmonisé.
///
/// Non couvert (hors périmètre, "reste un simple affichage", même principe
/// que le statut "mort" qui ne simule pas les règles complètes) : pénalité
/// de vitesse/désavantage Discrétion d'une armure trop lourde pour la Force
/// du personnage, plusieurs armures/boucliers équipés simultanément (donnée
/// incohérente, seul le premier trouvé de chaque emplacement compte).
abstract final class ArmorClassCalculator {
  /// Noms de classe (FR, `translations`) portant la Défense sans armure.
  static const String barbarianClassName = 'Barbare';
  static const String monkClassName = 'Moine';

  /// Nom de sous-classe (FR) de l'Ensorceleur portant la Résilience
  /// draconique (niveau 1 de la sous-classe).
  static const String draconicSubclassName = 'Lignage draconique';

  /// Libellé du style de combat Défense (`character_class_options
  /// .chosen_value`, voir `domain/level_up_choice_options.dart`).
  static const String defenseFightingStyle = 'Défense';

  static int compute({
    required Map<String, int> abilityScores,
    required List<CharacterInventoryItem> inventory,
    Set<String> classNames = const {},
    Set<String> subclassNames = const {},
    Set<String> fightingStyles = const {},
  }) {
    int modifier(String key) =>
        AbilityScoreRules.abilityModifier(abilityScores[key] ?? 10);
    final dexModifier = modifier('dex');

    final equippedArmor = _firstEquippedWithArmorProperties(
      inventory,
      slot: 'armure',
    );
    final equippedShield = _firstEquippedWithArmorProperties(
      inventory,
      slot: 'bouclier',
    );
    final shieldBonus = equippedShield?.acBase ?? 0;

    // Bonus des objets magiques équipés (et harmonisés si nécessaire).
    var itemBonus = 0;
    final magicUnarmoredBases = <int>[];
    for (final item in inventory) {
      final bonus = item.acBonus;
      if (bonus == null || !_grantsMagicBonus(item)) continue;
      switch (item.acBonusKind) {
        case 'toujours':
          itemBonus += bonus;
        case 'avec_armure' when equippedArmor != null:
          itemBonus += bonus;
        case 'sans_armure_ni_bouclier'
            when equippedArmor == null && equippedShield == null:
          itemBonus += bonus;
        case 'base_sans_armure' when equippedArmor == null:
          magicUnarmoredBases.add(bonus + dexModifier);
      }
    }

    if (equippedArmor != null) {
      final defenseBonus = fightingStyles.contains(defenseFightingStyle)
          ? 1
          : 0;
      return equippedArmor.acBase +
          _dexBonusFor(equippedArmor.acDexBonus, dexModifier) +
          defenseBonus +
          shieldBonus +
          itemBonus;
    }

    final unarmoredBases = [
      10 + dexModifier,
      if (classNames.contains(barbarianClassName))
        10 + dexModifier + modifier('con'),
      if (classNames.contains(monkClassName) && equippedShield == null)
        10 + dexModifier + modifier('wis'),
      if (subclassNames.contains(draconicSubclassName)) 13 + dexModifier,
      ...magicUnarmoredBases,
    ];
    final bestBase = unarmoredBases.reduce((a, b) => a > b ? a : b);
    return bestBase + shieldBonus + itemBonus;
  }

  /// Emplacement d'armure d'un objet : `armor_properties.slot` pour un objet
  /// magique, sinon sa catégorie ('armure'/'bouclier').
  static String? _slotOf(CharacterInventoryItem item) =>
      item.armorProperties?.slot ?? item.category;

  /// Un objet équipé donne son bonus magique de CA s'il ne requiert pas
  /// d'harmonisation, ou s'il est harmonisé.
  static bool _grantsMagicBonus(CharacterInventoryItem item) =>
      item.equipped && (!item.requiresAttunement || item.isAttuned);

  static CharacterInventoryArmorProperties? _firstEquippedWithArmorProperties(
    List<CharacterInventoryItem> inventory, {
    required String slot,
  }) {
    for (final item in inventory) {
      if (item.equipped &&
          item.armorProperties != null &&
          _slotOf(item) == slot) {
        return item.armorProperties;
      }
    }
    return null;
  }

  static int _dexBonusFor(String acDexBonus, int dexModifier) =>
      switch (acDexBonus) {
        'aucun' => 0,
        'max_2' => dexModifier > 2 ? 2 : dexModifier,
        'illimite' => dexModifier,
        // Ne devrait pas arriver (valeur contrainte côté base) — traité comme
        // 'aucun' plutôt que de crasher sur une donnée inattendue.
        _ => 0,
      };
}
