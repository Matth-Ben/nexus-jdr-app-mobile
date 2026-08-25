import 'package:freezed_annotation/freezed_annotation.dart';

import 'race_summary_formatter.dart';
import 'race_trait.dart';

part 'race_option.freezed.dart';

/// Une race sélectionnable à l'étape 1/9 de l'assistant de création
/// (`races`, voir `docs/cahier-des-charges/02-modele-donnees.md`).
///
/// [abilityBonuses] est gardé sous sa forme brute `Map<String, dynamic>`
/// (plutôt que `Map<String, int>`) : il peut contenir la clé spéciale
/// `choice_others` (bonus à caractéristiques au choix, ex. Demi-elfe) dont la
/// valeur n'est pas un simple entier — voir [RaceSummaryFormatter], qui
/// l'ignore explicitement dans le résumé court.
@freezed
abstract class RaceOption with _$RaceOption {
  const RaceOption._();

  const factory RaceOption({
    required int id,
    required String name,
    required Map<String, dynamic> abilityBonuses,
    required List<RaceTrait> traits,
  }) = _RaceOption;

  /// Ligne de résumé affichée sous le nom ("+2 Dex · Vision dans le noir ·
  /// Transe"), voir [RaceSummaryFormatter].
  String get summaryLine => RaceSummaryFormatter.format(
    abilityBonuses: abilityBonuses,
    traits: traits,
  );
}
