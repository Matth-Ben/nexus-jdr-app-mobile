import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/level_up_choice_kind.dart';
import 'package:personnages/features/characters/domain/level_up_choice_selection.dart';

void main() {
  group('LevelUpChoiceSelection.abilityScoreImprovement', () {
    test('porte les allocations, featId nul (mutuellement exclusif)', () {
      final selection = LevelUpChoiceSelection.abilityScoreImprovement({
        'str': 2,
      });
      expect(selection.kind, LevelUpChoiceKind.abilityScoreImprovement);
      expect(selection.abilityAllocations, {'str': 2});
      expect(selection.featId, isNull);
      expect(selection.subclassId, isNull);
      expect(selection.classFeatureId, isNull);
      expect(selection.chosenValue, isNull);
    });
  });

  group('LevelUpChoiceSelection.feat', () {
    test('même kind que abilityScoreImprovement, mais featId renseigné et '
        'abilityAllocations nul (mutuellement exclusif)', () {
      final selection = LevelUpChoiceSelection.feat(7);
      expect(selection.kind, LevelUpChoiceKind.abilityScoreImprovement);
      expect(selection.featId, 7);
      expect(selection.abilityAllocations, isNull);
      expect(selection.subclassId, isNull);
      expect(selection.classFeatureId, isNull);
      expect(selection.chosenValue, isNull);
    });
  });

  group('LevelUpChoiceSelection.subclass', () {
    test('porte le subclassId, aucun autre champ renseigné', () {
      final selection = LevelUpChoiceSelection.subclass(4);
      expect(selection.kind, LevelUpChoiceKind.subclass);
      expect(selection.subclassId, 4);
      expect(selection.abilityAllocations, isNull);
      expect(selection.featId, isNull);
      expect(selection.classFeatureId, isNull);
      expect(selection.chosenValue, isNull);
    });
  });

  group('LevelUpChoiceSelection.fightingStyle / favoredEnemy', () {
    test('portent classFeatureId + chosenValue, aucun autre champ', () {
      final style = LevelUpChoiceSelection.fightingStyle(
        classFeatureId: 12,
        chosenValue: 'Défense',
      );
      expect(style.kind, LevelUpChoiceKind.fightingStyle);
      expect(style.classFeatureId, 12);
      expect(style.chosenValue, 'Défense');
      expect(style.abilityAllocations, isNull);
      expect(style.featId, isNull);
      expect(style.subclassId, isNull);

      final enemy = LevelUpChoiceSelection.favoredEnemy(
        classFeatureId: 13,
        chosenValue: 'Morts-vivants',
      );
      expect(enemy.kind, LevelUpChoiceKind.favoredEnemy);
      expect(enemy.classFeatureId, 13);
      expect(enemy.chosenValue, 'Morts-vivants');
    });
  });
}
