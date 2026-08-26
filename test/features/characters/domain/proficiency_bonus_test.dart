import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/proficiency_bonus.dart';

void main() {
  group('ProficiencyBonusRules.forTotalLevel', () {
    test('niveaux 1 à 4 -> +2', () {
      expect(ProficiencyBonusRules.forTotalLevel(1), 2);
      expect(ProficiencyBonusRules.forTotalLevel(4), 2);
    });

    test('niveaux 5 à 8 -> +3', () {
      expect(ProficiencyBonusRules.forTotalLevel(5), 3);
      expect(ProficiencyBonusRules.forTotalLevel(8), 3);
    });

    test('niveaux 9 à 12 -> +4', () {
      expect(ProficiencyBonusRules.forTotalLevel(9), 4);
      expect(ProficiencyBonusRules.forTotalLevel(12), 4);
    });

    test('niveaux 13 à 16 -> +5', () {
      expect(ProficiencyBonusRules.forTotalLevel(13), 5);
      expect(ProficiencyBonusRules.forTotalLevel(16), 5);
    });

    test('niveaux 17 à 20 -> +6', () {
      expect(ProficiencyBonusRules.forTotalLevel(17), 6);
      expect(ProficiencyBonusRules.forTotalLevel(20), 6);
    });

    test('borne les niveaux hors plage plutôt que de crasher', () {
      expect(ProficiencyBonusRules.forTotalLevel(0), 2);
      expect(ProficiencyBonusRules.forTotalLevel(-3), 2);
      expect(ProficiencyBonusRules.forTotalLevel(99), 6);
    });
  });
}
