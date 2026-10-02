// Tests unitaires de la normalisation de chaîne partagée pour le tri/les
// comparaisons alphabétiques français (`lib/core/utils/french_text_normalizer.dart`).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/utils/french_text_normalizer.dart';

void main() {
  group('FrenchTextNormalizer.normalize', () {
    test('minuscule et retire les accents français usuels', () {
      expect(FrenchTextNormalizer.normalize('Épée'), 'epee');
      expect(FrenchTextNormalizer.normalize('Œil'), 'oeil');
      expect(FrenchTextNormalizer.normalize('À'), 'a');
      expect(
        FrenchTextNormalizer.normalize('Héros du peuple'),
        'heros du peuple',
      );
      expect(FrenchTextNormalizer.normalize('Élémentaire'), 'elementaire');
    });

    test(
      'deux graphies différentes du même nom se normalisent à l\'identique',
      () {
        expect(
          FrenchTextNormalizer.normalize('matériel de peintre'),
          FrenchTextNormalizer.normalize('Matériel de Peintre'),
        );
        expect(
          FrenchTextNormalizer.normalize('véhicules (terrestres)'),
          FrenchTextNormalizer.normalize('Véhicules (Terrestres)'),
        );
      },
    );

    test('trim + espaces multiples réduits à un seul', () {
      expect(
        FrenchTextNormalizer.normalize('  Grand   voyageur  '),
        'grand voyageur',
      );
    });

    test('chaîne vide -> chaîne vide', () {
      expect(FrenchTextNormalizer.normalize(''), '');
      expect(FrenchTextNormalizer.normalize('   '), '');
    });

    test('œ et æ transcrits en deux lettres', () {
      expect(FrenchTextNormalizer.normalize('Œuf'), 'oeuf');
      expect(FrenchTextNormalizer.normalize('Nævus'), 'naevus');
    });
  });

  group('FrenchTextNormalizer.compare', () {
    test('ordre alphabétique insensible aux accents/casse', () {
      final names = ['Rapière', 'épée courte', 'Dague', 'Épée longue']
        ..sort(FrenchTextNormalizer.compare);
      expect(names, ['Dague', 'épée courte', 'Épée longue', 'Rapière']);
    });

    test('« É » ne se classe pas après « Z » (piège d\'un compareTo brut : le '
        'point de code UTF-16 de « É » est supérieur à celui de « Z »)', () {
      expect(FrenchTextNormalizer.compare('Éclair', 'Zèbre'), lessThan(0));
      expect('Éclair'.compareTo('Zèbre'), greaterThan(0));
    });
  });
}
