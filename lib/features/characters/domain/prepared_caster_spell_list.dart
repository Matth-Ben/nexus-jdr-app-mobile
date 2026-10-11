import '../../../core/rules/character_class.dart';
import '../../../core/rules/class_spellcasting_rule.dart';
import 'spell_slot_progression.dart';

/// Lanceurs à préparation qui ont accès à **toute** la liste de sorts de leur
/// classe (D&D 5e : Clerc, Druide, Paladin, et l'Artificier depuis D41 — le
/// Magicien, lui, prépare depuis son grimoire, alimenté à la montée de
/// niveau). Leur onglet "Sorts" affiche donc chaque sort de la classe, du
/// niveau 1 jusqu'au plus haut niveau lançable à leur niveau de classe, et le
/// joueur coche ceux qu'il prépare (décision utilisateur du 2026-09-24).
///
/// Classification déléguée au registre unique
/// `core/rules/class_spellcasting_rule.dart::ClassSpellcastingRegistry`
/// (`ClassSpellcastingRule.hasFullSpellListAccess`) — dette D04,
/// `docs/dette-technique.md`.
abstract final class PreparedCasterSpellList {
  static Set<String> get classNames => {
    for (final c in CharacterClass.values)
      if (ClassSpellcastingRegistry.ruleFor(c).hasFullSpellListAccess)
        c.frenchName,
  };

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
