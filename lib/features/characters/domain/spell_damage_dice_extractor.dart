import 'dice_notation_parser.dart';

/// Extrait le premier dé de dégâts "NdM" mentionné dans la description d'un
/// sort (`spells.description`) — best-effort, aucune heuristique au-delà du
/// premier motif trouvé (ex. "3d8 ... +1d8/niveau" retient uniquement
/// "3d8"). Utilisé pour afficher [DiceTypeBadge]
/// (`core/widgets/dice_type_badge.dart`) à côté du nom du sort dans
/// `CharacterSpellsSection`.
///
/// Délègue le parsing/la validation du motif trouvé à [DiceNotationParser]
/// (même regex partagée, pas de duplication).
abstract final class SpellDamageDiceExtractor {
  static ({int count, int sides})? extract(String description) {
    final match = DiceNotationParser.pattern.firstMatch(description);
    if (match == null) {
      return null;
    }
    return DiceNotationParser.parse(match.group(0)!);
  }
}
