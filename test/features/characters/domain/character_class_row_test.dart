import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_class_row.dart';

void main() {
  group('CharacterClassesSummary.totalLevel', () {
    test('personnage mono-classe : niveau total = niveau de la classe', () {
      const classes = [
        CharacterClassRow(classId: 1, level: 5, isPrimary: true),
      ];

      expect(CharacterClassesSummary.totalLevel(classes), 5);
    });

    test('personnage multiclassé : niveau total = somme des niveaux', () {
      const classes = [
        CharacterClassRow(classId: 1, level: 3, isPrimary: true),
        CharacterClassRow(classId: 2, level: 2, isPrimary: false),
      ];

      expect(CharacterClassesSummary.totalLevel(classes), 5);
    });

    test('personnage triclassé : niveau total = somme des trois niveaux '
        '(ex. Guerrier 3 / Magicien 2 / Roublard 1 → niveau 6)', () {
      const classes = [
        CharacterClassRow(classId: 1, level: 3, isPrimary: true),
        CharacterClassRow(classId: 2, level: 2, isPrimary: false),
        CharacterClassRow(classId: 3, level: 1, isPrimary: false),
      ];

      expect(CharacterClassesSummary.totalLevel(classes), 6);
    });

    test('aucune classe : niveau total = 0', () {
      expect(CharacterClassesSummary.totalLevel(const []), 0);
    });
  });

  group('CharacterClassesSummary.primaryClassId', () {
    test('retourne la classe marquée is_primary même si elle n\'est pas '
        'première dans la liste', () {
      const classes = [
        CharacterClassRow(classId: 2, level: 2, isPrimary: false),
        CharacterClassRow(classId: 1, level: 3, isPrimary: true),
      ];

      expect(CharacterClassesSummary.primaryClassId(classes), 1);
    });

    test('retourne la première classe si aucune n\'est marquée is_primary '
        '(donnée incohérente, repli défensif)', () {
      const classes = [
        CharacterClassRow(classId: 2, level: 2, isPrimary: false),
        CharacterClassRow(classId: 1, level: 3, isPrimary: false),
      ];

      expect(CharacterClassesSummary.primaryClassId(classes), 2);
    });

    test('retourne la première classe marquée is_primary si plusieurs le sont '
        '(donnée incohérente, repli défensif contre une double primaire)', () {
      const classes = [
        CharacterClassRow(classId: 1, level: 3, isPrimary: true),
        CharacterClassRow(classId: 2, level: 2, isPrimary: true),
      ];

      expect(CharacterClassesSummary.primaryClassId(classes), 1);
    });

    test('personnage mono-classe non marquée is_primary : retourne quand même '
        'cette unique classe', () {
      const classes = [
        CharacterClassRow(classId: 7, level: 1, isPrimary: false),
      ];

      expect(CharacterClassesSummary.primaryClassId(classes), 7);
    });

    test('retourne null si le personnage n\'a aucune classe', () {
      expect(CharacterClassesSummary.primaryClassId(const []), isNull);
    });
  });
}
