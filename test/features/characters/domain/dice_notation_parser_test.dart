import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/dice_notation_parser.dart';

void main() {
  group('DiceNotationParser.parse', () {
    test('motif simple "1d8"', () {
      expect(DiceNotationParser.parse('1d8'), (count: 1, sides: 8));
    });

    test('motif "2d6"', () {
      expect(DiceNotationParser.parse('2d6'), (count: 2, sides: 6));
    });

    test('variante avec espaces et majuscule "2 D 6"', () {
      expect(DiceNotationParser.parse('2 D 6'), (count: 2, sides: 6));
    });

    test('motif entouré de texte', () {
      expect(DiceNotationParser.parse('Épée longue (1d8 tranchant)'), (
        count: 1,
        sides: 8,
      ));
    });

    test('aucun motif -> null', () {
      expect(DiceNotationParser.parse('aucun dé ici'), isNull);
    });

    test('texte vide -> null', () {
      expect(DiceNotationParser.parse(''), isNull);
    });

    test('nombre de dés nul "0d6" -> null', () {
      expect(DiceNotationParser.parse('0d6'), isNull);
    });

    test('nombre de faces nul "1d0" -> null', () {
      expect(DiceNotationParser.parse('1d0'), isNull);
    });

    test('plusieurs motifs : seul le premier est retenu', () {
      expect(
        DiceNotationParser.parse('3d8 puis +1d8 par niveau supplémentaire'),
        (count: 3, sides: 8),
      );
    });
  });
}
