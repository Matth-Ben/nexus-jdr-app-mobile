/// Matrices 16×16 **provisoires** des icônes pixel du résultat naturel du dé
/// animé (P2b) : étoile (20 naturel) et crâne (1 naturel). Mêmes règles de
/// forme que les conditions (`docs/p6-icones-conditions.md`) : 16 lignes de
/// 16 caractères, `#` = cellule pleine. À remplacer par le jeu définitif de
/// la direction artistique.
library;

const String kDieStarKey = 'star';
const String kDieSkullKey = 'skull';

const Map<String, List<String>> kDieResultPixelMatrices = {
  kDieStarKey: [
    '................',
    '.......##.......',
    '.......##.......',
    '......####......',
    '......####......',
    '..############..',
    '.##############.',
    '..############..',
    '...##########...',
    '....########....',
    '....########....',
    '...####..####...',
    '...###....###...',
    '..##........##..',
    '................',
    '................',
  ],
  kDieSkullKey: [
    '................',
    '....########....',
    '...##########...',
    '..############..',
    '..############..',
    '..###..##..###..',
    '..###..##..###..',
    '..############..',
    '...##########...',
    '....########....',
    '....#.#..#.#....',
    '....#.#..#.#....',
    '....########....',
    '................',
    '................',
    '................',
  ],
};
