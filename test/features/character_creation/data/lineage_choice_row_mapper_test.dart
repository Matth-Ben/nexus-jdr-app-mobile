import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/data/lineage_choice_row_mapper.dart';

void main() {
  group('LineageChoiceRowMapper.titleOf', () {
    test('ascendance draconique : "Dragon <couleur minuscule>" dérivé après '
        'le dernier ":"', () {
      expect(
        LineageChoiceRowMapper.titleOf(
          'Ancêtre draconique 2024 : Rouge',
          isDragonAncestry: true,
        ),
        'Dragon rouge',
      );
      expect(
        LineageChoiceRowMapper.titleOf(
          'Ancêtre draconique 2024 : Argent',
          isDragonAncestry: true,
        ),
        'Dragon argent',
      );
    });

    test('pas une ascendance draconique : nom brut inchangé', () {
      expect(
        LineageChoiceRowMapper.titleOf('Abyssal', isDragonAncestry: false),
        'Abyssal',
      );
      expect(
        LineageChoiceRowMapper.titleOf(
          'Géant des nuages',
          isDragonAncestry: false,
        ),
        'Géant des nuages',
      );
    });
  });

  group('LineageChoiceRowMapper.subtitleOf', () {
    test(
      'damageType non nul -> "Souffle et résistance : <Type>" capitalisé',
      () {
        expect(
          LineageChoiceRowMapper.subtitleOf(
            damageType: 'feu',
            hasInnateSpells: false,
          ),
          'Souffle et résistance : Feu',
        );
        expect(
          LineageChoiceRowMapper.subtitleOf(
            damageType: 'acide',
            hasInnateSpells: true, // damageType prioritaire sur hasInnateSpells
          ),
          'Souffle et résistance : Acide',
        );
      },
    );

    test('damageType nul + sorts innés -> texte fixe', () {
      expect(
        LineageChoiceRowMapper.subtitleOf(
          damageType: null,
          hasInnateSpells: true,
        ),
        'Détermine les sorts innés acquis (niveaux 1, 3 et 5)',
      );
    });

    test('ni damageType ni sorts innés -> null (ne jamais inventer un '
        'effet non stocké)', () {
      expect(
        LineageChoiceRowMapper.subtitleOf(
          damageType: null,
          hasInnateSpells: false,
        ),
        isNull,
      );
      expect(
        LineageChoiceRowMapper.subtitleOf(
          damageType: '',
          hasInnateSpells: false,
        ),
        isNull,
      );
    });
  });

  group('LineageChoiceRowMapper.toCatalog', () {
    test('les 10 ascendances draconiques du Drakéide (race_id = 5), ordre '
        'des lignes préservé, titres/sous-titres exacts', () {
      final rows = [
        {'id': 34, 'race_id': 5, 'damage_type': 'acide'},
        {'id': 35, 'race_id': 5, 'damage_type': 'foudre'},
        {'id': 41, 'race_id': 5, 'damage_type': 'feu'},
        {'id': 43, 'race_id': 5, 'damage_type': 'froid'},
      ];
      final names = {
        '34': 'Ancêtre draconique 2024 : Noir',
        '35': 'Ancêtre draconique 2024 : Bleu',
        '41': 'Ancêtre draconique 2024 : Rouge',
        '43': 'Ancêtre draconique 2024 : Blanc',
      };

      final catalog = LineageChoiceRowMapper.toCatalog(
        lineageRows: rows,
        names: names,
        lineageIdsWithInnateSpells: const {},
      );

      final options = catalog.optionsFor(5);
      expect(options.map((o) => o.name), [
        'Dragon noir',
        'Dragon bleu',
        'Dragon rouge',
        'Dragon blanc',
      ]);
      expect(options.map((o) => o.subtitle), [
        'Souffle et résistance : Acide',
        'Souffle et résistance : Foudre',
        'Souffle et résistance : Feu',
        'Souffle et résistance : Froid',
      ]);
    });

    test('Tieffelin (race_id = 9) : titre = nom brut, sous-titre sorts '
        'innés quand lineageIdsWithInnateSpells le contient', () {
      final catalog = LineageChoiceRowMapper.toCatalog(
        lineageRows: const [
          {'id': 31, 'race_id': 9, 'damage_type': null},
          {'id': 32, 'race_id': 9, 'damage_type': null},
          {'id': 33, 'race_id': 9, 'damage_type': null},
        ],
        names: const {'31': 'Abyssal', '32': 'Chtonien', '33': 'Infernal'},
        lineageIdsWithInnateSpells: const {31, 32, 33},
      );

      final options = catalog.optionsFor(9);
      expect(options.map((o) => o.name), ['Abyssal', 'Chtonien', 'Infernal']);
      expect(
        options.every(
          (o) =>
              o.subtitle ==
              'Détermine les sorts innés acquis (niveaux 1, 3 et 5)',
        ),
        isTrue,
      );
    });

    test('Goliath (race_id = 24) : titre = nom brut, aucun sous-titre '
        '(aucune donnée mécanique stockée)', () {
      final catalog = LineageChoiceRowMapper.toCatalog(
        lineageRows: const [
          {'id': 25, 'race_id': 24, 'damage_type': null},
          {'id': 28, 'race_id': 24, 'damage_type': null},
        ],
        names: const {'25': 'Géant des nuages', '28': 'Géant des collines'},
        lineageIdsWithInnateSpells: const {},
      );

      final options = catalog.optionsFor(24);
      expect(options.map((o) => o.name), [
        'Géant des nuages',
        'Géant des collines',
      ]);
      expect(options.every((o) => o.subtitle == null), isTrue);
    });

    test('une ligne sans id/race_id exploitable est ignorée', () {
      final catalog = LineageChoiceRowMapper.toCatalog(
        lineageRows: const [
          {'id': null, 'race_id': 9, 'damage_type': null},
          {'id': 31, 'race_id': null, 'damage_type': null},
        ],
        names: const {},
        lineageIdsWithInnateSpells: const {},
      );

      expect(catalog.optionsByRaceId, isEmpty);
    });

    test('nom non résolu : libellé générique', () {
      final catalog = LineageChoiceRowMapper.toCatalog(
        lineageRows: const [
          {'id': 99, 'race_id': 24, 'damage_type': null},
        ],
        names: const {},
        lineageIdsWithInnateSpells: const {},
      );

      expect(catalog.optionsFor(24).single.name, 'Lignée #99');
    });
  });
}
