import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/background_equipment_parser.dart';

void main() {
  group('extractStartingGold', () {
    test('extrait le montant de "Bourse (N po)" quelle que soit sa position '
        'dans la liste', () {
      expect(
        BackgroundEquipmentParser.extractStartingGold([
          'Symbole sacré',
          'Habits communs',
          'Bourse (15 po)',
        ]),
        15,
      );
    });

    test('reconnaît un montant à un ou plusieurs chiffres', () {
      expect(
        BackgroundEquipmentParser.extractStartingGold(['Bourse (5 po)']),
        5,
      );
      expect(
        BackgroundEquipmentParser.extractStartingGold(['Bourse (25 po)']),
        25,
      );
    });

    test('aucune ligne "Bourse (N po)" -> null', () {
      expect(
        BackgroundEquipmentParser.extractStartingGold([
          'Symbole sacré',
          'Habits communs',
        ]),
        isNull,
      );
    });

    test('liste vide -> null', () {
      expect(BackgroundEquipmentParser.extractStartingGold([]), isNull);
    });

    test('ne confond pas une chaîne qui contient "Bourse" sans le format '
        'exact avec la ligne recherchée', () {
      expect(
        BackgroundEquipmentParser.extractStartingGold([
          "Une bourse de voyage en cuir",
        ]),
        isNull,
      );
    });
  });

  group('withoutStartingGoldLine', () {
    test('retire la ligne "Bourse (N po)" et conserve les autres dans '
        "l'ordre", () {
      expect(
        BackgroundEquipmentParser.withoutStartingGoldLine([
          'Symbole sacré',
          'Habits communs',
          'Bourse (15 po)',
        ]),
        ['Symbole sacré', 'Habits communs'],
      );
    });

    test('aucune ligne "Bourse (N po)" -> liste inchangée', () {
      expect(
        BackgroundEquipmentParser.withoutStartingGoldLine([
          'Symbole sacré',
          'Habits communs',
        ]),
        ['Symbole sacré', 'Habits communs'],
      );
    });

    test('liste vide -> liste vide', () {
      expect(BackgroundEquipmentParser.withoutStartingGoldLine([]), isEmpty);
    });
  });
}
