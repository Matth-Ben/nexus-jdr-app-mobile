import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/class_choice_rules.dart';

void main() {
  group('ClassChoiceRules.kindFor/isConcerned', () {
    test('Guerrier (5) -> fightingStyle', () {
      expect(ClassChoiceRules.kindFor(5), ClassChoiceKind.fightingStyle);
      expect(ClassChoiceRules.isConcerned(5), isTrue);
    });

    test('Rôdeur (8) -> favoredEnemy', () {
      expect(ClassChoiceRules.kindFor(8), ClassChoiceKind.favoredEnemy);
      expect(ClassChoiceRules.isConcerned(8), isTrue);
    });

    test(
      'Roublard (9) -> null (point d\'insertion dédié, pas ClassStepScreen)',
      () {
        expect(ClassChoiceRules.kindFor(9), isNull);
        expect(ClassChoiceRules.isConcerned(9), isFalse);
      },
    );

    test('classe non concernée -> null', () {
      expect(ClassChoiceRules.kindFor(1), isNull);
      expect(ClassChoiceRules.isConcerned(1), isFalse);
    });
  });

  group('ClassChoiceRules.choiceTypeFor', () {
    test('fightingStyle -> style_combat', () {
      expect(
        ClassChoiceRules.choiceTypeFor(ClassChoiceKind.fightingStyle),
        'style_combat',
      );
    });

    test('favoredEnemy -> ennemi_jure', () {
      expect(
        ClassChoiceRules.choiceTypeFor(ClassChoiceKind.favoredEnemy),
        'ennemi_jure',
      );
    });

    test('expertise -> expertise', () {
      expect(
        ClassChoiceRules.choiceTypeFor(ClassChoiceKind.expertise),
        'expertise',
      );
    });
  });

  group('ClassChoiceRules.titleFor/announcementFor', () {
    test('fightingStyle', () {
      expect(
        ClassChoiceRules.titleFor(ClassChoiceKind.fightingStyle),
        'Style de combat',
      );
      expect(
        ClassChoiceRules.announcementFor(ClassChoiceKind.fightingStyle),
        'Choisis un style de combat.',
      );
    });

    test('favoredEnemy', () {
      expect(
        ClassChoiceRules.titleFor(ClassChoiceKind.favoredEnemy),
        'Ennemi juré',
      );
      expect(
        ClassChoiceRules.announcementFor(ClassChoiceKind.favoredEnemy),
        'Choisis un ennemi juré.',
      );
    });

    test('expertise', () {
      expect(ClassChoiceRules.titleFor(ClassChoiceKind.expertise), 'Expertise');
      expect(
        ClassChoiceRules.announcementFor(ClassChoiceKind.expertise),
        'Choisis 2 compétences maîtrisées.',
      );
    });
  });
}
