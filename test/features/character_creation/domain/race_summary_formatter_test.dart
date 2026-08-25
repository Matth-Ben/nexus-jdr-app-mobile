import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/race_summary_formatter.dart';
import 'package:personnages/features/character_creation/domain/race_trait.dart';

void main() {
  group('RaceSummaryFormatter.format', () {
    test('cas Humain : les 6 caractéristiques à +1 -> texte spécial plutôt que '
        'la liste', () {
      final summary = RaceSummaryFormatter.format(
        abilityBonuses: const {
          'str': 1,
          'dex': 1,
          'con': 1,
          'int': 1,
          'wis': 1,
          'cha': 1,
        },
        traits: const [],
      );

      expect(summary, '+1 à toutes les caractéristiques');
    });

    test('une seule caractéristique bonifiée, avec deux traits (Elfe)', () {
      final summary = RaceSummaryFormatter.format(
        abilityBonuses: const {'dex': 2},
        traits: const [
          RaceTrait(name: 'Vision dans le noir', description: '...'),
          RaceTrait(name: 'Transe', description: '...'),
        ],
      );

      expect(summary, '+2 Dex · Vision dans le noir · Transe');
    });

    test('plusieurs caractéristiques bonifiées, dans l\'ordre canonique '
        'For/Dex/Con/Int/Sag/Cha (Demi-orque)', () {
      final summary = RaceSummaryFormatter.format(
        abilityBonuses: const {'con': 1, 'str': 2},
        traits: const [RaceTrait(name: 'Robustesse', description: '...')],
      );

      expect(summary, '+2 For, +1 Con · Robustesse');
    });

    test('ignore la clé spéciale choice_others dans le résumé court', () {
      final summary = RaceSummaryFormatter.format(
        abilityBonuses: const {
          'cha': 2,
          'choice_others': {'amount': 1, 'count': 2},
        },
        traits: const [],
      );

      expect(summary, '+2 Cha');
    });

    test('plus de deux traits : seuls les deux premiers sont affichés', () {
      final summary = RaceSummaryFormatter.format(
        abilityBonuses: const {'dex': 2},
        traits: const [
          RaceTrait(name: 'Premier', description: '...'),
          RaceTrait(name: 'Second', description: '...'),
          RaceTrait(name: 'Troisième', description: '...'),
        ],
      );

      expect(summary, '+2 Dex · Premier · Second');
    });

    test('aucun bonus de caractéristique ni trait -> chaîne vide', () {
      final summary = RaceSummaryFormatter.format(
        abilityBonuses: const {},
        traits: const [],
      );

      expect(summary, isEmpty);
    });

    test('uniquement choice_others (aucune caractéristique fixe) -> seuls les '
        'traits apparaissent', () {
      final summary = RaceSummaryFormatter.format(
        abilityBonuses: const {
          'choice_others': {'amount': 1, 'count': 2},
        },
        traits: const [RaceTrait(name: 'Polyvalence', description: '...')],
      );

      expect(summary, 'Polyvalence');
    });
  });
}
