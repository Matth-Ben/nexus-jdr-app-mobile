import 'package:freezed_annotation/freezed_annotation.dart';

import 'alignment_option.dart';

part 'alignment_catalog.freezed.dart';

/// Catalogue complet des 9 alignements de `alignments`, récupéré en une fois
/// par `CharacterCreationRepository.fetchAlignmentCatalog` — voir la
/// documentation de classe de [AlignmentOption] pour le rationale de son
/// emplacement dans `character_creation/domain/` au bénéfice de
/// `features/xml_import/`.
@freezed
abstract class AlignmentCatalog with _$AlignmentCatalog {
  const factory AlignmentCatalog({required List<AlignmentOption> alignments}) =
      _AlignmentCatalog;
}
