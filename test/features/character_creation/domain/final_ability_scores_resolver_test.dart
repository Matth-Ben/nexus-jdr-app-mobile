// Tests unitaires de la résolution des scores de caractéristiques finaux à
// l'étape 9/9 "Récapitulatif"
// (`lib/features/character_creation/domain/final_ability_scores_resolver.dart`).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/final_ability_scores_resolver.dart';
import 'package:personnages/features/character_creation/domain/race_catalog.dart';
import 'package:personnages/features/character_creation/domain/race_option.dart';
import 'package:personnages/features/character_creation/domain/subrace_option.dart';

void main() {
  const elfe = RaceOption(
    id: 1,
    name: 'Elfe',
    abilityBonuses: {'dex': 2},
    traits: [],
    source: '',
  );
  const hautElfe = SubraceOption(
    id: 10,
    raceId: 1,
    name: 'Haut-elfe',
    abilityBonuses: {'int': 1},
    traits: [],
  );
  final catalog = const RaceCatalog(races: [elfe], subraces: [hautElfe]);

  test('édition 2014 : additionne le bonus racial au score de base pour '
      'chaque caractéristique', () {
    final result = FinalAbilityScoresResolver.resolve(
      baseScores: const {'str': 15, 'dex': 14, 'con': 13},
      raceCatalog: catalog,
      raceId: 1,
      subraceId: null,
      edition: '2014',
    );

    expect(result, {'str': 15, 'dex': 16, 'con': 13});
  });

  test('édition 2014 : cumule le bonus de race ET de sous-race', () {
    final result = FinalAbilityScoresResolver.resolve(
      baseScores: const {'int': 10},
      raceCatalog: catalog,
      raceId: 1,
      subraceId: 10,
      edition: '2014',
    );

    expect(result, {'int': 11});
  });

  test(
    'édition 2014 : raceId null (race personnalisée) -> aucun bonus appliqué',
    () {
      final result = FinalAbilityScoresResolver.resolve(
        baseScores: const {'str': 8, 'dex': 12},
        raceCatalog: catalog,
        raceId: null,
        subraceId: null,
        edition: '2014',
      );

      expect(result, {'str': 8, 'dex': 12});
    },
  );

  test('édition 2014 : baseScores vide -> map vide', () {
    final result = FinalAbilityScoresResolver.resolve(
      baseScores: const {},
      raceCatalog: catalog,
      raceId: 1,
      subraceId: null,
      edition: '2014',
    );

    expect(result, isEmpty);
  });

  test('édition 2024 : le bonus racial FIXE du catalogue est ignoré (RAW 2024, '
      'l\'espèce ne donne plus de bonus de caractéristique) — chantier '
      'différenciation 2014/2024 (24/10/2026)', () {
    final result = FinalAbilityScoresResolver.resolve(
      baseScores: const {'str': 15, 'dex': 14, 'con': 13},
      raceCatalog: catalog,
      raceId: 1,
      subraceId: 10,
      edition: '2024',
    );

    expect(result, {'str': 15, 'dex': 14, 'con': 13});
  });

  test('édition 2024 : seul le choix libre du joueur (racialBonusChoices) est '
      'appliqué, le bonus fixe du catalogue reste ignoré', () {
    final result = FinalAbilityScoresResolver.resolve(
      baseScores: const {'str': 15, 'dex': 14, 'con': 13},
      raceCatalog: catalog,
      raceId: 1,
      subraceId: 10,
      edition: '2024',
      racialBonusChoices: const {'dex': 2, 'con': 1},
    );

    expect(result, {'str': 15, 'dex': 16, 'con': 14});
  });
}
