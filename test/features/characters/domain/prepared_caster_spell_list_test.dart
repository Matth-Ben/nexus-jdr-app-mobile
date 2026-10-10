import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/prepared_caster_spell_list.dart';

void main() {
  group('PreparedCasterSpellList.maxSpellLevelFor', () {
    test('Clerc/Druide (lanceurs complets) : niveau de sort max selon le '
        'niveau de classe', () {
      expect(PreparedCasterSpellList.maxSpellLevelFor('Clerc', 1), 1);
      expect(PreparedCasterSpellList.maxSpellLevelFor('Clerc', 3), 2);
      expect(PreparedCasterSpellList.maxSpellLevelFor('Druide', 5), 3);
      expect(PreparedCasterSpellList.maxSpellLevelFor('Clerc', 17), 9);
    });

    test('Paladin (demi-lanceur) : aucun sort au niveau 1, niveau 1 au '
        'niveau 2, niveau 2 au niveau 5', () {
      expect(PreparedCasterSpellList.maxSpellLevelFor('Paladin', 1), 0);
      expect(PreparedCasterSpellList.maxSpellLevelFor('Paladin', 2), 1);
      expect(PreparedCasterSpellList.maxSpellLevelFor('Paladin', 5), 2);
    });

    test('toute autre classe (Magicien compris, qui prépare depuis son '
        'grimoire) : 0', () {
      expect(PreparedCasterSpellList.maxSpellLevelFor('Magicien', 5), 0);
      expect(PreparedCasterSpellList.maxSpellLevelFor('Barde', 5), 0);
      expect(PreparedCasterSpellList.maxSpellLevelFor('Guerrier', 5), 0);
    });

    test("Artificier (D41, demi-lanceur qui prépare) : mêmes valeurs que "
        "Paladin, même table d'emplacements (simplification assumée, voir "
        'docs/dette-technique.md)', () {
      expect(PreparedCasterSpellList.maxSpellLevelFor('Artificier', 1), 0);
      expect(PreparedCasterSpellList.maxSpellLevelFor('Artificier', 2), 1);
      expect(PreparedCasterSpellList.maxSpellLevelFor('Artificier', 5), 2);
    });
  });

  test('classNames : les 4 classes à liste de sorts complète '
      '(Clerc/Druide/Paladin/Artificier), jamais le Magicien (grimoire)', () {
    expect(PreparedCasterSpellList.classNames, {
      'Clerc',
      'Druide',
      'Paladin',
      'Artificier',
    });
  });
}
