import 'package:freezed_annotation/freezed_annotation.dart';

import 'combat_failure.dart';
import 'combat_snapshot.dart';

part 'combat_view_state.freezed.dart';

/// Phase de l'état de combat d'un groupe vue par l'écran.
enum CombatPhase {
  /// Premier chargement en cours (aucun état connu).
  loading,

  /// Aucun combat actif.
  none,

  /// Combat actif.
  active,

  /// Combat vu actif puis terminé (résumé : [CombatViewState.snapshot] garde
  /// le dernier état connu avant la fin).
  ended,

  /// Premier chargement échoué (aucun état connu à afficher).
  error,
}

/// État du combat d'un groupe, gardé **en mémoire** seulement (jamais
/// persisté) avec l'horodatage du dernier état connu.
@freezed
abstract class CombatViewState with _$CombatViewState {
  const CombatViewState._();

  const factory CombatViewState({
    required CombatPhase phase,

    /// Dernier état connu (combat actif, ou combat juste terminé).
    CombatSnapshot? snapshot,

    /// Horodatage (horloge injectée) du dernier refetch réussi.
    DateTime? lastKnownAt,

    /// `true` si le dernier refetch a échoué alors qu'un état était déjà
    /// connu : l'état affiché est périmé, lecture seule.
    @Default(false) bool isStale,

    /// Dernier échec (refetch ou premier chargement).
    CombatFailure? failure,
  }) = _CombatViewState;

  static const CombatViewState loading = CombatViewState(
    phase: CombatPhase.loading,
  );

  /// Lecture seule : état périmé (hors ligne ou refetch en échec).
  bool get isReadOnly => isStale;

  bool get hasActiveCombat => phase == CombatPhase.active;
}
