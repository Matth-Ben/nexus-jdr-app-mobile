import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/dice_roller.dart';

void main() {
  group('DiceRoller.rollD20', () {
    test('résultat toujours entre 1 et 20 inclus, sur un grand nombre de '
        'tirages (Random() par défaut, non déterministe)', () {
      for (var i = 0; i < 500; i++) {
        final result = DiceRoller.rollD20();
        expect(result, inInclusiveRange(1, 20));
      }
    });

    test('avec un Random injecté (seed fixe), le résultat est déterministe '
        'et reproductible', () {
      final first = DiceRoller.rollD20(random: Random(42));
      final second = DiceRoller.rollD20(random: Random(42));

      expect(first, second);
      expect(first, inInclusiveRange(1, 20));
    });

    test('Random.nextInt(20) + 1 : jamais 0, jamais 21 (bornes exactes, pas '
        'juste "dans la plage" sur un échantillon qui pourrait passer à côté '
        'des extrêmes par chance)', () {
      // Un Random(0) fixe suffit à documenter la formule elle-même
      // (nextInt(20) renvoie [0, 19], +1 donne [1, 20]) plutôt que de
      // dépendre d'un tirage aléatoire pour toucher les bornes.
      final results = [
        for (var seed = 0; seed < 200; seed++)
          DiceRoller.rollD20(random: Random(seed)),
      ];

      expect(results.every((r) => r >= 1), isTrue);
      expect(results.every((r) => r <= 20), isTrue);
    });
  });

  group('DiceRoller.rollDie', () {
    for (final sides in [4, 6, 8, 10, 12, 20, 100]) {
      test('d$sides : toujours entre 1 et $sides, bornes atteintes', () {
        final rolls = [
          for (var seed = 0; seed < 2000; seed++)
            DiceRoller.rollDie(sides, random: Random(seed)),
        ];
        expect(rolls.every((r) => r >= 1 && r <= sides), isTrue);
        expect(rolls, contains(1));
        expect(rolls, contains(sides));
      });
    }

    test('rollD20 reste identique à rollDie(20) pour une même graine', () {
      expect(
        DiceRoller.rollD20(random: Random(5)),
        DiceRoller.rollDie(20, random: Random(5)),
      );
    });
  });

  group('DiceRoller.rollD20Check', () {
    test('mode normal : un seul dé, aucun dé écarté, total = dé + modif', () {
      final r = DiceRoller.rollD20Check(modifier: 3, random: _Seq([12]));
      expect(r.dice, [12]);
      expect(r.kept, 12);
      expect(r.discarded, isNull);
      expect(r.total, 15);
      expect(r.mode, RollMode.normal);
    });

    test('mode normal : même tirage que rollD20 (même graine)', () {
      expect(
        DiceRoller.rollD20Check(random: Random(9)).kept,
        DiceRoller.rollD20(random: Random(9)),
      );
    });

    test('avantage : garde le max, conserve les deux dés', () {
      final r = DiceRoller.rollD20Check(
        mode: RollMode.advantage,
        modifier: 3,
        random: _Seq([4, 17]),
      );
      expect(r.dice, [4, 17]);
      expect(r.kept, 17);
      expect(r.discarded, 4);
      expect(r.discardedIndex, 0);
      expect(r.total, 20);
    });

    test('désavantage : garde le min, conserve les deux dés', () {
      final r = DiceRoller.rollD20Check(
        mode: RollMode.disadvantage,
        modifier: -2,
        random: _Seq([17, 4]),
      );
      expect(r.dice, [17, 4]);
      expect(r.kept, 4);
      expect(r.discarded, 17);
      expect(r.discardedIndex, 0);
      expect(r.total, 2);
    });

    test('égalité : le second dé est le dé écarté', () {
      final r = DiceRoller.rollD20Check(
        mode: RollMode.advantage,
        random: _Seq([9, 9]),
      );
      expect(r.kept, 9);
      expect(r.discardedIndex, 1);
    });

    test('avantage 20 et 3 : 20 naturel (dé gardé)', () {
      final r = DiceRoller.rollD20Check(
        mode: RollMode.advantage,
        random: _Seq([3, 20]),
      );
      expect(r.isNaturalTwenty, isTrue);
      expect(r.isNaturalOne, isFalse);
    });

    test('désavantage 20 et 3 : pas de 20 naturel (le 20 est écarté)', () {
      final r = DiceRoller.rollD20Check(
        mode: RollMode.disadvantage,
        random: _Seq([20, 3]),
      );
      expect(r.isNaturalTwenty, isFalse);
      expect(r.kept, 3);
    });

    test('désavantage 1 et 15 : 1 naturel ; avantage 1 et 15 : pas de 1', () {
      final dis = DiceRoller.rollD20Check(
        mode: RollMode.disadvantage,
        random: _Seq([1, 15]),
      );
      final adv = DiceRoller.rollD20Check(
        mode: RollMode.advantage,
        random: _Seq([1, 15]),
      );
      expect(dis.isNaturalOne, isTrue);
      expect(adv.isNaturalOne, isFalse);
    });
  });
}

/// Random figé : `nextInt(20)` renvoie successivement `valeur - 1` (le
/// tirage vaut donc la valeur donnée, formule `nextInt + 1`).
class _Seq implements Random {
  _Seq(this._values);

  final List<int> _values;
  int _i = 0;

  @override
  int nextInt(int max) => _values[_i++] - 1;

  @override
  bool nextBool() => true;

  @override
  double nextDouble() => 0;
}
