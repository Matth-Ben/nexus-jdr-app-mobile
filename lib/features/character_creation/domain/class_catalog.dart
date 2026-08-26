import 'package:freezed_annotation/freezed_annotation.dart';

import 'class_option.dart';

part 'class_catalog.freezed.dart';

/// Catalogue complet des classes de l'étape 2/9 de l'assistant de création,
/// récupéré en une fois au chargement de l'écran
/// (`data/character_creation_repository.dart`) — même rationale que
/// [RaceCatalog] pour l'étape 1 (volume faible, pas besoin de pagination).
///
/// Pas de sous-classes ici : contrairement à ce que la symétrie avec
/// race/sous-race pourrait suggérer, le choix de sous-classe n'intervient pas
/// à cette étape (ni la maquette `03_étape_2_classe.png`, ni
/// `docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` section 3 point
/// 2 ne le mentionnent) — décision du chef de projet.
///
/// Pas d'affichage/sélection des compétences ou outils octroyés par la
/// classe à *cette* étape (2/9) : `04-fonctionnalites-app-mobile.md` section
/// 3 point 2 les mentionne, mais ce texte précède le découpage détaillé en 9
/// étapes de `09-maquettes-captures.md`, qui a une étape 5 dédiée
/// "Compétences et outils" séparée de celle-ci — la maquette
/// `03_étape_2_classe.png` ne montre qu'un choix de classe simple. Ces
/// champs existent bien sur [ClassOption] (`skillChoices`/`toolChoice`/
/// `grantedToolNames`), simplement pas exploités par
/// `presentation/class_step_screen.dart` : voir
/// `presentation/skills_and_tools_step_screen.dart` (étape 5/9) pour leur
/// seul usage.
@freezed
abstract class ClassCatalog with _$ClassCatalog {
  const factory ClassCatalog({required List<ClassOption> classes}) =
      _ClassCatalog;
}
