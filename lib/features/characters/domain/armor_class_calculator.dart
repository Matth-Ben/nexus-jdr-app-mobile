import '../../character_creation/domain/ability_score_rules.dart';
import 'armor_slot_rules.dart';
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
/// Armures et boucliers personnalisés (P7, `custom_kind` armure/bouclier) : le
/// mapper leur construit des `armorProperties` (voir
/// `custom_armor_properties.dart`), ils suivent donc le même chemin que le
/// catalogue ; en plus, leur bonus magique (`magicBonus`, 0 pour le catalogue)
/// s'ajoute seulement s'ils sont équipés et harmonisés quand l'harmonisation
/// est requise — leur CA de base, elle, compte toujours.
///
/// Plusieurs armures ou plusieurs boucliers équipés (décision n° 37 du
/// 20/11/2026 : l'app empêche désormais de les équiper, voir
/// `armor_slot_rules.dart`, mais une fiche ancienne peut en avoir deux) :
/// toutes les combinaisons « une armure × un bouclier » sont évaluées et la
/// **meilleure CA** est retenue, quel que soit l'ordre de l'inventaire. Un
/// objet non retenu ne donne **rien** : ni sa base, ni son bonus magique, ni
/// son `ac_bonus` (quel que soit son type, `toujours` compris) ; le choix se
/// fait bonus de chaque objet compris. Une seule armure (ou un seul bouclier)
/// équipée est toujours retenue, même si s'en passer donnerait plus (Moine
/// avec bouclier). Reproduction exacte de `private.character_armor_class`
/// (DeepCore, migration `20261120090000`), dont les cas de parité (C1 à C27)
/// sont rejoués par `armor_class_deepcore_parity_test.dart`.
///
/// Non couvert (hors périmètre, "reste un simple affichage", même principe
/// que le statut "mort" qui ne simule pas les règles complètes) : pénalité
/// de vitesse/désavantage Discrétion d'une armure trop lourde pour la Force
/// du personnage ; écarts RAW relevés en D234.
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
    final defenseBonus = fightingStyles.contains(defenseFightingStyle) ? 1 : 0;

    // Objets équipés qui occupent un emplacement d'armure ou de bouclier (même
    // règle que le refus d'équipement, `ArmorSlotRules.slotOf`) : chacun ne
    // compte que dans SA combinaison. Les autres objets équipés (anneau,
    // cape, bracelets, robe, « Armure +N »...) donnent des bonus communs à
    // toutes les combinaisons.
    final armors = <CharacterInventoryItem>[];
    final shields = <CharacterInventoryItem>[];
    var alwaysBonus = 0;
    var withArmorBonus = 0;
    var bareBonus = 0;
    int? magicUnarmoredBase;
    for (final item in inventory) {
      if (!item.equipped) continue;
      switch (ArmorSlotRules.slotOf(item)) {
        case ArmorSlot.armor:
          armors.add(item);
          continue;
        case ArmorSlot.shield:
          shields.add(item);
          continue;
        case null:
          break;
      }
      final bonus = item.acBonus;
      if (bonus == null || !_grantsMagicBonus(item)) continue;
      switch (item.acBonusKind) {
        case 'toujours':
          alwaysBonus += bonus;
        case 'avec_armure':
          withArmorBonus += bonus;
        case 'sans_armure_ni_bouclier':
          bareBonus += bonus;
        case 'base_sans_armure':
          // Plusieurs objets : la plus haute base seule compte (pas de somme).
          if (magicUnarmoredBase == null || bonus > magicUnarmoredBase) {
            magicUnarmoredBase = bonus;
          }
      }
    }

    final bestMagicUnarmoredBase = magicUnarmoredBase;

    // CA de la combinaison `armor` (`null` : sans armure) × `shield` (`null` :
    // sans bouclier).
    int combination(
      CharacterInventoryItem? armor,
      CharacterInventoryItem? shield,
    ) {
      final armorOwnBonus = _ownBonusOf(armor);
      final shieldOwnBonus = _ownBonusOf(shield);
      final int base;
      if (armor != null) {
        final properties = armor.armorProperties!;
        base =
            properties.acBase +
            _dexBonusFor(properties.acDexBonus, dexModifier) +
            defenseBonus;
      } else {
        base = [
          10 + dexModifier,
          if (classNames.contains(barbarianClassName))
            10 + dexModifier + modifier('con'),
          if (classNames.contains(monkClassName) && shield == null)
            10 + dexModifier + modifier('wis'),
          if (subclassNames.contains(draconicSubclassName)) 13 + dexModifier,
          if (bestMagicUnarmoredBase != null)
            bestMagicUnarmoredBase + dexModifier,
          // `ac_bonus` « base sans armure » du bouclier retenu (aucun objet
          // du catalogue aujourd'hui, même règle que DeepCore).
          if (shield?.acBonusKind == 'base_sans_armure' &&
              shieldOwnBonus != null)
            shieldOwnBonus + dexModifier,
        ].reduce((a, b) => a > b ? a : b);
      }
      var total =
          base +
          (shield?.armorProperties!.acBase ?? 0) +
          // Bonus magique d'une armure/d'un bouclier personnalisé (P7) retenu,
          // seulement s'il compte (la base, elle, compte toujours). Toujours
          // 0 pour le catalogue (son bonus passe par `ac_bonus`).
          _magicBonusOf(armor) +
          _magicBonusOf(shield) +
          alwaysBonus;
      if (armor != null) total += withArmorBonus;
      if (armor == null && shield == null) total += bareBonus;
      // `ac_bonus` de l'armure et du bouclier retenus, évalué pour CETTE
      // combinaison (« sans armure ni bouclier » ne s'applique jamais à un
      // objet qui occupe lui-même un emplacement).
      if (armorOwnBonus != null &&
          (armor!.acBonusKind == 'toujours' ||
              armor.acBonusKind == 'avec_armure')) {
        total += armorOwnBonus;
      }
      if (shieldOwnBonus != null &&
          (shield!.acBonusKind == 'toujours' ||
              (shield.acBonusKind == 'avec_armure' && armor != null))) {
        total += shieldOwnBonus;
      }
      return total;
    }

    // Une seule armure (ou un seul bouclier) équipée est toujours retenue :
    // « sans armure » n'est une option que si aucune n'est équipée.
    final armorChoices = armors.isEmpty
        ? const <CharacterInventoryItem?>[null]
        : armors;
    final shieldChoices = shields.isEmpty
        ? const <CharacterInventoryItem?>[null]
        : shields;
    int? best;
    for (final armor in armorChoices) {
      for (final shield in shieldChoices) {
        final ac = combination(armor, shield);
        if (best == null || ac > best) best = ac;
      }
    }
    return best!;
  }

  /// Un objet équipé donne son bonus magique de CA s'il ne requiert pas
  /// d'harmonisation, ou s'il est harmonisé.
  static bool _grantsMagicBonus(CharacterInventoryItem item) =>
      item.equipped && (!item.requiresAttunement || item.isAttuned);

  static int _magicBonusOf(CharacterInventoryItem? item) =>
      item != null && _grantsMagicBonus(item) ? item.magicBonus : 0;

  /// `ac_bonus` propre à un objet d'emplacement retenu, `null` s'il n'en a
  /// pas ou s'il ne compte pas (harmonisation requise et non faite).
  static int? _ownBonusOf(CharacterInventoryItem? item) =>
      item != null && _grantsMagicBonus(item) ? item.acBonus : null;

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
