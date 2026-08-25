import 'package:freezed_annotation/freezed_annotation.dart';

import 'race_summary_formatter.dart';
import 'race_trait.dart';

part 'subrace_option.freezed.dart';

/// Une sous-race sélectionnable, affichée sous la liste des races une fois
/// une race qui en possède sélectionnée (`subraces`, voir
/// `docs/cahier-des-charges/02-modele-donnees.md`). Même structure que
/// [RaceOption] côté résumé — voir [RaceSummaryFormatter].
@freezed
abstract class SubraceOption with _$SubraceOption {
  const SubraceOption._();

  const factory SubraceOption({
    required int id,
    required int raceId,
    required String name,
    required Map<String, dynamic> abilityBonuses,
    required List<RaceTrait> traits,
  }) = _SubraceOption;

  /// Ligne de résumé affichée sous le nom, voir [RaceSummaryFormatter].
  String get summaryLine => RaceSummaryFormatter.format(
    abilityBonuses: abilityBonuses,
    traits: traits,
  );
}
