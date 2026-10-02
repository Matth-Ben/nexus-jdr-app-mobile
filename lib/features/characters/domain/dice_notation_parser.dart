/// Parse une notation de dé "NdM" (ex. "1d8", "2 D 6") à partir d'une chaîne
/// quelconque — utilisé pour extraire le dé de dégâts d'une arme
/// ([CharacterInventoryWeaponProperties.damageDice]) afin d'afficher
/// [DiceTypeBadge] (`core/widgets/dice_type_badge.dart`).
///
/// Motif partagé avec `SpellDamageDiceExtractor`, qui applique la même
/// regex directement sur une description de sort plutôt que sur une
/// notation déjà isolée.
abstract final class DiceNotationParser {
  /// Regex du motif "NdM" : un ou plusieurs chiffres, `d`/`D` (espaces
  /// tolérés autour), un ou plusieurs chiffres.
  static final RegExp pattern = RegExp(r'(\d+)\s*[dD]\s*(\d+)');

  /// Extrait le premier motif "NdM" de [raw]. Retourne `null` si aucun motif
  /// trouvé, ou si le nombre de dés ou le nombre de faces vaut 0 (notation
  /// dégénérée, ne doit jamais arriver en pratique mais pas de division par
  /// zéro/forme vide à prévoir côté affichage).
  static ({int count, int sides})? parse(String raw) {
    final match = pattern.firstMatch(raw);
    if (match == null) {
      return null;
    }
    final count = int.parse(match.group(1)!);
    final sides = int.parse(match.group(2)!);
    if (count <= 0 || sides <= 0) {
      return null;
    }
    return (count: count, sides: sides);
  }
}
