import '../../xml_import/domain/aidedd_reference_tables.dart';
import '../../xml_import/domain/xml_name_normalizer.dart';

/// Inverse des tables `identifiant numérique aidedd.org → libellé` de
/// `xml_import/domain/aidedd_reference_tables.dart` (`AideddReferenceTables`)
/// — `libellé → identifiant`, nécessaires à l'export XML compatible
/// aidedd.org (`data/xml_character_exporter.dart`) pour retrouver le code
/// numérique attendu par le format à partir d'un nom déjà résolu côté fiche
/// personnage (`CharacterDetail`).
///
/// Comparaison insensible à la casse/aux accents via [XmlNameNormalizer]
/// (même normalisation que `XmlNameResolver`, utilisée par l'import dans le
/// sens inverse) : un libellé de `CharacterDetail` n'est pas garanti
/// d'utiliser exactement la même casse/accentuation que
/// `AideddReferenceTables` (même si en pratique les deux viennent du même
/// contenu français D&D 5e).
///
/// Construites une seule fois par table (`static final`, pas `const` — la
/// construction elle-même n'est pas `const`-compatible avec la boucle
/// d'inversion), inversion "premier trouvé gagne" via `putIfAbsent` :
/// **aucune des tables sources n'a de libellé dupliqué** au moment de ce
/// chantier (vérifié pour les 8 tables ci-dessous par un test dédié,
/// `test/features/xml_export/domain/aidedd_reverse_tables_test.dart`), donc
/// ce choix reste actuellement uniquement défensif (voir la consigne
/// d'origine de la tâche : documenter plutôt que deviner silencieusement en
/// cas d'ambiguïté future si une table venait à évoluer côté
/// `xml_import`).
abstract final class AideddReverseTables {
  static Map<String, int> _invert(Map<int, String> table) {
    final result = <String, int>{};
    for (final entry in table.entries) {
      result.putIfAbsent(
        XmlNameNormalizer.normalize(entry.value),
        () => entry.key,
      );
    }
    return result;
  }

  static final Map<String, int> skills = _invert(AideddReferenceTables.skills);
  static final Map<String, int> armor = _invert(AideddReferenceTables.armor);
  static final Map<String, int> shield = _invert(AideddReferenceTables.shield);
  static final Map<String, int> weapons = _invert(
    AideddReferenceTables.weapons,
  );
  static final Map<String, int> toolsEquipment = _invert(
    AideddReferenceTables.toolsEquipment,
  );
  static final Map<String, int> items = _invert(AideddReferenceTables.items);
  static final Map<String, int> alignments = _invert(
    AideddReferenceTables.alignments,
  );
  static final Map<String, int> sexes = _invert(AideddReferenceTables.sexes);

  /// Recherche [label] (normalisé) dans [reverseTable] — `null` si aucune
  /// entrée de la table aidedd.org correspondante ne porte ce libellé (contenu
  /// hors du périmètre fixe du format, ex. objet magique, arme exotique,
  /// alignement/sexe non standard) : jamais une exception, voir
  /// `data/xml_character_exporter.dart` pour la façon dont chaque appelant
  /// gère ce repli (le plus souvent un texte libre `<itemX>`, ou l'omission
  /// pure et simple du tag pour un champ optionnel comme `<alignment>`/
  /// `<sexe>`).
  static int? lookup(Map<String, int> reverseTable, String? label) {
    final trimmed = label?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return reverseTable[XmlNameNormalizer.normalize(trimmed)];
  }
}
