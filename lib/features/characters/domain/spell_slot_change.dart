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
