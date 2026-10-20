import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/arcane_shots_known_progression.dart';

void main() {
  group('ArcaneShotsKnownProgression.newArcaneShotsAt', () {
    test('0 aux niveaux 1-2 (RAW : aucun tir arcanique avant le niveau 3)', () {
      expect(ArcaneShotsKnownProgression.newArcaneShotsAt(1), 0);
      expect(ArcaneShotsKnownProgression.newArcaneShotsAt(2), 0);
    });

    test('niveaux déclencheurs RAW (delta strictement positif) : '
        '3, 7, 10, 15, 18', () {
      const triggeringLevels = {3, 7, 10, 15, 18};
      for (var level = 1; level <= 20; level++) {
        final delta = ArcaneShotsKnownProgression.newArcaneShotsAt(level);
        if (triggeringLevels.contains(level)) {
          expect(delta, greaterThan(0), reason: 'niveau $level');
        } else {
          expect(delta, 0, reason: 'niveau $level');
        }
      }
    });

    test(
      'valeurs exactes des deltas aux niveaux déclencheurs (+1 seulement)',
      () {
        expect(ArcaneShotsKnownProgression.newArcaneShotsAt(3), 2);
        expect(ArcaneShotsKnownProgression.newArcaneShotsAt(7), 1);
        expect(ArcaneShotsKnownProgression.newArcaneShotsAt(10), 1);
        expect(ArcaneShotsKnownProgression.newArcaneShotsAt(15), 1);
        expect(ArcaneShotsKnownProgression.newArcaneShotsAt(18), 1);
      },
    );

    test('total connu au niveau 20 : 6 tirs arcaniques (RAW)', () {
      expect(ArcaneShotsKnownProgression.arcaneShotsKnownByLevel[20], 6);
    });

    test('niveau hors plage 1-20 : 0 (défensif)', () {
      expect(ArcaneShotsKnownProgression.newArcaneShotsAt(0), 0);
      expect(ArcaneShotsKnownProgression.newArcaneShotsAt(21), 0);
    });

    test(
      'somme des deltas 1 à 20 == valeur finale à 20 (cohérence interne)',
      () {
        var sum = 0;
        for (var level = 1; level <= 20; level++) {
          sum += ArcaneShotsKnownProgression.newArcaneShotsAt(level);
        }
        expect(sum, ArcaneShotsKnownProgression.arcaneShotsKnownByLevel[20]);
      },
    );

    test('nom de sous-classe RAW', () {
      expect(ArcaneShotsKnownProgression.subclassName, 'Archer arcanique');
    });
  });
}
