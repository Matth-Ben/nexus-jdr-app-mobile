import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/invocations_known_progression.dart';

void main() {
  group('InvocationsKnownProgression.newInvocationsAt', () {
    test('0 au niveau 1 (RAW : aucune invocation avant le niveau 2)', () {
      expect(InvocationsKnownProgression.newInvocationsAt(1), 0);
    });

    test('niveaux déclencheurs RAW (delta strictement positif) : '
        '2, 5, 7, 9, 12, 15, 18', () {
      const triggeringLevels = {2, 5, 7, 9, 12, 15, 18};
      for (var level = 1; level <= 20; level++) {
        final delta = InvocationsKnownProgression.newInvocationsAt(level);
        if (triggeringLevels.contains(level)) {
          expect(delta, greaterThan(0), reason: 'niveau $level');
        } else {
          expect(delta, 0, reason: 'niveau $level');
        }
      }
    });

    test('valeurs exactes des deltas aux niveaux déclencheurs', () {
      expect(InvocationsKnownProgression.newInvocationsAt(2), 2);
      expect(InvocationsKnownProgression.newInvocationsAt(5), 1);
      expect(InvocationsKnownProgression.newInvocationsAt(7), 1);
      expect(InvocationsKnownProgression.newInvocationsAt(9), 1);
      expect(InvocationsKnownProgression.newInvocationsAt(12), 1);
      expect(InvocationsKnownProgression.newInvocationsAt(15), 1);
      expect(InvocationsKnownProgression.newInvocationsAt(18), 1);
    });

    test('total connu au niveau 20 : 8 invocations (RAW, table PHB/SRD)', () {
      expect(InvocationsKnownProgression.invocationsKnownByLevel[20], 8);
    });

    test('niveau hors plage 1-20 : 0 (défensif)', () {
      expect(InvocationsKnownProgression.newInvocationsAt(0), 0);
      expect(InvocationsKnownProgression.newInvocationsAt(21), 0);
    });

    test(
      'somme des deltas 1 à 20 == valeur finale à 20 (cohérence interne)',
      () {
        var sum = 0;
        for (var level = 1; level <= 20; level++) {
          sum += InvocationsKnownProgression.newInvocationsAt(level);
        }
        expect(sum, InvocationsKnownProgression.invocationsKnownByLevel[20]);
      },
    );
  });
}
