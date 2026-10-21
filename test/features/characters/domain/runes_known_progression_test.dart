import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/runes_known_progression.dart';

void main() {
  group('RunesKnownProgression.newRunesAt', () {
    test('0 aux niveaux 1-2 (RAW : aucune rune avant le niveau 3)', () {
      expect(RunesKnownProgression.newRunesAt(1), 0);
      expect(RunesKnownProgression.newRunesAt(2), 0);
    });

    test('niveaux déclencheurs RAW (delta strictement positif) : 3, 10, 18 '
        '(PAS 7, contrairement aux manœuvres/tirs arcaniques)', () {
      const triggeringLevels = {3, 10, 18};
      for (var level = 1; level <= 20; level++) {
        final delta = RunesKnownProgression.newRunesAt(level);
        if (triggeringLevels.contains(level)) {
          expect(delta, greaterThan(0), reason: 'niveau $level');
        } else {
          expect(delta, 0, reason: 'niveau $level (en particulier 7)');
        }
      }
    });

    test('valeurs exactes des deltas aux niveaux déclencheurs', () {
      expect(RunesKnownProgression.newRunesAt(3), 2);
      expect(RunesKnownProgression.newRunesAt(10), 1);
      // Capstone "Maître des runes" : toutes les runes restantes (3 sur 6).
      expect(RunesKnownProgression.newRunesAt(18), 3);
    });

    test('total connu au niveau 20 : 6 runes (RAW, toutes connues)', () {
      expect(RunesKnownProgression.runesKnownByLevel[20], 6);
    });

    test('niveau hors plage 1-20 : 0 (défensif)', () {
      expect(RunesKnownProgression.newRunesAt(0), 0);
      expect(RunesKnownProgression.newRunesAt(21), 0);
    });

    test(
      'somme des deltas 1 à 20 == valeur finale à 20 (cohérence interne)',
      () {
        var sum = 0;
        for (var level = 1; level <= 20; level++) {
          sum += RunesKnownProgression.newRunesAt(level);
        }
        expect(sum, RunesKnownProgression.runesKnownByLevel[20]);
      },
    );

    test('nom de sous-classe RAW', () {
      expect(RunesKnownProgression.subclassName, 'Chevalier runique');
    });
  });
}
