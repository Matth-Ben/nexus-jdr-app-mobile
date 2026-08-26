import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/skill_ability_mapping.dart';

void main() {
  group('abbreviationFor', () {
    const expectedAbbreviations = {
      'Acrobaties': 'Dex',
      'Arcanes': 'Int',
      'Athlétisme': 'For',
      'Discrétion': 'Dex',
      'Dressage': 'Sag',
      'Escamotage': 'Dex',
      'Histoire': 'Int',
      'Intimidation': 'Cha',
      'Investigation': 'Int',
      'Médecine': 'Sag',
      'Nature': 'Int',
      'Perception': 'Sag',
      'Perspicacité': 'Sag',
      'Persuasion': 'Cha',
      'Religion': 'Int',
      'Représentation': 'Cha',
      'Survie': 'Sag',
      'Tromperie': 'Cha',
    };

    expectedAbbreviations.forEach((skill, abbreviation) {
      test('$skill -> $abbreviation', () {
        expect(SkillAbilityMapping.abbreviationFor(skill), abbreviation);
      });
    });

    test('les 18 compétences D&D 5e sont toutes couvertes', () {
      expect(expectedAbbreviations.length, 18);
      expect(
        SkillAbilityMapping.abilityAbbreviationBySkill.keys.toSet(),
        expectedAbbreviations.keys.toSet(),
      );
    });

    test('nom de compétence inconnu -> chaîne vide plutôt que crash', () {
      expect(SkillAbilityMapping.abbreviationFor('Vol'), '');
      expect(SkillAbilityMapping.abbreviationFor(''), '');
    });
  });

  group('allSkillNames', () {
    test('contient exactement les 18 compétences, sans doublon', () {
      expect(SkillAbilityMapping.allSkillNames.length, 18);
      expect(
        SkillAbilityMapping.allSkillNames.toSet().length,
        SkillAbilityMapping.allSkillNames.length,
      );
    });

    test('chaque nom de allSkillNames se résout vers une abréviation non '
        'vide', () {
      for (final skill in SkillAbilityMapping.allSkillNames) {
        expect(
          SkillAbilityMapping.abbreviationFor(skill),
          isNotEmpty,
          reason: '$skill devrait avoir une abréviation résolue',
        );
      }
    });
  });
}
