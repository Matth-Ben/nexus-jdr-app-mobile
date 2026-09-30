// Tests unitaires des bonus raciaux au choix
// (`lib/features/character_creation/domain/racial_bonus_choice.dart`) et de
// leur prise en compte dans les scores finaux (`FinalAbilityScoresResolver`).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/final_ability_scores_resolver.dart';
import 'package:personnages/features/character_creation/domain/race_catalog.dart';
import 'package:personnages/features/character_creation/domain/race_summary_formatter.dart';
import 'package:personnages/features/character_creation/domain/racial_bonus_choice.dart';

void main() {
  group('RacialBonusChoiceSpec.from', () {
    test('race sans choix -> null', () {
      expect(
        RacialBonusChoiceSpec.from(raceBonuses: const {'dex': 2}),
        isNull,
      );
      expect(RacialBonusChoiceSpec.from(raceBonuses: const {}), isNull);
    });

    test('choice_others (Demi-elfe) : exclut la caractéristique à bonus fixe', () {
      final spec = RacialBonusChoiceSpec.from(
        raceBonuses: const {
          'cha': 2,
          'choice_others': {'count': 2, 'amount': 1},
        },
      );
      expect(spec, isA<OthersRacialBonusSpec>());
      final others = spec! as OthersRacialBonusSpec;
      expect(others.count, 2);
      expect(others.amount, 1);
      expect(others.excluded, {'cha'});
    });

    test('choice_flexible -> règle flexible', () {
      expect(
        RacialBonusChoiceSpec.from(raceBonuses: const {'choice_flexible': true}),
        isA<FlexibleRacialBonusSpec>(),
      );
    });
  });

  group('OthersRacialBonusSpec.isComplete', () {
    const spec = OthersRacialBonusSpec(count: 2, amount: 1, excluded: {'cha'});

    test('deux caractéristiques différentes de CHA à +1 : complet', () {
      expect(spec.isComplete(const {'dex': 1, 'con': 1}), isTrue);
    });

    test('incomplet, caractéristique exclue ou montant faux : refusé', () {
      expect(spec.isComplete(const {'dex': 1}), isFalse);
      expect(spec.isComplete(const {'dex': 1, 'cha': 1}), isFalse);
      expect(spec.isComplete(const {'dex': 2, 'con': 1}), isFalse);
    });
  });

  group('FlexibleRacialBonusSpec.isComplete', () {
    const spec = FlexibleRacialBonusSpec();

    test('+2/+1 et +1/+1/+1 acceptés', () {
      expect(spec.isComplete(const {'str': 2, 'con': 1}), isTrue);
      expect(spec.isComplete(const {'str': 1, 'con': 1, 'wis': 1}), isTrue);
    });

    test('répartitions invalides refusées', () {
      expect(spec.isComplete(const {}), isFalse);
      expect(spec.isComplete(const {'str': 2}), isFalse);
      expect(spec.isComplete(const {'str': 2, 'con': 2}), isFalse);
      expect(spec.isComplete(const {'str': 1, 'con': 1}), isFalse);
      expect(spec.isComplete(const {'luck': 2, 'con': 1}), isFalse);
    });
  });

  test('FinalAbilityScoresResolver ajoute les bonus au choix aux bonus fixes', () {
    const catalog = RaceCatalog(races: [], subraces: []);
    final scores = FinalAbilityScoresResolver.resolve(
      baseScores: const {'str': 15, 'dex': 14, 'con': 13},
      raceCatalog: catalog,
      raceId: null,
      subraceId: null,
      racialBonusChoices: const {'str': 2, 'con': 1},
    );
    expect(scores, {'str': 17, 'dex': 14, 'con': 14});
  });

  test('RaceSummaryFormatter affiche la règle des bonus au choix', () {
    expect(
      RaceSummaryFormatter.formatAbilityBonuses(const {
        'cha': 2,
        'choice_others': {'count': 2, 'amount': 1},
      }),
      '+2 Cha, +1 à 2 caractéristiques au choix',
    );
    expect(
      RaceSummaryFormatter.formatAbilityBonuses(const {'choice_flexible': true}),
      '+2 à une caractéristique et +1 à une autre, ou +1 à trois',
    );
  });
}
