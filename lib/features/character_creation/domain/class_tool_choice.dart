import 'package:freezed_annotation/freezed_annotation.dart';

part 'class_tool_choice.freezed.dart';

/// Choix interactif d'outils/instruments de classe (`classes
/// .tool_proficiencies`, jsonb, forme `{"count": N, "type": "..."}`) à
/// l'étape 5/9 "Compétences et outils" de l'assistant de création — Barde
/// (instrument) et Moine (outils_artisan_ou_instrument) à ce jour.
///
/// [categories] est déjà résolue vers les vraies valeurs de `tools.category`
/// (`data/class_row_mapper.dart`) : le type jsonb `outils_artisan_ou_instrument`
/// n'est *pas* une catégorie réelle de `tools` (les seules catégories qui y
/// existent sont `outils_artisan`/`instrument`/`jeu`/`autre`, vérifié contre
/// `supabase/migrations/20260825090500_seed_reference_core_data.sql` du dépôt
/// web), c'est une union de deux catégories réelles — d'où une liste plutôt
/// qu'une seule valeur ici.
///
/// Distinct de [ClassSkillChoices] : `tool_proficiencies` a une troisième
/// forme réelle en base non documentée dans la consigne d'origine de cette
/// tâche, une liste de noms d'outils précis octroyés automatiquement (ex.
/// Druide, Roublard) — voir `ClassOption.grantedToolNames` pour cette forme,
/// qui n'a pas de représentation ici (ce n'est pas un choix).
@freezed
abstract class ClassToolChoice with _$ClassToolChoice {
  const factory ClassToolChoice({
    required int count,
    required List<String> categories,
  }) = _ClassToolChoice;
}
