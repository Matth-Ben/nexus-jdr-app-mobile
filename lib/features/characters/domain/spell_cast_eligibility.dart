import 'character_spell_slot.dart';

/// Logique de sélection/repli pour l'action "Lancer" d'un sort niveau ≥ 1
/// (`presentation/widgets/spell_action_sheet.dart`) : quels niveaux
/// d'emplacement sont éligibles pour lancer un sort de niveau [spellLevel],
/// et lequel présélectionner dans la sheet de choix quand plusieurs le sont.
///
/// Pas de sort niveau 0 ici (les sorts mineurs ne consomment jamais
/// d'emplacement, voir [CharacterSpellSlot]) — [hasAvailableSlot] retourne
/// toujours `true` pour ce cas, seul appelé pertinent pour un sort niveau 0
/// (l'action "Lancer" n'est alors jamais désactivée, voir la spec visuelle).
abstract final class SpellCastEligibility {
  /// Tous les niveaux d'emplacement `>= spellLevel`, triés par niveau
  /// croissant — un niveau épuisé (`remaining == 0`) reste listé, jamais
  /// masqué (spec visuelle : "un niveau épuisé reste listé").
  static List<CharacterSpellSlot> eligibleSlots({
    required List<CharacterSpellSlot> spellSlots,
    required int spellLevel,
  }) {
    final eligible =
        spellSlots.where((slot) => slot.level >= spellLevel).toList()
          ..sort((a, b) => a.level.compareTo(b.level));
    return eligible;
  }

  /// Vrai s'il existe au moins un niveau éligible avec `remaining > 0` — un
  /// sort de niveau 0 n'a rien à vérifier et retourne toujours `true`.
  static bool hasAvailableSlot({
    required List<CharacterSpellSlot> spellSlots,
    required int spellLevel,
  }) {
    if (spellLevel <= 0) return true;
    return eligibleSlots(
      spellSlots: spellSlots,
      spellLevel: spellLevel,
    ).any((slot) => slot.remaining > 0);
  }

  /// Niveau présélectionné dans la sheet de choix (plusieurs niveaux
  /// éligibles) : le plus petit niveau éligible avec `remaining > 0`, `null`
  /// si aucun (l'action "Lancer" est alors désactivée en amont, voir
  /// [hasAvailableSlot] — cette sheet ne devrait jamais s'ouvrir dans ce
  /// cas).
  static int? defaultSelectedLevel({
    required List<CharacterSpellSlot> spellSlots,
    required int spellLevel,
  }) {
    for (final slot in eligibleSlots(
      spellSlots: spellSlots,
      spellLevel: spellLevel,
    )) {
      if (slot.remaining > 0) return slot.level;
    }
    return null;
  }
}
