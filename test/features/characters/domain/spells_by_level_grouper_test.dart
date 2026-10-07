import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/spells_by_level_grouper.dart';

CharacterSpellEntry _spell({
  required int id,
  required String name,
  required int level,
  String school = 'Évocation',
}) {
  return CharacterSpellEntry(
    id: id,
    name: name,
    level: level,
    school: school,
    status: 'connu',
  );
}

void main() {
  group('SpellsByLevelGrouper.labelFor', () {
    test('"Sorts mineurs" pour le niveau 0', () {
      expect(SpellsByLevelGrouper.labelFor(0), 'Sorts mineurs');
    });

    test('"Niveau N" pour un niveau >= 1', () {
      expect(SpellsByLevelGrouper.labelFor(1), 'Niveau 1');
      expect(SpellsByLevelGrouper.labelFor(5), 'Niveau 5');
    });
  });

  group('SpellsByLevelGrouper.group', () {
    test('regroupe par niveau, triés par niveau croissant', () {
      final groups = SpellsByLevelGrouper.group([
        _spell(id: 1, name: 'Boule de feu', level: 3),
        _spell(id: 2, name: 'Lumière', level: 0),
        _spell(id: 3, name: 'Bouclier', level: 1),
        _spell(id: 4, name: 'Prestidigitation', level: 0),
      ]);

      expect(groups, hasLength(3));
      expect(groups[0].level, 0);
      expect(groups[0].label, 'Sorts mineurs');
      expect(groups[1].level, 1);
      expect(groups[1].label, 'Niveau 1');
      expect(groups[2].level, 3);
      expect(groups[2].label, 'Niveau 3');
    });

    test('trie les sorts d\'un même niveau par nom', () {
      final groups = SpellsByLevelGrouper.group([
        _spell(id: 1, name: 'Prestidigitation', level: 0),
        _spell(id: 2, name: 'Lumière', level: 0),
      ]);

      expect(groups.single.spells.map((s) => s.name), [
        'Lumière',
        'Prestidigitation',
      ]);
    });

    test('preparedFirst : les sorts restant à préparer passent après les '
        'autres au sein de leur niveau, chaque bloc trié par nom', () {
      const unpreparedA = CharacterSpellEntry(
        id: 1,
        name: 'Armure de mage',
        level: 1,
        school: '',
        status: 'connu',
      );
      const preparedZ = CharacterSpellEntry(
        id: 2,
        name: 'Zone de vérité',
        level: 1,
        school: '',
        status: 'préparé',
      );
      const preparedB = CharacterSpellEntry(
        id: 3,
        name: 'Bouclier',
        level: 1,
        school: '',
        status: 'préparé',
      );

      final groups = SpellsByLevelGrouper.group(const [
        unpreparedA,
        preparedZ,
        preparedB,
      ], preparedFirst: true);

      expect(groups.single.spells, [preparedB, preparedZ, unpreparedA]);
    });

    test('liste vide -> aucun groupe', () {
      expect(SpellsByLevelGrouper.group(const []), isEmpty);
    });
  });

  test('preparedFirst : un sort qui ne se prépare pas (classe à sorts '
      'connus) reste dans le premier bloc, même au statut "connu"', () {
    const knownC = CharacterSpellEntry(
      id: 1,
      name: 'Charme-personne',
      level: 1,
      school: '',
      status: 'connu',
      requiresPreparation: false,
    );
    const unpreparedA = CharacterSpellEntry(
      id: 2,
      name: 'Armure de mage',
      level: 1,
      school: '',
      status: 'connu',
    );
    const preparedZ = CharacterSpellEntry(
      id: 3,
      name: 'Zone de vérité',
      level: 1,
      school: '',
      status: 'préparé',
    );

    final groups = SpellsByLevelGrouper.group(const [
      unpreparedA,
      preparedZ,
      knownC,
    ], preparedFirst: true);

    expect(groups.single.spells, [knownC, preparedZ, unpreparedA]);
  });
}
