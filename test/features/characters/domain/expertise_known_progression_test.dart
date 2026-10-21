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

  // D104 de docs/dette-technique.md : la substitution "outils de voleur" à
  // une place d'Expertise est RAW-fausse (le texte 2024 du Manuel des
  // Joueurs l'a supprimée complètement, vérifié par 2 sources primaires
  // indépendantes) — retirée du modèle. `quotaAt` ne connaît donc QUE deux
  // valeurs, jamais 1 (ce que renverrait une substitution partielle), et
  // aucune méthode de substitution n'existe plus sur cette classe.
  test('le quota ne vaut jamais 1 (pas de substitution partielle)', () {
    for (final className in ['Barde', 'Roublard']) {
      for (var level = 1; level <= 20; level++) {
        expect(
          ExpertiseKnownProgression.quotaAt(className, level),
          isNot(1),
          reason: '$className niveau $level',
        );
      }
    }
  });
}
