import 'dart:math' as math;

import 'xml_raw_level_entry.dart';

/// Calcul des points de vie maximum d'un personnage importé, à partir de
/// l'historique par niveau exporté par aidedd.org (`<lvl lvl="X"><hp_brut>`)
/// — voir `docs/cahier-des-charges/02-modele-donnees.md`, `characters.max_hp`
/// : "recalculés/mis à jour à chaque montée de niveau (somme de
/// `character_level_hp.hp_rolled` + modificateur de Constitution par
/// niveau)".
///
/// Distinct de `character_creation/domain/hit_points_calculator.dart`
/// (`HitPointsCalculator.maxHpAtLevel1`, un seul niveau, dé de vie + modif.
/// Constitution, sans lancer de dé) : un personnage importé a déjà, pour
/// chaque niveau atteint, une valeur de PV réellement gagnée (lancée ou
/// moyenne, aidedd.org ne distingue pas laquelle) à sommer, pas un dé de vie
/// à recalculer — logiques différentes, pas de code à partager entre les
/// deux.
abstract final class XmlImportHitPointsCalculator {
  /// Somme `hp_brut + modificateur de Constitution` pour chaque entrée de
  /// [levels] où `hp_brut > 0` (les niveaux non encore atteints valent `0`,
  /// voir `XmlRawLevelEntry.hpBrut`) — plancher à 1, même rationale que
  /// `HitPointsCalculator.maxHpAtLevel1` (un modificateur de Constitution très
  /// négatif ne doit jamais ramener les PV maximum à 0 ou moins).
  static int computeMaxHp({
    required List<XmlRawLevelEntry> levels,
    required int constitutionModifier,
  }) {
    var total = 0;
    for (final entry in levels) {
      if (entry.hpBrut > 0) {
        total += entry.hpBrut + constitutionModifier;
      }
    }
    return math.max(1, total);
  }
}
