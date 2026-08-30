import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/xml_import/domain/xml_import_hit_points_calculator.dart';
import 'package:personnages/features/xml_import/domain/xml_raw_level_entry.dart';

XmlRawLevelEntry _level(int level, int hpBrut) => XmlRawLevelEntry(
  level: level,
  hpBrut: hpBrut,
  abilityIncreases: const [-1, -1, -1],
);

void main() {
  group('XmlImportHitPointsCalculator.computeMaxHp', () {
    test('somme hp_brut + modificateur de Constitution pour chaque niveau '
        'atteint (hp_brut > 0)', () {
      final levels = [
        _level(1, 8),
        _level(2, 5),
        for (var i = 3; i <= 20; i++) _level(i, 0),
      ];

      final maxHp = XmlImportHitPointsCalculator.computeMaxHp(
        levels: levels,
        constitutionModifier: 1,
      );

      // (8 + 1) + (5 + 1) = 15.
      expect(maxHp, 15);
    });

    test('les niveaux non encore atteints (hp_brut = 0) ne comptent pas', () {
      final levels = [_level(1, 8), for (var i = 2; i <= 20; i++) _level(i, 0)];

      final maxHp = XmlImportHitPointsCalculator.computeMaxHp(
        levels: levels,
        constitutionModifier: 0,
      );

      expect(maxHp, 8);
    });

    test('plancher à 1 même avec un modificateur de Constitution très '
        'négatif (jamais 0 ni moins)', () {
      final levels = [_level(1, 1), _level(2, 1)];

      final maxHp = XmlImportHitPointsCalculator.computeMaxHp(
        levels: levels,
        constitutionModifier: -5,
      );

      expect(maxHp, greaterThanOrEqualTo(1));
    });

    test('liste de niveaux vide -> plancher à 1', () {
      final maxHp = XmlImportHitPointsCalculator.computeMaxHp(
        levels: const [],
        constitutionModifier: 3,
      );

      expect(maxHp, 1);
    });
  });
}
