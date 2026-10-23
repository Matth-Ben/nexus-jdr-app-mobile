import 'package:freezed_annotation/freezed_annotation.dart';

part 'xml_named_option.freezed.dart';

/// Candidat générique {id, nom} pour `XmlNameResolver.resolveByName`, pour
/// les champs "en clair" de l'import XML aidedd.org qui n'ont pas de
/// `XxxOption` dédié directement réutilisable de `character_creation` —
/// contrairement à race/classe/historique/outil/langue/sort, qui réutilisent
/// directement `RaceOption`/`ClassOption`/`BackgroundOption`/`ToolOption`/
/// `LanguageOption`/`SpellOption`.
///
/// Sous-classe (`classPath`) : les candidats sont désormais fournis par
/// `xml_import/presentation/providers/xml_import_providers.dart` depuis le
/// catalogue complet `subclasses`
/// (`character_creation/domain/subclass_catalog.dart::SubclassCatalog`,
/// filtré sur la classe déjà résolue) — converti en [XmlNamedOption] plutôt
/// que de faire porter directement un `SubclassOption` par
/// `XmlCharacterImportResolver.resolve`, pour ne pas coupler ce résolveur à
/// un second type de candidat par champ "en clair" (voir
/// [XmlCharacterImportResolver.resolve]).
///
/// Invocation occulte (`knownInvocation`) : aucun catalogue Supabase dédié
/// n'existe encore ailleurs dans l'app pour ce champ — liste de candidats
/// toujours vide par défaut (voir `XmlCharacterImportResolver.resolve`), à
/// ajouter dans une tâche future quand un catalogue réel existera, plutôt que
/// d'introduire ici une requête non testable en conditions réelles.
@freezed
abstract class XmlNamedOption with _$XmlNamedOption {
  const factory XmlNamedOption({required Object id, required String name}) =
      _XmlNamedOption;
}
