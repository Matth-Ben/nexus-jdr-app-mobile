import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/level_up_choice_kind.dart';

void main() {
  group('LevelUpPendingChoiceResolver.resolve', () {
    test("'sous_classe' -> LevelUpChoiceKind.subclass", () {
      expect(
        LevelUpPendingChoiceResolver.resolve(
          targetLevel: 3,
          classFeatureChoiceType: 'sous_classe',
        ),
        LevelUpChoiceKind.subclass,
      );
    });

    test("'style_combat' -> LevelUpChoiceKind.fightingStyle", () {
      expect(
        LevelUpPendingChoiceResolver.resolve(
          targetLevel: 1,
          classFeatureChoiceType: 'style_combat',
        ),
        LevelUpChoiceKind.fightingStyle,
      );
    });

    test("'ennemi_jure' -> LevelUpChoiceKind.favoredEnemy", () {
      expect(
        LevelUpPendingChoiceResolver.resolve(
          targetLevel: 1,
          classFeatureChoiceType: 'ennemi_jure',
        ),
        LevelUpChoiceKind.favoredEnemy,
      );
    });

    test('un choice_type non résolu (ex. invocation) ne renvoie rien ici : '
        "l'appelant ne devrait jamais appeler resolve() pour un niveau que "
        'LevelUpBlockRules.evaluate a bloqué', () {
      expect(
        LevelUpPendingChoiceResolver.resolve(
          targetLevel: 2,
          classFeatureChoiceType: 'invocation',
        ),
        isNull,
      );
    });

    test('un niveau ASI (4/8/12/16/19) sans choice_type -> '
        'LevelUpChoiceKind.abilityScoreImprovement', () {
      for (final level in [4, 8, 12, 16, 19]) {
        expect(
          LevelUpPendingChoiceResolver.resolve(
            targetLevel: level,
            classFeatureChoiceType: null,
          ),
          LevelUpChoiceKind.abilityScoreImprovement,
          reason: 'niveau $level devrait résoudre en ASI',
        );
      }
    });

    test('niveau hors ASI sans choice_type -> null', () {
      expect(
        LevelUpPendingChoiceResolver.resolve(
          targetLevel: 5,
          classFeatureChoiceType: null,
        ),
        isNull,
      );
    });

    test('choice_type résolu prioritaire sur un niveau ASI (ne devrait pas '
        'arriver dans les données réelles, voir LevelUpBlockRules.evaluate '
        'pour le cas défensif "deux choix simultanés")', () {
      expect(
        LevelUpPendingChoiceResolver.resolve(
          targetLevel: 4,
          classFeatureChoiceType: 'sous_classe',
        ),
        LevelUpChoiceKind.subclass,
      );
    });
  });
}
