/// État PV d'un personnage manipulé par la feuille d'ajustement de la fiche
/// personnage (`presentation/widgets/hp_adjustment_sheet.dart`).
///
/// Petite classe immuable dédiée plutôt que de manipuler `CharacterDetail`
/// en entier ici : [HpAdjustmentCalculator] n'a besoin que de ces 3 champs,
/// et reste ainsi testable sans construire un `CharacterDetail` complet.
class HpState {
  const HpState({
    required this.currentHp,
    required this.maxHp,
    required this.temporaryHp,
  });

  final int currentHp;
  final int maxHp;
  final int temporaryHp;

  HpState copyWith({int? currentHp, int? maxHp, int? temporaryHp}) {
    return HpState(
      currentHp: currentHp ?? this.currentHp,
      maxHp: maxHp ?? this.maxHp,
      temporaryHp: temporaryHp ?? this.temporaryHp,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is HpState &&
      other.currentHp == currentHp &&
      other.maxHp == maxHp &&
      other.temporaryHp == temporaryHp;

  @override
  int get hashCode => Object.hash(currentHp, maxHp, temporaryHp);

  @override
  String toString() =>
      'HpState(currentHp: $currentHp, maxHp: $maxHp, temporaryHp: $temporaryHp)';
}

/// Logique pure de la feuille d'ajustement PV détaillée (bouton crayon du
/// bandeau PV) — voir la spec de la tâche qui a produit ce fichier pour le
/// détail des 3 règles ci-dessous, tranchées par le chef de projet.
///
/// Hors périmètre volontaire : repos court/long, dépense de dés de vie —
/// différés à un futur incrément (montée de niveau).
abstract final class HpAdjustmentCalculator {
  /// Dégâts : les PV temporaires sont absorbés en premier, le reliquat
  /// (s'il y en a) est retranché de `current_hp`, qui ne descend jamais sous
  /// 0. [amount] négatif ou nul ne change rien (garde de robustesse, le
  /// champ de saisie de la feuille d'ajustement ne devrait jamais produire
  /// de valeur négative).
  static HpState applyDamage(HpState state, int amount) {
    if (amount <= 0) return state;
    final absorbedByTemp = amount < state.temporaryHp
        ? amount
        : state.temporaryHp;
    final remaining = amount - absorbedByTemp;
    final newCurrent = (state.currentHp - remaining).clamp(0, state.maxHp);
    return state.copyWith(
      currentHp: newCurrent,
      temporaryHp: state.temporaryHp - absorbedByTemp,
    );
  }

  /// Soins : `current_hp = min(max_hp, current_hp + amount)`, n'affecte
  /// jamais `temporary_hp`. [amount] négatif ou nul ne change rien.
  static HpState applyHeal(HpState state, int amount) {
    if (amount <= 0) return state;
    final newCurrent = state.currentHp + amount > state.maxHp
        ? state.maxHp
        : state.currentHp + amount;
    return state.copyWith(currentHp: newCurrent);
  }

  /// PV temporaires : remplace `temporary_hp` par [amount] seulement si
  /// supérieur à la valeur actuelle — les PV temporaires ne se cumulent pas
  /// entre eux (règle RAW 5e, seul le plus élevé des deux est conservé).
  static HpState applyTemporaryHp(HpState state, int amount) {
    if (amount <= state.temporaryHp) return state;
    return state.copyWith(temporaryHp: amount);
  }
}
