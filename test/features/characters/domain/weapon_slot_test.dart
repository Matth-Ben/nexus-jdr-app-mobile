import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/weapon_slot.dart';

void main() {
  group('WeaponSlotExtension.value/label', () {
    test('principal', () {
      expect(WeaponSlot.principal.value, 'principal');
      expect(WeaponSlot.principal.label, 'Set principal');
    });

    test('secondary -> valeur DB "secondaire"', () {
      expect(WeaponSlot.secondary.value, 'secondaire');
      expect(WeaponSlot.secondary.label, 'Set secondaire');
    });
  });

  group('WeaponSlot.fromValue', () {
    test('parse les deux valeurs DB connues', () {
      expect(WeaponSlot.fromValue('principal'), WeaponSlot.principal);
      expect(WeaponSlot.fromValue('secondaire'), WeaponSlot.secondary);
    });

    test('null/valeur inconnue -> null', () {
      expect(WeaponSlot.fromValue(null), isNull);
      expect(WeaponSlot.fromValue(''), isNull);
      expect(WeaponSlot.fromValue('autre'), isNull);
    });
  });
}
