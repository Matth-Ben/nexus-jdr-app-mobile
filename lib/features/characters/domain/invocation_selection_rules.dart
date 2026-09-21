import 'level_up_invocation_option.dart';
import 'warlock_pact.dart';

/// Règles pures de l'étape "Invocations" de la montée de niveau : filtrage
/// des invocations éligibles, quota effectif et purge d'une sélection devenue
/// inéligible (ex. le joueur revient changer son choix de pacte ou de sort
/// mineur dans la même montée de niveau).
///
/// Ne revalide jamais rétroactivement les invocations déjà connues : seules
/// les candidates ([LevelUpInvocationOption], non connues) sont évaluées.
abstract final class InvocationSelectionRules {
  /// Sous-ensemble de [options] dont tous les prérequis sont satisfaits pour
  /// l'état donné — voir `InvocationPrerequisites.unmet`.
  static List<LevelUpInvocationOption> eligibleOptions(
    List<LevelUpInvocationOption> options, {
    required int warlockLevel,
    required WarlockPact? knownPact,
    required Set<int> knownCantripSpellIds,
  }) {
    return [
      for (final option in options)
        if (option
            .eligibilityFor(
              warlockLevel: warlockLevel,
              knownPact: knownPact,
              knownCantripSpellIds: knownCantripSpellIds,
            )
            .isEligible)
          option,
    ];
  }

  /// Quota EFFECTIF : `min(delta RAW, nombre d'invocations éligibles)` — l'app
  /// ne promet jamais un quota qu'elle ne peut pas tenir.
  static int effectiveQuota(
    List<LevelUpInvocationOption> options, {
    required int delta,
    required int warlockLevel,
    required WarlockPact? knownPact,
    required Set<int> knownCantripSpellIds,
  }) {
    final eligibleCount = eligibleOptions(
      options,
      warlockLevel: warlockLevel,
      knownPact: knownPact,
      knownCantripSpellIds: knownCantripSpellIds,
    ).length;
    return delta < eligibleCount ? delta : eligibleCount;
  }

  /// [selectedIds] (`invocation.id.toString()`) débarrassée des invocations
  /// devenues inéligibles (ou inconnues de [options]), ordre conservé, puis
  /// tronquée à [quota] si la sélection dépasse le quota effectif.
  static List<String> pruneSelection(
    List<String> selectedIds,
    List<LevelUpInvocationOption> options, {
    required int quota,
    required int warlockLevel,
    required WarlockPact? knownPact,
    required Set<int> knownCantripSpellIds,
  }) {
    final eligibleIds = {
      for (final option in eligibleOptions(
        options,
        warlockLevel: warlockLevel,
        knownPact: knownPact,
        knownCantripSpellIds: knownCantripSpellIds,
      ))
        option.id.toString(),
    };
    final kept = [
      for (final id in selectedIds)
        if (eligibleIds.contains(id)) id,
    ];
    return kept.length > quota ? kept.sublist(0, quota) : kept;
  }
}
