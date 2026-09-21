import '../../character_creation/domain/ability_score_rules.dart';
import 'character_detail_class_row.dart';

/// Limite de sorts préparés (5e RAW) des classes qui PRÉPARENT leurs sorts :
/// Clerc/Druide (Sagesse + niveau), Magicien (Intelligence + niveau) et
/// Paladin (Charisme + moitié du niveau arrondie à l'inférieur). Minimum 1
/// dans tous les cas.
///
/// Les classes à sorts connus (Barde, Ensorceleur, Occultiste, Rôdeur) et les
/// classes non lanceuses (les sous-classes lanceuses du Guerrier/Roublard ne
/// sont pas modélisées) n'ont pas de limite de préparation : [limitFor]
/// renvoie `null`.
abstract final class PreparedSpellsLimit {
  /// Clé de caractéristique d'incantation ('wis'/'int'/'cha') des classes qui
  /// préparent leurs sorts, `null` pour toute autre classe.
  static String? abilityKeyFor(String className) => switch (className) {
    'Clerc' || 'Druide' => 'wis',
    'Magicien' => 'int',
    'Paladin' => 'cha',
    _ => null,
  };

  /// Vrai si [className] prépare ses sorts.
  static bool preparesSpells(String className) =>
      abilityKeyFor(className) != null;

  /// Limite de sorts préparés d'une classe, `null` si [className] ne prépare
  /// pas ses sorts. [abilityModifier] est le modificateur de la
  /// caractéristique d'incantation de la classe (voir [abilityKeyFor]).
  static int? limitFor({
    required String className,
    required int classLevel,
    required int abilityModifier,
  }) {
    final base = switch (className) {
      'Clerc' || 'Druide' || 'Magicien' => classLevel,
      'Paladin' => classLevel ~/ 2,
      _ => null,
    };
    if (base == null) return null;
    final limit = base + abilityModifier;
    return limit < 1 ? 1 : limit;
  }

  /// Limite à afficher pour un personnage, `null` (rien à afficher) si aucune
  /// classe ne prépare, ou si PLUSIEURS classes préparent : le nombre de sorts
  /// préparés n'est pas ventilé par classe (le décompte porte sur tous les
  /// sorts du personnage), une limite par classe donnerait un chiffre faux.
  static int? limitForCharacter({
    required List<CharacterDetailClassRow> classes,
    required Map<String, int> abilityScores,
  }) {
    final preparing = [
      for (final row in classes)
        if (preparesSpells(row.className)) row,
    ];
    if (preparing.length != 1) return null;
    final row = preparing.single;
    final score = abilityScores[abilityKeyFor(row.className)] ?? 10;
    return limitFor(
      className: row.className,
      classLevel: row.level,
      abilityModifier: AbilityScoreRules.abilityModifier(score),
    );
  }
}
