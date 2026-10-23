import 'package:freezed_annotation/freezed_annotation.dart';

part 'subclass_option.freezed.dart';

/// Une sous-classe (`subclasses`), toutes classes et tous niveaux
/// d'obtention confondus — modèle minimal (id/nom/classe) distinct de
/// [SubclassChoiceOption] (`domain/subclass_choice_option.dart`), qui ne
/// porte que les sous-classes choisies au niveau 1 (étape 2/9 de l'assistant
/// de création) avec leur description complète.
///
/// Introduit pour l'import XML aidedd.org (`xml_import/domain
/// /xml_character_import_resolver.dart`, champ `classPath`) : contrairement
/// à l'assistant de création manuel, un personnage importé peut arriver à
/// n'importe quel niveau avec une sous-classe choisie bien après le niveau 1
/// (Voie du Barbare niveau 3, École de Magicien niveau 2...) — [SubclassCatalog]
/// doit donc couvrir l'intégralité de la table `subclasses`, pas seulement
/// les sous-classes de niveau 1 que couvre `SubclassChoiceCatalog`.
@freezed
abstract class SubclassOption with _$SubclassOption {
  const factory SubclassOption({
    required int id,
    required String name,
    required int classId,
  }) = _SubclassOption;
}
