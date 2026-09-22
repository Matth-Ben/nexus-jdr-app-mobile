import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/subclass_choice_rules.dart';

void main() {
  group('SubclassChoiceRules.titleFor', () {
    test('libellé propre à chaque classe concernée', () {
      expect(SubclassChoiceRules.titleFor('Clerc'), 'Domaine divin');
      expect(SubclassChoiceRules.titleFor('Occultiste'), 'Patron protecteur');
      expect(SubclassChoiceRules.titleFor('Ensorceleur'), 'Origine magique');
    });

    test('libellé de repli pour toute autre classe', () {
      expect(SubclassChoiceRules.titleFor('Guerrier'), 'Sous-classe');
      expect(SubclassChoiceRules.titleFor(''), 'Sous-classe');
    });

    test("annonce d'accessibilité", () {
      expect(
        SubclassChoiceRules.announcementFor('Clerc'),
        'Choisis ton domaine divin.',
      );
      expect(
        SubclassChoiceRules.announcementFor('Barbare'),
        'Choisis ta sous-classe.',
      );
    });
  });

  group('SubclassChoiceRules.subclassAfterClassChange', () {
    test('même classe : la sous-classe est conservée', () {
      expect(
        SubclassChoiceRules.subclassAfterClassChange(
          previousClassId: 3,
          newClassId: 3,
          currentSubclassId: 31,
        ),
        31,
      );
    });

    test('classe différente : la sous-classe passe à null', () {
      expect(
        SubclassChoiceRules.subclassAfterClassChange(
          previousClassId: 3,
          newClassId: 4,
          currentSubclassId: 31,
        ),
        isNull,
      );
    });

    test('aucune classe précédente : null', () {
      expect(
        SubclassChoiceRules.subclassAfterClassChange(
          previousClassId: null,
          newClassId: 3,
          currentSubclassId: 31,
        ),
        isNull,
      );
    });
  });
}
