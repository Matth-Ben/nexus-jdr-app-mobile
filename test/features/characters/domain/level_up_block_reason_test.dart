import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/level_up_block_reason.dart';

void main() {
  group(
    'LevelUpBlockRules.evaluate — condition 1 (choice_type non résolu)',
    () {
      test('une valeur de choice_type future/inconnue bloque, avec '
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

      test("'invocation' ne bloque plus (chantier sorts/dons/invocations) "
          '— rejoint resolvedChoiceTypes, mène désormais à la nouvelle '
          'étape "Invocations", jamais à l\'étape "Choix à faire"', () {
        final reason = LevelUpBlockRules.evaluate(
          targetLevel: 2,
          className: 'Occultiste',
          classFeatureChoiceType: 'invocation',
        );
        expect(reason, isNull);
      });
    },
  );

  group('LevelUpBlockRules.evaluate — increment 2 : resolvedChoiceTypes ne '
      'bloquent plus', () {
    test('resolvedChoiceTypes contient exactement sous_classe/'
        'style_combat/ennemi_jure/invocation', () {
      expect(LevelUpBlockRules.resolvedChoiceTypes, {
        'sous_classe',
        'style_combat',
        'ennemi_jure',
        'invocation',
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
        'faire", répartition de caractéristiques ou don)', () {
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

  group('LevelUpBlockRules.evaluate — ancienne condition 3 supprimée (chantier '
      'sorts/dons/invocations)', () {
    test('ne bloque plus jamais les classes "à sorts connus" '
        '(Barde/Ensorceleur/Occultiste/Rôdeur) au-delà du niveau 1 — la '
        'nouvelle étape "Sorts" généralisée gère désormais ce cas', () {
      for (final className in [
        'Barde',
        'Ensorceleur',
        'Occultiste',
        'Rôdeur',
      ]) {
        for (final level in [2, 3, 5, 10, 20]) {
          final reason = LevelUpBlockRules.evaluate(
            targetLevel: level,
            className: className,
            classFeatureChoiceType: null,
          );
          expect(
            reason,
            isNull,
            reason: '$className niveau $level ne devrait plus bloquer',
          );
        }
      }
    });

    test('un choice_type résolu (ex. style_combat) à un niveau qui '
        'apprend aussi un nouveau sort connu ne bloque plus non plus — '
        'vérifié en base : Rôdeur niveau 2 (style de combat)', () {
      final reason = LevelUpBlockRules.evaluate(
        targetLevel: 2,
        className: 'Rôdeur',
        classFeatureChoiceType: 'style_combat',
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
