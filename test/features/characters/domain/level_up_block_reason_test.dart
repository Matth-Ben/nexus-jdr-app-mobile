import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/level_up_block_reason.dart';

void main() {
  group('LevelUpBlockRules.evaluate — condition 1 (choice_type)', () {
    test('un choice_type non nul bloque, quel que soit le niveau', () {
      final reason = LevelUpBlockRules.evaluate(
        targetLevel: 3,
        className: 'Guerrier',
        classFeatureChoiceType: 'style_combat',
      );
      expect(reason, isNotNull);
      expect(reason!.detail, 'Guerrier niveau 3 : Style de combat');
    });

    test('prioritaire sur la condition 2 (niveau ASI)', () {
      final reason = LevelUpBlockRules.evaluate(
        targetLevel: 4,
        className: 'Rôdeur',
        classFeatureChoiceType: 'sous_classe',
      );
      expect(reason!.detail, 'Rôdeur niveau 4 : Sous-classe à choisir');
    });
  });

  group('LevelUpBlockRules.evaluate — condition 2 (niveau amélioration '
      'de caractéristique)', () {
    test('bloque aux niveaux 4/8/12/16/19', () {
      for (final level in [4, 8, 12, 16, 19]) {
        final reason = LevelUpBlockRules.evaluate(
          targetLevel: level,
          className: 'Guerrier',
          classFeatureChoiceType: null,
        );
        expect(
          reason?.detail,
          'Amélioration de caractéristique ou don',
          reason: 'niveau $level devrait bloquer',
        );
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
  });

  test('aucune des 3 conditions ne matche -> pas de blocage', () {
    final reason = LevelUpBlockRules.evaluate(
      targetLevel: 3,
      className: 'Guerrier',
      classFeatureChoiceType: null,
    );
    expect(reason, isNull);
  });
}
