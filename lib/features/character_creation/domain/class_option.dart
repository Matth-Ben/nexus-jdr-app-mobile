import 'package:freezed_annotation/freezed_annotation.dart';

import 'class_skill_choices.dart';
import 'class_tool_choice.dart';

part 'class_option.freezed.dart';

/// Une classe sélectionnable à l'étape 2/9 de l'assistant de création
/// (`classes`, voir `docs/cahier-des-charges/02-modele-donnees.md`).
///
/// Contrairement à [RaceOption], pas de logique de formatage dédiée
/// (`RaceSummaryFormatter`) : [description] est déjà une phrase complète
/// résolue depuis `translations` (`field_name='description'`), il suffit de
/// lui accoler le dé de vie — voir [summaryLine].
///
/// [skillChoices]/[toolChoice]/[grantedToolNames] ne sont utilisés qu'à
/// l'étape 5/9 "Compétences et outils" (`presentation
/// /skills_and_tools_step_screen.dart`), pas à l'étape 2/9 : ils voyagent sur
/// ce modèle plutôt qu'un modèle dédié à l'étape 5 pour éviter de refaire une
/// jointure/un mapping de `classes` en double (même catalogue, même ligne
/// brute). Valeurs par défaut permissives (`ClassSkillChoices(count: 0,
/// choices: [])`, `toolChoice: null`, `grantedToolNames: []`) pour ne pas
/// casser les usages existants de l'étape 2/9 (tests inclus) qui construisent
/// un [ClassOption] sans les renseigner.
///
/// Trois formes réelles constatées pour `classes.tool_proficiencies` en base
/// (vérifiées contre `supabase/migrations/20260825090700_seed_classes_subclasses_features.sql`
/// du dépôt web, où seules deux étaient anticipées dans la consigne d'origine
/// de la tâche qui a ajouté ces champs — signalé au chef de projet) :
/// - `[]` (vide) : ni choix ni octroi automatique — [toolChoice] `null`,
///   [grantedToolNames] vide.
/// - `{"count": N, "type": "..."}` (Barde, Moine) : un vrai choix —
///   [toolChoice] non `null`, [grantedToolNames] vide.
/// - une liste de noms d'outils précis (Druide : "outils d'herboriste",
///   Roublard : "outils de voleur") : un octroi automatique, pas un choix —
///   [toolChoice] `null`, [grantedToolNames] non vide. Rendu à l'écran avec
///   le même style non interactif que les outils d'historique (voir
///   `CheckableOptionTile`), sous le même titre de section "OUTILS (CLASSE)"
///   que la forme interactive plutôt qu'une 5e section dédiée non prévue par
///   la consigne — choix technique du sous-agent `dev-flutter`, à valider par
///   le chef de projet.
@freezed
abstract class ClassOption with _$ClassOption {
  const ClassOption._();

  const factory ClassOption({
    required int id,
    required String name,
    required String description,
    required int hitDie,

    /// Compétences de classe (`classes.skill_choices`), voir
    /// [ClassSkillChoices] pour le détail des deux formes jsonb résolues.
    @Default(ClassSkillChoices(count: 0, choices: []))
    ClassSkillChoices skillChoices,

    /// Choix interactif d'outils/instruments (`classes.tool_proficiencies`,
    /// forme `{"count", "type"}`), `null` si cette classe n'a pas de choix
    /// interactif (forme `[]` ou liste de noms précis, voir
    /// [grantedToolNames]).
    ClassToolChoice? toolChoice,

    /// Noms d'outils précis octroyés automatiquement par
    /// `classes.tool_proficiencies` quand cette colonne est une liste de
    /// chaînes plutôt qu'un objet `{"count", "type"}` — voir le commentaire
    /// de classe pour le détail. Vide dans tous les autres cas.
    @Default(<String>[]) List<String> grantedToolNames,
  }) = _ClassOption;

  /// Ligne de résumé affichée sous le nom ("Lanceur de sorts érudit · dé de
  /// vie d6", maquette `03_étape_2_classe.png`), en omettant la description
  /// si elle n'a pas pu être résolue (pas de ' · ' orphelin en tête) — même
  /// pattern que `_summaryLine` de `character_card.dart`.
  String get summaryLine {
    final segments = [
      if (description.isNotEmpty) description,
      'dé de vie d$hitDie',
    ];
    return segments.join(' · ');
  }
}
