/// Motif stable d'échec de `XmlCharacterImportParser.parse` — porté par
/// [XmlImportParseResult.failure] puis par `XmlImportInvalidFileFailure`
/// (`presentation/providers/xml_import_providers.dart`), jusqu'à être résolu
/// en texte affichable par `presentation/xml_import_review_screen.dart` (seul
/// consommateur de ce type, voir sa fonction privée de résolution) — jamais
/// un message déjà construit : ce fichier reste dans `domain/`, donc sans
/// `BuildContext`, suivant le même principe que les enums d'échec déjà posés
/// ailleurs dans ce chantier de traduction (`CharacterErrorCode`/
/// `GroupErrorCode`).
///
/// Un seul consommateur existant (contrairement à `CharacterCreationFailure`/
/// `GroupFailure`, dupliqués dans plusieurs écrans) : pas de champ `message`
/// de repli transitoire nécessaire ici, voir la documentation de classe de
/// `XmlImportParseResult`.
enum XmlImportParseErrorCode {
  /// XML illisible (`XmlDocument.parse` lève une exception).
  invalidXml,

  /// XML lisible, mais racine différente de `<builder>`.
  missingBuilderRoot,

  /// Racine `<builder>` reconnue, mais balise `<character>` absente.
  missingCharacterElement,

  /// `<character>` présent, mais au moins un des 4 champs minimaux (nom,
  /// race, classe, historique) est absent.
  missingRequiredFields,
}
