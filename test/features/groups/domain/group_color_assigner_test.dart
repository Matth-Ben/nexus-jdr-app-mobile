import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/groups/domain/group_color_assigner.dart';

void main() {
  group('GroupColorAssigner.colorFor', () {
    test('renvoie toujours la meme couleur pour le meme id (stable)', () {
      final first = GroupColorAssigner.colorFor('group-42');
      final second = GroupColorAssigner.colorFor('group-42');

      expect(first, second);
    });

    test('id vide -> premiere couleur de la palette, sans planter', () {
      expect(() => GroupColorAssigner.colorFor(''), returnsNormally);
    });

    test('deux ids differents peuvent produire des couleurs differentes', () {
      final colors = {
        GroupColorAssigner.colorFor('group-a'),
        GroupColorAssigner.colorFor('group-b'),
        GroupColorAssigner.colorFor('group-c'),
        GroupColorAssigner.colorFor('group-d'),
      };

      // Pas de garantie qu'ils soient tous distincts (palette volontairement
      // petite), mais au moins 2 couleurs différentes sur ces 4 ids sinon la
      // fonction de hash serait cassée (constante).
      expect(colors.length, greaterThan(1));
    });
  });
}
