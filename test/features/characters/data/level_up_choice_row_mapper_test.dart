import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/level_up_choice_row_mapper.dart';

void main() {
  group('LevelUpChoiceRowMapper.collectSubclassIds', () {
    test('collecte les id en Set<String>', () {
      final rows = [
        {'id': 5, 'available_from_level': 3},
        {'id': 8, 'available_from_level': 3},
      ];
      expect(LevelUpChoiceRowMapper.collectSubclassIds(rows), {'5', '8'});
    });

    test('ignore une ligne sans id', () {
      final rows = [
        {'id': null, 'available_from_level': 3},
      ];
      expect(LevelUpChoiceRowMapper.collectSubclassIds(rows), isEmpty);
    });
  });

  group('LevelUpChoiceRowMapper.toSubclassOptions', () {
    test('résout nom et description depuis les maps déjà traduites', () {
      final rows = [
        {'id': 5, 'available_from_level': 3},
        {'id': 8, 'available_from_level': 3},
      ];

      final options = LevelUpChoiceRowMapper.toSubclassOptions(
        rows,
        names: const {'5': 'Champion', '8': 'Chasseur'},
        descriptions: const {'5': 'Un archétype simple et efficace.'},
      );

      expect(options, hasLength(2));
      expect(options[0].id, 5);
      expect(options[0].name, 'Champion');
      expect(options[0].description, 'Un archétype simple et efficace.');
      expect(options[1].id, 8);
      expect(options[1].name, 'Chasseur');
      // Pas de description résolue pour l'id 8 : `null`, pas de texte de
      // repli (voir la documentation de `LevelUpSubclassOption.description`).
      expect(options[1].description, isNull);
    });

    test('un id sans nom résolu retombe sur un libellé générique', () {
      final rows = [
        {'id': 42, 'available_from_level': 3},
      ];

      final options = LevelUpChoiceRowMapper.toSubclassOptions(
        rows,
        names: const {},
        descriptions: const {},
      );

      expect(options.single.name, 'Sous-classe #42');
    });

    test('ignore une ligne sans id', () {
      final rows = [
        {'id': null, 'available_from_level': 3},
      ];

      final options = LevelUpChoiceRowMapper.toSubclassOptions(
        rows,
        names: const {},
        descriptions: const {},
      );

      expect(options, isEmpty);
    });

    test('tri alphabétique normalisé (accents ignorés), pas l\'ordre des '
        'lignes `id`', () {
      final rows = [
        {'id': 5, 'available_from_level': 3},
        {'id': 8, 'available_from_level': 3},
      ];

      final options = LevelUpChoiceRowMapper.toSubclassOptions(
        rows,
        // Inversé par rapport à l'ordre des lignes (id 5 puis 8) : "Zéphyr"
        // doit malgré tout finir après "École".
        names: const {'5': 'Zéphyr', '8': 'École des éléments'},
        descriptions: const {},
      );

      expect(options.map((o) => o.name), ['École des éléments', 'Zéphyr']);
    });
  });
}
