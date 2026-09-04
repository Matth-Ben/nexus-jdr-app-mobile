import 'package:freezed_annotation/freezed_annotation.dart';

part 'alignment_option.freezed.dart';

/// Un alignement de `alignments` (`docs/cahier-des-charges/02-modele-donnees.md`)
/// — malgré ce que documente `02-modele-donnees.md` (`id int (PK)` + `name
/// text` seulement), `alignments.name` n'est **pas** une colonne directe sur
/// le schéma réellement déployé : comme `skills`/`races`/`classes`/
/// `backgrounds`, le nom vit dans `translations`
/// (`CharacterCreationRepository.fetchAlignmentCatalog`). Une régression
/// avait supposé le contraire (doc non mise à jour après l'introduction de
/// `translations`), faisant échouer l'import XML avec une
/// `PostgrestException` 42703.
///
/// Introduit pour l'import XML aidedd.org (`features/xml_import/`), pas pour
/// l'assistant de création lui-même : `characters.alignment_id` y est toujours
/// écrit `null` (voir `data/character_creation_repository.dart`, aucun choix
/// d'alignement dans les 9 étapes) — ce catalogue vit néanmoins dans
/// `character_creation/domain/` plutôt que dans `xml_import/domain/`, cohérent
/// avec le reste des catalogues exposés par `CharacterCreationRepository`
/// (`RaceCatalog`, `ClassCatalog`...), même si `xml_import` en est aujourd'hui
/// l'unique consommateur — signalé ici plutôt qu'introduit silencieusement,
/// à valider par le chef de projet si un découpage différent était préféré.
@freezed
abstract class AlignmentOption with _$AlignmentOption {
  const factory AlignmentOption({required int id, required String name}) =
      _AlignmentOption;
}
