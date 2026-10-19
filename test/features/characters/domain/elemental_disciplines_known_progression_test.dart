import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/elemental_disciplines_known_progression.dart';

void main() {
  group('ElementalDisciplinesKnownProgression.newDisciplinesAt', () {
    test('0 aux niveaux 1-2 (RAW : aucune discipline avant le niveau 3)', () {
      expect(ElementalDisciplinesKnownProgression.newDisciplinesAt(1), 0);
      expect(ElementalDisciplinesKnownProgression.newDisciplinesAt(2), 0);
    });

    test('niveaux déclencheurs RAW (delta strictement positif) : '
        '3, 6, 11, 17', () {
      const triggeringLevels = {3, 6, 11, 17};
      for (var level = 1; level <= 20; level++) {
        final delta = ElementalDisciplinesKnownProgression.newDisciplinesAt(
          level,
        );
        if (triggeringLevels.contains(level)) {
          expect(delta, greaterThan(0), reason: 'niveau $level');
        } else {
          expect(delta, 0, reason: 'niveau $level');
        }
      }
    });

    test('valeurs exactes des deltas aux niveaux déclencheurs', () {
      expect(ElementalDisciplinesKnownProgression.newDisciplinesAt(3), 2);
      expect(ElementalDisciplinesKnownProgression.newDisciplinesAt(6), 1);
      expect(ElementalDisciplinesKnownProgression.newDisciplinesAt(11), 1);
      expect(ElementalDisciplinesKnownProgression.newDisciplinesAt(17), 1);
    });

    test('total connu au niveau 20 : 5 disciplines (RAW, table PHB/SRD)', () {
      expect(
        ElementalDisciplinesKnownProgression.disciplinesKnownByLevel[20],
        5,
      );
    });

    test('niveau hors plage 1-20 : 0 (défensif)', () {
      expect(ElementalDisciplinesKnownProgression.newDisciplinesAt(0), 0);
      expect(ElementalDisciplinesKnownProgression.newDisciplinesAt(21), 0);
    });

    test(
      'somme des deltas 1 à 20 == valeur finale à 20 (cohérence interne)',
      () {
        var sum = 0;
        for (var level = 1; level <= 20; level++) {
          sum += ElementalDisciplinesKnownProgression.newDisciplinesAt(level);
        }
        expect(
          sum,
          ElementalDisciplinesKnownProgression.disciplinesKnownByLevel[20],
        );
      },
    );
  });
}
