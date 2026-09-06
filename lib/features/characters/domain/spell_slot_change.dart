/// Changement du total d'emplacements de sorts d'un niveau de sort donné,
/// entre `targetLevel - 1` et `targetLevel` (personnage) — étape "Sorts" de
/// la montée de niveau (increment 3, `presentation/level_up_screen.dart`),
/// voir `domain/spell_slot_progression.dart::SpellSlotProgression.changesFor`.
///
/// Volontairement une classe simple (pas `freezed`), même précédent que
/// [CharacterClassFeature]/[LevelUpLevelData] : donnée en lecture seule,
/// construite une fois par [LevelUpStepData].
class SpellSlotChange {
  const SpellSlotChange({
    required this.spellLevel,
    required this.oldTotal,
    required this.newTotal,
  });

  /// Niveau de sort concerné, entre 1 et 9 (jamais 0 : les cantrips ne
  /// consomment jamais d'emplacement, voir `domain/character_spell_slot.dart`).
  final int spellLevel;

  /// Total théorique à `targetLevel - 1` (jamais lu en base — voir le point
  /// critique de la spec visuelle direction-artistique de l'étape "Sorts").
  final int oldTotal;

  /// Total théorique à `targetLevel`.
  final int newTotal;

  /// Cas A de la spec visuelle : ce palier n'existait pas du tout avant ce
  /// niveau ("Nouveaux emplacements de sorts / Niveau $spellLevel débloqué").
  bool get isNewlyUnlocked => oldTotal == 0 && newTotal > 0;

  /// Cas B de la spec visuelle : ce palier existait déjà et se renforce
  /// ("Emplacements de sorts renforcés / Niveau $spellLevel : $oldTotal →
  /// $newTotal (+$delta)").
  int get delta => newTotal - oldTotal;

  @override
  bool operator ==(Object other) =>
      other is SpellSlotChange &&
      other.spellLevel == spellLevel &&
      other.oldTotal == oldTotal &&
      other.newTotal == newTotal;

  @override
  int get hashCode => Object.hash(spellLevel, oldTotal, newTotal);

  @override
  String toString() =>
      'SpellSlotChange(spellLevel: $spellLevel, oldTotal: $oldTotal, '
      'newTotal: $newTotal)';
}

/// Changement de la magie de pacte de l'Occultiste (charges/niveau de
/// charge), entre le niveau de personnage précédent et le niveau ciblé —
/// équivalent de [SpellSlotChange] pour ce mécanisme séparé (voir
/// `domain/spell_slot_progression.dart::SpellSlotProgression.pactChangeFor`).
///
/// Volontairement une classe simple (pas `freezed`), même précédent que
/// [SpellSlotChange].
class PactSlotChange {
  const PactSlotChange({
    required this.oldCharges,
    required this.newCharges,
    required this.oldSlotLevel,
    required this.newSlotLevel,
  });

  /// Nombre de charges avant ce niveau, 0 si l'Occultiste vient d'être
  /// multiclassé ce niveau précis (pas de niveau antérieur dans cette
  /// classe).
  final int oldCharges;

  final int newCharges;

  /// Niveau des charges de pacte avant ce niveau, 0 si l'Occultiste vient
  /// d'être multiclassé ce niveau précis — jamais un vrai niveau de sort 0
  /// (voir [PactSlotChange.oldCharges]).
  final int oldSlotLevel;

  final int newSlotLevel;

  @override
  bool operator ==(Object other) =>
      other is PactSlotChange &&
      other.oldCharges == oldCharges &&
      other.newCharges == newCharges &&
      other.oldSlotLevel == oldSlotLevel &&
      other.newSlotLevel == newSlotLevel;

  @override
  int get hashCode =>
      Object.hash(oldCharges, newCharges, oldSlotLevel, newSlotLevel);

  @override
  String toString() =>
      'PactSlotChange(oldCharges: $oldCharges, newCharges: $newCharges, '
      'oldSlotLevel: $oldSlotLevel, newSlotLevel: $newSlotLevel)';
}
