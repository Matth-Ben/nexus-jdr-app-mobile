import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/hit_dice_pool.dart';

void main() {
  group('HitDicePool.available', () {
    test('total - dépensés', () {
      const pool = HitDicePool(
        classId: 1,
        className: 'Magicien',
        hitDie: 6,
        total: 5,
        spent: 2,
      );
      expect(pool.available, 3);
    });

    test('jamais négatif, même si spent > total (défensif)', () {
      const pool = HitDicePool(
        classId: 1,
        className: 'Magicien',
        hitDie: 6,
        total: 3,
        spent: 5,
      );
      expect(pool.available, 0);
    });

    test('jamais supérieur à total, même si spent < 0 (défensif)', () {
      const pool = HitDicePool(
        classId: 1,
        className: 'Magicien',
        hitDie: 6,
        total: 3,
        spent: -1,
      );
      expect(pool.available, 3);
    });
  });

  group('HitDicePools.fromClasses', () {
    test('un pool par classe, mono-classe', () {
      final pools = HitDicePools.fromClasses(const [
        CharacterDetailClassRow(
          classId: 1,
          className: 'Guerrier',
          level: 5,
          hitDie: 10,
          hitDiceSpent: 2,
          isPrimary: true,
          savingThrowProficiencies: [],
        ),
      ]);

      expect(pools, hasLength(1));
      expect(pools.single.classId, 1);
      expect(pools.single.className, 'Guerrier');
      expect(pools.single.hitDie, 10);
      expect(pools.single.total, 5);
      expect(pools.single.spent, 2);
    });

    test('un pool par classe, multiclassé (ordre conservé)', () {
      final pools = HitDicePools.fromClasses(const [
        CharacterDetailClassRow(
          classId: 1,
          className: 'Guerrier',
          level: 5,
          hitDie: 10,
          hitDiceSpent: 1,
          isPrimary: true,
          savingThrowProficiencies: [],
        ),
        CharacterDetailClassRow(
          classId: 2,
          className: 'Magicien',
          level: 3,
          hitDie: 6,
          hitDiceSpent: 0,
          isPrimary: false,
          savingThrowProficiencies: [],
        ),
      ]);

      expect(pools, hasLength(2));
      expect(pools[0].className, 'Guerrier');
      expect(pools[0].hitDie, 10);
      expect(pools[1].className, 'Magicien');
      expect(pools[1].hitDie, 6);
    });

    test('une classe dont hitDie est null (gap de données défensif) est '
        'omise, les autres restent présentes', () {
      final pools = HitDicePools.fromClasses(const [
        CharacterDetailClassRow(
          classId: 1,
          className: 'Guerrier',
          level: 5,
          hitDie: null,
          isPrimary: true,
          savingThrowProficiencies: [],
        ),
        CharacterDetailClassRow(
          classId: 2,
          className: 'Magicien',
          level: 3,
          hitDie: 6,
          isPrimary: false,
          savingThrowProficiencies: [],
        ),
      ]);

      expect(pools, hasLength(1));
      expect(pools.single.className, 'Magicien');
    });

    test('liste de classes vide -> liste de pools vide', () {
      expect(HitDicePools.fromClasses(const []), isEmpty);
    });
  });
}
