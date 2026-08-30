// Tests unitaires de la normalisation de noms pour la résolution "en clair"
// de l'import XML aidedd.org
// (`lib/features/xml_import/domain/xml_name_normalizer.dart`).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/xml_import/domain/xml_name_normalizer.dart';

void main() {
  test('minuscule et retire les accents français usuels', () {
    expect(XmlNameNormalizer.normalize('Héros du peuple'), 'heros du peuple');
    expect(XmlNameNormalizer.normalize('Élémentaire'), 'elementaire');
    expect(XmlNameNormalizer.normalize('Occultiste'), 'occultiste');
  });

  test(
    'deux graphies différentes du même nom se normalisent à l\'identique',
    () {
      expect(
        XmlNameNormalizer.normalize('matériel de peintre'),
        XmlNameNormalizer.normalize('Matériel de Peintre'),
      );
      expect(
        XmlNameNormalizer.normalize('véhicules (terrestres)'),
        XmlNameNormalizer.normalize('Véhicules (Terrestres)'),
      );
    },
  );

  test('trim + espaces multiples réduits à un seul', () {
    expect(
      XmlNameNormalizer.normalize('  Grand   voyageur  '),
      'grand voyageur',
    );
  });

  test('chaîne vide -> chaîne vide', () {
    expect(XmlNameNormalizer.normalize(''), '');
    expect(XmlNameNormalizer.normalize('   '), '');
  });

  test('œ et æ transcrits en deux lettres', () {
    expect(XmlNameNormalizer.normalize('Œuf'), 'oeuf');
    expect(XmlNameNormalizer.normalize('Nævus'), 'naevus');
  });
}
