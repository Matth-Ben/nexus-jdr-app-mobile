import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/expertise_known_progression.dart';

void main() {
  group('ExpertiseKnownProgression.quotaAt', () {
    test('Barde : quota de 2 aux niveaux 3 et 10, 0 ailleurs', () {
      for (var level = 1; level <= 20; level++) {
        final quota = ExpertiseKnownProgression.quotaAt('Barde', level);
        if (level == 3 || level == 10) {
          expect(quota, 2, reason: 'niveau $level');
        } else {
          expect(quota, 0, reason: 'niveau $level');
        }
      }
    });

    test('Roublard : quota de 2 aux niveaux 1 et 6, 0 ailleurs', () {
      for (var level = 1; level <= 20; level++) {
        final quota = ExpertiseKnownProgression.quotaAt('Roublard', level);
        if (level == 1 || level == 6) {
          expect(quota, 2, reason: 'niveau $level');
        } else {
          expect(quota, 0, reason: 'niveau $level');
        }
      }
    });

    test('aucune autre classe ne déclenche jamais l\'Expertise', () {
      for (final className in ['Guerrier', 'Magicien', 'Ensorceleur']) {
        for (var level = 1; level <= 20; level++) {
          expect(
            ExpertiseKnownProgression.quotaAt(className, level),
            0,
            reason: '$className niveau $level',
          );
        }
      }
    });
  });

  group('ExpertiseKnownProgression.allowsThievesToolsSubstitution', () {
    test('true pour le Roublard uniquement', () {
      expect(
        ExpertiseKnownProgression.allowsThievesToolsSubstitution('Roublard'),
        isTrue,
      );
    });

    test('false pour le Barde (et toute autre classe)', () {
      expect(
        ExpertiseKnownProgression.allowsThievesToolsSubstitution('Barde'),
        isFalse,
      );
      expect(
        ExpertiseKnownProgression.allowsThievesToolsSubstitution('Guerrier'),
        isFalse,
      );
    });
  });
}
