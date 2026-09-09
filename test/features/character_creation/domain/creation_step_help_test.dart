import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/creation_step_help.dart';

void main() {
  group('CreationStepHelp', () {
    // Une entrée par étape (1 à 9), title/body jamais vides — filet de
    // sécurité contre une entrée oubliée/mal renseignée en ajoutant une
    // étape, plutôt que de dépendre uniquement d'un rendu visuel pour le
    // détecter.
    const entries = [
      CreationStepHelp.race,
      CreationStepHelp.classStep,
      CreationStepHelp.background,
      CreationStepHelp.abilityScore,
      CreationStepHelp.skillsAndTools,
      CreationStepHelp.spells,
      CreationStepHelp.equipment,
      CreationStepHelp.appearanceAndBackstory,
      CreationStepHelp.summary,
    ];

    test('9 entrées, chacune avec un titre et un corps non vides', () {
      expect(entries, hasLength(9));
      for (final entry in entries) {
        expect(entry.title, isNotEmpty);
        expect(entry.body, isNotEmpty);
      }
    });

    test('chaque titre correspond au format "{numéro}. {libellé}" affiché '
        'dans le bandeau bois de l\'étape correspondante', () {
      expect(CreationStepHelp.race.title, '1. Race');
      expect(CreationStepHelp.classStep.title, '2. Classe');
      expect(CreationStepHelp.background.title, '3. Historique');
      expect(CreationStepHelp.abilityScore.title, '4. Caractéristiques');
      expect(CreationStepHelp.skillsAndTools.title, '5. Compétences');
      expect(CreationStepHelp.spells.title, '6. Sorts');
      expect(CreationStepHelp.equipment.title, '7. Équipement');
      expect(
        CreationStepHelp.appearanceAndBackstory.title,
        '8. Apparence, histoire et portrait',
      );
      expect(CreationStepHelp.summary.title, '9. Récapitulatif');
    });
  });
}
