// Tests unitaires du calcul pur du bonus d'attaque/modificateur de dégâts
// d'une arme (`domain/weapon_attack_calculator.dart`).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/weapon_attack_calculator.dart';

void main() {
  group('isProficient', () {
    test('token de catégorie "courantes" avec une arme simple -> true', () {
      expect(
        WeaponAttackCalculator.isProficient(
          weaponName: 'Dague',
          proficiencyTokens: ['courantes'],
        ),
        isTrue,
      );
    });

    test('token de catégorie "martiales" avec une arme martiale -> true', () {
      expect(
        WeaponAttackCalculator.isProficient(
          weaponName: 'Épée longue',
          proficiencyTokens: ['martiales'],
        ),
        isTrue,
      );
    });

    test('token "courantes" avec une arme martiale -> false', () {
      expect(
        WeaponAttackCalculator.isProficient(
          weaponName: 'Épée longue',
          proficiencyTokens: ['courantes'],
        ),
        isFalse,
      );
    });

    test('nom spécifique exact ("dague") -> true', () {
      expect(
        WeaponAttackCalculator.isProficient(
          weaponName: 'Dague',
          proficiencyTokens: ['dague'],
        ),
        isTrue,
      );
    });

    test('nom spécifique au pluriel ("épées courtes") contre l\'arme catalogue '
        '"Épée courte" -> true (singularisation)', () {
      expect(
        WeaponAttackCalculator.isProficient(
          weaponName: 'Épée courte',
          proficiencyTokens: ['épées courtes'],
        ),
        isTrue,
      );
    });

    test('aucun token pertinent -> false', () {
      expect(
        WeaponAttackCalculator.isProficient(
          weaponName: 'Épée longue',
          proficiencyTokens: ['dague', 'courantes'],
        ),
        isFalse,
      );
    });

    test('liste de tokens vide -> false', () {
      expect(
        WeaponAttackCalculator.isProficient(
          weaponName: 'Dague',
          proficiencyTokens: [],
        ),
        isFalse,
      );
    });

    test('weaponProperties contient "naturelle" -> toujours true, même sans '
        'aucun token de maîtrise pertinent (griffes/cornes/sabots...)', () {
      expect(
        WeaponAttackCalculator.isProficient(
          weaponName: 'Griffes félines',
          proficiencyTokens: const [],
          weaponProperties: const ['à deux mains', 'naturelle'],
        ),
        isTrue,
      );
    });

    test('weaponProperties contient "naturelle" malgré des tokens de '
        'maîtrise sans rapport -> reste true', () {
      expect(
        WeaponAttackCalculator.isProficient(
          weaponName: 'Cornes',
          proficiencyTokens: const ['dague'],
          weaponProperties: const ['à deux mains', 'naturelle'],
        ),
        isTrue,
      );
    });

    test('une arme normale (sans "naturelle") suit la vérification de '
        'maîtrise habituelle, inchangée', () {
      expect(
        WeaponAttackCalculator.isProficient(
          weaponName: 'Épée longue',
          proficiencyTokens: const ['courantes'],
          weaponProperties: const ['lourde', 'à deux mains'],
        ),
        isFalse,
      );
    });
  });

  group('abilityModifierFor', () {
    test(
      'arme à distance (munitions) -> Dextérité même si Force plus élevée',
      () {
        final modifier = WeaponAttackCalculator.abilityModifierFor(
          weaponProperties: const ['munitions(24/96)'],
          abilityScores: const {'str': 18, 'dex': 12},
        );
        expect(modifier, 1); // Dex 12 -> +1 (pas Force 18 -> +4).
      },
    );

    test(
      'arme corps à corps "finesse" -> meilleur des deux (Force > Dext)',
      () {
        final modifier = WeaponAttackCalculator.abilityModifierFor(
          weaponProperties: const ['finesse'],
          abilityScores: const {'str': 16, 'dex': 12},
        );
        expect(modifier, 3); // Force 16 -> +3, supérieur à Dext 12 -> +1.
      },
    );

    test(
      'arme corps à corps "finesse" -> meilleur des deux (Dext > Force)',
      () {
        final modifier = WeaponAttackCalculator.abilityModifierFor(
          weaponProperties: const ['finesse'],
          abilityScores: const {'str': 10, 'dex': 18},
        );
        expect(modifier, 4); // Dext 18 -> +4, supérieur à Force 10 -> +0.
      },
    );

    test('arme corps à corps sans "finesse" (même avec "lancer") -> Force '
        'uniquement', () {
      final modifier = WeaponAttackCalculator.abilityModifierFor(
        weaponProperties: const ['lancer', 'légère'],
        abilityScores: const {'str': 8, 'dex': 18},
      );
      expect(modifier, -1); // Force 8 -> -1, jamais Dext malgré "lancer".
    });

    test(
      'caractéristique absente de la map -> repli sur 10 (modificateur 0)',
      () {
        final modifier = WeaponAttackCalculator.abilityModifierFor(
          weaponProperties: const [],
          abilityScores: const {},
        );
        expect(modifier, 0);
      },
    );
  });

  group('attackBonus', () {
    test('compétent -> modificateur + bonus de maîtrise', () {
      final bonus = WeaponAttackCalculator.attackBonus(
        weaponName: 'Dague',
        weaponProperties: const ['finesse', 'légère'],
        abilityScores: const {'str': 10, 'dex': 16},
        proficiencyTokens: const ['courantes'],
        proficiencyBonus: 2,
      );
      expect(bonus, 5); // Dext +3 (finesse, meilleur des deux) + maîtrise +2.
    });

    test('non compétent -> modificateur seul (pas de bonus de maîtrise)', () {
      final bonus = WeaponAttackCalculator.attackBonus(
        weaponName: 'Épée longue',
        weaponProperties: const [],
        abilityScores: const {'str': 16, 'dex': 10},
        proficiencyTokens: const ['courantes'],
        proficiencyBonus: 2,
      );
      expect(bonus, 3); // Force +3 uniquement (pas martiale -> pas maîtrisé).
    });

    test('modificateur négatif géré correctement', () {
      final bonus = WeaponAttackCalculator.attackBonus(
        weaponName: 'Dague',
        weaponProperties: const [],
        abilityScores: const {'str': 6, 'dex': 8},
        proficiencyTokens: const [],
        proficiencyBonus: 2,
      );
      expect(bonus, -2); // Force 6 -> -2, non compétent (aucun token).
    });

    test('arme naturelle (« naturelle ») -> toujours le bonus de maîtrise, '
        'même sans aucun token de maîtrise pertinent', () {
      final bonus = WeaponAttackCalculator.attackBonus(
        weaponName: 'Griffes félines',
        weaponProperties: const ['à deux mains', 'naturelle'],
        abilityScores: const {'str': 14, 'dex': 10},
        proficiencyTokens: const [],
        proficiencyBonus: 2,
      );
      expect(bonus, 4); // Force +2 + maîtrise +2 (toujours compétent).
    });
  });

  group('catalogue réel des armes (items.category = arme)', () {
    const catalogNames = <String>[
      'Gourdin',
      'Dague',
      'Gourdin à deux mains',
      'Hachette',
      'Javeline',
      'Marteau léger',
      "Masse d'armes",
      'Faucille',
      'Épieu',
      'Bâton de combat',
      'Arc court',
      'Arbalète légère',
      'Dard',
      'Fronde',
      "Hache d'armes",
      "Fléau d'armes",
      'Glaive',
      'Grande hache',
      'Épée à deux mains',
      'Hallebarde',
      'Lance de cavalerie',
      'Épée longue',
      'Maillet',
      'Morgenstern',
      'Pique',
      'Rapière',
      'Cimeterre',
      'Épée courte',
      'Trident',
      'Pic de guerre',
      'Marteau de guerre',
      'Fouet',
      'Sarbacane',
      'Arbalète de poing',
      'Arbalète lourde',
      'Arc long',
      'Filet',
    ];

    test('le catalogue de référence compte 37 armes', () {
      expect(catalogNames, hasLength(37));
    });

    for (final name in catalogNames) {
      test('"$name" est classée courante ou martiale (jamais inconnue)', () {
        final common = WeaponAttackCalculator.isProficient(
          weaponName: name,
          proficiencyTokens: const ['courantes'],
        );
        final martial = WeaponAttackCalculator.isProficient(
          weaponName: name,
          proficiencyTokens: const ['martiales'],
        );
        expect(common != martial, isTrue, reason: '$name: exactement une');
      });
    }

    test('Barbare FOR 16 (+3), maîtrise +2, martiales, Grande hache -> +5', () {
      expect(
        WeaponAttackCalculator.attackBonus(
          weaponName: 'Grande hache',
          weaponProperties: const ['lourde', 'à deux mains'],
          abilityScores: const {'str': 16, 'dex': 10},
          proficiencyTokens: const ['courantes', 'martiales'],
          proficiencyBonus: 2,
        ),
        5,
      );
    });

    test('Faucille avec "courantes" -> compétent (maîtrise ajoutée)', () {
      expect(
        WeaponAttackCalculator.attackBonus(
          weaponName: 'Faucille',
          weaponProperties: const ['légère'],
          abilityScores: const {'str': 10, 'dex': 10},
          proficiencyTokens: const ['courantes'],
          proficiencyBonus: 2,
        ),
        2,
      );
    });
  });
}
