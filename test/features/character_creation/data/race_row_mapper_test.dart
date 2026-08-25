import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/data/race_row_mapper.dart';
import 'package:personnages/features/character_creation/domain/race_trait.dart';

void main() {
  group('collectIds', () {
    test('normalise les ids int en String et déduplique', () {
      final rows = [
        {'id': 1},
        {'id': 2},
        {'id': 1},
      ];
      expect(RaceRowMapper.collectIds(rows), {'1', '2'});
    });

    test('ignore les ids nuls', () {
      expect(RaceRowMapper.collectIds([{}]), isEmpty);
    });
  });

  group('parseTranslatedNames', () {
    test('lit les colonnes réelles entity_id/value', () {
      final names = RaceRowMapper.parseTranslatedNames([
        {'entity_id': '1', 'value': 'Elfe'},
        {'entity_id': '2', 'value': 'Nain'},
      ]);
      expect(names, {'1': 'Elfe', '2': 'Nain'});
    });

    test('ignore une ligne sans entity_id ou sans value exploitable', () {
      final names = RaceRowMapper.parseTranslatedNames([
        {'entity_id': '1', 'value': null},
        {'entity_id': null, 'value': 'Orphelin'},
        {'entity_id': '3', 'value': 'Halfelin'},
      ]);
      expect(names, {'3': 'Halfelin'});
    });
  });

  group('parseAbilityBonuses', () {
    test('convertit un jsonb Map en Map<String, dynamic>', () {
      expect(RaceRowMapper.parseAbilityBonuses({'dex': 2}), {'dex': 2});
    });

    test('conserve la clé spéciale choice_others telle quelle', () {
      final parsed = RaceRowMapper.parseAbilityBonuses({
        'cha': 2,
        'choice_others': {'amount': 1, 'count': 2},
      });
      expect(parsed['cha'], 2);
      expect(parsed['choice_others'], {'amount': 1, 'count': 2});
    });

    test('null ou type inattendu -> map vide', () {
      expect(RaceRowMapper.parseAbilityBonuses(null), isEmpty);
      expect(RaceRowMapper.parseAbilityBonuses('pas une map'), isEmpty);
    });
  });

  group('parseTraits', () {
    test('parse une liste de {name, description}', () {
      final traits = RaceRowMapper.parseTraits([
        {'name': 'Vision dans le noir', 'description': '...'},
        {'name': 'Transe', 'description': '...'},
      ]);
      expect(traits, [
        const RaceTrait(name: 'Vision dans le noir', description: '...'),
        const RaceTrait(name: 'Transe', description: '...'),
      ]);
    });

    test('ignore une entrée sans name exploitable', () {
      final traits = RaceRowMapper.parseTraits([
        {'description': 'sans nom'},
        {'name': 'Robustesse', 'description': '...'},
      ]);
      expect(traits, [const RaceTrait(name: 'Robustesse', description: '...')]);
    });

    test('null ou type inattendu -> liste vide', () {
      expect(RaceRowMapper.parseTraits(null), isEmpty);
      expect(RaceRowMapper.parseTraits('pas une liste'), isEmpty);
    });

    test('description manquante -> chaîne vide plutôt que crash', () {
      final traits = RaceRowMapper.parseTraits([
        {'name': 'Chanceux'},
      ]);
      expect(traits.single.description, isEmpty);
    });
  });

  group('toRaceOption', () {
    test('résout le nom via la map de traductions', () {
      final race = RaceRowMapper.toRaceOption(
        {
          'id': 2,
          'ability_bonuses': {'dex': 2},
          'traits': [
            {'name': 'Vision dans le noir', 'description': '...'},
          ],
        },
        names: {'2': 'Elfe'},
      );

      expect(race.id, 2);
      expect(race.name, 'Elfe');
      expect(race.summaryLine, '+2 Dex · Vision dans le noir');
    });

    test(
      'id sans traduction résolue -> libellé générique plutôt que crash',
      () {
        final race = RaceRowMapper.toRaceOption({
          'id': 99,
          'ability_bonuses': {},
          'traits': [],
        }, names: const {});

        expect(race.name, 'Race #99');
      },
    );
  });

  group('toSubraceOption', () {
    test('résout le nom via la map de traductions et porte le raceId', () {
      final subrace = RaceRowMapper.toSubraceOption(
        {
          'id': 5,
          'race_id': 2,
          'ability_bonuses': {'int': 1},
          'traits': <Map<String, dynamic>>[],
        },
        names: {'5': 'Haut-elfe'},
      );

      expect(subrace.id, 5);
      expect(subrace.raceId, 2);
      expect(subrace.name, 'Haut-elfe');
    });

    test(
      'id sans traduction résolue -> libellé générique plutôt que crash',
      () {
        final subrace = RaceRowMapper.toSubraceOption({
          'id': 42,
          'race_id': 2,
          'ability_bonuses': {},
          'traits': [],
        }, names: const {});

        expect(subrace.name, 'Sous-race #42');
      },
    );
  });
}
