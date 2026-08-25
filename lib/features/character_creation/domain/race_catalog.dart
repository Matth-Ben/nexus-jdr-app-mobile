import 'package:freezed_annotation/freezed_annotation.dart';

import 'race_option.dart';
import 'subrace_option.dart';

part 'race_catalog.freezed.dart';

/// Catalogue complet races + sous-races de l'étape 1/9 de l'assistant de
/// création, récupéré en une fois au chargement de l'écran
/// (`data/character_creation_repository.dart`) : volume faible (quelques
/// dizaines de lignes, voir `docs/cahier-des-charges/01-architecture-technique.md`),
/// pas besoin de paginer ni de charger les sous-races à la demande par race.
@freezed
abstract class RaceCatalog with _$RaceCatalog {
  const RaceCatalog._();

  const factory RaceCatalog({
    required List<RaceOption> races,
    required List<SubraceOption> subraces,
  }) = _RaceCatalog;

  /// Sous-races de la race [raceId], dans leur ordre d'origine. Liste vide
  /// si cette race n'a pas de sous-race (cas normal pour la plupart des
  /// races).
  List<SubraceOption> subracesOf(int raceId) =>
      subraces.where((subrace) => subrace.raceId == raceId).toList();
}
