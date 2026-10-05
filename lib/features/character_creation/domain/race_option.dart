import 'package:freezed_annotation/freezed_annotation.dart';

import 'class_skill_choices.dart';
import 'race_summary_formatter.dart';
import 'race_tool_choice.dart';
import 'race_trait.dart';

part 'race_option.freezed.dart';

/// Une race sélectionnable à l'étape 1/9 de l'assistant de création
/// (`races`, voir `docs/cahier-des-charges/02-modele-donnees.md`).
///
/// [abilityBonuses] est gardé sous sa forme brute `Map<String, dynamic>`
/// (plutôt que `Map<String, int>`) : il peut contenir la clé spéciale
/// `choice_others` (bonus à caractéristiques au choix, ex. Demi-elfe) dont la
/// valeur n'est pas un simple entier — voir [RaceSummaryFormatter], qui
/// l'ignore explicitement dans le résumé court.
@freezed
abstract class RaceOption with _$RaceOption {
  const RaceOption._();

  const factory RaceOption({
    required int id,
    required String name,
    required Map<String, dynamic> abilityBonuses,
    required List<RaceTrait> traits,

    /// `races.source` — livre d'origine ("Manuel des Joueurs", "Manuel des
    /// Joueurs (2024)", "Eberron / Monstres du Multivers"...). Sert
    /// uniquement à [isCoreSource] (regroupement races de base/extension de
    /// l'étape 1/9, voir `presentation/race_step_screen.dart`) — jamais
    /// affiché tel quel à l'utilisateur. Chaîne vide retombée pour une ligne
    /// sans `source` exploitable (cache offline écrit avant l'introduction
    /// de cette colonne) plutôt que de crasher — voir `RaceRowMapper
    /// .toRaceOption` ; classée comme extension par [isCoreSource] dans ce
    /// cas (fallback conservateur).
    required String source,

    /// `races.is_incomplete` — `true` pour une entrée placeholder créée par
    /// l'import XML aidedd.org quand l'utilisateur choisit "Garder comme
    /// élément personnalisé" pour une race non cataloguée (voir
    /// `features/xml_import/data/xml_import_placeholder_catalog_repository.dart`).
    /// Signale qu'il manque des informations à compléter plus tard côté
    /// contenu — `false` pour toute race peuplée normalement par l'équipe
    /// `dev-backend-supabase`.
    @Default(false) bool isIncomplete,

    /// Choix interactif de compétence(s) de race (`races.skill_choice`,
    /// jsonb), `null` si cette race n'en a pas (la grande majorité) — étape
    /// 5/9 "Compétences et outils" de l'assistant de création, carte "CHOIX
    /// DE RACE" de la fiche personnage. Réutilise [ClassSkillChoices] tel
    /// quel (même shape `{count, choices}`, voir sa documentation de
    /// classe) : `choices` est déjà développée en la liste complète des 18
    /// compétences par `data/race_row_mapper.dart::parseSkillChoice` quand
    /// la colonne porte `choices: null` (choix libre, ex. Demi-elfe/
    /// Forgelier/Kenku), même principe que la forme `"toutes"` du Barde.
    ClassSkillChoices? skillChoice,

    /// Choix interactif d'outil(s) de race (`races.tool_choice`, jsonb),
    /// `null` si cette race n'en a pas (la grande majorité) — même étape/
    /// carte que [skillChoice]. Voir [RaceToolChoice] pour le détail des
    /// trois formes brutes déjà résolues en une liste plate de noms
    /// candidats.
    RaceToolChoice? toolChoice,

    /// Compétence(s) octroyée(s) automatiquement par la race
    /// (`races.skill_proficiencies`, text[]) — PAS un choix du joueur
    /// (Satyre uniquement à ce jour : "Persuasion"/"Représentation"), même
    /// rôle que `BackgroundOption.skillProficiencies`. Vide pour toute autre
    /// race (la grande majorité).
    @Default(<String>[]) List<String> skillProficiencies,
  }) = _RaceOption;

  /// `true` si cette race vient du Manuel des Joueurs ("race de base"),
  /// `false` pour toute race d'extension (tout autre supplément : Eberron,
  /// Monstres du Multivers, Strixhaven...) — règle de classification
  /// demandée par le chef de projet (retour utilisateur du 03/10/2026) :
  /// basée sur le préfixe de [source] plutôt que sur la liste exacte de ses
  /// valeurs actuelles (ex. "Manuel des Joueurs (2024) / SRD 5.2"), qui peut
  /// évoluer avec un futur peuplement de contenu par `dev-backend-supabase`.
  /// Utilisée pour le regroupement/tri à deux niveaux de l'étape 1/9, voir
  /// `data/character_creation_repository.dart::_mapRaceCatalogPayload` et
  /// `presentation/race_step_screen.dart`.
  bool get isCoreSource => source.startsWith('Manuel des Joueurs');

  /// Ligne de résumé affichée sous le nom ("+2 Dex · Vision dans le noir ·
  /// Transe"), voir [RaceSummaryFormatter].
  String get summaryLine => RaceSummaryFormatter.format(
    abilityBonuses: abilityBonuses,
    traits: traits,
  );

  /// Texte complet du panneau ⓘ (bonus + traits détaillés), voir
  /// [RaceSummaryFormatter.formatInfo].
  String get infoText => RaceSummaryFormatter.formatInfo(
    abilityBonuses: abilityBonuses,
    traits: traits,
  );
}
