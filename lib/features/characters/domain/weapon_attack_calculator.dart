import '../../character_creation/domain/ability_score_rules.dart';
import 'pact_weapon_rules.dart';

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
/// Non couvert (aucune donnée disponible côté catalogue, `items.rarity`
/// toujours vide, vérifié) : bonus d'enchantement d'une arme magique (+1/+2)
/// — uniquement le modificateur de caractéristique standard est calculable
/// aujourd'hui.
abstract final class WeaponAttackCalculator {
  /// Armes courantes (simples) du SRD 5e — noms canoniques français tels que
  /// résolus dans le catalogue réel (voir
  /// `xml_import/domain/aidedd_reference_tables.dart::AideddReferenceTables
  /// .weapons`, ids 2 à 38).
  static const List<String> _simpleWeaponNames = [
    'Bâton',
    'Dague',
    'Gourdin',
    'Hachette',
    'Javeline',
    'Lance',
    'Marteau léger',
    "Masse d'armes",
    'Massue',
    'Serpe',
    'Arbalète légère',
    'Arc court',
    'Fléchette',
    'Fronde',
  ];

  /// Armes de guerre (martiales) du SRD 5e — même rationale que
  /// [_simpleWeaponNames].
  static const List<String> _martialWeaponNames = [
    'Cimeterre',
    'Coutille',
    'Épée à deux mains',
    'Épée courte',
    'Épée longue',
    "Fléau d'armes",
    'Fouet',
    'Hache à deux mains',
    "Hache d'armes",
    'Hallebarde',
    "Lance d'arçon",
    'Maillet',
    'Marteau de guerre',
    'Morgenstern',
    'Pic de guerre',
    'Pique',
    'Rapière',
    'Trident',
    'Arbalète de poing',
    'Arbalète lourde',
    'Arc long',
    'Filet',
    'Sarbacane',
  ];

  /// `true` si le personnage est compétent avec l'arme [weaponName], d'après
  /// [proficiencyTokens] (`CharacterDetail.weaponProficiencyNames` : tokens
  /// de catégorie 'courantes'/'martiales' et/ou noms d'armes spécifiques,
  /// parfois au pluriel, ex. « épées courtes »).
  static bool isProficient({
    required String weaponName,
    required List<String> proficiencyTokens,
  }) {
    final normalizedWeaponName = _singularize(
      PactWeaponRules.normalize(weaponName),
    );

    for (final token in proficiencyTokens) {
      final normalizedToken = PactWeaponRules.normalize(token);
      if (_singularize(normalizedToken) == normalizedWeaponName) return true;

      if (normalizedToken == 'courantes' &&
          _simpleWeaponNames.any(
            (name) =>
                _singularize(PactWeaponRules.normalize(name)) ==
                normalizedWeaponName,
          )) {
        return true;
      }

      if (normalizedToken == 'martiales' &&
          _martialWeaponNames.any(
            (name) =>
                _singularize(PactWeaponRules.normalize(name)) ==
                normalizedWeaponName,
          )) {
        return true;
      }
    }

    return false;
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
  }) {
    final strMod = AbilityScoreRules.abilityModifier(
      abilityScores['str'] ?? 10,
    );
    final dexMod = AbilityScoreRules.abilityModifier(
      abilityScores['dex'] ?? 10,
    );

    return switch (_primaryAbilityKey(weaponProperties)) {
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
    );
    return abilityModifier + (proficient ? proficiencyBonus : 0);
  }

  /// Caractéristique principale d'une arme d'après ses [weaponProperties]
  /// (déjà normalisées via [PactWeaponRules.normalize]) : `'dex'` pour une
  /// arme à distance (propriété commençant par « munitions »), `'best'` pour
  /// une arme de corps à corps « finesse » (le meilleur de Force/Dextérité),
  /// `'str'` sinon (y compris « lancer »/thrown sans « finesse »).
  static String _primaryAbilityKey(List<String> weaponProperties) {
    final normalized = weaponProperties.map(PactWeaponRules.normalize);
    if (normalized.any((property) => property.startsWith('munitions'))) {
      return 'dex';
    }
    if (normalized.contains('finesse')) return 'best';
    return 'str';
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
