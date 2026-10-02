import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/armor_proficiency_category.dart';

void main() {
  group('ArmorProficiencyCategoryRules.categoryFor', () {
    test("'illimite' -> légère", () {
      expect(
        ArmorProficiencyCategoryRules.categoryFor('illimite'),
        ArmorProficiencyCategory.legere,
      );
    });

    test("'max_2' -> intermédiaire", () {
      expect(
        ArmorProficiencyCategoryRules.categoryFor('max_2'),
        ArmorProficiencyCategory.intermediaire,
      );
    });

    test("'aucun' -> lourde", () {
      expect(
        ArmorProficiencyCategoryRules.categoryFor('aucun'),
        ArmorProficiencyCategory.lourde,
      );
    });

    test('valeur inattendue -> null (filet de sécurité)', () {
      expect(ArmorProficiencyCategoryRules.categoryFor('???'), isNull);
    });
  });
}
