// Logique pure des filtres de sorts (P4) : normalisation d'école FR/EN, ET
// entre critères, OU entre valeurs d'un même critère.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/rules/spell_status.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/spell_list_filter.dart';
import 'package:personnages/features/characters/domain/spell_school.dart';

CharacterSpellEntry _spell(
  int id,
  int level,
  String school, {
  bool concentration = false,
}) => CharacterSpellEntry(
  id: id,
  name: 'S$id',
  level: level,
  school: school,
  status: SpellStatus.known,
  concentration: concentration,
);

List<int> _ids(List<CharacterSpellEntry> spells) => [
  for (final spell in spells) spell.id,
];

void main() {
  group('SpellSchool.fromStored', () {
    test('les huit écoles FR du seed', () {
      const french = {
        'Abjuration': SpellSchool.abjuration,
        'Invocation': SpellSchool.conjuration,
        'Divination': SpellSchool.divination,
        'Enchantement': SpellSchool.enchantment,
        'Évocation': SpellSchool.evocation,
        'Illusion': SpellSchool.illusion,
        'Nécromancie': SpellSchool.necromancy,
        'Transmutation': SpellSchool.transmutation,
      };
      french.forEach((stored, school) {
        expect(SpellSchool.fromStored(stored), school, reason: stored);
      });
    });

    test('les huit écoles EN et la variante « Conjuration » du seed', () {
      const english = {
        'Abjuration': SpellSchool.abjuration,
        'Conjuration': SpellSchool.conjuration,
        'Divination': SpellSchool.divination,
        'Enchantment': SpellSchool.enchantment,
        'Evocation': SpellSchool.evocation,
        'Illusion': SpellSchool.illusion,
        'Necromancy': SpellSchool.necromancy,
        'Transmutation': SpellSchool.transmutation,
      };
      english.forEach((stored, school) {
        expect(SpellSchool.fromStored(stored), school, reason: stored);
      });
    });

    test('insensible à la casse, aux accents et aux espaces', () {
      expect(SpellSchool.fromStored('  évocation '), SpellSchool.evocation);
      expect(SpellSchool.fromStored('EVOCATION'), SpellSchool.evocation);
      expect(SpellSchool.fromStored('NÉCROMANCIE'), SpellSchool.necromancy);
    });

    test('vide, nul ou inconnu : aucune école', () {
      expect(SpellSchool.fromStored(null), isNull);
      expect(SpellSchool.fromStored(''), isNull);
      expect(SpellSchool.fromStored('Chronurgie'), isNull);
    });
  });

  group('SpellListFilter', () {
    final spells = [
      _spell(1, 0, 'Évocation'),
      _spell(2, 1, 'Abjuration'),
      _spell(3, 1, 'Enchantement', concentration: true),
      _spell(4, 3, 'Evocation'),
      _spell(5, 3, 'Transmutation', concentration: true),
      _spell(6, 2, ''),
    ];

    test('aucun filtre : tout passe, rien d\'actif', () {
      expect(SpellListFilter.none.isActive, isFalse);
      expect(SpellListFilter.none.activeCount, 0);
      expect(_ids(SpellListFilter.none.apply(spells)), [1, 2, 3, 4, 5, 6]);
    });

    test('OU entre les valeurs d\'un même critère (niveau 1 OU 3)', () {
      const filter = SpellListFilter(levels: {1, 3});
      expect(_ids(filter.apply(spells)), [2, 3, 4, 5]);
    });

    test('OU entre écoles', () {
      const filter = SpellListFilter(
        schools: {SpellSchool.abjuration, SpellSchool.transmutation},
      );
      expect(_ids(filter.apply(spells)), [2, 5]);
    });

    test('ET entre critères', () {
      const filter = SpellListFilter(
        levels: {1, 3},
        schools: {SpellSchool.evocation, SpellSchool.enchantment},
        concentration: SpellConcentrationFilter.concentration,
      );
      // Niveau 1/3 ET (Évocation OU Enchantement) ET concentration.
      expect(_ids(filter.apply(spells)), [3]);
    });

    test('école comparée sur la clé normalisée : valeur FR et EN', () {
      const filter = SpellListFilter(schools: {SpellSchool.evocation});
      // 1 : « Évocation » (FR), 4 : « Evocation » (EN).
      expect(_ids(filter.apply(spells)), [1, 4]);
    });

    test('un sort sans école ne passe aucun filtre d\'école', () {
      const filter = SpellListFilter(schools: {SpellSchool.abjuration});
      expect(_ids(filter.apply(spells)), isNot(contains(6)));
    });

    test('concentration : Tous / Avec / Sans', () {
      expect(_ids(SpellListFilter.none.apply(spells)).length, 6);
      const only = SpellListFilter(
        concentration: SpellConcentrationFilter.concentration,
      );
      const none = SpellListFilter(
        concentration: SpellConcentrationFilter.noConcentration,
      );
      expect(_ids(only.apply(spells)), [3, 5]);
      expect(_ids(none.apply(spells)), [1, 2, 4, 6]);
    });

    test('activeCount : une unité par valeur, une pour la concentration', () {
      const filter = SpellListFilter(
        levels: {1, 3},
        schools: {SpellSchool.evocation},
        concentration: SpellConcentrationFilter.noConcentration,
      );
      expect(filter.activeCount, 4);
      expect(filter.isActive, isTrue);
    });

    test('niveaux et écoles présents seulement', () {
      expect(SpellListFilter.presentLevels(spells), [0, 1, 2, 3]);
      expect(SpellListFilter.presentSchools(spells), [
        SpellSchool.abjuration,
        SpellSchool.enchantment,
        SpellSchool.evocation,
        SpellSchool.transmutation,
      ]);
    });

    test('égalité par valeur', () {
      expect(
        const SpellListFilter(levels: {1, 3}),
        const SpellListFilter(levels: {3, 1}),
      );
      expect(
        const SpellListFilter(levels: {1}),
        isNot(const SpellListFilter(levels: {2})),
      );
    });
  });
}
