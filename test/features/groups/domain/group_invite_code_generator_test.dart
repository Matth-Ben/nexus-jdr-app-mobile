import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/groups/domain/group_invite_code_generator.dart';

void main() {
  group('GroupInviteCodeGenerator.generate', () {
    test('produit un code de 8 caractères', () {
      final code = GroupInviteCodeGenerator.generate(random: Random(1));
      expect(code.length, 8);
    });

    test("n'utilise que l'alphabet 23456789ABCDEFGHJKMNPQRSTUVWXYZ (jamais "
        '0/1/O/I ambigus)', () {
      final code = GroupInviteCodeGenerator.generate(random: Random(42));
      const alphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
      for (final char in code.split('')) {
        expect(alphabet.contains(char), isTrue, reason: '$char hors alphabet');
      }
      expect(code.contains('0'), isFalse);
      expect(code.contains('1'), isFalse);
      expect(code.contains('O'), isFalse);
      expect(code.contains('I'), isFalse);
    });

    test('déterministe pour une même graine (facilite ce test)', () {
      final first = GroupInviteCodeGenerator.generate(random: Random(7));
      final second = GroupInviteCodeGenerator.generate(random: Random(7));
      expect(first, second);
    });

    test('deux graines différentes produisent (en pratique) des codes '
        'différents', () {
      final first = GroupInviteCodeGenerator.generate(random: Random(1));
      final second = GroupInviteCodeGenerator.generate(random: Random(2));
      expect(first, isNot(second));
    });
  });
}
