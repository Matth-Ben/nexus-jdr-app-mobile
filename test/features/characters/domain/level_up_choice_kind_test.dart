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

    test("'pacte' -> LevelUpChoiceKind.pact", () {
      expect(
        LevelUpPendingChoiceResolver.resolve(
          targetLevel: 3,
          classFeatureChoiceType: 'pacte',
        ),
        LevelUpChoiceKind.pact,
      );
    });

    test("'invocation' ne renvoie jamais de LevelUpChoiceKind (chantier "
        'sorts/dons/invocations) : ce choice_type est dans '
        'resolvedChoiceTypes (ne bloque plus le flux), mais mène à la '
        'nouvelle étape "Invocations" dédiée, jamais à l\'étape "Choix à '
        'faire"', () {
      expect(
        LevelUpPendingChoiceResolver.resolve(
          targetLevel: 2,
          classFeatureChoiceType: 'invocation',
        ),
        isNull,
      );
    });

    test("'invocation' reste prioritaire sur un niveau ASI (jamais "
        'rencontré en pratique — vérifié en base, la seule ligne '
        "'invocation' est au niveau 2 — mais couvre le cas où ce ne serait "
        'plus vrai un jour)', () {
      expect(
        LevelUpPendingChoiceResolver.resolve(
          targetLevel: 4,
          classFeatureChoiceType: 'invocation',
        ),
        isNull,
      );
    });

    test("'discipline_elementaire' ne renvoie jamais de LevelUpChoiceKind "
        '(correctif Moine, Voie des quatre éléments) : ce choice_type est '
        'dans resolvedChoiceTypes (ne bloque plus le flux), mais mène à la '
        'nouvelle étape "Disciplines élémentaires" dédiée, jamais à l\'étape '
        '"Choix à faire"', () {
      expect(
        LevelUpPendingChoiceResolver.resolve(
          targetLevel: 3,
          classFeatureChoiceType: 'discipline_elementaire',
        ),
        isNull,
      );
    });

    test("'discipline_elementaire' reste prioritaire sur un niveau ASI "
        '(jamais rencontré en pratique — la seule ligne '
        "'discipline_elementaire' est au niveau 3 — mais couvre le cas où "
        'ce ne serait plus vrai un jour)', () {
      expect(
        LevelUpPendingChoiceResolver.resolve(
          targetLevel: 4,
          classFeatureChoiceType: 'discipline_elementaire',
        ),
        isNull,
      );
    });

    test("'tir_arcanique' ne renvoie jamais de LevelUpChoiceKind (Guerrier, "
        'Archer arcanique) : ce choice_type est dans resolvedChoiceTypes '
        '(ne bloque plus le flux), mais mène à la nouvelle étape "Tirs '
        'arcaniques" dédiée, jamais à l\'étape "Choix à faire"', () {
      expect(
        LevelUpPendingChoiceResolver.resolve(
          targetLevel: 3,
          classFeatureChoiceType: 'tir_arcanique',
        ),
        isNull,
      );
    });

    test("'rune' ne renvoie jamais de LevelUpChoiceKind (Guerrier, "
        'Chevalier runique) : ce choice_type est dans resolvedChoiceTypes '
        '(ne bloque plus le flux), mais mène à la nouvelle étape "Runes" '
        'dédiée, jamais à l\'étape "Choix à faire"', () {
      expect(
        LevelUpPendingChoiceResolver.resolve(
          targetLevel: 3,
          classFeatureChoiceType: 'rune',
        ),
        isNull,
      );
    });

    test("'infusion' ne renvoie jamais de LevelUpChoiceKind (Artificier, "
        'aptitude de CLASSE) : ce choice_type est dans resolvedChoiceTypes '
        '(ne bloque plus le flux), mais mène à la nouvelle étape '
        '"Infusions" dédiée, jamais à l\'étape "Choix à faire"', () {
      expect(
        LevelUpPendingChoiceResolver.resolve(
          targetLevel: 2,
          classFeatureChoiceType: 'infusion',
        ),
        isNull,
      );
    });

    test("'manoeuvre' ne renvoie jamais de LevelUpChoiceKind (correctif D92, "
        'Guerrier Maître de guerre) : ce choice_type est dans '
        'resolvedChoiceTypes (ne bloque plus le flux), mais mène à la '
        'nouvelle étape "Manœuvres" dédiée, jamais à l\'étape "Choix à '
        'faire" — vérifie que le StateError défensif du switch ci-dessous '
        'ne se déclenche pas', () {
      expect(
        LevelUpPendingChoiceResolver.resolve(
          targetLevel: 3,
          classFeatureChoiceType: 'manoeuvre',
        ),
        isNull,
      );
    });

    test("'manoeuvre' reste prioritaire sur un niveau ASI (jamais rencontré "
        "en pratique — la seule ligne 'manoeuvre' est au niveau 3 — mais "
        'couvre le cas où ce ne serait plus vrai un jour)', () {
      expect(
        LevelUpPendingChoiceResolver.resolve(
          targetLevel: 4,
          classFeatureChoiceType: 'manoeuvre',
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
