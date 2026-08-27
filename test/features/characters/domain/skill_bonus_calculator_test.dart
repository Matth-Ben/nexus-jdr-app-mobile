import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_skill_row.dart';
import 'package:personnages/features/characters/domain/skill_bonus_calculator.dart';

void main() {
  group('SkillBonusCalculator.proficiencyMultiplier', () {
    test('0 pour "aucune"', () {
      expect(SkillBonusCalculator.proficiencyMultiplier('aucune'), 0);
    });

    test('1 pour "competente"', () {
      expect(SkillBonusCalculator.proficiencyMultiplier('competente'), 1);
    });

    test('2 pour "expertise"', () {
      expect(SkillBonusCalculator.proficiencyMultiplier('expertise'), 2);
    });

    test('une valeur inattendue retombe sur 0', () {
      expect(SkillBonusCalculator.proficiencyMultiplier('n_importe_quoi'), 0);
    });
  });

  group('SkillBonusCalculator.bonusFor', () {
    test('non maîtrisée : seulement le modificateur de caractéristique', () {
      // Score 16 -> modificateur +3.
      expect(
        SkillBonusCalculator.bonusFor(
          score: 16,
          proficiency: 'aucune',
          proficiencyBonus: 3,
        ),
        3,
      );
    });

    test('maîtrisée : modificateur + bonus de maîtrise', () {
      expect(
        SkillBonusCalculator.bonusFor(
          score: 16,
          proficiency: 'competente',
          proficiencyBonus: 3,
        ),
        6,
      );
    });

    test('expertise : modificateur + 2x le bonus de maîtrise', () {
      expect(
        SkillBonusCalculator.bonusFor(
          score: 16,
          proficiency: 'expertise',
          proficiencyBonus: 3,
        ),
        9,
      );
    });

    test('modificateur négatif maîtrisé', () {
      // Score 8 -> modificateur -1.
      expect(
        SkillBonusCalculator.bonusFor(
          score: 8,
          proficiency: 'competente',
          proficiencyBonus: 2,
        ),
        1,
      );
    });
  });

  group('SkillBonusCalculator.computeAll', () {
    test('un résultat par compétence, dans l\'ordre reçu', () {
      final results = SkillBonusCalculator.computeAll(
        skills: const [
          CharacterSkillRow(
            id: 1,
            name: 'Acrobaties',
            abilityId: 'dex',
            proficiency: 'competente',
          ),
          CharacterSkillRow(
            id: 2,
            name: 'Arcanes',
            abilityId: 'int',
            proficiency: 'aucune',
          ),
          CharacterSkillRow(
            id: 3,
            name: 'Escamotage',
            abilityId: 'dex',
            proficiency: 'expertise',
          ),
        ],
        abilityScores: const {'dex': 16, 'int': 10},
        proficiencyBonus: 2,
      );

      expect(results, hasLength(3));
      expect(results[0].name, 'Acrobaties');
      expect(results[0].isMastered, isTrue);
      expect(results[0].bonus, 5); // +3 (mod) + 2 (maîtrise)
      expect(results[1].isMastered, isFalse);
      expect(results[1].bonus, 0); // mod nul, pas de maîtrise
      expect(results[2].isMastered, isTrue);
      expect(results[2].bonus, 7); // +3 (mod) + 2x2 (expertise)
    });

    test(
      'une caractéristique absente de la map retombe sur un score de 10',
      () {
        final results = SkillBonusCalculator.computeAll(
          skills: const [
            CharacterSkillRow(
              id: 1,
              name: 'Athlétisme',
              abilityId: 'str',
              proficiency: 'aucune',
            ),
          ],
          abilityScores: const {},
          proficiencyBonus: 2,
        );

        expect(results.single.bonus, 0);
      },
    );
  });
}
