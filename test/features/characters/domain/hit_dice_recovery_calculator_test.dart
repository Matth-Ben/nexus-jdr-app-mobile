import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/hit_dice_pool.dart';
import 'package:personnages/features/characters/domain/hit_dice_recovery_calculator.dart';

void main() {
  const guerrier = HitDicePool(
    classId: 1,
    className: 'Guerrier',
    hitDie: 10,
    total: 5,
    spent: 3,
  );
  const magicien = HitDicePool(
    classId: 2,
    className: 'Magicien',
    hitDie: 6,
    total: 3,
    spent: 2,
  );

  group('HitDiceRecoveryCalculator.recoveredCount', () {
    test('moitié du niveau total, arrondie à l\'inférieur', () {
      expect(HitDiceRecoveryCalculator.recoveredCount(totalLevel: 8), 4);
      expect(HitDiceRecoveryCalculator.recoveredCount(totalLevel: 5), 2);
    });

    test('au moins 1, même pour un niveau total de 1', () {
      expect(HitDiceRecoveryCalculator.recoveredCount(totalLevel: 1), 1);
    });

    test('porte sur le niveau TOTAL du personnage, pas une seule classe '
        '(non-régression du défaut RAW corrigé le 10/10/2026) — niveau '
        'total 8 (Guerrier 5 / Magicien 3) donne 4, jamais 2 (moitié de la '
        'seule classe primaire, Guerrier 5)', () {
      expect(HitDiceRecoveryCalculator.recoveredCount(totalLevel: 5 + 3), 4);
    });
  });

  group('HitDiceRecoveryCalculator.totalSpent', () {
    test('somme des dés dépensés de tous les pools', () {
      expect(HitDiceRecoveryCalculator.totalSpent([guerrier, magicien]), 5);
    });

    test('liste vide -> 0', () {
      expect(HitDiceRecoveryCalculator.totalSpent(const []), 0);
    });
  });

  group('HitDiceRecoveryCalculator.spentPools', () {
    test('ne garde que les pools avec au moins un dé dépensé', () {
      const vide = HitDicePool(
        classId: 3,
        className: 'Roublard',
        hitDie: 8,
        total: 2,
        spent: 0,
      );
      expect(HitDiceRecoveryCalculator.spentPools([guerrier, vide, magicien]), [
        guerrier,
        magicien,
      ]);
    });
  });

  group('HitDiceRecoveryCalculator.needsPlayerChoice', () {
    test('mono-classe, récupération insuffisante : jamais de choix (un seul '
        'type de dé, rien à départager)', () {
      expect(
        HitDiceRecoveryCalculator.needsPlayerChoice(
          pools: [guerrier],
          recovered: 2,
        ),
        isFalse,
      );
    });

    test('multiclassé, récupération suffisante : aucun choix nécessaire', () {
      expect(
        HitDiceRecoveryCalculator.needsPlayerChoice(
          pools: [guerrier, magicien],
          recovered: 5,
        ),
        isFalse,
      );
    });

    test('multiclassé, récupération insuffisante ET plus d\'un pool dépensé '
        ': le joueur doit choisir', () {
      expect(
        HitDiceRecoveryCalculator.needsPlayerChoice(
          pools: [guerrier, magicien],
          recovered: 4,
        ),
        isTrue,
      );
    });

    test('multiclassé, récupération insuffisante MAIS un seul pool a des dés '
        'dépensés : aucun choix nécessaire (rien à départager entre deux '
        'dés identiques)', () {
      const sansDepense = HitDicePool(
        classId: 2,
        className: 'Magicien',
        hitDie: 6,
        total: 3,
        spent: 0,
      );
      expect(
        HitDiceRecoveryCalculator.needsPlayerChoice(
          pools: [guerrier, sansDepense],
          recovered: 1,
        ),
        isFalse,
      );
    });
  });

  group('HitDiceRecoveryCalculator.defaultRecovery', () {
    test('mono-classe, récupération suffisante : pool ramené à 0', () {
      expect(
        HitDiceRecoveryCalculator.defaultRecovery(
          pools: [guerrier],
          recovered: 5,
        ),
        {1: 3},
      );
    });

    test('mono-classe, récupération insuffisante : applique directement le '
        'nombre récupéré (même formule que l\'ancien calcul mono-classe, '
        'avant cette fonctionnalité)', () {
      expect(
        HitDiceRecoveryCalculator.defaultRecovery(
          pools: [guerrier],
          recovered: 2,
        ),
        {1: 2},
      );
    });

    test('multiclassé, récupération suffisante : chaque pool dépensé revient '
        'à 0, quel que soit son niveau', () {
      expect(
        HitDiceRecoveryCalculator.defaultRecovery(
          pools: [guerrier, magicien],
          recovered: 5,
        ),
        {1: 3, 2: 2},
      );
    });

    test('multiclassé, récupération EXACTEMENT suffisante : même résultat', () {
      expect(
        HitDiceRecoveryCalculator.defaultRecovery(
          pools: [guerrier, magicien],
          recovered: 5,
        ),
        {1: 3, 2: 2},
      );
    });

    test('aucun dé dépensé -> map vide (aucune écriture nécessaire)', () {
      const sansDepense = HitDicePool(
        classId: 1,
        className: 'Guerrier',
        hitDie: 10,
        total: 5,
        spent: 0,
      );
      expect(
        HitDiceRecoveryCalculator.defaultRecovery(
          pools: [sansDepense],
          recovered: 3,
        ),
        isEmpty,
      );
    });
  });
}
