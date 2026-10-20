import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/superiority_dice_progression.dart';

void main() {
  group('SuperiorityDiceProgression.diceCountAt', () {
    test('0 avant le niveau 3 (RAW : aucun dé de supériorité)', () {
      expect(SuperiorityDiceProgression.diceCountAt(1), 0);
      expect(SuperiorityDiceProgression.diceCountAt(2), 0);
    });

    test('valeurs exactes aux 5 paliers RAW (4/5/5/6/6)', () {
      expect(SuperiorityDiceProgression.diceCountAt(3), 4);
      expect(SuperiorityDiceProgression.diceCountAt(6), 4);
      expect(SuperiorityDiceProgression.diceCountAt(7), 5);
      expect(SuperiorityDiceProgression.diceCountAt(9), 5);
      expect(SuperiorityDiceProgression.diceCountAt(10), 5);
      expect(SuperiorityDiceProgression.diceCountAt(14), 5);
      expect(SuperiorityDiceProgression.diceCountAt(15), 6);
      expect(SuperiorityDiceProgression.diceCountAt(17), 6);
      expect(SuperiorityDiceProgression.diceCountAt(18), 6);
      expect(SuperiorityDiceProgression.diceCountAt(20), 6);
    });

    test('niveau hors plage 1-20 : 0 (défensif)', () {
      expect(SuperiorityDiceProgression.diceCountAt(0), 0);
      expect(SuperiorityDiceProgression.diceCountAt(21), 0);
    });
  });

  group('SuperiorityDiceProgression.diceSizeAt', () {
    test('0 avant le niveau 3', () {
      expect(SuperiorityDiceProgression.diceSizeAt(1), 0);
      expect(SuperiorityDiceProgression.diceSizeAt(2), 0);
    });

    test('valeurs exactes aux 3 paliers RAW (d8/d10/d12)', () {
      expect(SuperiorityDiceProgression.diceSizeAt(3), 8);
      expect(SuperiorityDiceProgression.diceSizeAt(9), 8);
      expect(SuperiorityDiceProgression.diceSizeAt(10), 10);
      expect(SuperiorityDiceProgression.diceSizeAt(17), 10);
      expect(SuperiorityDiceProgression.diceSizeAt(18), 12);
      expect(SuperiorityDiceProgression.diceSizeAt(20), 12);
    });

    test('niveau hors plage 1-20 : 0 (défensif)', () {
      expect(SuperiorityDiceProgression.diceSizeAt(0), 0);
      expect(SuperiorityDiceProgression.diceSizeAt(21), 0);
    });
  });

  test('nom de sous-classe et choice_type RAW', () {
    expect(SuperiorityDiceProgression.subclassName, 'Maître de guerre');
    expect(SuperiorityDiceProgression.choiceType, 'manoeuvre');
  });
}
