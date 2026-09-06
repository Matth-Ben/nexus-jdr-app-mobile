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
    this.isPact = false,
  });

  /// Entre 1 et 9 (`character_spell_slots.slot_level`), ou 1 à 5
  /// (`character_pact_slots.slot_level`) si [isPact] — les sorts mineurs
  /// (niveau 0) ne consomment jamais d'emplacement, donc aucune ligne de ce
  /// type n'existe niveau 0.
  final int level;

  final int total;
  final int used;

  /// `true` si cet emplacement provient de la magie de pacte de l'Occultiste
  /// (`character_pact_slots`) plutôt que d'un emplacement classique
  /// (`character_spell_slots`) — voir `domain/spell_slot_progression.dart`
  /// pour le rationale de la séparation des deux pools. Sert uniquement à
  /// distinguer les deux une fois fusionnés dans une même liste d'éligibilité
  /// (`presentation/widgets/spell_action_sheet.dart::castSpellFlow`) :
  /// [remaining]/[total]/[used] fonctionnent identiquement pour les deux.
  final bool isPact;

  /// `total - used`, jamais négatif même si `used` dépasse `total` (donnée
  /// serveur incohérente) ni supérieur à [total].
  int get remaining {
    final safeTotal = total < 0 ? 0 : total;
    return (safeTotal - used).clamp(0, safeTotal);
  }
}
