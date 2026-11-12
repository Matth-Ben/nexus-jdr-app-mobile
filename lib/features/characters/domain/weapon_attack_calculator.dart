import '../../character_creation/domain/ability_score_rules.dart';
import 'character_inventory_item.dart';
import 'custom_item_enrichment.dart';
import 'pact_weapon_rules.dart';
import 'weapon_proficiency_category_rules.dart';

/// Calcul pur du bonus d'attaque (`+n` ajouté au d20 pour toucher) et du
/// modificateur de dégâts (`+n` ajouté au(x) dé(s) de dégâts) d'une arme —
/// même gabarit que `armor_class_calculator.dart::ArmorClassCalculator`/
/// `weapon_slot_rules.dart::WeaponSlotRules`.
///
/// Règles 5e couvertes :
/// - Attaque = d20 + modificateur de caractéristique + bonus de maîtrise (si
///   le personnage est compétent avec cette arme, voir [isProficient]).
/// - Dégâts = dé(s) de l'arme + le MÊME modificateur de caractéristique,
///   jamais le bonus de maîtrise (voir [abilityModifierFor], réutilisé tel
///   quel par les deux calculs — pas de fonction "damageModifier" séparée).
/// - Caractéristique utilisée (voir [_primaryAbilityKey]) : Dextérité pour
///   une arme à distance (propriété « munitions(...) »), le meilleur de Force
///   et Dextérité pour une arme de corps à corps « finesse », Force pour une
///   arme de corps à corps sans « finesse » (y compris « lancer »/thrown, ex.
///   javeline, hachette).
///
/// Armes personnalisées (P7 PR 2b, [statsFor]) : en plus de ce qui précède,
/// le bonus magique (`custom_magic_bonus`, 0..3) s'ajoute à l'attaque ET aux
/// dégâts (jamais la maîtrise aux dégâts), suspendu si l'objet requiert
/// l'harmonisation sans l'être ; la caractéristique suit `custom_weapon_range`
/// (Force au corps à corps ET quand la portée n'est pas précisée, Dextérité à
/// distance) sauf propriété « munitions » (Dextérité) ou « finesse » (la
/// meilleure des deux) ; la maîtrise se déduit de `custom_weapon_category`
/// seule (jamais du nom, texte libre) et reste **non évaluée** si elle n'est
/// pas renseignée.
///
/// Non couvert (aucune donnée disponible côté catalogue, `items.rarity`
/// toujours vide, vérifié) : bonus d'enchantement d'une arme magique du
/// **catalogue** (+1/+2) — uniquement le modificateur de caractéristique
/// standard est calculable pour elles aujourd'hui.
abstract final class WeaponAttackCalculator {
  /// `true` si le personnage est compétent avec l'arme [weaponName], d'après
  /// [proficiencyTokens] (`CharacterDetail.weaponProficiencyNames` : tokens
  /// de catégorie 'courantes'/'martiales' et/ou noms d'armes spécifiques,
  /// parfois au pluriel, ex. « épées courtes »).
  ///
  /// [weaponProperties] (déjà normalisées via [PactWeaponRules.normalize] en
  /// interne) : toujours compétent sans condition si elles contiennent
  /// « naturelle » (griffes/cornes/sabots..., voir
  /// `character_creation/domain/race_option.dart::RaceOption
  /// .naturalWeaponItemId`) — on est toujours compétent avec ses propres
  /// armes naturelles, indépendamment des maîtrises d'armes réelles du
  /// personnage ([proficiencyTokens]). Vide par défaut : aucun appelant
  /// existant avant l'introduction de ce paramètre n'a besoin de ce
  /// comportement spécial.
  static bool isProficient({
    required String weaponName,
    required List<String> proficiencyTokens,
    List<String> weaponProperties = const <String>[],
  }) {
    if (weaponProperties.any(
      (property) => PactWeaponRules.normalize(property) == 'naturelle',
    )) {
      return true;
    }

    final normalizedWeaponName = _singularize(
      PactWeaponRules.normalize(weaponName),
    );

    for (final token in proficiencyTokens) {
      final normalizedToken = PactWeaponRules.normalize(token);
      if (_singularize(normalizedToken) == normalizedWeaponName) return true;

      // Source de vérité unique de la répartition courantes/martiales :
      // `WeaponProficiencyCategoryRules` (noms exacts du catalogue `items`).
      if (normalizedToken == 'courantes' &&
          WeaponProficiencyCategoryRules.isCommon(weaponName)) {
        return true;
      }

      if (normalizedToken == 'martiales' &&
          WeaponProficiencyCategoryRules.isMartial(weaponName)) {
        return true;
      }
    }

    return false;
  }

