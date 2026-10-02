import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/proficiency_catalog.dart';
import 'package:personnages/features/characters/domain/proficiency_token_resolver.dart';

const _dagger = ProficiencyCatalogWeapon(
  id: 1,
  name: 'Dague',
  damageDice: '1d4',
  damageType: 'perforant',
  properties: ['finesse', 'légère', 'lancer'],
);
const _shortSword = ProficiencyCatalogWeapon(
  id: 2,
  name: 'Épée courte',
  damageDice: '1d6',
  damageType: 'perforant',
);
const _longSword = ProficiencyCatalogWeapon(
  id: 3,
  name: 'Épée longue',
  damageDice: '1d8',
  damageType: 'tranchant',
);
const _musket = ProficiencyCatalogWeapon(
  id: 4,
  name: 'Mousquet',
  damageDice: '1d12',
  damageType: 'perforant',
);
const _net = ProficiencyCatalogWeapon(id: 5, name: 'Filet');

/// Pluriel irrégulier français en « -eux » (pas un simple « s » terminal) —
/// vu tel quel dans `classes.weapon_proficiencies` du Druide (`'épieux'`).
const _spear = ProficiencyCatalogWeapon(
  id: 6,
  name: 'Épieu',
  damageDice: '1d6',
  damageType: 'perforant',
  properties: ['polyvalente(1d8)', 'lancer'],
);

const _weapons = [_dagger, _shortSword, _longSword, _musket, _net, _spear];

const _leatherArmor = ProficiencyCatalogArmor(
  id: 10,
  name: 'Armure de cuir',
  category: 'armure',
  acBase: 11,
  acDexBonus: 'illimite',
);
const _hideArmor = ProficiencyCatalogArmor(
  id: 11,
  name: 'Armure de peau',
  category: 'armure',
  acBase: 12,
  acDexBonus: 'max_2',
);
const _chainShirt = ProficiencyCatalogArmor(
  id: 12,
  name: 'Chemise de mailles',
  category: 'armure',
  acBase: 13,
  acDexBonus: 'max_2',
);
const _plateArmor = ProficiencyCatalogArmor(
  id: 13,
  name: 'Harnois',
  category: 'armure',
  acBase: 18,
  acDexBonus: 'aucun',
  strengthRequirement: 15,
  stealthDisadvantage: true,
);

const _armors = [_leatherArmor, _hideArmor, _chainShirt, _plateArmor];

const _shield = ProficiencyCatalogArmor(
  id: 20,
  name: 'Bouclier',
  category: 'bouclier',
  acBase: 2,
  acDexBonus: 'aucun',
);

const _shields = [_shield];

