import 'package:freezed_annotation/freezed_annotation.dart';

import 'subclass_option.dart';

part 'subclass_catalog.freezed.dart';

/// Catalogue complet des sous-classes (`subclasses`), toutes classes et tous
/// niveaux d'obtention confondus — voir la documentation de classe de
/// [SubclassOption] pour le rationale. Pas de pagination (volume faible,
/// même mécanique que [ClassCatalog]).
///
/// Lecture seule, utilisée aujourd'hui uniquement par l'écran de
/// vérification de l'import XML aidedd.org (`xml_import/presentation
/// /providers/xml_import_providers.dart`) pour résoudre `classPath` — même
/// rationale que `CharacterCreationRepository.fetchAlignmentCatalog`, jamais
/// consommé par l'assistant de création manuel lui-même (qui choisit sa
/// propre sous-classe de niveau 1 via `SubclassChoiceRepository`/
/// `SubclassChoiceCatalog`, un catalogue distinct et volontairement filtré).
@freezed
abstract class SubclassCatalog with _$SubclassCatalog {
  const factory SubclassCatalog({required List<SubclassOption> subclasses}) =
      _SubclassCatalog;
}
