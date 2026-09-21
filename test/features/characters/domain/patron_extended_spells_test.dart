import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/spell_catalog.dart';
import 'package:personnages/features/character_creation/domain/spell_option.dart';
import 'package:personnages/features/characters/domain/patron_extended_spells.dart';

SpellOption _spell(int id, String name, int level) => SpellOption(
  id: id,
  name: name,
  level: level,
  school: 'Ecole',
  castingTime: '1 action',
);

PatronExtendedSpell _ext(int id, String name, int level, int classLevel) =>
    PatronExtendedSpell(spell: _spell(id, name, level), classLevel: classLevel);

void main() {
  final base = SpellCatalog(
    spells: [_spell(1, 'Bouclier', 1), _spell(2, 'Sommeil', 1)],
  );

  test('sans sort de patron : catalogue inchange', () {
    final result = PatronExtendedSpells.merge(
      base: base,
      extended: const [],
      warlockLevel: 5,
      maxSpellLevel: 3,
    );
    expect(result.catalog, base);
    expect(result.patronOnlySpellIds, isEmpty);
  });

  test('ajoute les sorts accessibles, tries par nom, marques patron', () {
    final result = PatronExtendedSpells.merge(
      base: base,
      extended: [
        _ext(10, 'Mains brulantes', 1, 1),
        _ext(11, 'Fracasser', 2, 3),
      ],
      warlockLevel: 3,
      maxSpellLevel: 2,
    );
    expect(result.catalog.spells.map((s) => s.name), [
      'Bouclier',
      'Fracasser',
      'Mains brulantes',
      'Sommeil',
    ]);
    expect(result.patronOnlySpellIds, {10, 11});
  });

  test('exclut les sorts dont le niveau de classe requis > niveau cible', () {
    final result = PatronExtendedSpells.merge(
      base: base,
      extended: [_ext(10, 'A', 1, 1), _ext(11, 'B', 2, 3)],
      warlockLevel: 2,
      maxSpellLevel: 5,
    );
    expect(result.patronOnlySpellIds, {10});
  });

  test('inclut un sort quand niveau cible == class_level (borne)', () {
    final result = PatronExtendedSpells.merge(
      base: base,
      extended: [_ext(11, 'B', 2, 3)],
      warlockLevel: 3,
      maxSpellLevel: 5,
    );
    expect(result.patronOnlySpellIds, {11});
  });

  test('respecte le plafond de niveau de sort (emplacements de pacte)', () {
    final result = PatronExtendedSpells.merge(
      base: base,
      extended: [_ext(10, 'A', 1, 1), _ext(12, 'C', 3, 1)],
      warlockLevel: 9,
      maxSpellLevel: 2,
    );
    expect(result.patronOnlySpellIds, {10});
    expect(result.catalog.spells.any((s) => s.id == 12), isFalse);
  });

  test('aucun doublon : sort deja dans la liste de classe ou repete', () {
    final result = PatronExtendedSpells.merge(
      base: base,
      extended: [
        _ext(2, 'Sommeil', 1, 1),
        _ext(10, 'A', 1, 1),
        _ext(10, 'A', 1, 1),
      ],
      warlockLevel: 5,
      maxSpellLevel: 3,
    );
    expect(result.catalog.spells.where((s) => s.id == 2), hasLength(1));
    expect(result.catalog.spells.where((s) => s.id == 10), hasLength(1));
    // Sort deja dans la liste de classe : pas marque "Patron".
    expect(result.patronOnlySpellIds, {10});
  });
}
