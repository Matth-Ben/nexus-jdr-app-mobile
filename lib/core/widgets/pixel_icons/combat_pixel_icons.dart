/// Icône pixel 16×16 « épées croisées » du combat de groupe (`combat_swords`),
/// dessinée avec `PixelIcon` (voir `docs/combat-groupe-ui.md` §0). À valider
/// visuellement à 16 et 32 dp comme les icônes de P6
/// (`docs/p6-icones-conditions.md`) : deux lames croisées, gardes horizontales
/// de 4 cellules (ligne 10) puis pommeaux en bas. Le motif occupe les lignes
/// 1 à 14 (centré verticalement, une ligne vide en haut et en bas). `#` =
/// pixel plein, `.` = vide.
const List<String> kCombatSwordsMatrix = [
  '................',
  '##............##',
  '###..........###',
  '.###........###.',
  '..###......###..',
  '...###....###...',
  '....###..###....',
  '.....######.....',
  '......####......',
  '.....######.....',
  '..####....####..',
  '..#####..#####..',
  '..###......###..',
  '.####......####.',
  '..##........##..',
  '................',
];
