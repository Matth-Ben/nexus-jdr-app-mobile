import 'character_spell_slot.dart';

/// Formatte les emplacements de sorts d'un niveau en pastilles pleines/vides
/// (ex. "●●○" pour 2 emplacements restants sur 3) — section "SORTS" de
/// l'onglet Compétences, voir
/// `presentation/widgets/character_spells_section.dart`.
abstract final class SpellSlotPipsFormatter {
  static const String _filled = '●';
  static const String _empty = '○';

  static String format(CharacterSpellSlot slot) {
    final total = slot.total < 0 ? 0 : slot.total;
    final remaining = slot.remaining;
    return _filled * remaining + _empty * (total - remaining);
  }
}
