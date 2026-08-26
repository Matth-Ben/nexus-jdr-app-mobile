import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/saving_throw_calculator.dart';

void main() {
  group('SavingThrowCalculator.bonusFor', () {
    test('non maîtrisé : seulement le modificateur de caractéristique', () {
      // Score 16 -> modificateur +3.
      expect(
        SavingThrowCalculator.bonusFor(
          score: 16,
          isProficient: false,
          proficiencyBonus: 3,
        ),
        3,
      );
    });

    test('maîtrisé : modificateur + bonus de maîtrise', () {
      expect(
        SavingThrowCalculator.bonusFor(
          score: 16,
          isProficient: true,
          proficiencyBonus: 3,
        ),
        6,
      );
    });

    test('modificateur négatif maîtrisé', () {
      // Score 8 -> modificateur -1.
      expect(
        SavingThrowCalculator.bonusFor(
          score: 8,
          isProficient: true,
          proficiencyBonus: 2,
        ),
        1,
      );
    });
  });

  group('SavingThrowCalculator.computeAll', () {
    test('retourne les 6 résultats dans l\'ordre canonique For/Dex/Con/Int/Sag/Cha', () {
      final results = SavingThrowCalculator.computeAll(
        abilityScores: const {
          'str': 16,
          'dex': 12,
          'con': 14,
          'int': 10,
          'wis': 13,
          'cha': 8,
        },
        proficientAbilities: const {'str', 'con'},
        proficiencyBonus: 2,
      );

      expect(results, hasLength(6));
      expect(results.map((r) => r.abilityKey), [
        'str',
        'dex',
        'con',
        'int',
        'wis',
        'cha',
      ]);
      expect(results[0].isProficient, isTrue);
      expect(results[0].bonus, 5); // +3 (mod) + 2 (maîtrise)
      expect(results[1].isProficient, isFalse);
      expect(results[1].bonus, 1); // +1 (mod), pas de maîtrise
      expect(results[2].isProficient, isTrue);
      expect(results[2].bonus, 4); // +2 (mod) + 2 (maîtrise)
      expect(results[5].bonus, -1); // cha 8 -> -1, non maîtrisé
    });

    test(
      'une caractéristique absente de la map retombe sur un score de 10',
      () {
        final results = SavingThrowCalculator.computeAll(
          abilityScores: const {},
          proficientAbilities: const {},
          proficiencyBonus: 2,
        );

        expect(results.every((r) => r.bonus == 0), isTrue);
      },
    );
  });
}
