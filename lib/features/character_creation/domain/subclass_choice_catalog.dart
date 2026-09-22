import 'package:freezed_annotation/freezed_annotation.dart';

import 'subclass_choice_option.dart';

part 'subclass_choice_catalog.freezed.dart';

/// Sous-classes à choisir dès le niveau 1, par `classes.id`.
///
/// Une classe est « concernée » si elle porte, aux données, une aptitude de
/// niveau 1 `class_features.choice_type = 'sous_classe'` (voir
/// `SubclassChoiceRowMapper`) : elle est alors une clé de
/// [optionsByClassId], même si sa liste d'options est vide (cas défensif :
/// données incomplètes). Aucune classe n'est désignée par son nom.
@freezed
abstract class SubclassChoiceCatalog with _$SubclassChoiceCatalog {
  const SubclassChoiceCatalog._();

  const factory SubclassChoiceCatalog({
    required Map<int, List<SubclassChoiceOption>> optionsByClassId,
  }) = _SubclassChoiceCatalog;

  /// `true` si [classId] choisit sa sous-classe au niveau 1.
  bool isConcerned(int classId) => optionsByClassId.containsKey(classId);

  /// Options de [classId] ; `null` si la classe n'est pas concernée, liste
  /// éventuellement vide si elle l'est mais qu'aucune sous-classe n'existe.
  List<SubclassChoiceOption>? optionsFor(int classId) =>
      optionsByClassId[classId];

  /// Nom de la sous-classe [subclassId] de [classId], `null` si introuvable.
  String? nameOf({required int classId, required int subclassId}) {
    final options = optionsByClassId[classId];
    if (options == null) return null;
    for (final option in options) {
      if (option.id == subclassId) return option.name;
    }
    return null;
  }
}
