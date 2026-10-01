import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/hit_point_bonus_rules.dart';

void main() {
  group('HitPointBonusRules.perLevelBonus', () {
    test('aucun bonus par défaut', () {
      expect(
        HitPointBonusRules.perLevelBonus(
          subraceName: 'Haut-elfe',
          hasToughFeat: false,
          levelingClassName: 'Magicien',
          levelingSubclassName: null,
        ),
        0,
      );
    });

    test('Nain des collines : +1', () {
      expect(
        HitPointBonusRules.perLevelBonus(
          subraceName: HitPointBonusRules.hillDwarfSubraceName,
          hasToughFeat: false,
          levelingClassName: 'Guerrier',
          levelingSubclassName: null,
        ),
        1,
      );
    });

    test('don Robuste : +2', () {
      expect(
        HitPointBonusRules.perLevelBonus(
          subraceName: null,
          hasToughFeat: true,
          levelingClassName: 'Guerrier',
          levelingSubclassName: null,
        ),
        2,
      );
    });

    test('Résilience draconique : +1 seulement sur un niveau d\'Ensorceleur', () {
      expect(
        HitPointBonusRules.perLevelBonus(
          subraceName: null,
          hasToughFeat: false,
          levelingClassName: HitPointBonusRules.sorcererClassName,
          levelingSubclassName: HitPointBonusRules.draconicSubclassName,
        ),
        1,
      );
      expect(
        HitPointBonusRules.perLevelBonus(
          subraceName: null,
          hasToughFeat: false,
          levelingClassName: 'Guerrier',
          levelingSubclassName: null,
        ),
        0,
      );
    });

    test('cumul : Nain des collines + Robuste + draconique = +4', () {
      expect(
        HitPointBonusRules.perLevelBonus(
          subraceName: HitPointBonusRules.hillDwarfSubraceName,
          hasToughFeat: true,
          levelingClassName: HitPointBonusRules.sorcererClassName,
          levelingSubclassName: HitPointBonusRules.draconicSubclassName,
        ),
        4,
      );
    });
  });

  test('don Robuste pris au niveau 8 : +16 PV rétroactifs', () {
    expect(HitPointBonusRules.toughFeatRetroactiveBonus(8), 16);
  });

  test('featTakenBonus : Robuste physiquement, Faveur de robustesse, autres', () {
    expect(
      HitPointBonusRules.featTakenBonus(
        featName: 'Robuste physiquement',
        totalLevel: 8,
      ),
      16,
    );
    expect(
      HitPointBonusRules.featTakenBonus(
        featName: 'Faveur de robustesse',
        totalLevel: 19,
      ),
      40,
    );
    // « Robuste » est le don Resilient en base : aucun PV.
    expect(
      HitPointBonusRules.featTakenBonus(featName: 'Robuste', totalLevel: 8),
      0,
    );
  });

  group('HitPointBonusRules.constitutionRetroactiveBonus', () {
    test('15 -> 16 (+2 -> +3) au niveau 8 : +8 PV', () {
      expect(
        HitPointBonusRules.constitutionRetroactiveBonus(
          oldScore: 15,
          newScore: 16,
          totalLevel: 8,
        ),
        8,
      );
    });

    test('14 -> 15 (modificateur inchangé) : 0', () {
      expect(
        HitPointBonusRules.constitutionRetroactiveBonus(
          oldScore: 14,
          newScore: 15,
          totalLevel: 8,
        ),
        0,
      );
    });

    test('9 -> 11 (−1 -> 0) au niveau 4 : +4 PV', () {
      expect(
        HitPointBonusRules.constitutionRetroactiveBonus(
          oldScore: 9,
          newScore: 11,
          totalLevel: 4,
        ),
        4,
      );
    });
  });
}
