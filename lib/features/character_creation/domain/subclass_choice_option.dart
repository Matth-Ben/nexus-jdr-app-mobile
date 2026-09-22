import 'package:freezed_annotation/freezed_annotation.dart';

part 'subclass_choice_option.freezed.dart';

/// Une sous-classe proposée à l'étape 2/9 de l'assistant de création, pour
/// les classes qui la choisissent dès le niveau 1 (Clerc, Occultiste,
/// Ensorceleur — déterminé par les données, voir [SubclassChoiceCatalog]).
///
/// Nom et description déjà résolus via `translations`
/// (`entity_type = 'subclass'`), comme `LevelUpSubclassOption` côté montée de
/// niveau (modèle distinct : les deux features restent découplées).
@freezed
abstract class SubclassChoiceOption with _$SubclassChoiceOption {
  const factory SubclassChoiceOption({
    /// `subclasses.id`.
    required int id,
    required String name,

    /// `null` si aucune description n'est renseignée en base (la tuile
    /// n'affiche alors pas de sous-titre).
    String? description,
  }) = _SubclassChoiceOption;
}