  /// Maîtrise d'une arme **personnalisée** d'après sa catégorie
  /// ([weaponCategory] : `courante`/`guerre`, `null` = non renseignée). Mêmes
  /// jetons de catégorie que [isProficient] ('courantes' -> courante,
  /// 'martiales' -> de guerre) ; `unknown` si la catégorie est absente
  /// (jamais devinée). Le nom de l'objet n'est pas comparé (texte libre).
  static WeaponProficiencyStatus customProficiency({
    required String? weaponCategory,
    required List<String> proficiencyTokens,
    List<String> weaponProperties = const <String>[],
  }) {
    if (weaponProperties.any(
      (property) => PactWeaponRules.normalize(property) == 'naturelle',
    )) {
      return WeaponProficiencyStatus.proficient;
    }
    final expectedToken = switch (weaponCategory) {
      CustomWeaponCategories.common => 'courantes',
      CustomWeaponCategories.martial => 'martiales',
      _ => null,
    };
    if (expectedToken == null) return WeaponProficiencyStatus.unknown;
    final proficient = proficiencyTokens.any(
      (token) => PactWeaponRules.normalize(token) == expectedToken,
    );
    return proficient
        ? WeaponProficiencyStatus.proficient
        : WeaponProficiencyStatus.notProficient;
  }

  /// Attaque et dégâts complets de [item] (arme du catalogue ou objet
  /// personnalisé de type arme, voir [CharacterInventoryItem.isWeapon]), ou
  /// `null` si ce n'est pas une arme à dé de dégâts connu. Pour une arme du
  /// catalogue : strictement [attackBonus]/[abilityModifierFor] (aucun bonus
  /// magique, voir la documentation de classe).
  static WeaponAttackStats? statsFor({
    required CharacterInventoryItem item,
    required Map<String, int> abilityScores,
    required List<String> proficiencyTokens,
    required int proficiencyBonus,
  }) {
    final weapon = item.weaponProperties;
    if (!item.isWeapon || weapon?.damageDice == null) return null;
    final properties = weapon!.properties;

    if (!item.isCustom) {
      return WeaponAttackStats(
        attackBonus: attackBonus(
          weaponName: item.name,
          weaponProperties: properties,
          abilityScores: abilityScores,
          proficiencyTokens: proficiencyTokens,
          proficiencyBonus: proficiencyBonus,
        ),
        damageModifier: abilityModifierFor(
          weaponProperties: properties,
          abilityScores: abilityScores,
        ),
        proficiency: WeaponProficiencyStatus.proficient,
      );
    }

    final abilityModifier = abilityModifierFor(
      weaponProperties: properties,
      abilityScores: abilityScores,
      weaponRange: item.customWeaponRange,
    );
    final proficiency = customProficiency(
      weaponCategory: item.customWeaponCategory,
      proficiencyTokens: proficiencyTokens,
      weaponProperties: properties,
    );
    final magic = item.isMagicBonusSuspended ? 0 : item.magicBonus;
    return WeaponAttackStats(
      attackBonus:
          abilityModifier +
          (proficiency == WeaponProficiencyStatus.proficient
              ? proficiencyBonus
              : 0) +
          magic,
      damageModifier: abilityModifier + magic,
      magicBonus: magic,
      magicBonusSuspended: item.isMagicBonusSuspended,
      proficiency: proficiency,
      rangeUnspecified:
          item.customWeaponRange == null &&
          _primaryAbilityKey(properties, null) == 'str',
    );
  }

  /// Modificateur de caractéristique applicable à une arme dont les
  /// propriétés sont [weaponProperties] — voir [_primaryAbilityKey]. Score
  /// par défaut de 10 (modificateur nul) si absent de [abilityScores], même
  /// repli que `ArmorClassCalculator`. Réutilisé tel quel pour le bonus
  /// d'attaque ([attackBonus]) et le modificateur de dégâts (un seul calcul,
  /// pas deux fonctions distinctes).
  static int abilityModifierFor({
    required List<String> weaponProperties,
    required Map<String, int> abilityScores,
    String? weaponRange,
  }) {
    final strMod = AbilityScoreRules.abilityModifier(
      abilityScores['str'] ?? 10,
    );
    final dexMod = AbilityScoreRules.abilityModifier(
      abilityScores['dex'] ?? 10,
    );

    return switch (_primaryAbilityKey(weaponProperties, weaponRange)) {
      'dex' => dexMod,
      'best' => strMod > dexMod ? strMod : dexMod,
      _ => strMod,
    };
  }

