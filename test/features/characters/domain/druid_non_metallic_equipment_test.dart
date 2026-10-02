import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/druid_non_metallic_equipment.dart';

void main() {
  group('DruidNonMetallicEquipment.isNonMetallicArmor', () {
    test("'Armure de peau' est non métallique", () {
      expect(
        DruidNonMetallicEquipment.isNonMetallicArmor('Armure de peau'),
        isTrue,
      );
    });

    test('insensible aux accents/casse', () {
      expect(
        DruidNonMetallicEquipment.isNonMetallicArmor('armure DE PEAU'),
        isTrue,
      );
    });

    test('une autre armure intermédiaire (ex. Demi-plate) n\'est pas non '
        'métallique', () {
      expect(
        DruidNonMetallicEquipment.isNonMetallicArmor('Demi-plate'),
        isFalse,
      );
    });
  });

  group('DruidNonMetallicEquipment.isNonMetallicShield', () {
    test('toujours faux (aucun bouclier non métallique dans ce catalogue)', () {
      expect(
        DruidNonMetallicEquipment.isNonMetallicShield('Bouclier'),
        isFalse,
      );
      expect(
        DruidNonMetallicEquipment.isNonMetallicShield('Armure de peau'),
        isFalse,
      );
    });
  });
}
