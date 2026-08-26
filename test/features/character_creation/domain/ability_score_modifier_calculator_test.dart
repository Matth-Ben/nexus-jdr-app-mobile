// Tests unitaires du calcul du bonus racial/sous-racial et du modificateur
// final affiché à l'étape 4/9 "Caractéristiques"
// (`lib/features/character_creation/domain/ability_score_modifier_calculator.dart`).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/ability_score_modifier_calculator.dart';
import 'package:personnages/features/character_creation/domain/race_catalog.dart';
import 'package:personnages/features/character_creation/domain/race_option.dart';
import 'package:personnages/features/character_creation/domain/subrace_option.dart';

void main() {
  const elfe = RaceOption(
    id: 1,
    name: 'Elfe',
    abilityBonuses: {'dex': 2},
    traits: [],
  );
  const hautElfe = SubraceOption(
    id: 10,
    raceId: 1,
    name: 'Haut-elfe',
    abilityBonuses: {'int': 1},
    traits: [],
  );
  const demiElfe = RaceOption(
    id: 2,
    name: 'Demi-elfe',
    abilityBonuses: {'cha': 2, 'choice_others': 2},
    traits: [],
  );
  const humain = RaceOption(
    id: 3,
    name: 'Humain',
    abilityBonuses: {
      'str': 1,
      'dex': 1,
      'con': 1,
      'int': 1,
      'wis': 1,
      'cha': 1,
    },
    traits: [],
  );

  final catalog = const RaceCatalog(
    races: [elfe, demiElfe, humain],
    subraces: [hautElfe],
  );

  group('racialBonusFor', () {
    test('retourne 0 si raceId est null (race personnalisée)', () {
      final bonus = AbilityScoreModifierCalculator.racialBonusFor(
        abilityKey: 'dex',
        catalog: catalog,
        raceId: null,
        subraceId: null,
      );

      expect(bonus, 0);
    });

    test('retourne le bonus de race seule quand aucune sous-race choisie', () {
      final bonus = AbilityScoreModifierCalculator.racialBonusFor(
        abilityKey: 'dex',
        catalog: catalog,
        raceId: 1,
        subraceId: null,
      );

      expect(bonus, 2);
    });

    test('additionne le bonus de race et de sous-race pour des '
        'caractéristiques différentes', () {
      final dexBonus = AbilityScoreModifierCalculator.racialBonusFor(
        abilityKey: 'dex',
        catalog: catalog,
        raceId: 1,
        subraceId: 10,
      );
      final intBonus = AbilityScoreModifierCalculator.racialBonusFor(
        abilityKey: 'int',
        catalog: catalog,
        raceId: 1,
        subraceId: 10,
      );

      expect(dexBonus, 2, reason: 'bonus de race Elfe');
      expect(intBonus, 1, reason: 'bonus de sous-race Haut-elfe');
    });

    test('additionne les bonus de race ET de sous-race sur une même '
        "caractéristique s'ils se chevauchent", () {
      const naineDesCollines = SubraceOption(
        id: 20,
        raceId: 4,
        name: 'Nain des collines',
        abilityBonuses: {'con': 1},
        traits: [],
      );
      const nain = RaceOption(
        id: 4,
        name: 'Nain',
        abilityBonuses: {'con': 2},
        traits: [],
      );
      final catalogWithNain = RaceCatalog(
        races: [...catalog.races, nain],
        subraces: [...catalog.subraces, naineDesCollines],
      );

      final bonus = AbilityScoreModifierCalculator.racialBonusFor(
        abilityKey: 'con',
        catalog: catalogWithNain,
        raceId: 4,
        subraceId: 20,
      );

      expect(bonus, 3);
    });

    test('ignore la clé spéciale choice_others (bonus au choix)', () {
      final bonus = AbilityScoreModifierCalculator.racialBonusFor(
        abilityKey: 'choice_others',
        catalog: catalog,
        raceId: 2,
        subraceId: null,
      );

      expect(bonus, 0);
    });

    test("retourne 0 pour une caractéristique qui n'a pas de bonus pour "
        'cette race', () {
      final bonus = AbilityScoreModifierCalculator.racialBonusFor(
        abilityKey: 'str',
        catalog: catalog,
        raceId: 1,
        subraceId: null,
      );

      expect(bonus, 0);
    });

    test(
      'reflète un bonus uniforme à toutes les caractéristiques (Humain)',
      () {
        for (final key in ['str', 'dex', 'con', 'int', 'wis', 'cha']) {
          final bonus = AbilityScoreModifierCalculator.racialBonusFor(
            abilityKey: key,
            catalog: catalog,
            raceId: 3,
            subraceId: null,
          );
          expect(bonus, 1);
        }
      },
    );

    test('retourne 0 si raceId ne correspond plus à aucune race du '
        'catalogue', () {
      final bonus = AbilityScoreModifierCalculator.racialBonusFor(
        abilityKey: 'dex',
        catalog: catalog,
        raceId: 999,
        subraceId: null,
      );

      expect(bonus, 0);
    });
  });

  group('modifierFor', () {
    test('applique la formule floor((score + bonus - 10) / 2)', () {
      expect(
        AbilityScoreModifierCalculator.modifierFor(
          baseScore: 15,
          racialBonus: 2,
        ),
        3,
      );
      expect(
        AbilityScoreModifierCalculator.modifierFor(
          baseScore: 8,
          racialBonus: 0,
        ),
        -1,
      );
      expect(
        AbilityScoreModifierCalculator.modifierFor(
          baseScore: 13,
          racialBonus: 1,
        ),
        2,
      );
    });
  });
}
