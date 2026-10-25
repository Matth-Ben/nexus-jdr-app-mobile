// Tests unitaires de `RaceCatalog.isUnifiedRaceIn2024` — chantier
// "différenciation 2014/2024 pour les races" (24/10/2026).
//
// (`subracesOf`/les getters générés par freezed ne sont pas retestés ici :
// seule la logique ajoutée par ce chantier est couverte.)

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/race_catalog.dart';
import 'package:personnages/features/character_creation/domain/race_option.dart';
import 'package:personnages/features/character_creation/domain/subrace_option.dart';

void main() {
  group('isUnifiedRaceIn2024', () {
    test('Nain : traits2024 non nul sur la race, aucune sous-race n\'a de '
        'traits2024 propre -> true', () {
      const nain = RaceOption(
        id: 3,
        name: 'Nain',
        abilityBonuses: {'con': 2},
        traits: [],
        source: '',
        traits2024: [],
      );
      const nainDesCollines = SubraceOption(
        id: 7,
        raceId: 3,
        name: 'Nain des collines',
        abilityBonuses: {'wis': 1},
        traits: [],
      );
      const nainDesMontagnes = SubraceOption(
        id: 8,
        raceId: 3,
        name: 'Nain des montagnes',
        abilityBonuses: {'str': 2},
        traits: [],
      );
      final catalog = const RaceCatalog(
        races: [nain],
        subraces: [nainDesCollines, nainDesMontagnes],
      );

      expect(catalog.isUnifiedRaceIn2024(3), isTrue);
    });

    test('Elfe : traits2024 non nul sur la race, MAIS au moins une sous-race a '
        'elle-même un traits2024 propre -> false (choix de lignée géré par '
        'LineageStepScreen, pas par l\'unification)', () {
      const elfe = RaceOption(
        id: 1,
        name: 'Elfe',
        abilityBonuses: {'dex': 2},
        traits: [],
        source: '',
        traits2024: [],
      );
      const hautElfe2024 = SubraceOption(
        id: 10,
        raceId: 1,
        name: 'Haut-elfe',
        abilityBonuses: {'int': 1},
        traits: [],
        traits2024: [],
      );
      final catalog = const RaceCatalog(
        races: [elfe],
        subraces: [hautElfe2024],
      );

      expect(catalog.isUnifiedRaceIn2024(1), isFalse);
    });

    test('race sans traits2024 (pas de contenu 2024 propre) -> false', () {
      const demiElfe = RaceOption(
        id: 7,
        name: 'Demi-elfe',
        abilityBonuses: {'cha': 2},
        traits: [],
        source: '',
      );
      final catalog = const RaceCatalog(races: [demiElfe], subraces: []);

      expect(catalog.isUnifiedRaceIn2024(7), isFalse);
    });

    test('race avec traits2024 mais SANS aucune sous-race -> false (rien à '
        'unifier, voir Drakéide/Tieffelin/Humain)', () {
      const humain = RaceOption(
        id: 2,
        name: 'Humain',
        abilityBonuses: {},
        traits: [],
        source: '',
        traits2024: [],
      );
      final catalog = const RaceCatalog(races: [humain], subraces: []);

      expect(catalog.isUnifiedRaceIn2024(2), isFalse);
    });

    test('raceId introuvable dans le catalogue -> false, pas de crash', () {
      final catalog = const RaceCatalog(races: [], subraces: []);

      expect(catalog.isUnifiedRaceIn2024(999), isFalse);
    });
  });
}