void main() {
  group('resolveWeapon', () {
    test("'courantes' -> armes courantes RAW uniquement, triées, Mousquet "
        'exclu', () {
      final detail = ProficiencyTokenResolver.resolveWeapon(
        token: 'courantes',
        weapons: _weapons,
      );
      expect(detail.weapons.map((w) => w.name), ['Dague', 'Épieu']);
      expect(detail.armors, isEmpty);
    });

    test("'martiales' -> armes de guerre RAW uniquement (Filet y compris), "
        'triées', () {
      final detail = ProficiencyTokenResolver.resolveWeapon(
        token: 'martiales',
        weapons: _weapons,
      );
      expect(detail.weapons.map((w) => w.name), [
        'Épée courte',
        'Épée longue',
        'Filet',
      ]);
    });

    test('insensible aux accents/casse pour le token', () {
      final detail = ProficiencyTokenResolver.resolveWeapon(
        token: 'MARTIALES',
        weapons: _weapons,
      );
      expect(detail.weapons, hasLength(3));
    });

    test(
      'token déjà spécifique au singulier : recherche par nom normalisé',
      () {
        final detail = ProficiencyTokenResolver.resolveWeapon(
          token: 'dague',
          weapons: _weapons,
        );
        expect(detail.weapons.map((w) => w.name), ['Dague']);
      },
    );

    test('token déjà spécifique au pluriel ("dagues") matche "Dague"', () {
      final detail = ProficiencyTokenResolver.resolveWeapon(
        token: 'dagues',
        weapons: _weapons,
      );
      expect(detail.weapons.map((w) => w.name), ['Dague']);
    });

    test('token multi-mots au pluriel ("épées courtes") matche "Épée '
        'courte"', () {
      final detail = ProficiencyTokenResolver.resolveWeapon(
        token: 'épées courtes',
        weapons: _weapons,
      );
      expect(detail.weapons.map((w) => w.name), ['Épée courte']);
    });

    test('token spécifique sans correspondance -> liste vide', () {
      final detail = ProficiencyTokenResolver.resolveWeapon(
        token: 'Hallebarde',
        weapons: _weapons,
      );
      expect(detail.weapons, isEmpty);
    });

    test('pluriel irrégulier en "-eux" ("épieux") matche "Épieu" '
        '(classes.weapon_proficiencies du Druide, vu tel quel en base)', () {
      final detail = ProficiencyTokenResolver.resolveWeapon(
        token: 'épieux',
        weapons: _weapons,
      );
      expect(detail.weapons.map((w) => w.name), ['Épieu']);
    });
  });

  group('resolveArmor', () {
    test("'légère' -> armures ac_dex_bonus=illimite uniquement", () {
      final detail = ProficiencyTokenResolver.resolveArmor(
        token: 'légère',
        armors: _armors,
        shields: _shields,
      );
      expect(detail.armors.map((a) => a.name), ['Armure de cuir']);
    });

    test("'intermédiaire' -> armures ac_dex_bonus=max_2, triées", () {
      final detail = ProficiencyTokenResolver.resolveArmor(
        token: 'intermédiaire',
        armors: _armors,
        shields: _shields,
      );
      expect(detail.armors.map((a) => a.name), [
        'Armure de peau',
        'Chemise de mailles',
      ]);
    });

    test("'lourde' -> armures ac_dex_bonus=aucun", () {
      final detail = ProficiencyTokenResolver.resolveArmor(
        token: 'lourde',
        armors: _armors,
        shields: _shields,
      );
      expect(detail.armors.map((a) => a.name), ['Harnois']);
    });

    test("'boucliers' -> tous les boucliers ordinaires", () {
      final detail = ProficiencyTokenResolver.resolveArmor(
        token: 'boucliers',
        armors: _armors,
        shields: _shields,
      );
      expect(detail.armors.map((a) => a.name), ['Bouclier']);
      expect(detail.weapons, isEmpty);
    });

    test("'intermédiaire (non métallique)' -> seulement Armure de peau "
        '(liste blanche Druide)', () {
      final detail = ProficiencyTokenResolver.resolveArmor(
        token: 'intermédiaire (non métallique)',
        armors: _armors,
        shields: _shields,
      );
      expect(detail.armors.map((a) => a.name), ['Armure de peau']);
    });

    test(
      "'boucliers (non métalliques)' -> toujours vide dans ce catalogue",
      () {
        final detail = ProficiencyTokenResolver.resolveArmor(
          token: 'boucliers (non métalliques)',
          armors: _armors,
          shields: _shields,
        );
        expect(detail.armors, isEmpty);
        expect(detail.weapons, isEmpty);
      },
    );

    test('token spécifique (repli défensif, vocabulaire armure ne contient '
        'normalement jamais ce cas) : recherche par nom normalisé, matche '
        '"Harnois"', () {
      final detail = ProficiencyTokenResolver.resolveArmor(
        token: 'Harnois',
        armors: _armors,
        shields: _shields,
      );
      expect(detail.armors.map((a) => a.name), ['Harnois']);
    });

    test('token spécifique (repli défensif) sans aucune correspondance -> '
        'liste vide (ni armors ni shields)', () {
      final detail = ProficiencyTokenResolver.resolveArmor(
        token: 'Cuirasse en diamant',
        armors: _armors,
        shields: _shields,
      );
      expect(detail.armors, isEmpty);
    });
  });
}
