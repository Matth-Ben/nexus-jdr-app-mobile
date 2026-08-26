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
/// Pas non plus de choix de compétences/outils/langues octroyés par
/// l'historique à cette étape : `skill_proficiencies` de chaque
/// [BackgroundOption] n'est affiché que comme information ("Compétences :
/// X, Y"), jamais transformé en UI de sélection — même report que
/// `ClassCatalog` pour les compétences/outils de classe (repoussé à l'étape 5
/// "Compétences et outils", voir ce fichier pour le rationale détaillé) :
/// décision du chef de projet, pas un oubli.
@freezed
abstract class BackgroundCatalog with _$BackgroundCatalog {
  const factory BackgroundCatalog({
    required List<BackgroundOption> backgrounds,
  }) = _BackgroundCatalog;
}
