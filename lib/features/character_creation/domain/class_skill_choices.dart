import 'package:freezed_annotation/freezed_annotation.dart';

part 'class_skill_choices.freezed.dart';

/// Choix de compétences de classe (`classes.skill_choices`, jsonb) à
/// l'étape 5/9 "Compétences et outils" de l'assistant de création.
///
/// Deux formes réelles constatées en base
/// (`supabase/migrations/20260825090700_seed_classes_subclasses_features.sql`,
/// dépôt web) : `{"count": N, "choices": [liste de noms]}` pour la plupart
/// des classes, ou `{"count": 3, "choices": "toutes"}` pour le Barde
/// uniquement — dans ce second cas, [choices] est déjà développée en la
/// liste complète des 18 compétences D&D 5e au moment du parsing
/// (`data/class_row_mapper.dart`, voir `skill_ability_mapping.dart` pour la
/// constante source), donc ce modèle n'expose plus la distinction : l'appelant
/// n'a jamais besoin de savoir laquelle des deux formes a produit [choices].
@freezed
abstract class ClassSkillChoices with _$ClassSkillChoices {
  const factory ClassSkillChoices({
    required int count,
    required List<String> choices,
  }) = _ClassSkillChoices;
}
