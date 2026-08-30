import 'package:freezed_annotation/freezed_annotation.dart';

import 'xml_character_import_raw.dart';

part 'xml_import_parse_result.freezed.dart';

/// Résultat de `XmlCharacterImportParser.parse` — jamais une exception non
/// gérée qui remonterait jusqu'à l'UI (voir
/// `docs/cahier-des-charges/03-import-xml-aidedd.md`, "gérer un fichier XML
/// malformé/structure non reconnue sans crasher").
@freezed
sealed class XmlImportParseResult with _$XmlImportParseResult {
  const factory XmlImportParseResult.success(XmlCharacterImportRaw character) =
      XmlImportParseSuccess;

  /// [message] est un texte déjà présentable à l'utilisateur (pas une trace
  /// technique) — voir `XmlCharacterImportParser` pour les cas couverts
  /// (XML illisible, racine `<builder><character>` absente, tag requis
  /// manquant).
  const factory XmlImportParseResult.failure(String message) =
      XmlImportParseFailure;
}
