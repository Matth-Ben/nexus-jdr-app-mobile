import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/spell_grant_source.dart';
import 'package:personnages/features/characters/domain/subclass_spell_grant_resolver.dart';

// Domaine de Clerc fictif : 2 sorts par palier 1/3/5/7/9.
const _clericGrants = [
  SubclassSpellGrant(subclassId: 10, spellId: 101, classLevel: 1),
  SubclassSpellGrant(subclassId: 10, spellId: 102, classLevel: 1),
  SubclassSpellGrant(subclassId: 10, spellId: 103, classLevel: 3),
  SubclassSpellGrant(subclassId: 10, spellId: 104, classLevel: 3),
  SubclassSpellGrant(subclassId: 10, spellId: 105, classLevel: 5),
  SubclassSpellGrant(subclassId: 10, spellId: 106, classLevel: 5),
  SubclassSpellGrant(subclassId: 10, spellId: 107, classLevel: 7),
  SubclassSpellGrant(subclassId: 10, spellId: 108, classLevel: 7),
  SubclassSpellGrant(subclassId: 10, spellId: 109, classLevel: 9),
  SubclassSpellGrant(subclassId: 10, spellId: 110, classLevel: 9),
];

// Serment de Paladin fictif : paliers 3/5.
const _paladinGrants = [
  SubclassSpellGrant(subclassId: 20, spellId: 201, classLevel: 3),
  SubclassSpellGrant(subclassId: 20, spellId: 202, classLevel: 3),
  SubclassSpellGrant(subclassId: 20, spellId: 203, classLevel: 5),
];

SubclassProgress _cleric(int level) => SubclassProgress(
  subclassId: 10,
  classLevel: level,
  source: SpellGrantSource.domain,
);

void main() {
  group('SubclassSpellGrantResolver.resolve', () {
    test('par palier de niveau de classe (rétroactif, cumulatif)', () {
      const expectedCounts = {
        1: 2,
        2: 2,
        3: 4,
        4: 4,
        5: 6,
        6: 6,
        7: 8,
        8: 8,
        9: 10,
        20: 10,
      };
      expectedCounts.forEach((level, count) {
        final result = SubclassSpellGrantResolver.resolve(
          progress: [_cleric(level)],
          grants: _clericGrants,
        );
        expect(result, hasLength(count), reason: 'niveau de classe $level');
      });
    });

    test('niveau 5 : contient tous les sorts jusqu\'au palier 5, pas 7', () {
      final result = SubclassSpellGrantResolver.resolve(
        progress: [_cleric(5)],
        grants: _clericGrants,
      );
      expect(result.keys, containsAll([101, 102, 103, 104, 105, 106]));
      expect(result.keys, isNot(contains(107)));
    });

    test('niveau 0 (donnée incohérente) : rien', () {
      expect(
        SubclassSpellGrantResolver.resolve(
          progress: [_cleric(0)],
          grants: _clericGrants,
        ),
        isEmpty,
      );
    });

    test('sous-classe sans sorts accordés : vide', () {
      final result = SubclassSpellGrantResolver.resolve(
        progress: const [
          SubclassProgress(
            subclassId: 99,
            classLevel: 20,
            source: SpellGrantSource.domain,
          ),
        ],
        grants: _clericGrants,
      );
      expect(result, isEmpty);
    });

    test('aucune sous-classe : vide', () {
      expect(
        SubclassSpellGrantResolver.resolve(
          progress: const [],
          grants: _clericGrants,
        ),
        isEmpty,
      );
    });

    test('multiclassage : chaque sous-classe utilise le niveau de SA classe '
        '(pas le niveau total)', () {
      // Clerc 3 / Paladin 5 (niveau total 8) : le palier 5 du Clerc et le
      // palier 7 du Clerc ne sont pas atteints, mais le palier 5 du Paladin
      // l'est.
      final result = SubclassSpellGrantResolver.resolve(
        progress: [
          _cleric(3),
          const SubclassProgress(
            subclassId: 20,
            classLevel: 5,
            source: SpellGrantSource.oath,
          ),
        ],
        grants: [..._clericGrants, ..._paladinGrants],
      );
      expect(result.keys.toSet(), {101, 102, 103, 104, 201, 202, 203});
      expect(result[103], SpellGrantSource.domain);
      expect(result[203], SpellGrantSource.oath);
    });

    test('un sort accordé par deux sous-classes garde la première origine', () {
      final result = SubclassSpellGrantResolver.resolve(
        progress: [
          _cleric(1),
          const SubclassProgress(
            subclassId: 20,
            classLevel: 3,
            source: SpellGrantSource.oath,
          ),
        ],
        grants: const [
          SubclassSpellGrant(subclassId: 10, spellId: 500, classLevel: 1),
          SubclassSpellGrant(subclassId: 20, spellId: 500, classLevel: 3),
        ],
      );
      expect(result, {500: SpellGrantSource.domain});
    });
  });

  group('SpellGrantSource.forClassName', () {
    test('Clerc -> domaine, Paladin -> serment, autre -> sous-classe', () {
      expect(SpellGrantSource.forClassName('Clerc'), SpellGrantSource.domain);
      expect(SpellGrantSource.forClassName('Paladin'), SpellGrantSource.oath);
      expect(
        SpellGrantSource.forClassName('Druide'),
        SpellGrantSource.subclass,
      );
      expect(SpellGrantSource.domain.label, 'Domaine');
      expect(SpellGrantSource.oath.label, 'Serment');
    });
  });
}
