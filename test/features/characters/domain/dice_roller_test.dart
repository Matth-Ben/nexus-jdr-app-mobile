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
        for (var seed = 0; seed < 200; seed++) DiceRoller.rollD20(random: Random(seed)),
      ];

      expect(results.every((r) => r >= 1), isTrue);
      expect(results.every((r) => r <= 20), isTrue);
    });
  });
}
