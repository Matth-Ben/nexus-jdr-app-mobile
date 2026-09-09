import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/spell_name_filter.dart';

CharacterSpellEntry _spell(int id, String name, {int level = 1}) =>
    CharacterSpellEntry(
      id: id,
      name: name,
      level: level,
      school: 'évocation',
      status: 'connu',
    );

void main() {
  group('SpellNameFilter.apply', () {
    final spells = [
      _spell(1, 'Boule de feu'),
      _spell(2, 'Bouclier'),
      _spell(3, 'Détection de la magie'),
    ];

    test('requête vide renvoie la liste telle quelle', () {
      expect(SpellNameFilter.apply(spells: spells, query: ''), spells);
    });

    test('requête vide après trim (espaces seuls) équivaut à aucune requête', () {
      expect(SpellNameFilter.apply(spells: spells, query: '   '), spells);
    });

    test('filtre par sous-chaîne du nom, insensible à la casse', () {
      final result = SpellNameFilter.apply(spells: spells, query: 'BOULE');
      expect(result, [spells[0]]);
    });

    test('sous-chaîne partagée par plusieurs sorts ("bou")', () {
      final result = SpellNameFilter.apply(spells: spells, query: 'bou');
      expect(result, [spells[0], spells[1]]);
    });

    test('sous-chaîne au milieu du nom', () {
      final result = SpellNameFilter.apply(spells: spells, query: 'magie');
      expect(result, [spells[2]]);
    });

    test('aucun résultat renvoie une liste vide', () {
      expect(SpellNameFilter.apply(spells: spells, query: 'zzzzz'), isEmpty);
    });
  });
}
