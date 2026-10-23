import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/creation_step_help.dart';

void main() {
  group('CreationStepHelp', () {
    // Une entrée par étape (1 à 10 depuis le chantier "choix d'édition
    // 2014/2024 par personnage", voir `EditionStepScreen`), title/body
    // jamais vides — filet de sécurité contre une entrée oubliée/mal
    // renseignée en ajoutant une étape, plutôt que de dépendre uniquement
    // d'un rendu visuel pour le détecter.
    const entries = [
      CreationStepHelp.edition,
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

    test('10 entrées, chacune avec un titre et un corps non vides', () {
      expect(entries, hasLength(10));
      for (final entry in entries) {
        expect(entry.title, isNotEmpty);
        expect(entry.body, isNotEmpty);
      }
    });

    test('chaque titre correspond au format "{numéro}. {libellé}" affiché '
        'dans le bandeau bois de l\'étape correspondante', () {
      expect(CreationStepHelp.edition.title, '1. Édition');
      expect(CreationStepHelp.race.title, '2. Race');
      expect(CreationStepHelp.classStep.title, '3. Classe');
      expect(CreationStepHelp.background.title, '4. Historique');
      expect(CreationStepHelp.abilityScore.title, '5. Caractéristiques');
      expect(CreationStepHelp.skillsAndTools.title, '6. Compétences');
      expect(CreationStepHelp.spells.title, '7. Sorts');
      expect(CreationStepHelp.equipment.title, '8. Équipement');
      expect(
        CreationStepHelp.appearanceAndBackstory.title,
        '9. Apparence, histoire et portrait',
      );
      expect(CreationStepHelp.summary.title, '10. Récapitulatif');
    });
  });
}
