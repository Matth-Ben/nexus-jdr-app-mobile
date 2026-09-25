import 'spell_slot_progression.dart';

/// Lanceurs à préparation qui ont accès à **toute** la liste de sorts de leur
/// classe (D&D 5e : Clerc, Druide, Paladin — le Magicien, lui, prépare depuis
/// son grimoire, alimenté à la montée de niveau). Leur onglet "Sorts" affiche
/// donc chaque sort de la classe, du niveau 1 jusqu'au plus haut niveau
/// lançable à leur niveau de classe, et le joueur coche ceux qu'il prépare
/// (décision utilisateur du 2026-09-24).
abstract final class PreparedCasterSpellList {
  static const Set<String> classNames = {'Clerc', 'Druide', 'Paladin'};

  /// Plus haut niveau de sort accessible à [className] au niveau de classe
  /// [classLevel] (0 : aucun, ex. Paladin niveau 1 ou classe non concernée).
  /// Calculé sur la seule progression de cette classe, comme le veut la
  /// règle de préparation d'un personnage multiclassé.
  static int maxSpellLevelFor(String className, int classLevel) {
    if (!classNames.contains(className)) return 0;
    return SpellSlotProgression.maxCastableSpellLevel(
      SpellSlotProgression.slotsForLevel(className, classLevel),
    );
  }
}
