import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/expertise_known_progression.dart';

void main() {
  group('ExpertiseKnownProgression.quotaAt', () {
    test('Barde, édition 2014 (défaut implicite) : quota de 2 aux niveaux 3 '
        'et 10, 0 ailleurs', () {
      for (var level = 1; level <= 20; level++) {
        final quota = ExpertiseKnownProgression.quotaAt('Barde', level);
        if (level == 3 || level == 10) {
          expect(quota, 2, reason: 'niveau $level');
        } else {
          expect(quota, 0, reason: 'niveau $level');
        }
      }
    });

    test('Barde, édition 2024 explicite : quota de 2 aux niveaux 2 et 9 '
        '(déclenchements avancés d\'un niveau par rapport à 2014), jamais '
        'aux niveaux 2014 (3/10) — chantier "choix d\'édition 2014/2024 par '
        'personnage"', () {
      for (var level = 1; level <= 20; level++) {
        final quota = ExpertiseKnownProgression.quotaAt(
          'Barde',
          level,
          edition: '2024',
        );
        if (level == 2 || level == 9) {
          expect(quota, 2, reason: 'niveau $level');
        } else {
          expect(quota, 0, reason: 'niveau $level');
        }
      }
    });

    test('Roublard : quota de 2 aux niveaux 1 et 6, 0 ailleurs, INCHANGÉ '
        'entre les deux éditions', () {
      for (final edition in ['2014', '2024']) {
        for (var level = 1; level <= 20; level++) {
          final quota = ExpertiseKnownProgression.quotaAt(
            'Roublard',
            level,
            edition: edition,
          );
          if (level == 1 || level == 6) {
            expect(quota, 2, reason: 'édition $edition, niveau $level');
          } else {
            expect(quota, 0, reason: 'édition $edition, niveau $level');
          }
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

  // Réintroduit par le chantier "choix d'édition 2014/2024 par personnage"
  // après avoir été retiré en D104 de `docs/dette-technique.md` sur la base
  // d'une citation RAW erronée : le texte 2014 PHB autorise bien la
  // substitution outils de voleur du Roublard, aux DEUX niveaux 1 et 6 —
  // voir la doc de classe de ce fichier pour le texte primaire exact. Cette
  // méthode ne connaît elle-même aucune notion d'édition (voir sa doc) :
  // c'est à l'appelant de gater par `edition == '2014'`.
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
