import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/level_up_invocation_row_mapper.dart';

void main() {
  group('LevelUpInvocationRowMapper.collectInvocationIds', () {
    test('collecte les id en Set<String>, ignore les lignes sans id', () {
      final rows = [
        {'id': 7, 'prerequisites': <String, dynamic>{}},
        {'id': 9, 'prerequisites': <String, dynamic>{}},
        {'prerequisites': <String, dynamic>{}},
      ];
      expect(LevelUpInvocationRowMapper.collectInvocationIds(rows), {'7', '9'});
    });
  });

  group('LevelUpInvocationRowMapper.prerequisiteTextFor', () {
    test('extrait prerequisites->>text', () {
      final row = {
        'id': 1,
        'prerequisites': {'text': 'Niveau 5 requis'},
      };
      expect(
        LevelUpInvocationRowMapper.prerequisiteTextFor(row),
        'Niveau 5 requis',
      );
    });

    test('null si absent, vide, ou de type invalide', () {
      expect(
        LevelUpInvocationRowMapper.prerequisiteTextFor({
          'id': 1,
          'prerequisites': <String, dynamic>{},
        }),
        isNull,
      );
      expect(
        LevelUpInvocationRowMapper.prerequisiteTextFor({
          'id': 1,
          'prerequisites': {'text': ''},
        }),
        isNull,
      );
      expect(
        LevelUpInvocationRowMapper.prerequisiteTextFor({
          'id': 1,
          'prerequisites': 'invalide',
        }),
        isNull,
      );
    });
  });

  group('LevelUpInvocationRowMapper.toInvocationOptions', () {
    test('construit les options avec noms/descriptions résolus, triées '
        'alphabétiquement', () {
      final rows = [
        {'id': 1, 'prerequisites': <String, dynamic>{}},
        {
          'id': 2,
          'prerequisites': {'text': 'Pacte de la lame'},
        },
      ];

      final options = LevelUpInvocationRowMapper.toInvocationOptions(
        rows,
        names: {'1': 'Vue dans les ténèbres', '2': 'Agile esquive'},
        descriptions: {'1': 'Description 1', '2': 'Description 2'},
      );

      expect(options, hasLength(2));
      expect(options[0].name, 'Agile esquive');
      expect(options[0].id, 2);
      expect(options[0].prerequisiteText, 'Pacte de la lame');
      expect(options[1].name, 'Vue dans les ténèbres');
      expect(options[1].prerequisiteText, isNull);
    });

    test('nom de repli "Invocation #<id>" si absent de names (défensif)', () {
      final rows = [
        {'id': 99, 'prerequisites': <String, dynamic>{}},
      ];

      final options = LevelUpInvocationRowMapper.toInvocationOptions(
        rows,
        names: const {},
        descriptions: const {},
      );

      expect(options.single.name, 'Invocation #99');
      expect(options.single.description, '');
    });

    test('ignore les lignes sans id', () {
      final rows = [
        <String, dynamic>{'prerequisites': <String, dynamic>{}},
      ];

      expect(
        LevelUpInvocationRowMapper.toInvocationOptions(
          rows,
          names: const {},
          descriptions: const {},
        ),
        isEmpty,
      );
    });
  });
}
