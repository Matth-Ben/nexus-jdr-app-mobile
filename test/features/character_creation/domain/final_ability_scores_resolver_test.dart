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
  );
  const hautElfe = SubraceOption(
    id: 10,
    raceId: 1,
    name: 'Haut-elfe',
    abilityBonuses: {'int': 1},
    traits: [],
  );
  final catalog = const RaceCatalog(races: [elfe], subraces: [hautElfe]);

  test('additionne le bonus racial au score de base pour chaque '
      'caractéristique', () {
    final result = FinalAbilityScoresResolver.resolve(
      baseScores: const {'str': 15, 'dex': 14, 'con': 13},
      raceCatalog: catalog,
      raceId: 1,
      subraceId: null,
    );

    expect(result, {'str': 15, 'dex': 16, 'con': 13});
  });

  test('cumule le bonus de race ET de sous-race', () {
    final result = FinalAbilityScoresResolver.resolve(
      baseScores: const {'int': 10},
      raceCatalog: catalog,
      raceId: 1,
      subraceId: 10,
    );

    expect(result, {'int': 11});
  });

  test('raceId null (race personnalisée) -> aucun bonus appliqué', () {
    final result = FinalAbilityScoresResolver.resolve(
      baseScores: const {'str': 8, 'dex': 12},
      raceCatalog: catalog,
      raceId: null,
      subraceId: null,
    );

    expect(result, {'str': 8, 'dex': 12});
  });

  test('baseScores vide -> map vide', () {
    final result = FinalAbilityScoresResolver.resolve(
      baseScores: const {},
      raceCatalog: catalog,
      raceId: 1,
      subraceId: null,
    );

    expect(result, isEmpty);
  });
}
