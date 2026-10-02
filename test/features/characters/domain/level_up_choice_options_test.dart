import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/utils/french_text_normalizer.dart';
import 'package:personnages/features/characters/domain/level_up_choice_options.dart';

void main() {
  group('LevelUpChoiceOptions.fightingStyles', () {
    test('contient les 6 options du Manuel des Joueurs 5e', () {
      expect(LevelUpChoiceOptions.fightingStyles, hasLength(6));
      expect(LevelUpChoiceOptions.fightingStyles.toSet(), {
        'Archerie',
        'Défense',
        'Duel',
        'Combat à deux armes',
        'Combat à deux mains',
        'Protection',
      });
    });

    test('est triée par ordre alphabétique normalisé', () {
      final sorted = [...LevelUpChoiceOptions.fightingStyles]
        ..sort((a, b) => FrenchTextNormalizer.compare(a, b));
      expect(LevelUpChoiceOptions.fightingStyles, sorted);
    });
  });

  group('LevelUpChoiceOptions.favoredEnemies', () {
    test('contient les 12 types de créatures du Manuel des Joueurs 5e', () {
      expect(LevelUpChoiceOptions.favoredEnemies, hasLength(12));
      expect(LevelUpChoiceOptions.favoredEnemies.toSet(), {
        'Aberrations',
        'Bêtes',
        'Célestes',
        'Constructions',
        'Dragons',
        'Élémentaires',
        'Fées',
        'Fiélons',
        'Géants',
        'Monstruosités',
        'Plantes',
        'Morts-vivants',
      });
    });

    test('est triée par ordre alphabétique normalisé', () {
      final sorted = [...LevelUpChoiceOptions.favoredEnemies]
        ..sort((a, b) => FrenchTextNormalizer.compare(a, b));
      expect(LevelUpChoiceOptions.favoredEnemies, sorted);
    });
  });
}
