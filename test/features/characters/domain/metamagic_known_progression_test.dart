import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/metamagic_known_progression.dart';

void main() {
  group('MetamagicKnownProgression.newMetamagicOptionsAt', () {
    test('0 au niveau 1 et 2 (RAW : aucune option avant le niveau 3)', () {
      expect(MetamagicKnownProgression.newMetamagicOptionsAt(1), 0);
      expect(MetamagicKnownProgression.newMetamagicOptionsAt(2), 0);
    });

    test(
      'niveaux déclencheurs RAW (delta strictement positif) : 3, 10, 17',
      () {
        const triggeringLevels = {3, 10, 17};
        for (var level = 1; level <= 20; level++) {
          final delta = MetamagicKnownProgression.newMetamagicOptionsAt(level);
          if (triggeringLevels.contains(level)) {
            expect(delta, greaterThan(0), reason: 'niveau $level');
          } else {
            expect(delta, 0, reason: 'niveau $level');
          }
        }
      },
    );

    test('valeurs exactes des deltas aux niveaux déclencheurs (+1 chacun)', () {
      expect(MetamagicKnownProgression.newMetamagicOptionsAt(3), 2);
      expect(MetamagicKnownProgression.newMetamagicOptionsAt(10), 1);
      expect(MetamagicKnownProgression.newMetamagicOptionsAt(17), 1);
    });

    test('total connu au niveau 20 : 4 options (RAW)', () {
      expect(MetamagicKnownProgression.metamagicKnownByLevel[20], 4);
    });

    test('niveau hors plage 1-20 : 0 (défensif)', () {
      expect(MetamagicKnownProgression.newMetamagicOptionsAt(0), 0);
      expect(MetamagicKnownProgression.newMetamagicOptionsAt(21), 0);
    });

    test(
      'somme des deltas 1 à 20 == valeur finale à 20 (cohérence interne)',
      () {
        var sum = 0;
        for (var level = 1; level <= 20; level++) {
          sum += MetamagicKnownProgression.newMetamagicOptionsAt(level);
        }
        expect(sum, MetamagicKnownProgression.metamagicKnownByLevel[20]);
      },
    );

    test('nom de classe RAW (aptitude de classe, pas de sous-classe)', () {
      expect(MetamagicKnownProgression.className, 'Ensorceleur');
    });
  });
}
