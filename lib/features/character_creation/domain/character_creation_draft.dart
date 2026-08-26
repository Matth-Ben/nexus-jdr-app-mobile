import 'package:freezed_annotation/freezed_annotation.dart';

import 'ability_score_method.dart';
import 'equipment_choice_tab.dart';

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

    /// Compétences de classe choisies à l'étape 5 (noms affichés, ex.
    /// "Arcanes", pas des ids `skills.id`). Liste vide tant qu'aucune n'est
    /// choisie.
    ///
    /// Décision assumée (voir `presentation/skills_and_tools_step_screen.dart`)
    /// : le brouillon garde des **noms** plutôt que des ids `skills`/`tools`/
    /// `languages` réels pour les trois champs de cette étape — la
    /// résolution fine vers ces ids est repoussée à l'étape 9
    /// "Récapitulatif" (pas encore implémentée), seule étape qui écrira
    /// réellement des lignes en base. Ce choix évite de faire porter à cette
    /// étape une jointure supplémentaire (nom -> id) dont le résultat
    /// n'est utile qu'au moment d'écrire en base, à l'étape 9.
    @Default(<String>[]) List<String> classSkillChoices,

    /// Outils/instruments de classe choisis à l'étape 5 (noms affichés),
    /// vide si la classe n'a pas de choix interactif d'outils
    /// (`ClassOption.toolChoice` `null`) ou si aucun n'est encore choisi.
    /// Même décision noms-plutôt-qu'ids que [classSkillChoices].
    @Default(<String>[]) List<String> classToolChoices,

    /// Langues d'historique choisies à l'étape 5 (noms affichés), vide si
    /// l'historique n'offre pas de choix de langue
    /// (`BackgroundOption.languageChoiceCount` `null`) ou si aucune n'est
    /// encore choisie. Même décision noms-plutôt-qu'ids que
    /// [classSkillChoices].
    @Default(<String>[]) List<String> backgroundLanguageChoices,

    /// Sorts mineurs ("cantrips") choisis à l'étape 6 (noms affichés). Vide
    /// tant qu'aucun n'est choisi, et reste vide en permanence pour une
    /// classe non lanceuse de sorts ou une classe lanceuse sans quota de
    /// cantrips (Paladin/Rôdeur, voir `domain/spellcasting_rules.dart`) —
    /// cette étape est alors sautée entièrement (voir
    /// `presentation/skills_and_tools_step_screen.dart`). Même décision
    /// noms-plutôt-qu'ids que [classSkillChoices].
    @Default(<String>[]) List<String> classCantripChoices,

    /// Sorts de niveau 1 choisis à l'étape 6 (noms affichés), même rationale
    /// que [classCantripChoices].
    @Default(<String>[]) List<String> classLevelOneSpellChoices,

    /// Onglet actif de l'étape 7 "Équipement de départ" au moment de
    /// "Suivant", `null` tant que l'étape n'a pas encore été validée une
    /// première fois. Détermine lequel de [purchasedEquipment] ou de
    /// l'équipement de l'historique choisi (recalculé à l'étape 9
    /// "Récapitulatif" à partir de `backgroundId`, jamais dupliqué ici) est
    /// retenu — voir `domain/equipment_choice_tab.dart` pour le rationale du
    /// choix mutuellement exclusif.
    EquipmentChoiceTab? equipmentChoiceTab,

    /// Panier de l'onglet "Acheter" de l'étape 7 (`{nom d'objet: quantité}`),
    /// même décision noms-plutôt-qu'ids que [classSkillChoices]. Conservé
    /// même si [equipmentChoiceTab] vaut `EquipmentChoiceTab.background` au
    /// moment de "Suivant" (panier préservé au changement d'onglet, voir
    /// `presentation/equipment_step_screen.dart`) : c'est
    /// [equipmentChoiceTab], pas la présence de ce champ, qui détermine ce
    /// qui est effectivement retenu à l'étape 9.
    @Default(<String, int>{}) Map<String, int> purchasedEquipment,
  }) = _CharacterCreationDraft;
}
