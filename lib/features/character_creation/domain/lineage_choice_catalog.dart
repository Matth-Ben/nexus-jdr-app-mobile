import 'package:freezed_annotation/freezed_annotation.dart';

import 'lineage_option.dart';

part 'lineage_choice_catalog.freezed.dart';

/// Lignées 2024 à choisir à l'étape 1/9 "Race", sans sous-race, par
/// `races.id` — mirroring `SubclassChoiceCatalog` (`optionsByClassId` ->
/// [optionsByRaceId]).
///
/// Une seule requête couvre TOUTES les races concernées (voir
/// `data/lineage_choice_repository.dart`), plutôt qu'une méthode paramétrée
/// par `raceId` : le volume de données est trivial (moins de 20 lignes au
/// total, voir la doc de classe du mapper), et `RaceStepScreen._submit` a
/// besoin d'une réponse déjà résolue pour décider instantanément, pour
/// N'IMPORTE QUELLE race sélectionnée, si elle pousse `LineageStepScreen` ou
/// l'étape 2/9 directement — exactement le même besoin qui a motivé le choix
/// "toutes les classes en une requête" de [SubclassChoiceCatalog] pour
/// `ClassStepScreen`.
@freezed
abstract class LineageChoiceCatalog with _$LineageChoiceCatalog {
  const LineageChoiceCatalog._();

  const factory LineageChoiceCatalog({
    required Map<int, List<LineageOption>> optionsByRaceId,
  }) = _LineageChoiceCatalog;

  /// `true` si [raceId] a au moins une lignée 2024 à choisir sans sous-race
  /// — critère de déclenchement de `LineageStepScreen` (voir
  /// `presentation/race_step_screen.dart::_submit`).
  bool isConcerned(int raceId) => optionsByRaceId[raceId]?.isNotEmpty ?? false;

  /// Options de [raceId], liste vide si la race n'en a aucune.
  List<LineageOption> optionsFor(int raceId) =>
      optionsByRaceId[raceId] ?? const [];

  /// Nom (déjà raccourci/affiché) de la lignée [lineageId] de [raceId],
  /// `null` si introuvable.
  String? nameOf({required int raceId, required int lineageId}) {
    for (final option in optionsFor(raceId)) {
      if (option.id == lineageId) return option.name;
    }
    return null;
  }
}
