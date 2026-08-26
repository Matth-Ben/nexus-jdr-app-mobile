import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/data/class_row_mapper.dart';

void main() {
  group('collectIds', () {
    test('normalise les ids int en String et déduplique', () {
      final rows = [
        {'id': 1},
        {'id': 2},
        {'id': 1},
      ];
      expect(ClassRowMapper.collectIds(rows), {'1', '2'});
    });

    test('ignore les ids nuls', () {
      expect(ClassRowMapper.collectIds([{}]), isEmpty);
    });
  });

  group('parseTranslatedValues', () {
    test('lit les colonnes réelles entity_id/value', () {
      final values = ClassRowMapper.parseTranslatedValues([
        {'entity_id': '1', 'value': 'Magicien'},
        {'entity_id': '2', 'value': 'Guerrier'},
      ]);
      expect(values, {'1': 'Magicien', '2': 'Guerrier'});
    });

    test('ignore une ligne sans entity_id ou sans value exploitable', () {
      final values = ClassRowMapper.parseTranslatedValues([
        {'entity_id': '1', 'value': null},
        {'entity_id': null, 'value': 'Orphelin'},
        {'entity_id': '3', 'value': 'Roublard'},
      ]);
      expect(values, {'3': 'Roublard'});
    });
  });

  group('toClassOption', () {
    test('résout le nom et la description via les maps de traductions', () {
      final classOption = ClassRowMapper.toClassOption(
        {'id': 1, 'hit_die': 6},
        names: {'1': 'Magicien'},
        descriptions: {
          '1':
              'Érudit de la magie arcanique, dont le pouvoir vient de '
              "l'étude et d'un grimoire.",
        },
      );

      expect(classOption.id, 1);
      expect(classOption.name, 'Magicien');
      expect(
        classOption.summaryLine,
        'Érudit de la magie arcanique, dont le pouvoir vient de '
        "l'étude et d'un grimoire. · dé de vie d6",
      );
    });

    test(
      'id sans traduction résolue -> libellé générique plutôt que crash',
      () {
        final classOption = ClassRowMapper.toClassOption(
          {'id': 99, 'hit_die': 8},
          names: const {},
          descriptions: const {},
        );

        expect(classOption.name, 'Classe #99');
        expect(classOption.description, isEmpty);
        expect(classOption.summaryLine, 'dé de vie d8');
      },
    );

    test('nom résolu mais description manquante -> description vide, nom '
        'conservé (résolution indépendante des deux maps)', () {
      final classOption = ClassRowMapper.toClassOption(
        {'id': 5, 'hit_die': 10},
        names: {'5': 'Guerrier'},
        descriptions: const {},
      );

      expect(classOption.name, 'Guerrier');
      expect(classOption.description, isEmpty);
      expect(classOption.summaryLine, 'dé de vie d10');
    });

    test('description résolue mais nom manquant -> libellé générique mais '
        'description conservée (résolution indépendante des deux maps)', () {
      final classOption = ClassRowMapper.toClassOption(
        {'id': 7, 'hit_die': 8},
        names: const {},
        descriptions: {'7': 'Combattant polyvalent.'},
      );

      expect(classOption.name, 'Classe #7');
      expect(classOption.description, 'Combattant polyvalent.');
      expect(classOption.summaryLine, 'Combattant polyvalent. · dé de vie d8');
    });
  });
}
