import 'package:freezed_annotation/freezed_annotation.dart';

part 'race_tool_choice.freezed.dart';

/// Choix interactif d'outils de race (`races.tool_choice`, jsonb) à l'étape
/// 5/9 "Compétences et outils" de l'assistant de création — Nain (outils
/// d'artisan au choix dans une liste nommée), Satyre (un instrument au choix,
/// forme `categories`) et Forgelier (n'importe quel outil du catalogue,
/// `choices: null`) à ce jour.
///
/// Même shape que [ClassSkillChoices] (`{count, choices}`), mais type
/// distinct plutôt que réutilisé tel quel : `races.tool_choice` a trois
/// formes brutes réelles (voir la consigne d'origine de cette tâche) —
/// `choices` direct (liste de noms exacts), `categories` (liste de
/// `tools.category` à développer contre le catalogue d'outils déjà chargé),
/// ou ni l'un ni l'autre (choix libre parmi tout le catalogue) — toutes les
/// trois déjà résolues en une liste plate de noms candidats au moment du
/// parsing (`data/race_row_mapper.dart::parseToolChoice`), même principe que
/// [ClassSkillChoices] pour la forme `"toutes"` du Barde : ce modèle n'expose
/// plus laquelle des trois formes a produit [choices].
@freezed
abstract class RaceToolChoice with _$RaceToolChoice {
  const factory RaceToolChoice({
    required int count,
    required List<String> choices,
  }) = _RaceToolChoice;
}
