import 'package:freezed_annotation/freezed_annotation.dart';

import 'tool_option.dart';

part 'tool_catalog.freezed.dart';

/// Catalogue complet des outils/instruments de l'étape 5/9 "Compétences et
/// outils" de l'assistant de création, récupéré en une fois au chargement de
/// l'écran (`data/character_creation_repository.dart`) — même rationale que
/// [ClassCatalog]/[BackgroundCatalog] des étapes précédentes (volume faible,
/// pas besoin de pagination).
@freezed
abstract class ToolCatalog with _$ToolCatalog {
  const factory ToolCatalog({required List<ToolOption> tools}) = _ToolCatalog;
}
