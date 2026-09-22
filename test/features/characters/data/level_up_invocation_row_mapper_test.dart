import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/level_up_invocation_row_mapper.dart';
import 'package:personnages/features/characters/domain/warlock_pact.dart';

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

    test('expose les prérequis structurés et le nom du sort mineur requis', () {
      final rows = [
        {
          'id': 5,
          'prerequisites': {
            'text': 'Pacte de la lame',
            'level': 5,
            'pact': 'lame',
            'cantrip_spell_id': 42,
          },
        },
      ];

      final options = LevelUpInvocationRowMapper.toInvocationOptions(
        rows,
        names: {'5': 'Frappe assoiffée'},
        descriptions: const {},
        cantripNames: {'42': 'Décharge occulte'},
      );

      final option = options.single;
      expect(option.prerequisites.level, 5);
      expect(option.prerequisites.pact, WarlockPact.blade);
      expect(option.prerequisites.cantripSpellId, 42);
      expect(option.cantripName, 'Décharge occulte');
      expect(option.prerequisiteText, 'Pacte de la lame');
    });

    test('collectCantripSpellIds : ids de sorts mineurs requis, sans doublon '
        'ni valeur invalide', () {
      final rows = [
        {
          'id': 1,
          'prerequisites': {'cantrip_spell_id': 42},
        },
        {
          'id': 2,
          'prerequisites': {'cantrip_spell_id': 42},
        },
        {
          'id': 3,
          'prerequisites': {'cantrip_spell_id': 'x'},
        },
        {'id': 4, 'prerequisites': null},
      ];
      expect(LevelUpInvocationRowMapper.collectCantripSpellIds(rows), {'42'});
    });

    test('prérequis structurés absents -> aucune contrainte', () {
      final rows = [
        {
          'id': 1,
          'prerequisites': {'text': 'Niveau 5 requis'},
        },
      ];
      final option = LevelUpInvocationRowMapper.toInvocationOptions(
        rows,
        names: const {},
        descriptions: const {},
      ).single;
      expect(option.prerequisites.isEmpty, isTrue);
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
