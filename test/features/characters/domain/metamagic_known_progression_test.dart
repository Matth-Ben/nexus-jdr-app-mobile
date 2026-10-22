import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/metamagic_known_progression.dart';

void main() {
  group('MetamagicKnownProgression.newMetamagicOptionsAt', () {
    test('édition 2014 (défaut implicite) : 0 aux niveaux 1 et 2 (RAW : aucune '
        'option avant le niveau 3)', () {
      expect(MetamagicKnownProgression.newMetamagicOptionsAt(1), 0);
      expect(MetamagicKnownProgression.newMetamagicOptionsAt(2), 0);
    });

    test('édition 2014 (défaut implicite) : niveaux déclencheurs RAW (delta '
        'strictement positif) : 3, 10, 17', () {
      const triggeringLevels = {3, 10, 17};
      for (var level = 1; level <= 20; level++) {
        final delta = MetamagicKnownProgression.newMetamagicOptionsAt(level);
        if (triggeringLevels.contains(level)) {
          expect(delta, greaterThan(0), reason: 'niveau $level');
        } else {
          expect(delta, 0, reason: 'niveau $level');
        }
      }
    });

    test('édition 2014 (défaut implicite) : valeurs exactes des deltas aux '
        'niveaux déclencheurs (+1 chacun)', () {
      expect(MetamagicKnownProgression.newMetamagicOptionsAt(3), 2);
      expect(MetamagicKnownProgression.newMetamagicOptionsAt(10), 1);
      expect(MetamagicKnownProgression.newMetamagicOptionsAt(17), 1);
    });

    test('édition 2014 (défaut implicite) : total connu au niveau 20 : 4 '
        'options (RAW)', () {
      expect(MetamagicKnownProgression.metamagicKnownByLevel2014[20], 4);
    });

    test('édition 2014 (défaut implicite) : niveau hors plage 1-20 : 0 '
        '(défensif)', () {
      expect(MetamagicKnownProgression.newMetamagicOptionsAt(0), 0);
      expect(MetamagicKnownProgression.newMetamagicOptionsAt(21), 0);
    });

    test('édition 2014 (défaut implicite) : somme des deltas 1 à 20 == valeur '
        'finale à 20 (cohérence interne)', () {
      var sum = 0;
      for (var level = 1; level <= 20; level++) {
        sum += MetamagicKnownProgression.newMetamagicOptionsAt(level);
      }
      expect(sum, MetamagicKnownProgression.metamagicKnownByLevel2014[20]);
    });

    test('édition 2014 explicite : table identique à l\'appel par défaut, '
        'valeur par valeur aux niveaux clés', () {
      for (final level in [1, 2, 3, 9, 10, 16, 17, 20]) {
        expect(
          MetamagicKnownProgression.newMetamagicOptionsAt(
            level,
            edition: '2014',
          ),
          MetamagicKnownProgression.newMetamagicOptionsAt(level),
          reason: 'niveau $level',
        );
      }
    });

    test('édition 2024 explicite : niveaux déclencheurs RAW (delta strictement '
        'positif) : 2, 10, 17 — chantier "choix d\'édition 2014/2024 par '
        'personnage"', () {
      const triggeringLevels = {2, 10, 17};
      for (var level = 1; level <= 20; level++) {
        final delta = MetamagicKnownProgression.newMetamagicOptionsAt(
          level,
          edition: '2024',
        );
        if (triggeringLevels.contains(level)) {
          expect(delta, greaterThan(0), reason: 'niveau $level');
        } else {
          expect(delta, 0, reason: 'niveau $level');
        }
      }
    });

    test('édition 2024 explicite : valeurs exactes des deltas aux niveaux '
        'déclencheurs (progression cumulative 2/4/6, deltas 2/2/2)', () {
      expect(
        MetamagicKnownProgression.newMetamagicOptionsAt(2, edition: '2024'),
        2,
      );
      expect(
        MetamagicKnownProgression.newMetamagicOptionsAt(10, edition: '2024'),
        2,
      );
      expect(
        MetamagicKnownProgression.newMetamagicOptionsAt(17, edition: '2024'),
        2,
      );
    });

    test('édition 2024 explicite : valeurs cumulées exactes aux niveaux clés '
        '(1, 2, 3, 9, 10, 16, 17, 20)', () {
      const expected = {1: 0, 2: 2, 3: 2, 9: 2, 10: 4, 16: 4, 17: 6, 20: 6};
      for (final entry in expected.entries) {
        expect(
          MetamagicKnownProgression.metamagicKnownByLevel2024[entry.key],
          entry.value,
          reason: 'niveau ${entry.key}',
        );
      }
    });

    test('édition 2014 explicite : valeurs cumulées exactes aux niveaux clés '
        '(1, 2, 3, 9, 10, 16, 17, 20)', () {
      const expected = {1: 0, 2: 0, 3: 2, 9: 2, 10: 3, 16: 3, 17: 4, 20: 4};
      for (final entry in expected.entries) {
        expect(
          MetamagicKnownProgression.metamagicKnownByLevel2014[entry.key],
          entry.value,
          reason: 'niveau ${entry.key}',
        );
      }
    });

    test('édition 2024 explicite : niveau hors plage 1-20 : 0 (défensif)', () {
      expect(
        MetamagicKnownProgression.newMetamagicOptionsAt(0, edition: '2024'),
        0,
      );
      expect(
        MetamagicKnownProgression.newMetamagicOptionsAt(21, edition: '2024'),
        0,
      );
    });

    test('édition 2024 explicite : somme des deltas 1 à 20 == valeur finale à '
        '20 (cohérence interne)', () {
      var sum = 0;
      for (var level = 1; level <= 20; level++) {
        sum += MetamagicKnownProgression.newMetamagicOptionsAt(
          level,
          edition: '2024',
        );
      }
      expect(sum, MetamagicKnownProgression.metamagicKnownByLevel2024[20]);
    });

    test('nom de classe RAW (aptitude de classe, pas de sous-classe)', () {
      expect(MetamagicKnownProgression.className, 'Ensorceleur');
    });
  });
}
