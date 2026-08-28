import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/level_up_block_reason.dart';

void main() {
  group(
    'LevelUpBlockRules.evaluate — condition 1 (choice_type non résolu)',
    () {
      test('un choice_type non résolu (ex. invocation) bloque, quel que soit '
          'le niveau', () {
        final reason = LevelUpBlockRules.evaluate(
          targetLevel: 2,
          className: 'Occultiste',
          classFeatureChoiceType: 'invocation',
        );
        expect(reason, isNotNull);
        expect(reason!.detail, 'Occultiste niveau 2 : Invocation occulte');
      });

      test('une valeur de choice_type future/inconnue bloque aussi, avec '
          "l'humanisation générique de ClassFeatureChoiceLabelFormatter", () {
        final reason = LevelUpBlockRules.evaluate(
          targetLevel: 6,
          className: 'Clerc',
          classFeatureChoiceType: 'nouveau_choix_pas_encore_repertorie',
        );
        expect(
          reason!.detail,
          'Clerc niveau 6 : Nouveau Choix Pas Encore Repertorie',
        );
      });
    },
  );

  group('LevelUpBlockRules.evaluate — increment 2 : resolvedChoiceTypes ne '
      'bloquent plus', () {
    test('resolvedChoiceTypes contient exactement sous_classe/'
        'style_combat/ennemi_jure', () {
      expect(LevelUpBlockRules.resolvedChoiceTypes, {
        'sous_classe',
        'style_combat',
        'ennemi_jure',
      });
    });

    test("'sous_classe'/'style_combat'/'ennemi_jure' ne bloquent plus le "
        'flux (classe non lanceuse de sorts, niveau non ASI) — mènent '
        'désormais à l\'étape "Choix à faire"', () {
      for (final choiceType in ['sous_classe', 'style_combat', 'ennemi_jure']) {
        final reason = LevelUpBlockRules.evaluate(
          targetLevel: 3,
          className: 'Guerrier',
          classFeatureChoiceType: choiceType,
        );
        expect(reason, isNull, reason: '$choiceType ne devrait plus bloquer');
      }
    });
  });

  group('LevelUpBlockRules.evaluate — increment 2 : niveaux ASI ne bloquent '
      'plus', () {
    test('les niveaux 4/8/12/16/19 ne bloquent plus (étape "Choix à '
        'faire", répartition de caractéristiques)', () {
      for (final level in [4, 8, 12, 16, 19]) {
        final reason = LevelUpBlockRules.evaluate(
          targetLevel: level,
          className: 'Guerrier',
          classFeatureChoiceType: null,
        );
        expect(reason, isNull, reason: 'niveau $level ne devrait plus bloquer');
      }
    });

    test('ne bloque pas un niveau hors de cette liste', () {
      final reason = LevelUpBlockRules.evaluate(
        targetLevel: 5,
        className: 'Guerrier',
        classFeatureChoiceType: null,
      );
      expect(reason, isNull);
    });
  });

  group('LevelUpBlockRules.evaluate — cas défensif : choice_type résolu ET '
      'niveau ASI simultanés', () {
    test("lève une CharacterFailure explicite plutôt que de choisir "
        'silencieusement lequel des deux choix traiter (jamais rencontré '
        'dans les données actuelles, vérifié : tous les choice_type '
        'peuplés sont aux niveaux 1-3, les niveaux ASI sont 4/8/12/16/19)', () {
      expect(
        () => LevelUpBlockRules.evaluate(
          targetLevel: 4,
          className: 'Rôdeur',
          classFeatureChoiceType: 'sous_classe',
        ),
        throwsA(isA<CharacterFailure>()),
      );
    });

    test('le message de la CharacterFailure mentionne la classe, le '
        'niveau et les deux choix en conflit', () {
      try {
        LevelUpBlockRules.evaluate(
          targetLevel: 8,
          className: 'Guerrier',
          classFeatureChoiceType: 'style_combat',
        );
        fail('devait lever une CharacterFailure');
      } on CharacterFailure catch (failure) {
        expect(failure.message, contains('Guerrier niveau 8'));
        expect(failure.message, contains('Style de combat'));
        expect(failure.message, contains('amélioration de caractéristique'));
      }
    });
  });

  group('LevelUpBlockRules.evaluate — condition 3 (classes à sorts connus, '
      'extension chef de projet)', () {
    test('bloque Barde/Ensorceleur/Occultiste/Rôdeur au-delà du niveau 1', () {
      for (final className in [
        'Barde',
        'Ensorceleur',
        'Occultiste',
        'Rôdeur',
      ]) {
        final reason = LevelUpBlockRules.evaluate(
          targetLevel: 3,
          className: className,
          classFeatureChoiceType: null,
        );
        expect(
          reason?.detail,
          '$className niveau 3 : nouveau sort à choisir '
          '(pas encore disponible)',
          reason: '$className devrait bloquer au niveau 3',
        );
      }
    });

    test('bloque Barde au niveau 2 (borne exacte : le tout premier niveau '
        'de montée après la création, cas explicitement cité dans la tâche '
        'de la fonctionnalité)', () {
      final reason = LevelUpBlockRules.evaluate(
        targetLevel: 2,
        className: 'Barde',
        classFeatureChoiceType: null,
      );
      expect(
        reason?.detail,
        'Barde niveau 2 : nouveau sort à choisir (pas encore disponible)',
      );
    });

    test('ne bloque jamais ces classes au niveau 1 (création, hors '
        'périmètre de la montée de niveau)', () {
      final reason = LevelUpBlockRules.evaluate(
        targetLevel: 1,
        className: 'Barde',
        classFeatureChoiceType: null,
      );
      expect(reason, isNull);
    });

    test('ne bloque jamais une classe "préparée" (Clerc/Druide/Magicien/'
        'Paladin) via cette condition', () {
      final reason = LevelUpBlockRules.evaluate(
        targetLevel: 3,
        className: 'Magicien',
        classFeatureChoiceType: null,
      );
      expect(reason, isNull);
    });

    test('ne bloque jamais une classe non lanceuse de sorts (le repli par '
        'défaut de SpellcastingRules.statusFor ne doit jamais faire '
        'croire à une classe "connu")', () {
      final reason = LevelUpBlockRules.evaluate(
        targetLevel: 3,
        className: 'Guerrier',
        classFeatureChoiceType: null,
      );
      expect(reason, isNull);
    });

    test('increment 2, décision documentée : un choice_type résolu (ex. '
        'sous-classe) à un niveau qui apprend AUSSI un nouveau sort connu '
        'reste bloqué (le nouveau sort n\'est toujours pas gérable) — '
        'vérifié en base : Rôdeur niveau 2 (style de combat)', () {
      final reason = LevelUpBlockRules.evaluate(
        targetLevel: 2,
        className: 'Rôdeur',
        classFeatureChoiceType: 'style_combat',
      );
      expect(
        reason?.detail,
        'Rôdeur niveau 2 : nouveau sort à choisir (pas encore disponible)',
      );
    });

    test('à l\'inverse, un choice_type résolu à un niveau <= 1 pour une '
        'classe "à sorts connus" ne bloque pas (condition 3 exige '
        'targetLevel > 1) — vérifié en base : Occultiste niveau 1 '
        '(sous-classe)', () {
      final reason = LevelUpBlockRules.evaluate(
        targetLevel: 1,
        className: 'Occultiste',
        classFeatureChoiceType: 'sous_classe',
      );
      expect(reason, isNull);
    });
  });

  test('aucune des conditions ne matche -> pas de blocage', () {
    final reason = LevelUpBlockRules.evaluate(
      targetLevel: 3,
      className: 'Guerrier',
      classFeatureChoiceType: null,
    );
    expect(reason, isNull);
  });
}
