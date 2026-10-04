import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/lineage_choice_catalog.dart';
import 'package:personnages/features/character_creation/domain/lineage_option.dart';

void main() {
  const catalog = LineageChoiceCatalog(
    optionsByRaceId: {
      9: [
        LineageOption(id: 31, name: 'Abyssal'),
        LineageOption(id: 32, name: 'Chtonien'),
      ],
    },
  );

  group('LineageChoiceCatalog.isConcerned', () {
    test('race avec options -> true', () {
      expect(catalog.isConcerned(9), isTrue);
    });

    test('race absente du catalogue -> false', () {
      expect(catalog.isConcerned(1), isFalse);
    });
  });

  group('LineageChoiceCatalog.optionsFor', () {
    test('race concernée -> ses options', () {
      expect(catalog.optionsFor(9).map((o) => o.name), ['Abyssal', 'Chtonien']);
    });

    test('race non concernée -> liste vide', () {
      expect(catalog.optionsFor(1), isEmpty);
    });
  });

  group('LineageChoiceCatalog.nameOf', () {
    test('lignée trouvée -> son nom', () {
      expect(catalog.nameOf(raceId: 9, lineageId: 32), 'Chtonien');
    });

    test('lignée introuvable ou race non concernée -> null', () {
      expect(catalog.nameOf(raceId: 9, lineageId: 99), isNull);
      expect(catalog.nameOf(raceId: 1, lineageId: 31), isNull);
    });
  });
}
