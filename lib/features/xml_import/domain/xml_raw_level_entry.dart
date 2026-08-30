import 'package:freezed_annotation/freezed_annotation.dart';

part 'xml_raw_level_entry.freezed.dart';

/// Une entrée `<lvl lvl="X">` du XML aidedd.org — un personnage exporté en
/// contient toujours 20 (niveaux 1 à 20), la plupart à `hpBrut = 0` pour les
/// niveaux non encore atteints (voir
/// `docs/cahier-des-charges/03-import-xml-aidedd.md`).
@freezed
abstract class XmlRawLevelEntry with _$XmlRawLevelEntry {
  const factory XmlRawLevelEntry({
    required int level,

    /// `<hp_brut>` — `0` pour un niveau non encore atteint.
    required int hpBrut,

    /// `<aug_carac0>`, `<aug_carac1>`, `<aug_carac2>` dans cet ordre —
    /// `-1` signifie "aucune augmentation à ce niveau" (hypothèse du
    /// document de rétro-ingénierie, non confirmée sur un export avec ASI
    /// réelle faute d'échantillon niveau 4+ disponible ; gardée telle
    /// quelle, non retraduite ici, pour ne pas figer une interprétation non
    /// vérifiée dans le modèle — voir `xml-import-reference-mapping.md`,
    /// section "Points non vérifiables en session anonyme").
    required List<int> abilityIncreases,
  }) = _XmlRawLevelEntry;
}
