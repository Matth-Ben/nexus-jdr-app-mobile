import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';

CharacterSummary _summary({required int level, required int xp}) {
  return CharacterSummary(id: '1', name: 'Test', level: level, xp: xp);
}

void main() {
  group('CharacterSummary.nextLevelXpThreshold', () {
    test('niveau 1 : seuil du niveau 2 (300 XP)', () {
      expect(_summary(level: 1, xp: 0).nextLevelXpThreshold, 300);
    });

    test('niveau max (20) : pas de niveau suivant', () {
      expect(_summary(level: 20, xp: 355000).nextLevelXpThreshold, isNull);
    });
  });

  group('CharacterSummary.xpProgress', () {
    test('juste après une montée de niveau, la jauge repart de 0', () {
      expect(_summary(level: 2, xp: 300).xpProgress, 0);
    });

    test('à mi-chemin entre deux seuils, la jauge est à moitié', () {
      // Niveau 1 → 2 : 0 à 300 XP, 150 XP = moitié.
      expect(_summary(level: 1, xp: 150).xpProgress, 0.5);
    });

    test('à mi-chemin entre deux seuils plus élevés (niveau 9 → 10 : 48 000 à '
        '64 000 XP), la jauge est aussi à moitié', () {
      expect(_summary(level: 9, xp: 56000).xpProgress, 0.5);
    });

    test('juste avant le seuil suivant, la jauge est presque pleine', () {
      expect(_summary(level: 1, xp: 299).xpProgress, closeTo(1, 0.01));
    });

    test('un excédent d\'XP au-delà du seuil ne dépasse pas 1 (jauge pleine '
        'au max)', () {
      expect(_summary(level: 1, xp: 1000).xpProgress, 1);
    });

    test('au niveau maximum, la jauge est toujours pleine', () {
      expect(_summary(level: 20, xp: 355000).xpProgress, 1);
    });
  });

  group('CharacterSummary — robustesse face à un niveau incohérent', () {
    // `CharacterSummary` ne valide pas elle-même que `level >= 1` : c'est au
    // dépôt (`data/character_repository.dart`, `_toSummary`) qui garantit
    // qu'un personnage sans ligne `character_classes` est toujours résolu en
    // niveau 1 plutôt que 0. Ce test documente que, même si cette garantie
    // était un jour contournée ailleurs, la jauge XP resterait cohérente :
    // `XpTable.cumulativeXpForNextLevel` clampe désormais le niveau de départ
    // *avant* de calculer le seuil suivant (comme le fait déjà
    // `XpTable.cumulativeXpForLevel` pour son propre paramètre), donc un
    // niveau 0 (ou négatif) se comporte comme le niveau 1 plutôt que
    // d'afficher un seuil suivant erroné (0 XP) et une jauge pleine à tort.
    test('un niveau à 0 se comporte comme le niveau 1 (seuil suivant et '
        'remplissage identiques)', () {
      final zeroLevel = _summary(level: 0, xp: 150);
      final levelOne = _summary(level: 1, xp: 150);

      expect(zeroLevel.nextLevelXpThreshold, levelOne.nextLevelXpThreshold);
      expect(zeroLevel.xpProgress, levelOne.xpProgress);
      expect(levelOne.nextLevelXpThreshold, 300);
      expect(levelOne.xpProgress, 0.5);
    });
  });
}
