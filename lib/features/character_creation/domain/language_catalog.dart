import 'package:freezed_annotation/freezed_annotation.dart';

import 'language_option.dart';

part 'language_catalog.freezed.dart';

/// Catalogue complet des langues de l'étape 5/9 "Compétences et outils" de
/// l'assistant de création, récupéré en une fois au chargement de l'écran
/// (`data/character_creation_repository.dart`) — même rationale que
/// [ToolCatalog].
@freezed
abstract class LanguageCatalog with _$LanguageCatalog {
  const factory LanguageCatalog({required List<LanguageOption> languages}) =
      _LanguageCatalog;
}
