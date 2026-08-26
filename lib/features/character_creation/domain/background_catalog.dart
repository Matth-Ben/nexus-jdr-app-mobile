import 'package:freezed_annotation/freezed_annotation.dart';

import 'background_option.dart';

part 'background_catalog.freezed.dart';

/// Catalogue complet des historiques de l'étape 3/9 de l'assistant de
/// création, récupéré en une fois au chargement de l'écran
/// (`data/character_creation_repository.dart`) — même rationale que
/// [ClassCatalog] pour l'étape 2 (volume faible, pas besoin de pagination).
///
/// Pas d'historique personnalisé (homebrew) à cette étape, contrairement à la
/// race (`race_step_selection.dart`) : ni la maquette
/// `04_étape_3_historique.png` ni `04-fonctionnalites-app-mobile.md` ne le
/// prévoient — décision du chef de projet.
///
/// Pas de choix de compétences octroyées par l'historique à *cette* étape
/// (3/9) : `skill_proficiencies` de chaque [BackgroundOption] n'est affiché
/// que comme information ("Compétences : X, Y"), jamais transformé en UI de
/// sélection à cette étape. Les outils/langues octroyés par l'historique
/// (`tool_or_language_choices`) existent bien sur [BackgroundOption]
/// (`toolOrLanguageGrantedTools`/`languageChoiceCount`), simplement pas
/// exploités par `presentation/background_step_screen.dart` : voir
/// `presentation/skills_and_tools_step_screen.dart` (étape 5/9) pour leur
/// seul usage.
@freezed
abstract class BackgroundCatalog with _$BackgroundCatalog {
  const factory BackgroundCatalog({
    required List<BackgroundOption> backgrounds,
  }) = _BackgroundCatalog;
}
