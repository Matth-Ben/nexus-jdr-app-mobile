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
  });
}
