import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/level_up_chain_resolver.dart';
import 'package:personnages/features/characters/domain/xp_table.dart';

void main() {
  group('LevelUpChainResolver.hasNextLevelAlreadyUnlocked', () {
    test('faux si l\'XP actuelle ne couvre pas encore le niveau suivant', () {
      // Niveau 6 cible : seuil niveau 7 = 23 000.
      expect(
        LevelUpChainResolver.hasNextLevelAlreadyUnlocked(
          targetLevel: 6,
          currentXp: 22999,
        ),
        isFalse,
      );
    });

    test('vrai si l\'XP actuelle couvre déjà le niveau suivant', () {
      expect(
        LevelUpChainResolver.hasNextLevelAlreadyUnlocked(
          targetLevel: 6,
          currentXp: 23000,
        ),
        isTrue,
      );
    });

    test('faux au niveau maximum : aucun niveau suivant possible', () {
      expect(
        LevelUpChainResolver.hasNextLevelAlreadyUnlocked(
          targetLevel: XpTable.maxLevel,
          currentXp: 1000000,
        ),
        isFalse,
      );
    });
  });

  group('LevelUpChainResolver.remainingLevelsAfter', () {
    test('0 si l\'XP actuelle ne franchit aucun seuil supplémentaire', () {
      expect(
        LevelUpChainResolver.remainingLevelsAfter(
          targetLevel: 3,
          currentXp: 900,
        ),
        0,
      );
    });

    test('compte tous les niveaux déjà déverrouillés au-delà de la cible', () {
      // Niveau 3 cible, XP = 14000 -> couvre les niveaux 4 (2700), 5 (6500)
      // et 6 (14000) : 3 niveaux supplémentaires déjà déverrouillés.
      expect(
        LevelUpChainResolver.remainingLevelsAfter(
          targetLevel: 3,
          currentXp: 14000,
        ),
        3,
      );
    });

    test('plafonne au niveau maximum', () {
      expect(
        LevelUpChainResolver.remainingLevelsAfter(
          targetLevel: 18,
          currentXp: 100000000,
        ),
        2,
      );
    });
  });
}
