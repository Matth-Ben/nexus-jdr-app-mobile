/// Emplacements de sorts d'un niveau donné (`character_spell_slots`), pour
/// la section "SORTS" de l'onglet Compétences — voir
/// `presentation/widgets/character_spells_section.dart` et
/// `spell_slot_pips_formatter.dart` pour l'affichage en pastilles.
///
/// Volontairement une classe simple (pas `freezed`), même précédent que
/// `CharacterDetailClassRow`.
class CharacterSpellSlot {
  const CharacterSpellSlot({
    required this.level,
    required this.total,
    required this.used,
  });

  /// Entre 1 et 9 (`character_spell_slots.slot_level`) — les sorts mineurs
  /// (niveau 0) ne consomment jamais d'emplacement, donc aucune ligne de ce
  /// type n'existe niveau 0.
  final int level;

  final int total;
  final int used;

  /// `total - used`, jamais négatif même si `used` dépasse `total` (donnée
  /// serveur incohérente) ni supérieur à [total].
  int get remaining {
    final safeTotal = total < 0 ? 0 : total;
    return (safeTotal - used).clamp(0, safeTotal);
  }
}