  /// Bonus d'attaque complet (`+n` ajouté au d20 pour toucher) : modificateur
  /// de caractéristique ([abilityModifierFor]) plus [proficiencyBonus] si le
  /// personnage est compétent avec cette arme ([isProficient]), sinon le
  /// modificateur seul.
  static int attackBonus({
    required String weaponName,
    required List<String> weaponProperties,
    required Map<String, int> abilityScores,
    required List<String> proficiencyTokens,
    required int proficiencyBonus,
  }) {
    final abilityModifier = abilityModifierFor(
      weaponProperties: weaponProperties,
      abilityScores: abilityScores,
    );
    final proficient = isProficient(
      weaponName: weaponName,
      proficiencyTokens: proficiencyTokens,
      weaponProperties: weaponProperties,
    );
    return abilityModifier + (proficient ? proficiencyBonus : 0);
  }

  /// Caractéristique principale d'une arme d'après ses [weaponProperties]
  /// (déjà normalisées via [PactWeaponRules.normalize]) : `'dex'` pour une
  /// arme à distance (propriété commençant par « munitions »), `'best'` pour
  /// une arme de corps à corps « finesse » (le meilleur de Force/Dextérité),
  /// `'str'` sinon (y compris « lancer »/thrown sans « finesse »).
  ///
  /// [weaponRange] (`custom_weapon_range`, armes personnalisées seulement) ne
  /// départage que le « sinon » : `distance` -> `'dex'`, `melee`/`null` ->
  /// `'str'` (les propriétés restent prioritaires).
  static String _primaryAbilityKey(
    List<String> weaponProperties,
    String? weaponRange,
  ) {
    final normalized = weaponProperties.map(PactWeaponRules.normalize);
    if (normalized.any((property) => property.startsWith('munitions'))) {
      return 'dex';
    }
    if (normalized.contains('finesse')) return 'best';
    return weaponRange == CustomWeaponRanges.ranged ? 'dex' : 'str';
  }

  /// Singularise légèrement une chaîne déjà normalisée ([PactWeaponRules
  /// .normalize]) : retire un 's' final de chaque mot de longueur > 1 — no-op
  /// sur un mot déjà singulier, corrige le cas « épées courtes » (pluriel,
  /// `CharacterDetail.weaponProficiencyNames`) contre « Épée courte »
  /// (catalogue, singulier).
  static String _singularize(String normalized) {
    return normalized
        .split(' ')
        .map(
          (word) => word.length > 1 && word.endsWith('s')
              ? word.substring(0, word.length - 1)
              : word,
        )
        .join(' ');
  }
}

/// Maîtrise d'une arme : [unknown] = catégorie d'une arme personnalisée non
/// renseignée (aucun bonus de maîtrise ajouté, légende « maîtrise non
/// évaluée »).
enum WeaponProficiencyStatus { proficient, notProficient, unknown }

/// Résultat de [WeaponAttackCalculator.statsFor].
class WeaponAttackStats {
  const WeaponAttackStats({
    required this.attackBonus,
    required this.damageModifier,
    this.magicBonus = 0,
    this.magicBonusSuspended = false,
    this.proficiency = WeaponProficiencyStatus.proficient,
    this.rangeUnspecified = false,
  });

  /// Bonus d'attaque complet (caractéristique + maîtrise + bonus magique actif).
  final int attackBonus;

  /// Modificateur de dégâts (caractéristique + bonus magique actif).
  final int damageModifier;

  /// Bonus magique **appliqué** (0 s'il est suspendu).
  final int magicBonus;

  /// Bonus magique présent mais suspendu (harmonisation requise, non faite).
  final bool magicBonusSuspended;

  final WeaponProficiencyStatus proficiency;

  /// Portée d'une arme personnalisée non précisée : Force par défaut.
  final bool rangeUnspecified;
}
