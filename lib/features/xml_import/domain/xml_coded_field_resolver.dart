import 'xml_field_resolution.dart';

/// Résout un champ "codé" de l'import XML aidedd.org (armure, bouclier,
/// arme, outil/instrument physique, objet d'équipement, alignement, sexe,
/// compétence, paquetage) : identifiant numérique → libellé, via une table
/// de correspondance de `data/aidedd_reference_tables.dart` passée en
/// paramètre — jamais une exception si l'identifiant est inconnu (voir
/// `docs/cahier-des-charges/03-import-xml-aidedd.md`, point 4 du
/// "Comportement attendu de l'import").
abstract final class XmlCodedFieldResolver {
  static XmlFieldResolution<String> resolveById({
    required int? id,
    required Map<int, String> table,
  }) {
    if (id == null) {
      return const XmlFieldResolution<String>.unrecognized('(absent)');
    }
    final label = table[id];
    if (label == null) {
      return XmlFieldResolution<String>.unrecognized(id.toString());
    }
    return XmlFieldResolution<String>.recognized(label);
  }

  /// Comme [resolveById], mais à partir d'un jeton brut pas encore parsé en
  /// `int` (`XmlCharacterImportRaw.skillsProf`/`weaponIds`/
  /// `toolEquipmentIds`/`itemIds`, voir leur documentation) — un jeton qui
  /// n'est même pas un entier valide (export corrompu, ex. jeton `"abc"`
  /// dans `item`) retombe directement sur [XmlFieldResolution.unrecognized]
  /// avec le jeton brut préservé tel quel, plutôt que d'être silencieusement
  /// confondu avec l'identifiant `0` ("emplacement vide") par un repli
  /// `int.tryParse(...) ?? 0` en amont — voir la revue QA de l'increment 1.
  static XmlFieldResolution<String> resolveByRawToken({
    required String? rawToken,
    required Map<int, String> table,
  }) {
    final trimmed = rawToken?.trim() ?? '';
    if (trimmed.isEmpty) {
      return const XmlFieldResolution<String>.unrecognized('(absent)');
    }
    final id = int.tryParse(trimmed);
    if (id == null) {
      return XmlFieldResolution<String>.unrecognized(trimmed);
    }
    return resolveById(id: id, table: table);
  }
}
