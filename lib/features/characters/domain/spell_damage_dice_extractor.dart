import 'dice_notation_parser.dart';
import 'spell_damage_dice_exceptions.dart';

/// Dé de dégâts d'un sort, affiché par [DiceTypeBadge]
/// (`core/widgets/dice_type_badge.dart`) à côté de son nom dans
/// `CharacterSpellsSection` et `PrepareSpellsSheet` — un seul point d'entrée
/// pour les deux écrans.
///
/// Applique d'abord [SpellDamageDiceExceptions] sur le nom français du sort
/// (sans pastille, ou dé imposé), puis, pour tout autre sort, retient le
/// premier motif "NdM" de sa description (`spells.description`) —
/// best-effort, aucune heuristique au-delà du premier motif trouvé (ex.
/// "3d8 ... +1d8/niveau" retient uniquement "3d8").
///
/// Délègue le parsing/la validation du motif trouvé à [DiceNotationParser]
/// (même regex partagée, pas de duplication).
abstract final class SpellDamageDiceExtractor {
  static ({int count, int sides})? extract({
    required String name,
    required String description,
  }) {
    if (SpellDamageDiceExceptions.hidesBadge(name)) {
      return null;
    }
    final forced = SpellDamageDiceExceptions.forcedDice(name);
    if (forced != null) {
      return forced;
    }
    final match = DiceNotationParser.pattern.firstMatch(description);
    if (match == null) {
      return null;
    }
    return DiceNotationParser.parse(match.group(0)!);
  }
}
