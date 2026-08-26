import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/signed_modifier_formatter.dart';

void main() {
  group('SignedModifierFormatter.format', () {
    test('valeur positive : signe +', () {
      expect(SignedModifierFormatter.format(2), '+2');
    });

    test('zéro : signe +', () {
      expect(SignedModifierFormatter.format(0), '+0');
    });

    test('valeur négative : vrai signe moins Unicode (U+2212)', () {
      expect(SignedModifierFormatter.format(-1), '−1');
      expect(SignedModifierFormatter.format(-1), isNot(contains('-1')));
    });
  });
}
