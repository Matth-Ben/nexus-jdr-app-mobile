// Tests de caractérisation (P7, PR 0) de `WeaponAttackCalculator` : figent le
// comportement ACTUEL avant que les armes personnalisées deviennent
// équipables avec attaque/dégâts calculés. Complète
// `weapon_attack_calculator_test.dart` sans le dupliquer.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/weapon_attack_calculator.dart';

int _modifier(List<String> properties, Map<String, int> scores) =>
    WeaponAttackCalculator.abilityModifierFor(
      weaponProperties: properties,
      abilityScores: scores,
    );

int _attack({
  required String name,
  List<String> properties = const [],
  Map<String, int> scores = const {'str': 10, 'dex': 10},
  List<String> tokens = const [],
  int proficiency = 2,
}) => WeaponAttackCalculator.attackBonus(
  weaponName: name,
  weaponProperties: properties,
  abilityScores: scores,
  proficiencyTokens: tokens,
  proficiencyBonus: proficiency,
);

void main() {
  group('abilityModifierFor : choix de la caractéristique', () {
    test('munitions : Dex, même avec Force supérieure ; Dex 20 -> +5', () {
      expect(_modifier(['munitions(24/96)'], {'str': 20, 'dex': 20}), 5);
      expect(_modifier(['munitions(24/96)'], {'str': 20, 'dex': 8}), -1);
    });

    test('munitions prime sur finesse (Dex même si Force est meilleure)', () {
      expect(
        _modifier(['finesse', 'munitions(9/36)'], {'str': 18, 'dex': 10}),
        0,
      );
    });

    test('propriétés insensibles à la casse et aux accents', () {
      expect(_modifier(['Munitions(24/96)'], {'str': 18, 'dex': 12}), 1);
      expect(_modifier(['FINESSE'], {'str': 8, 'dex': 14}), 2);
    });

    test('finesse : Force = Dex -> même valeur ; deux malus -> le moins '
        'mauvais', () {
      expect(_modifier(['finesse'], {'str': 14, 'dex': 14}), 2);
      expect(_modifier(['finesse'], {'str': 6, 'dex': 8}), -1);
    });

    test('finesse + lancer (dague) : le meilleur de Force/Dex', () {
      expect(
        _modifier(['finesse', 'lancer(6/18)', 'légère'], {'str': 8, 'dex': 16}),
        3,
      );
    });

    test('sans propriété, à deux mains, lourde : Force uniquement', () {
      expect(_modifier([], {'str': 20, 'dex': 8}), 5);
      expect(_modifier(['lourde', 'à deux mains'], {'str': 8, 'dex': 20}), -1);
    });

    test('une propriété de bonus magique (« +1 ») n\'a aucun effet', () {
      expect(_modifier(['+1', 'finesse'], {'str': 10, 'dex': 14}), 2);
    });

    test('Force absente : 10 par défaut ; Dex absente idem', () {
      expect(_modifier([], {'dex': 20}), 0);
      expect(_modifier(['munitions(24/96)'], {'str': 20}), 0);
    });

    test('dégâts : le même modificateur que l\'attaque, sans maîtrise '
        '(attaque - maîtrise = modificateur de dégâts)', () {
      const scores = {'str': 10, 'dex': 18};
      const properties = ['finesse', 'légère'];
      final damageModifier = _modifier(properties, scores);
      final attack = _attack(
        name: 'Rapière',
        properties: properties,
        scores: scores,
        tokens: ['martiales'],
        proficiency: 3,
      );
      expect(damageModifier, 4);
      expect(attack, 7);
      expect(attack - 3, damageModifier);
    });
  });

  group('attackBonus : mod + maîtrise, valeur par valeur', () {
    test('maîtrise +2 à +6 ajoutée telle quelle', () {
      for (var proficiency = 2; proficiency <= 6; proficiency++) {
        expect(
          _attack(
            name: 'Épée longue',
            scores: const {'str': 16, 'dex': 10},
            tokens: ['martiales'],
            proficiency: proficiency,
          ),
          3 + proficiency,
          reason: 'maîtrise $proficiency',
        );
      }
    });

    test('Rapière (finesse, martiale) Dex 16, maîtrise +3 : 3 + 3 = 6', () {
      expect(
        _attack(
          name: 'Rapière',
          properties: ['finesse'],
          scores: const {'str': 10, 'dex': 16},
          tokens: ['courantes', 'martiales'],
          proficiency: 3,
        ),
        6,
      );
    });

    test(
      'Arc court (munitions) Dex 14, courantes, maîtrise +2 : 2 + 2 = 4',
      () {
        expect(
          _attack(
            name: 'Arc court',
            properties: ['munitions(24/96)', 'à deux mains'],
            scores: const {'str': 18, 'dex': 14},
            tokens: ['courantes'],
          ),
          4,
        );
      },
    );

    test(
      'Arc court sans maîtrise de l\'arme (martiales seules) : mod seul',
      () {
        expect(
          _attack(
            name: 'Arc court',
            properties: ['munitions(24/96)'],
            scores: const {'dex': 14},
            tokens: ['martiales'],
          ),
          2,
        );
      },
    );

    test('Grande hache (à deux mains) Force 20 : +5 + maîtrise +4 = 9', () {
      expect(
        _attack(
          name: 'Grande hache',
          properties: ['lourde', 'à deux mains'],
          scores: const {'str': 20, 'dex': 10},
          tokens: ['martiales'],
          proficiency: 4,
        ),
        9,
      );
    });

    test('malus de caractéristique + maîtrise : Force 6 (-2) + 2 = 0', () {
      expect(
        _attack(
          name: 'Dague',
          scores: const {'str': 6, 'dex': 10},
          tokens: ['courantes'],
        ),
        0,
      );
    });

    test('maîtrise par nom d\'arme spécifique au pluriel (martiale)', () {
      expect(
        _attack(
          name: 'Arbalète de poing',
          properties: ['munitions(9/36)'],
          scores: const {'dex': 14},
          tokens: ['arbalètes de poing'],
        ),
        4,
      );
      expect(
        _attack(
          name: 'Épée longue',
          scores: const {'str': 10},
          tokens: ['épées longues'],
        ),
        2,
      );
    });

    test('nom de token insensible à la casse et aux accents', () {
      expect(
        WeaponAttackCalculator.isProficient(
          weaponName: 'ÉPÉE LONGUE',
          proficiencyTokens: const ['MARTIALES'],
        ),
        isTrue,
      );
      expect(
        WeaponAttackCalculator.isProficient(
          weaponName: 'Epee longue',
          proficiencyTokens: const ['epees longues'],
        ),
        isTrue,
      );
    });

    test('un token de catégorie ne fait pas passer une arme de l\'autre '
        'catégorie', () {
      expect(
        _attack(
          name: 'Dague',
          scores: const {'str': 10},
          tokens: ['martiales'],
        ),
        0,
      );
    });
  });

  group('arme naturelle', () {
    test(
      '« naturelle » : maîtrise accordée sans token, casse indifférente',
      () {
        expect(
          _attack(
            name: 'Morsure',
            properties: ['Naturelle'],
            scores: const {'str': 12, 'dex': 10},
          ),
          3, // +1 Force +2 maîtrise
        );
      },
    );

    test('naturelle + finesse : meilleure de Force/Dex + maîtrise', () {
      expect(
        _attack(
          name: 'Griffes',
          properties: ['naturelle', 'finesse'],
          scores: const {'str': 8, 'dex': 16},
          proficiency: 3,
        ),
        6,
      );
    });
  });

  group('arme personnalisée au nom libre (characterisation)', () {
    // Une arme personnalisée n'a pas de ligne catalogue : seule son
    // appartenance par NOM aux catégories du catalogue décide de la maîtrise.
    test('nom libre inconnu : jamais maîtrisée, même avec courantes + '
        'martiales -> modificateur seul', () {
      expect(
        WeaponAttackCalculator.isProficient(
          weaponName: 'Excalibur',
          proficiencyTokens: const ['courantes', 'martiales'],
          weaponProperties: const ['finesse'],
        ),
        isFalse,
      );
      expect(
        _attack(
          name: 'Excalibur',
          properties: ['finesse'],
          scores: const {'str': 16, 'dex': 10},
          tokens: ['courantes', 'martiales'],
        ),
        3,
      );
    });

    test('nom libre égal à un token d\'arme spécifique : maîtrisée par le '
        'nom exact', () {
      expect(
        WeaponAttackCalculator.isProficient(
          weaponName: 'Excalibur',
          proficiencyTokens: const ['excalibur'],
        ),
        isTrue,
      );
    });

    test('nom libre qui reprend un nom du catalogue (« Épée longue ») : '
        'traitée comme l\'arme du catalogue (la maîtrise dépend du nom '
        'seul)', () {
      expect(
        WeaponAttackCalculator.isProficient(
          weaponName: 'Épée longue',
          proficiencyTokens: const ['martiales'],
        ),
        isTrue,
      );
    });

    test('nom libre avec suffixe (« Épée longue +1 », « Dague de '
        'Marcel ») : non reconnue, donc jamais maîtrisée', () {
      for (final name in ['Épée longue +1', 'Dague de Marcel']) {
        expect(
          WeaponAttackCalculator.isProficient(
            weaponName: name,
            proficiencyTokens: const ['courantes', 'martiales'],
          ),
          isFalse,
          reason: name,
        );
      }
    });

    test('nom libre vide : jamais maîtrisée', () {
      expect(
        WeaponAttackCalculator.isProficient(
          weaponName: '',
          proficiencyTokens: const ['courantes', 'martiales'],
        ),
        isFalse,
      );
    });
  });
}
