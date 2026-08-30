import 'package:freezed_annotation/freezed_annotation.dart';

part 'xml_named_option.freezed.dart';

/// Candidat générique {id, nom} pour `XmlNameResolver.resolveByName`, pour
/// les champs "en clair" de l'import XML aidedd.org qui n'ont **pas** encore
/// de catalogue dédié ailleurs dans l'app (sous-classe, invocation
/// occulte) — contrairement à race/classe/historique/outil/langue/sort, qui
/// réutilisent directement `RaceOption`/`ClassOption`/`BackgroundOption`/
/// `ToolOption`/`LanguageOption`/`SpellOption` de `character_creation`.
///
/// Les deux fixtures réelles de ce chantier (`test/fixtures/xml_import/`)
/// n'ont ni sous-classe ni invocation renseignées (personnages niveau 2, ces
/// choix n'interviennent pas encore) : la résolution de ces deux champs est
/// donc implémentée et testée avec des candidats fournis par l'appelant
/// (voir `XmlCharacterImportResolver.resolve`), mais aucune requête Supabase
/// ne récupère encore ces candidats nulle part dans l'app — à ajouter dans
/// une tâche future quand l'écran de récapitulatif (increment suivant) en
/// aura réellement besoin, plutôt que d'introduire ici une requête non
/// testable en conditions réelles.
@freezed
abstract class XmlNamedOption with _$XmlNamedOption {
  const factory XmlNamedOption({required Object id, required String name}) =
      _XmlNamedOption;
}
