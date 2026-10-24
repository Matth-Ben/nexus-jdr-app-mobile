import 'dart:typed_data';

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

  /// Met à jour l'édition de règles choisie à l'étape 1 "Édition"
  /// (`EditionStepScreen`, TOUTE PREMIÈRE étape de l'assistant) — voir
  /// `domain/character_creation_draft.dart::edition`.
  ///
  /// Si [edition] diffère RÉELLEMENT de celle déjà en brouillon (retour en
  /// arrière depuis une étape suivante — possible malgré la doc d'origine
  /// de cette méthode, qui supposait à tort "aucun choix fait avant celle-
  /// ci" — puis nouveau choix sur `EditionStepScreen`), efface intégralement
  /// l'identité de race et tout ce qui en dérive :
  /// `raceId`/`subraceId`/`raceCustomText`, `lineageId`,
  /// `racialBonusChoices`, `raceSkillChoices`/`raceToolChoices` (carte
  /// "CHOIX DE RACE", même rationale que [setRace]). Bug corrigé (retour
  /// QA, chantier "différenciation 2014/2024 pour les races", 24/10/2026) :
  /// avant ce correctif, une race/sous-race/lignée choisie dans l'ancienne
  /// édition restait dans le brouillon après un changement d'édition, et
  /// `RaceStepScreen`/`LineageStepScreen` la réhydrataient telle quelle à
  /// l'écran (`initState`) sans revérifier sa disponibilité dans la
  /// NOUVELLE édition (`RaceStepScreen._isRaceAvailable`,
  /// `RaceCatalog.isUnifiedRaceIn2024`, `LineageChoiceRepository
  /// .fetchLineageChoices`) — laissant "Suivant" actif sur une sélection
  /// devenue RAW-invalide (ex. Demi-elfe choisi en 2014, encore sélectionné
  /// après bascule vers 2024, sans aucun message).
  ///
  /// `abilityScores`/`abilityScoreMethod` ne sont PAS effacés : les scores
  /// DE BASE (avant bonus racial) sont indépendants de l'édition — seule
  /// leur mise en forme (bonus fixe vs choix libre, voir
  /// `presentation/ability_score_step_screen.dart`) en dépend, déjà
  /// recalculée à chaque visite de cette étape à partir de [racialBonusChoices]
  /// (effacé ci-dessus) et de l'édition courante, sans rien stocker de
  /// périmé dans le brouillon.
  ///
  /// Si [edition] ne change PAS (ex. l'utilisateur retape "Suivant" sur
  /// `EditionStepScreen` sans rien changer, y compris à la toute première
  /// visite), aucun champ n'est effacé — comportement d'avant ce correctif,
  /// inchangé.
  void setEdition(String edition) {
    if (state.edition == edition) return;
    state = state.copyWith(
      edition: edition,
      raceId: null,
      subraceId: null,
      raceCustomText: null,
      lineageId: null,
      racialBonusChoices: const <String, int>{},
      raceSkillChoices: const <String>[],
      raceToolChoices: const <String>[],
    );
  }

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
    final raceChanged = state.raceId != raceId || state.subraceId != subraceId;
    state = state.copyWith(
      raceId: raceId,
      subraceId: subraceId,
      raceCustomText: raceCustomText,
      // Les bonus raciaux au choix ne valent que pour la race précédente.
      racialBonusChoices: raceChanged
          ? const <String, int>{}
          : state.racialBonusChoices,
      // La lignée (Drakéide/Tieffelin/Goliath, voir `LineageStepScreen`) ne
      // vaut que pour la race/sous-race précédente.
      lineageId: raceChanged ? null : state.lineageId,
      // Les compétences/outils de race choisis à l'étape 5 (carte "CHOIX DE
      // RACE") ne valent que pour la race précédente — même rationale que
      // `classSkillChoices`/`classToolChoices` dans [setClass].
      raceSkillChoices: raceChanged ? const <String>[] : state.raceSkillChoices,
      raceToolChoices: raceChanged ? const <String>[] : state.raceToolChoices,
    );
  }

  /// Met à jour la lignée 2024 choisie à `LineageStepScreen`, second écran de
  /// l'étape 1 "Race" pour les races qui en ont (voir
  /// `domain/character_creation_draft.dart::lineageId`). Fusion partielle via
  /// `copyWith`, même rationale que [setClass].
  void setLineage(int lineageId) {
    state = state.copyWith(lineageId: lineageId);
  }

  /// Met à jour le choix de classe (et de sous-classe, [subclassId] `null`
  /// pour une classe sans choix de niveau 1) de l'étape 2. Fusion partielle
  /// via `copyWith`, avec un effacement des choix qui dépendent de la classe :
  /// - classe DIFFÉRENTE d'une classe déjà enregistrée : compétences/outils de
  ///   classe et sorts (étapes 5 et 6) sont vidés, ils ne valent que pour la
  ///   classe précédente ;
  /// - même classe mais sous-classe différente : seuls les sorts sont vidés
  ///   (les listes étendues d'un patron d'Occultiste diffèrent d'un patron à
  ///   l'autre).
  /// Les autres champs (race, historique, équipement...) sont conservés.
  void setClass({required int classId, int? subclassId}) {
    final previousClassId = state.classId;
    final classChanged = previousClassId != null && previousClassId != classId;
    final subclassChanged =
        previousClassId == classId && state.subclassId != subclassId;
    state = state.copyWith(
      classId: classId,
      subclassId: subclassId,
      classSkillChoices: classChanged
          ? const <String>[]
          : state.classSkillChoices,
      classToolChoices: classChanged
          ? const <String>[]
          : state.classToolChoices,
      classCantripChoices: classChanged || subclassChanged
          ? const <String>[]
          : state.classCantripChoices,
      classLevelOneSpellChoices: classChanged || subclassChanged
          ? const <String>[]
          : state.classLevelOneSpellChoices,
      classEquipmentOption: classChanged ? null : state.classEquipmentOption,
      // Style de combat/Ennemi juré (`ClassChoiceStepScreen`) ne vaut que
      // pour la classe précédente — correctif D99.
      classFeatureChoiceValue: classChanged
          ? null
          : state.classFeatureChoiceValue,
      // Expertise du Roublard ne vaut que pour la classe précédente — même
      // rationale.
      expertiseSkillChoices: classChanged
          ? const <String>[]
          : state.expertiseSkillChoices,
      expertiseThievesToolsSubstitution: classChanged
          ? false
          : state.expertiseThievesToolsSubstitution,
      // Ancêtre draconique (ou tout second choix de sous-classe futur) ne
      // vaut que pour la sous-classe précédente.
      subclassFeatureChoiceValue: classChanged || subclassChanged
          ? null
          : state.subclassFeatureChoiceValue,
    );
  }

  /// Met à jour le choix nommé de CLASSE fait dès le niveau 1 (Style de
  /// combat du Guerrier/Ennemi juré du Rôdeur), à `ClassChoiceStepScreen` —
  /// correctif D99 (`docs/dette-technique.md`).
  void setClassFeatureChoice(String? value) {
    state = state.copyWith(classFeatureChoiceValue: value);
  }

  /// Met à jour le second choix de niveau 1 propre à la sous-classe choisie
  /// (ex. Ancêtre draconique), à `SubclassFeatureChoiceBlock` —
  /// correctif D99.
  void setSubclassFeatureChoice(String? value) {
    state = state.copyWith(subclassFeatureChoiceValue: value);
  }

  /// Met à jour l'Expertise du Roublard faite au niveau 1, à
  /// `ClassChoiceStepScreen` (poussé par `SkillsAndToolsStepScreen`, APRÈS
  /// les choix de compétences de cette étape) — correctif D99.
  void setExpertiseChoices({
    required List<String> skillNames,
    required bool thievesToolsSubstitution,
  }) {
    state = state.copyWith(
      expertiseSkillChoices: skillNames,
      expertiseThievesToolsSubstitution: thievesToolsSubstitution,
    );
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
    Map<String, int> racialBonusChoices = const {},
  }) {
    state = state.copyWith(
      abilityScoreMethod: method,
      abilityScores: scores,
      racialBonusChoices: racialBonusChoices,
    );
  }

  /// Mode modification : scores FINAUX saisis directement (bonus de race et
  /// améliorations compris), sans méthode de génération.
  void setFinalAbilityScores(Map<String, int> scores) {
    state = state.copyWith(abilityScoreMethod: null, abilityScores: scores);
  }

  /// Met à jour les compétences/outils/langues choisis à l'étape 5. Fusion
  /// partielle via `copyWith` (même rationale que [setClass]/[setBackground]/
  /// [setAbilityScores]) : cette étape n'a pas de champ à effacer sur les
  /// étapes suivantes en fonction du choix fait ici. Les trois premières
  /// listes sont toujours fournies ensemble par l'écran (même si une section
  /// ne s'appliquait pas, auquel cas l'appelant fournit une liste vide) :
  /// voir `domain/character_creation_draft.dart` pour le rationale des noms
  /// plutôt que des ids stockés. [raceSkillChoices]/[raceToolChoices] à
  /// défaut vide, même principe, pour les deux sections "(RACE)" qui ne
  /// s'appliquent qu'à une minorité de races (voir `RaceOption.skillChoice`/
  /// `toolChoice`).
  void setSkillsAndTools({
    required List<String> classSkillChoices,
    required List<String> classToolChoices,
    required List<String> backgroundLanguageChoices,
    List<String> raceSkillChoices = const [],
    List<String> raceToolChoices = const [],
  }) {
    state = state.copyWith(
      classSkillChoices: classSkillChoices,
      classToolChoices: classToolChoices,
      backgroundLanguageChoices: backgroundLanguageChoices,
      raceSkillChoices: raceSkillChoices,
      raceToolChoices: raceToolChoices,
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
    String? classEquipmentOption,
  }) {
    state = state.copyWith(
      equipmentChoiceTab: activeTab,
      purchasedEquipment: purchasedEquipment,
      classEquipmentOption: classEquipmentOption,
    );
  }

  /// Met à jour les 7 champs d'identité et les 9 champs texte libres de l'étape 8 "Apparence, histoire
  /// et portrait". Fusion partielle via `copyWith` (même rationale que
  /// [setSpells]/[setEquipment]) : cette étape n'a pas de champ à effacer sur
  /// l'étape suivante en fonction du choix fait ici. Les 9 valeurs sont
  /// toujours fournies ensemble (même si un champ est resté vide, auquel cas
  /// l'appelant fournit `null`) — voir `domain/character_creation_draft.dart`.
  void setAppearanceAndBackstory({
    required String? sexe,
    required String? age,
    required String? height,
    required String? weight,
    required String? eyes,
    required String? skin,
    required String? hair,
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
      sexe: sexe,
      age: age,
      height: height,
      weight: weight,
      eyes: eyes,
      skin: skin,
      hair: hair,
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

  /// Définit (ou retire, avec `null`) le portrait de l'étape 8 — le
  /// `copyWith` de freezed distingue bien un `null` explicite d'un paramètre
  /// omis.
  void setPortraitBytes(Uint8List? portraitBytes) {
    state = state.copyWith(portraitBytes: portraitBytes);
  }

  /// Définit (ou retire, avec `null`) l'alignement de l'étape 8.
  void setAlignment(int? alignmentId) {
    state = state.copyWith(alignmentId: alignmentId);
  }

  /// Remplace tout le brouillon — utilisé uniquement pour pré-remplir
  /// l'assistant en mode modification d'un personnage existant (voir
  /// `CharacterEditHydrator`).
  void replaceWith(CharacterCreationDraft draft) => state = draft;

  /// Remet le brouillon à zéro. Appelé par `CharacterListScreen` avant de
  /// démarrer une nouvelle création ("+ Créer"), pour ne jamais reprendre
  /// silencieusement un brouillon abandonné d'une session précédente.
  void reset() => state = const CharacterCreationDraft();
}
