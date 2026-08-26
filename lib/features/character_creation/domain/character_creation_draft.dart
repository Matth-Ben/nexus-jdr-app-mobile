import 'package:freezed_annotation/freezed_annotation.dart';

import 'ability_score_method.dart';

part 'character_creation_draft.freezed.dart';

/// Brouillon du personnage en cours de création par l'assistant, tenu
/// **entièrement côté client** (aucune ligne `characters` en base tant que
/// l'étape 9 "Récapitulatif" n'a pas été validée — voir
/// `presentation/providers/character_creation_draft_provider.dart` pour le
/// notifier qui porte cet état et le compromis assumé sur la reprise après
/// fermeture complète de l'app).
///
/// Un seul modèle pour tout l'assistant (plutôt qu'un modèle par étape) :
/// chaque étape suivante (Classe, Historique...) ajoutera ses propres champs
/// nullable ici plutôt que de créer un brouillon par étape.
@freezed
abstract class CharacterCreationDraft with _$CharacterCreationDraft {
  const factory CharacterCreationDraft({
    /// Race choisie à l'étape 1, `null` si race personnalisée ou pas encore
    /// choisie.
    int? raceId,

    /// Sous-race choisie à l'étape 1, `null` si la race n'a pas de sous-race
    /// ou pas encore choisie.
    int? subraceId,

    /// Texte libre de race personnalisée (étape 1), `null` si une race du
    /// catalogue a été choisie à la place.
    String? raceCustomText,

    /// Classe choisie à l'étape 2, `null` si pas encore choisie. Pas de
    /// sous-classe ni de "classe personnalisée" à cette étape (décision du
    /// chef de projet, voir `domain/class_catalog.dart`).
    int? classId,

    /// Historique choisi à l'étape 3, `null` si pas encore choisi. Pas
    /// d'historique personnalisé à cette étape (décision du chef de projet,
    /// voir `domain/background_catalog.dart`).
    int? backgroundId,

    /// Méthode de génération des scores de caractéristiques choisie à
    /// l'étape 4, `null` si pas encore choisie (l'écran retombe alors sur
    /// `AbilityScoreMethod.standardArray` par défaut — voir
    /// `presentation/ability_score_step_screen.dart`).
    AbilityScoreMethod? abilityScoreMethod,

    /// Scores de base choisis à l'étape 4, clés
    /// 'str'/'dex'/'con'/'int'/'wis'/'cha' — **avant** application du bonus
    /// racial (voir `domain/ability_score_modifier_calculator.dart` pour le
    /// calcul du modificateur final affiché, qui l'ajoute). `null` si pas
    /// encore choisis.
    Map<String, int>? abilityScores,
  }) = _CharacterCreationDraft;
}
