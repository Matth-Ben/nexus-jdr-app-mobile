// Non-régression des quatre icônes redessinées le 12/11/2026
// (`docs/p6-icones-conditions.md`, addendum) : une matrice ne doit pas
// changer par accident. Modifier une de ces matrices impose de mettre à jour
// ce contenu attendu, donc de le faire sciemment.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/pixel_icon.dart';
import 'package:personnages/core/widgets/pixel_icons/condition_pixel_icons.dart';

const _expected = <String, List<String>>{
  'grappled': [
    '................',
    '................',
    '.##############.',
    '.#..#..#..#...#.',
    '.#..#..#..#...#.',
    '.##############.',
    '.#............#.',
    '.#.######.....#.',
    '.#.######.....#.',
    '.#............#.',
    '.#............#.',
    '..#..........#..',
    '...##########...',
    '................',
    '................',
    '................',
  ],
  'prone': [
    '................',
    '................',
    '................',
    '................',
    '................',
    '.............###',
    '.###.......####.',
    '#####.########..',
    '#####.#####.....',
    '#####.#########.',
    '.###.......#####',
    '................',
    '################',
    '.##############.',
    '................',
    '................',
  ],
  'stunned': [
    '................',
    '........#.......',
    '..#....###......',
    '.###....#....#..',
    '..#.........###.',
    '.............#..',
    '................',
    '.....######.....',
    '....########....',
    '....#..##..#....',
    '....#..##..#....',
    '....########....',
    '....##....##....',
    '.....######.....',
    '......####......',
    '................',
  ],
  'unconscious': [
    '................',
    '.........######.',
    '............##..',
    '...........##...',
    '..........##....',
    '.........######.',
    '................',
    '.....####.......',
    '....######......',
    '...########.....',
    '...#..##..#.....',
    '...########.....',
    '...###..###.....',
    '....######......',
    '.....####.......',
    '................',
  ],
};

void main() {
  group('icônes redessinées (12/11/2026)', () {
    _expected.forEach((key, matrix) {
      test('$key : matrice inchangée', () {
        expect(kConditionPixelMatrices[key], matrix);
      });

      for (final size in const [16, 32]) {
        testWidgets('$key : rendu à $size dp sans exception', (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Align(
                alignment: Alignment.topLeft,
                child: PixelIcon(matrix: matrix, size: size.toDouble()),
              ),
            ),
          );
          expect(tester.takeException(), isNull);
          expect(
            tester.getSize(find.byType(PixelIcon)),
            Size(size.toDouble(), size.toDouble()),
          );
        });
      }
    });
  });
}
