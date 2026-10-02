import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/spell_damage_dice_extractor.dart';

void main() {
  group('SpellDamageDiceExtractor.extract', () {
    test('description avec un motif net', () {
      expect(
        SpellDamageDiceExtractor.extract(
          'La cible doit subir 8d6 dégâts de feu lors d\'un échec.',
        ),
        (count: 8, sides: 6),
      );
    });

    test('description sans motif (sort utilitaire) -> null', () {
      expect(
        SpellDamageDiceExtractor.extract(
          'Vous créez une lumière vive dans un rayon de 6 mètres.',
        ),
        isNull,
      );
    });

    test('motif de mise à l\'échelle après le motif principal : ne retient '
        'que le premier', () {
      expect(
        SpellDamageDiceExtractor.extract(
          'La cible subit 3d8 dégâts de force (+1d8/niv au-delà du '
          'niveau 5).',
        ),
        (count: 3, sides: 8),
      );
    });

    test('description vide -> null', () {
      expect(SpellDamageDiceExtractor.extract(''), isNull);
    });
  });
}
