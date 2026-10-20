import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/infusions_known_progression.dart';

void main() {
  group('InfusionsKnownProgression.newInfusionsAt', () {
    test('0 au niveau 1 (RAW : aucune infusion avant le niveau 2)', () {
      expect(InfusionsKnownProgression.newInfusionsAt(1), 0);
    });

    test(
      'niveaux déclencheurs RAW (delta strictement positif) : 2, 6, 10, 14, 18',
      () {
        const triggeringLevels = {2, 6, 10, 14, 18};
        for (var level = 1; level <= 20; level++) {
          final delta = InfusionsKnownProgression.newInfusionsAt(level);
          if (triggeringLevels.contains(level)) {
            expect(delta, greaterThan(0), reason: 'niveau $level');
          } else {
            expect(delta, 0, reason: 'niveau $level');
          }
        }
      },
    );

    test('valeurs exactes des deltas aux niveaux déclencheurs (+2 chacun)', () {
      expect(InfusionsKnownProgression.newInfusionsAt(2), 4);
      expect(InfusionsKnownProgression.newInfusionsAt(6), 2);
      expect(InfusionsKnownProgression.newInfusionsAt(10), 2);
      expect(InfusionsKnownProgression.newInfusionsAt(14), 2);
      expect(InfusionsKnownProgression.newInfusionsAt(18), 2);
    });

    test('total connu au niveau 20 : 12 infusions (RAW)', () {
      expect(InfusionsKnownProgression.infusionsKnownByLevel[20], 12);
    });

    test('niveau hors plage 1-20 : 0 (défensif)', () {
      expect(InfusionsKnownProgression.newInfusionsAt(0), 0);
      expect(InfusionsKnownProgression.newInfusionsAt(21), 0);
    });

    test(
      'somme des deltas 1 à 20 == valeur finale à 20 (cohérence interne)',
      () {
        var sum = 0;
        for (var level = 1; level <= 20; level++) {
          sum += InfusionsKnownProgression.newInfusionsAt(level);
        }
        expect(sum, InfusionsKnownProgression.infusionsKnownByLevel[20]);
      },
    );

    test('nom de classe RAW (aptitude de classe, pas de sous-classe)', () {
      expect(InfusionsKnownProgression.className, 'Artificier');
    });
  });
}
