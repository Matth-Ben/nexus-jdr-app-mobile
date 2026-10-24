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

  /// `true` si [raceId] est une race "unifiée" en édition 2024 — Nain et
  /// Halfelin à ce jour, qui perdent toute notion de sous-race dans le
  /// Manuel des Joueurs (2024), chacune de ses anciennes sous-races (Nain
  /// des collines/des montagnes, Halfelin lígerpied/robuste...) étant
  /// fusionnée dans la race elle-même (`RaceOption.traits2024`) — voir
  /// `presentation/race_step_screen.dart::_submit`, qui saute entièrement
  /// `SubraceStepScreen` dans ce cas.
  ///
  /// Signal dérivé des données plutôt qu'une liste de races en dur (même
  /// principe que `LineageChoiceCatalog.isConcerned`) : [raceId] a un
  /// contenu 2024 propre (`RaceOption.traits2024` non nul) ET a des
  /// sous-races, ET AUCUNE de ses sous-races n'a elle-même de contenu 2024
  /// propre (contrairement à l'Elfe/au Gnome, dont certaines sous-races
  /// portent un contenu 2024 distinct de la race elle-même, voir
  /// `data/character_creation_repository.dart::createCharacter`).
  bool isUnifiedRaceIn2024(int raceId) {
    RaceOption? race;
    for (final candidate in races) {
      if (candidate.id == raceId) {
        race = candidate;
        break;
      }
    }
    if (race?.traits2024 == null) return false;
    final subracesList = subracesOf(raceId);
    if (subracesList.isEmpty) return false;
    return subracesList.every((subrace) => subrace.traits2024 == null);
  }
}
