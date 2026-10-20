import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/maneuvers_known_progression.dart';

void main() {
  group('ManeuversKnownProgression.newManeuversAt', () {
    test('0 aux niveaux 1-2 (RAW : aucune manœuvre avant le niveau 3)', () {
      expect(ManeuversKnownProgression.newManeuversAt(1), 0);
      expect(ManeuversKnownProgression.newManeuversAt(2), 0);
    });

    test('niveaux déclencheurs RAW (delta strictement positif) : '
        '3, 7, 10, 15', () {
      const triggeringLevels = {3, 7, 10, 15};
      for (var level = 1; level <= 20; level++) {
        final delta = ManeuversKnownProgression.newManeuversAt(level);
        if (triggeringLevels.contains(level)) {
          expect(delta, greaterThan(0), reason: 'niveau $level');
        } else {
          expect(delta, 0, reason: 'niveau $level');
        }
      }
    });

    test('valeurs exactes des deltas aux niveaux déclencheurs', () {
      expect(ManeuversKnownProgression.newManeuversAt(3), 3);
      expect(ManeuversKnownProgression.newManeuversAt(7), 2);
      expect(ManeuversKnownProgression.newManeuversAt(10), 2);
      expect(ManeuversKnownProgression.newManeuversAt(15), 2);
    });

    test('total connu au niveau 20 : 9 manœuvres (RAW, table PHB/SRD)', () {
      expect(ManeuversKnownProgression.maneuversKnownByLevel[20], 9);
    });

    test('niveau hors plage 1-20 : 0 (défensif)', () {
      expect(ManeuversKnownProgression.newManeuversAt(0), 0);
      expect(ManeuversKnownProgression.newManeuversAt(21), 0);
    });

    test(
      'somme des deltas 1 à 20 == valeur finale à 20 (cohérence interne)',
      () {
        var sum = 0;
        for (var level = 1; level <= 20; level++) {
          sum += ManeuversKnownProgression.newManeuversAt(level);
        }
        expect(sum, ManeuversKnownProgression.maneuversKnownByLevel[20]);
      },
    );

    test('nom de sous-classe RAW', () {
      expect(ManeuversKnownProgression.subclassName, 'Maître de guerre');
    });
  });
}
