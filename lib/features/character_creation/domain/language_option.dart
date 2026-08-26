import 'package:freezed_annotation/freezed_annotation.dart';

part 'language_option.freezed.dart';

/// Une langue sélectionnable à l'étape 5/9 "Compétences et outils" de
/// l'assistant de création (`languages`, voir
/// `docs/cahier-des-charges/02-modele-donnees.md`).
///
/// [type] ('standard'/'exotique', colonne réelle de `languages`) n'est pas
/// affiché à cette étape (ni la consigne de la tâche ni la maquette ne le
/// demandent) — gardé ici pour rester fidèle à la ligne brute plutôt que de
/// le laisser tomber au parsing.
@freezed
abstract class LanguageOption with _$LanguageOption {
  const factory LanguageOption({
    required int id,
    required String name,
    required String type,
  }) = _LanguageOption;
}
