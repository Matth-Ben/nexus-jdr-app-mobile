import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/ability_score_method.dart';
import '../../domain/character_creation_draft.dart';
import '../../domain/equipment_choice_tab.dart';

part 'character_creation_draft_provider.g.dart';

/// Brouillon en mémoire de la session de création en cours, réutilisé par
/// toutes les étapes de l'assistant (voir `domain/character_creation_draft.dart`).
///
/// Volontairement `keepAlive` : doit survivre à la navigation entre les
/// écrans de l'assistant (une étape par écran, poussés avec `context.push`)
/// pendant toute la session en cours.
///
/// Compromis assumé : cet état n'est *pas* persisté (ni en base, ni en cache
/// local `drift`) — une fermeture complète de l'application avant l'étape 9
/// "Récapitulatif" perd le brouillon en cours. C'est un renoncement
/// temporaire à la reprise de création après redémarrage de l'app (objectif
/// de l'ancienne architecture, qui persistait une ligne `characters`
/// incomplète dès l'étape 1 — voir le rapport de la tâche qui a supprimé
/// `CharacterCreationRepository.saveRaceStep`), pas un oubli : à traiter plus
/// tard, probablement avec la persistance locale `drift` du brouillon en
/// cours (au-delà des seules données de référence).
@Riverpod(keepAlive: true)
class CharacterCreationDraftController
    extends _$CharacterCreationDraftController {
  @override
  CharacterCreationDraft build() => const CharacterCreationDraft();

  /// Met à jour le choix de race/sous-race (ou race personnalisée) de
  /// l'étape 1. Remplace intégralement ces trois champs (pas de fusion
  /// partielle sur ces trois-là) via `copyWith` : l'appelant
  /// (`presentation/race_step_screen.dart`) doit toujours fournir la
  /// sélection complète et cohérente de l'écran, y compris les champs à
  /// effacer (ex. `subraceId: null` en cas de race sans sous-race). Les
  /// autres champs du brouillon (ex. `classId` de l'étape 2) sont conservés :
  /// revenir à l'étape 1 puis retaper "Suivant" ne doit pas effacer les
  /// choix déjà faits aux étapes suivantes.
  void setRace({int? raceId, int? subraceId, String? raceCustomText}) {
    state = state.copyWith(
      raceId: raceId,
      subraceId: subraceId,
      raceCustomText: raceCustomText,
    );
  }

  /// Met à jour le choix de classe de l'étape 2. Ne touche à aucun autre
  /// champ (fusion partielle via `copyWith`, contrairement à [setRace]) :
  /// cette étape n'a pas de sous-choix à effacer en fonction de la classe
  /// choisie (pas de sous-classe ici, voir `domain/class_catalog.dart`).
  void setClass({required int classId}) {
    state = state.copyWith(classId: classId);
  }

  /// Met à jour le choix d'historique de l'étape 3. Fusion partielle via
  /// `copyWith` (jamais `CharacterCreationDraft(...)` reconstruit de zéro) :
  /// même piège que documenté sur [setRace] déjà rencontré une fois en revue
  /// — reconstruire l'état effacerait silencieusement `raceId`/`classId` déjà
  /// choisis aux étapes précédentes. Pas de sous-choix à effacer ici (pas
  /// d'historique personnalisé, voir `domain/background_catalog.dart`), même
  /// rationale que [setClass].
  void setBackground({required int backgroundId}) {
    state = state.copyWith(backgroundId: backgroundId);
  }

  /// Met à jour la méthode et les scores de caractéristiques de l'étape 4.
  /// Fusion partielle via `copyWith` (même rationale que [setClass] et
  /// [setBackground]) : cette étape n'a pas de champ à effacer sur les
  /// étapes suivantes en fonction du choix fait ici.
  void setAbilityScores({
    required AbilityScoreMethod method,
    required Map<String, int> scores,
  }) {
    state = state.copyWith(abilityScoreMethod: method, abilityScores: scores);
  }

  /// Met à jour les compétences/outils/langues choisis à l'étape 5. Fusion
  /// partielle via `copyWith` (même rationale que [setClass]/[setBackground]/
  /// [setAbilityScores]) : cette étape n'a pas de champ à effacer sur les
  /// étapes suivantes en fonction du choix fait ici. Les trois listes sont
  /// toujours fournies ensemble (même si une section ne s'appliquait pas,
  /// auquel cas l'appelant fournit une liste vide) : voir
  /// `domain/character_creation_draft.dart` pour le rationale des noms
  /// plutôt que des ids stockés.
  void setSkillsAndTools({
    required List<String> classSkillChoices,
    required List<String> classToolChoices,
    required List<String> backgroundLanguageChoices,
  }) {
    state = state.copyWith(
      classSkillChoices: classSkillChoices,
      classToolChoices: classToolChoices,
      backgroundLanguageChoices: backgroundLanguageChoices,
    );
  }

  /// Met à jour les sorts choisis à l'étape 6 "Sorts". Fusion partielle via
  /// `copyWith` (même rationale que [setSkillsAndTools]) : cette étape n'a
  /// pas de champ à effacer sur les étapes suivantes en fonction du choix
  /// fait ici. Les deux listes sont toujours fournies ensemble (même si un
  /// onglet ne s'appliquait pas à cette classe, auquel cas l'appelant fournit
  /// une liste vide) — voir `domain/character_creation_draft.dart`.
  void setSpells({
    required List<String> classCantripChoices,
    required List<String> classLevelOneSpellChoices,
  }) {
    state = state.copyWith(
      classCantripChoices: classCantripChoices,
      classLevelOneSpellChoices: classLevelOneSpellChoices,
    );
  }

  /// Met à jour le choix d'équipement de l'étape 7 "Équipement de départ".
  /// Fusion partielle via `copyWith` (même rationale que [setSpells]) :
  /// [purchasedEquipment] est toujours fourni (liste/carte vide si l'onglet
  /// "Historique" est celui retenu) — voir `domain/character_creation_draft.dart`
  /// pour le rationale du choix mutuellement exclusif porté par
  /// [activeTab].
  void setEquipment({
    required EquipmentChoiceTab activeTab,
    required Map<String, int> purchasedEquipment,
  }) {
    state = state.copyWith(
      equipmentChoiceTab: activeTab,
      purchasedEquipment: purchasedEquipment,
    );
  }

  /// Met à jour les 9 champs texte libres de l'étape 8 "Apparence, histoire
  /// et portrait". Fusion partielle via `copyWith` (même rationale que
  /// [setSpells]/[setEquipment]) : cette étape n'a pas de champ à effacer sur
  /// l'étape suivante en fonction du choix fait ici. Les 9 valeurs sont
  /// toujours fournies ensemble (même si un champ est resté vide, auquel cas
  /// l'appelant fournit `null`) — voir `domain/character_creation_draft.dart`.
  void setAppearanceAndBackstory({
    required String? appearanceText,
    required String? traitsText,
    required String? idealsText,
    required String? bondsText,
    required String? flawsText,
    required String? backstoryText,
    required String? alliesText,
    required String? featuresText,
    required String? treasureText,
  }) {
    state = state.copyWith(
      appearanceText: appearanceText,
      traitsText: traitsText,
      idealsText: idealsText,
      bondsText: bondsText,
      flawsText: flawsText,
      backstoryText: backstoryText,
      alliesText: alliesText,
      featuresText: featuresText,
      treasureText: treasureText,
    );
  }

  /// Met à jour le nom du personnage saisi à l'étape 9 "Récapitulatif".
  /// Fusion partielle via `copyWith` (même rationale que les setters
  /// précédents). Contrairement aux étapes 1-8, l'étape 9 n'a pas de
  /// "Suivant" qui committerait ce champ au brouillon avant de naviguer (elle
  /// se termine soit par la création réelle du personnage, soit par un retour
  /// en arrière) — `presentation/summary_step_screen.dart` appelle donc cette
  /// méthode explicitement avant toute navigation qui la quitte (retour
  /// arrière, édition d'une étape antérieure), pas seulement à la
  /// soumission finale, pour ne jamais perdre silencieusement le nom déjà
  /// saisi.
  void setCharacterName(String? characterName) {
    state = state.copyWith(characterName: characterName);
  }

  /// Remet le brouillon à zéro. Appelé par `CharacterListScreen` avant de
  /// démarrer une nouvelle création ("+ Créer"), pour ne jamais reprendre
  /// silencieusement un brouillon abandonné d'une session précédente.
  void reset() => state = const CharacterCreationDraft();
}
