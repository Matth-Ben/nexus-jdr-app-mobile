import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/weapon_proficiency_category_rules.dart';

void main() {
  group('WeaponProficiencyCategoryRules.isCommon', () {
    const commonNames = [
      'Gourdin',
      'Dague',
      'Gourdin à deux mains',
      'Hachette',
      'Javeline',
      'Marteau léger',
      "Masse d'armes",
      'Bâton de combat',
      'Faucille',
      'Épieu',
      'Arbalète légère',
      'Dard',
      'Arc court',
      'Fronde',
    ];

    for (final name in commonNames) {
      test('$name est une arme courante', () {
        expect(WeaponProficiencyCategoryRules.isCommon(name), isTrue);
        expect(WeaponProficiencyCategoryRules.isMartial(name), isFalse);
      });
    }

    test('14 armes courantes au total (vérifie la liste n\'a pas grossi/'
        'rétréci par erreur)', () {
      expect(commonNames, hasLength(14));
    });

    test('insensible aux accents/casse', () {
      expect(WeaponProficiencyCategoryRules.isCommon('dague'), isTrue);
      expect(WeaponProficiencyCategoryRules.isCommon('DAGUE'), isTrue);
      expect(WeaponProficiencyCategoryRules.isCommon('epieu'), isTrue);
    });
  });

  group('WeaponProficiencyCategoryRules.isMartial', () {
    const martialNames = [
      "Hache d'armes",
      "Fléau d'armes",
      'Glaive',
      'Grande hache',
      'Épée à deux mains',
      'Hallebarde',
      'Lance de cavalerie',
      'Épée longue',
      'Maillet',
      'Morgenstern',
      'Pique',
      'Rapière',
      'Cimeterre',
      'Épée courte',
      'Trident',
      'Pic de guerre',
      'Marteau de guerre',
      'Fouet',
      'Sarbacane',
      'Arbalète de poing',
      'Arbalète lourde',
      'Arc long',
      'Filet',
    ];

    for (final name in martialNames) {
      test('$name est une arme de guerre', () {
        expect(WeaponProficiencyCategoryRules.isMartial(name), isTrue);
        expect(WeaponProficiencyCategoryRules.isCommon(name), isFalse);
      });
    }

    test('23 armes de guerre au total', () {
      expect(martialNames, hasLength(23));
    });
  });

  group('exclusion Mousquet/Pistolet (armes à poudre)', () {
    test('Mousquet n\'est ni courante ni de guerre', () {
      expect(WeaponProficiencyCategoryRules.isCommon('Mousquet'), isFalse);
      expect(WeaponProficiencyCategoryRules.isMartial('Mousquet'), isFalse);
    });

    test('Pistolet n\'est ni courant ni de guerre', () {
      expect(WeaponProficiencyCategoryRules.isCommon('Pistolet'), isFalse);
      expect(WeaponProficiencyCategoryRules.isMartial('Pistolet'), isFalse);
    });
  });

  test('un nom hors catalogue n\'est ni courant ni de guerre', () {
    expect(WeaponProficiencyCategoryRules.isCommon('Objet inconnu'), isFalse);
    expect(WeaponProficiencyCategoryRules.isMartial('Objet inconnu'), isFalse);
  });
}
