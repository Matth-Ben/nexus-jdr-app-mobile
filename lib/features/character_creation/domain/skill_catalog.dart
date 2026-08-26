import 'package:freezed_annotation/freezed_annotation.dart';

import 'skill_option.dart';

part 'skill_catalog.freezed.dart';

/// Catalogue complet des 18 compétences de `skills`, récupéré en une fois à
/// l'étape 9/9 "Récapitulatif" de l'assistant de création
/// (`data/character_creation_repository.dart`) — même rationale que
/// [ToolCatalog]/[LanguageCatalog] des étapes précédentes (volume fixe très
/// faible, pas besoin de pagination).
@freezed
abstract class SkillCatalog with _$SkillCatalog {
  const factory SkillCatalog({required List<SkillOption> skills}) =
      _SkillCatalog;
}
