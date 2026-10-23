import 'dart:typed_data';

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
    /// Édition de règles choisie à l'étape 1 "Édition" (TOUTE PREMIÈRE étape
    /// de l'assistant, avant même la Race) — `'2014'` (Manuel des Joueurs) ou
    /// `'2024'` (Manuel des Joueurs revu), persistée immuable sur
    /// `characters.edition` par `createCharacter`. `@Default('2014')` plutôt
    /// que `String?` : même convention que [abilityScoreMethod] (un champ
    /// jamais "non choisi" visuellement, l'écran préselectionne toujours une
    /// tuile) — contrairement à [abilityScoreMethod], cette valeur par
    /// défaut correspond aussi au défaut DB (`characters.edition not null
    /// default '2014'`, voir la migration du dépôt web), donc un personnage
    /// créé sans jamais toucher à cet écran (ne devrait pas arriver, "Suivant"
    /// de `EditionStepScreen` l'écrit toujours explicitement) resterait de
    /// toute façon cohérent avec la base. Pilote le filtre d'édition sur le
    /// contenu Métamagie/Expertise à la création (voir
    /// `data/character_creation_repository.dart::createCharacter`) et le
    /// gating de la substitution outils de voleur du Roublard (voir
    /// [expertiseThievesToolsSubstitution]).
    @Default('2014') String edition,

    /// Race choisie à l'étape 1, `null` si race personnalisée ou pas encore
    /// choisie.
    int? raceId,

    /// Sous-race choisie à l'étape 1, `null` si la race n'a pas de sous-race
    /// ou pas encore choisie.
    int? subraceId,

    /// Texte libre de race personnalisée (étape 1), `null` si une race du
    /// catalogue a été choisie à la place.
    String? raceCustomText,

    /// Lignée 2024 choisie à l'étape 1 (`race_lineages.id`), uniquement pour
    /// les races qui en ont un choix explicite SANS sous-race (Drakéide,
    /// Tieffelin, Goliath à ce jour — voir
    /// `domain/lineage_choice_catalog.dart` et
    /// `presentation/lineage_step_screen.dart`). `null` pour toutes les
    /// autres races, ou tant que rien n'est choisi. Pour les races dont la
    /// lignée se déduit de la sous-race choisie (Gnome, Génasi), ce champ
    /// reste `null` : la résolution se fait côté serveur à la création, voir
    /// `data/character_creation_repository.dart::createCharacter`.
    int? lineageId,

    /// Classe choisie à l'étape 2, `null` si pas encore choisie. Pas de
    /// "classe personnalisée" à cette étape (décision du chef de projet, voir
    /// `domain/class_catalog.dart`).
    int? classId,

    /// Sous-classe choisie à l'étape 2 (`subclasses.id`), uniquement pour les
    /// classes qui la choisissent au niveau 1 (Clerc, Occultiste,
    /// Ensorceleur — voir `domain/subclass_choice_catalog.dart`). `null`
    /// pour toutes les autres classes ou tant que rien n'est choisi.
    int? subclassId,

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

    /// Bonus raciaux au choix répartis à l'étape 4 (clé de caractéristique →
    /// bonus), pour les races à `choice_others`/`choice_flexible` — voir
    /// `domain/racial_bonus_choice.dart`. Vide pour une race sans choix ;
    /// effacé quand la race ou la sous-race change.
    @Default(<String, int>{}) Map<String, int> racialBonusChoices,

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

    /// Compétence(s) de race choisies à l'étape 5 (noms affichés), vide si
    /// la race n'a pas de choix interactif de compétence
    /// (`RaceOption.skillChoice` `null`) ou si aucune n'est encore choisie.
    /// Même décision noms-plutôt-qu'ids que [classSkillChoices]. N'inclut
    /// jamais l'octroi automatique (`RaceOption.skillProficiencies`, Satyre
    /// uniquement) : celui-ci n'est pas un choix, donc jamais porté par le
    /// brouillon, résolu directement depuis le catalogue à l'étape 9
    /// "Récapitulatif" (voir `data/character_creation_repository.dart
    /// ::createCharacter`).
    @Default(<String>[]) List<String> raceSkillChoices,

    /// Outil(s) de race choisis à l'étape 5 (noms affichés), vide si la race
    /// n'a pas de choix interactif d'outil (`RaceOption.toolChoice` `null`)
    /// ou si aucun n'est encore choisi. Même décision noms-plutôt-qu'ids que
    /// [classSkillChoices].
    @Default(<String>[]) List<String> raceToolChoices,

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

    /// Option d'équipement de départ de classe retenue à l'étape 7 ("A",
    /// "B"...), voir `domain/class_starting_equipment.dart` — `null` = option
    /// A par défaut. Effacée quand la classe change.
    String? classEquipmentOption,

    /// Les 9 champs texte libres de l'étape 8 "Apparence, histoire et
    /// portrait" (`presentation/appearance_and_backstory_step_screen.dart`),
    /// tous optionnels — `null` tant que le champ n'a jamais été renseigné.
    /// Ordre canonique du XML aidedd.org / des colonnes `characters.*` (voir
    /// le commentaire de classe de `AppearanceAndBackstoryStepScreen`), pas
    /// l'ordre partiel visible sur la maquette (extrait tronqué). Aucune
    /// résolution supplémentaire nécessaire à l'étape 9 contrairement aux
    /// autres champs du brouillon : ce sont déjà les valeurs texte finales
    /// destinées aux colonnes `characters.appearance_text`/`traits_text`/...
    String? appearanceText,

    /// Identité physique saisie à l'étape 8 (champs courts, texte libre) —
    /// colonnes `characters.sexe`/`age`/`height`/`weight`/`eyes`/`skin`/
    /// `hair`, toutes `text` nullables. `null` = jamais renseigné.
    String? sexe,

    /// Voir [sexe] — `characters.age`.
    String? age,

    /// Voir [sexe] — `characters.height`.
    String? height,

    /// Voir [sexe] — `characters.weight`.
    String? weight,

    /// Voir [sexe] — `characters.eyes`.
    String? eyes,

    /// Voir [sexe] — `characters.skin`.
    String? skin,

    /// Voir [sexe] — `characters.hair`.
    String? hair,

    /// Voir [appearanceText] — `characters.traits_text`.
    String? traitsText,

    /// Voir [appearanceText] — `characters.ideals_text`.
    String? idealsText,

    /// Voir [appearanceText] — `characters.bonds_text`.
    String? bondsText,

    /// Voir [appearanceText] — `characters.flaws_text`.
    String? flawsText,

    /// Voir [appearanceText] — `characters.backstory_text`.
    String? backstoryText,

    /// Voir [appearanceText] — `characters.allies_text`.
    String? alliesText,

    /// Voir [appearanceText] — `characters.features_text`.
    String? featuresText,

    /// Voir [appearanceText] — `characters.treasure_text`.
    String? treasureText,

    /// Nom du personnage, saisi à l'étape 9 "Récapitulatif" (`characters
    /// .name`) — `null` tant qu'il n'a jamais été renseigné. Aucune étape 1-8
    /// ne capture ce champ (gap identifié et validé avec l'utilisateur lors
    /// de l'implémentation de l'étape 9) : contrairement aux autres champs de
    /// ce brouillon, il n'a donc pas d'étape "propriétaire" antérieure,
    /// seule `presentation/summary_step_screen.dart` le lit/l'écrit.
    String? characterName,

    /// Portrait choisi et recadré à l'étape 8 (PNG carré, sortie de
    /// `PortraitCropScreen` en mode local) — `null` si aucun. Gardé en
    /// mémoire uniquement (le brouillon n'est jamais persisté) et envoyé
    /// dans Storage juste après la création du personnage à l'étape 9, une
    /// fois son identifiant connu (voir `summary_step_screen.dart`).
    Uint8List? portraitBytes,

    /// Alignement choisi à l'étape 8 (`characters.alignment_id`), `null` si
    /// aucun.
    int? alignmentId,

    /// Choix nommé de CLASSE fait dès le niveau 1, à l'écran
    /// `ClassChoiceStepScreen` poussé juste après `ClassStepScreen` —
    /// correctif D99 (`docs/dette-technique.md`). Libellé choisi dans
    /// `LevelUpChoiceOptions.fightingStyles`/`.favoredEnemies` selon la
    /// classe (voir `domain/class_choice_rules.dart`) : Style de combat du
    /// Guerrier, Ennemi juré du Rôdeur. `null` tant qu'aucune classe
    /// concernée n'est choisie, ou que rien n'est encore choisi. N'inclut
    /// PAS l'Expertise du Roublard (voir [expertiseSkillChoices]), ni
    /// l'Ancêtre draconique (voir [subclassFeatureChoiceValue]) — chacun son
    /// propre champ, pour ne jamais mélanger les 3 écritures distinctes de
    /// `character_class_options` au moment de `createCharacter` (voir
    /// `data/character_creation_repository.dart`).
    String? classFeatureChoiceValue,

    /// Second choix de niveau 1 propre à la SOUS-CLASSE choisie (ex. type de
    /// dragon pour l'Ancêtre draconique du Lignage draconique, Ensorceleur),
    /// fait sur `SubclassStepScreen` via `SubclassFeatureChoiceBlock` —
    /// correctif D99. Nom de l'option choisie (ex. "Dragon rouge"), `null`
    /// tant qu'aucune sous-classe concernée n'est choisie, ou que rien n'est
    /// encore choisi. Voir `domain/subclass_feature_choice.dart`.
    String? subclassFeatureChoiceValue,

    /// Compétences choisies pour l'Expertise du Roublard au niveau 1, à
    /// l'écran `ClassChoiceStepScreen` poussé par `SkillsAndToolsStepScreen`
    /// APRÈS la résolution des choix de compétences de cette étape (pas
    /// juste après la classe : les compétences candidates n'existent pas
    /// encore à ce stade) — correctif D99. Noms affichés, même décision
    /// noms-plutôt-qu'ids que [classSkillChoices]. Quota RAW 2, qui peut
    /// être réduit à 1 (voir [expertiseThievesToolsSubstitution]) — voir
    /// `domain/expertise_step_selection.dart`. Vide tant que rien n'est
    /// encore choisi, ou pour toute classe autre que le Roublard.
    @Default(<String>[]) List<String> expertiseSkillChoices,

    /// `true` si une des 2 "cases" d'Expertise du Roublard est utilisée sur
    /// sa maîtrise d'outils de voleur plutôt que sur une compétence (RAW
    /// 2014 PHB : "deux compétences, OU une compétence et les outils de
    /// voleur") — purement descriptif à la persistance, voir
    /// `domain/expertise_step_selection.dart` pour le rationale de l'absence
    /// de bonus chiffré associé. `false` par défaut/tant que rien n'est
    /// choisi. Chantier édition (`docs/cahier-des-charges`, choix
    /// 2014/2024) : cette substitution n'existe RAW qu'en édition 2014 (le
    /// texte 2024 l'a supprimée) — seulement exploitable quand [edition]
    /// vaut `'2014'`, voir `presentation/class_choice_step_screen.dart`.
    @Default(false) bool expertiseThievesToolsSubstitution,
  }) = _CharacterCreationDraft;
}
