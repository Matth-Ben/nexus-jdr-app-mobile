import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/spell_status_formatter.dart';
import 'package:personnages/features/characters/domain/spell_grant_source.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/data/character_spell_row_mapper.dart';

void main() {
  group('CharacterSpellRowMapper.collectSpellIds', () {
    test('collecte les spell_id en Set<int>, dédupliqués', () {
      final rows = [
        {'spell_id': 1, 'status': 'connu'},
        {'spell_id': 2, 'status': 'connu'},
        {'spell_id': 1, 'status': 'connu'},
      ];
      expect(CharacterSpellRowMapper.collectSpellIds(rows), {1, 2});
    });

    test('ignore une ligne sans spell_id exploitable', () {
      final rows = [
        {'spell_id': null, 'status': 'connu'},
      ];
      expect(CharacterSpellRowMapper.collectSpellIds(rows), isEmpty);
    });
  });

  group('CharacterSpellRowMapper.parseStatuses', () {
    test('construit {spell_id: status}', () {
      final rows = [
        {'spell_id': 1, 'status': 'préparé'},
        {'spell_id': 2, 'status': 'inné'},
      ];
      expect(CharacterSpellRowMapper.parseStatuses(rows), {
        1: 'préparé',
        2: 'inné',
      });
    });
  });

  group('CharacterSpellRowMapper.parseStatuses — lignes en double', () {
    test("une ligne ordinaire l'emporte sur une ligne 'inné', quel que soit "
        "l'ordre", () {
      for (final ordinary in ['connu', 'préparé', 'autre']) {
        final rows = [
          {'spell_id': 1, 'status': 'inné'},
          {'spell_id': 1, 'status': ordinary},
        ];
        expect(CharacterSpellRowMapper.parseStatuses(rows), {1: ordinary});
        expect(CharacterSpellRowMapper.parseStatuses(rows.reversed.toList()), {
          1: ordinary,
        });
      }
    });

    test("deux lignes 'inné' : le sort reste inné", () {
      final rows = [
        {'spell_id': 1, 'status': 'inné'},
        {'spell_id': 1, 'status': 'inné'},
      ];
      expect(CharacterSpellRowMapper.parseStatuses(rows), {1: 'inné'});
    });

    test("lignes ordinaires de statuts différents ('connu'/'préparé') : "
        "'préparé' l'emporte toujours, quel que soit l'ordre des lignes — "
        'corrigé (D10) : avant ce correctif, la dernière ligne lue '
        "l'emportait (ordre non garanti côté PostgREST)", () {
      final rows = [
        {'spell_id': 1, 'status': 'connu'},
        {'spell_id': 1, 'status': 'préparé'},
      ];
      expect(CharacterSpellRowMapper.parseStatuses(rows), {1: 'préparé'});
      expect(CharacterSpellRowMapper.parseStatuses(rows.reversed.toList()), {
        1: 'préparé',
      });
    });

    test("un sort inné d'un autre identifiant n'est pas affecté", () {
      final rows = [
        {'spell_id': 1, 'status': 'connu'},
        {'spell_id': 2, 'status': 'inné'},
      ];
      expect(CharacterSpellRowMapper.parseStatuses(rows), {
        1: 'connu',
        2: 'inné',
      });
    });
  });

  group('CharacterSpellRowMapper.toCharacterSpellEntries', () {
    test('résout le nom, le niveau, l\'école et le statut', () {
      final spellRows = [
        {'id': 1, 'level': 3, 'school': 'Évocation'},
      ];

      final result = CharacterSpellRowMapper.toCharacterSpellEntries(
        spellRows,
        names: const {'1': 'Boule de feu'},
        descriptions: const {},
        statuses: const {1: 'connu'},
        classes: const [],
      );

      expect(result, hasLength(1));
      expect(result.single.name, 'Boule de feu');
      expect(result.single.level, 3);
      expect(result.single.school, 'Évocation');
      expect(result.single.status, 'connu');
    });

    test('un id sans nom résolu retombe sur un libellé générique', () {
      final spellRows = [
        {'id': 42, 'level': 0, 'school': null},
      ];

      final result = CharacterSpellRowMapper.toCharacterSpellEntries(
        spellRows,
        names: const {},
        descriptions: const {},
        statuses: const {},
        classes: const [],
      );

      expect(result.single.name, 'Sort #42');
      expect(result.single.school, '');
      // Aucun statut résolu : retombe sur 'connu'.
      expect(result.single.status, 'connu');
    });

    test('résout castingTime/range/components/duration/concentration/'
        'description', () {
      final spellRows = [
        {
          'id': 1,
          'level': 1,
          'school': 'Abjuration',
          'casting_time': '1 action',
          'range': '9 mètres',
          'components': {'verbal': true, 'somatic': true, 'material': false},
          'duration': '1 minute',
          'concentration': true,
        },
      ];

      final result = CharacterSpellRowMapper.toCharacterSpellEntries(
        spellRows,
        names: const {'1': 'Bouclier'},
        descriptions: const {'1': 'Une description complète.'},
        statuses: const {1: 'connu'},
        classes: const [],
      );

      expect(result.single.castingTime, '1 action');
      expect(result.single.range, '9 mètres');
      expect(result.single.components, {
        'verbal': true,
        'somatic': true,
        'material': false,
      });
      expect(result.single.duration, '1 minute');
      expect(result.single.concentration, isTrue);
      expect(result.single.description, 'Une description complète.');
    });

    test(
      'champs techniques absents -> replis (chaînes vides, false, map vide)',
      () {
        final spellRows = [
          {'id': 1, 'level': 0, 'school': ''},
        ];

        final result = CharacterSpellRowMapper.toCharacterSpellEntries(
          spellRows,
          names: const {},
          descriptions: const {},
          statuses: const {},
          classes: const [],
        );

        expect(result.single.castingTime, '');
        expect(result.single.range, '');
        expect(result.single.components, isEmpty);
        expect(result.single.duration, '');
        expect(result.single.concentration, isFalse);
        expect(result.single.description, '');
      },
    );
  });

  test('un sort sans ligne character_spells (liste de classe jamais '
      'préparée) est "connu" et non persisté', () {
    final result = CharacterSpellRowMapper.toCharacterSpellEntries(
      const [
        {'id': 7, 'level': 2, 'school': 'Évocation'},
        {'id': 8, 'level': 1, 'school': 'Abjuration'},
      ],
      names: const {},
      descriptions: const {},
      statuses: const {8: 'préparé'},
      classes: const [],
    );

    final classListSpell = result.firstWhere((spell) => spell.id == 7);
    expect(classListSpell.status, 'connu');
    expect(classListSpell.isPersisted, isFalse);
    final chosenSpell = result.firstWhere((spell) => spell.id == 8);
    expect(chosenSpell.status, 'préparé');
    expect(chosenSpell.isPersisted, isTrue);
  });

  group('CharacterSpellRowMapper.parseSourceClassIds', () {
    test('regroupe les origines non nulles par sort, doublons compris', () {
      final rows = [
        {'spell_id': 1, 'status': 'connu', 'source_class_id': 10},
        {'spell_id': 2, 'status': 'connu', 'source_class_id': null},
        {'spell_id': 3, 'status': 'connu'},
        {'spell_id': 4, 'status': 'connu', 'source_class_id': 10},
        {'spell_id': 4, 'status': 'préparé', 'source_class_id': 11},
        {'spell_id': 4, 'status': 'préparé', 'source_class_id': null},
      ];
      expect(CharacterSpellRowMapper.parseSourceClassIds(rows), {
        1: {10},
        4: {10, 11},
      });
    });
  });

  group('toCharacterSpellEntries : requiresPreparation', () {
    CharacterDetailClassRow cls(int id, String name) => CharacterDetailClassRow(
      classId: id,
      className: name,
      level: 3,
      isPrimary: id == 1,
      savingThrowProficiencies: const [],
      hitDie: 8,
    );
    const spellRows = [
      {'id': 1, 'level': 1, 'school': ''},
      {'id': 2, 'level': 1, 'school': ''},
      {'id': 3, 'level': 1, 'school': ''},
      {'id': 4, 'level': 0, 'school': ''},
      {'id': 5, 'level': 2, 'school': ''},
      {'id': 6, 'level': 1, 'school': ''},
      {'id': 7, 'level': 1, 'school': ''},
    ];
    const statuses = {
      1: 'connu',
      2: 'connu',
      3: 'connu',
      4: 'connu',
      5: 'inné',
      6: 'connu',
    };

    Map<int, CharacterSpellEntry> map(
      List<CharacterDetailClassRow> classes, {
      Map<int, Set<int>> sources = const {},
    }) => {
      for (final spell in CharacterSpellRowMapper.toCharacterSpellEntries(
        spellRows,
        names: const {},
        descriptions: const {},
        statuses: statuses,
        grants: const {6: SpellGrantSource.domain},
        classes: classes,
        sourceClassIds: sources,
      ))
        spell.id: spell,
    };

    test('Barde seul : aucun sort ne se prépare, avec ou sans origine', () {
      final spells = map(
        [cls(1, 'Barde')],
        sources: const {
          1: {1},
        },
      );
      expect(spells[1]!.requiresPreparation, isFalse);
      expect(spells[2]!.requiresPreparation, isFalse);
      expect(SpellStatusFormatter.canCast(spells[1]!), isTrue);
      expect(SpellStatusFormatter.canCast(spells[2]!), isTrue);
    });

    test('Clerc seul : tout se prépare (comportement inchangé)', () {
      final spells = map(
        [cls(2, 'Clerc')],
        sources: const {
          1: {2},
        },
      );
      expect(spells[1]!.requiresPreparation, isTrue);
      expect(spells[2]!.requiresPreparation, isTrue);
      // Sort de la liste de classe sans ligne persistée.
      expect(spells[7]!.requiresPreparation, isTrue);
      expect(spells[7]!.isPersisted, isFalse);
      expect(SpellStatusFormatter.canCast(spells[1]!), isFalse);
    });

    test('Barde + Clerc : tranché par source_class_id, origine inconnue à '
        'préparer', () {
      final spells = map(
        [cls(1, 'Barde'), cls(2, 'Clerc')],
        sources: const {
          1: {1},
          2: {2},
        },
      );
      expect(spells[1]!.requiresPreparation, isFalse);
      expect(spells[2]!.requiresPreparation, isTrue);
      expect(spells[3]!.requiresPreparation, isTrue);
      expect(spells[7]!.requiresPreparation, isTrue);
    });

    test('sort mineur, inné et accordé par une sous-classe : comportement '
        'inchangé quelle que soit la classe', () {
      for (final classes in [
        [cls(1, 'Barde')],
        [cls(2, 'Clerc')],
        [cls(1, 'Barde'), cls(2, 'Clerc')],
      ]) {
        final spells = map(classes);
        final cantrip = spells[4]!;
        expect(SpellStatusFormatter.canCast(cantrip), isTrue);
        expect(SpellStatusFormatter.canTogglePrepared(cantrip), isFalse);
        expect(SpellStatusFormatter.subtitle(cantrip), isNull);

        final innate = spells[5]!;
        expect(innate.status, 'inné');
        expect(SpellStatusFormatter.canCast(innate), isTrue);
        expect(SpellStatusFormatter.canTogglePrepared(innate), isFalse);
        expect(SpellStatusFormatter.subtitle(innate), isNull);

        final granted = spells[6]!;
        expect(granted.status, 'préparé');
        expect(granted.storedStatus, 'connu');
        expect(SpellStatusFormatter.canCast(granted), isTrue);
        expect(SpellStatusFormatter.canTogglePrepared(granted), isFalse);
        expect(
          SpellStatusFormatter.subtitle(granted),
          'toujours préparé · ${SpellGrantSource.domain.label}',
        );
      }
    });
  });

  group('CharacterSpellRowMapper.parseInnateUsesSpent', () {
    test(
      "construit {spell_id: innate_uses_spent} depuis les lignes 'inné'",
      () {
        final rows = [
          {'spell_id': 1, 'status': 'inné', 'innate_uses_spent': 1},
          {'spell_id': 2, 'status': 'inné', 'innate_uses_spent': 0},
        ];
        expect(CharacterSpellRowMapper.parseInnateUsesSpent(rows), {
          1: 1,
          2: 0,
        });
      },
    );

    test('clé absente (cache antérieur à la colonne) ou valeur inexploitable '
        ': rien, jamais de crash', () {
      final rows = [
        {'spell_id': 1, 'status': 'inné'},
        {'spell_id': 2, 'status': 'inné', 'innate_uses_spent': null},
        {'spell_id': 3, 'status': 'inné', 'innate_uses_spent': 'x'},
        {'spell_id': null, 'status': 'inné', 'innate_uses_spent': 1},
      ];
      expect(CharacterSpellRowMapper.parseInnateUsesSpent(rows), isEmpty);
    });

    test("ligne ordinaire ('connu'/'préparé') : ignorée, même avec une valeur "
        'renseignée', () {
      final rows = [
        {'spell_id': 1, 'status': 'connu', 'innate_uses_spent': 1},
        {'spell_id': 2, 'status': 'préparé', 'innate_uses_spent': 1},
      ];
      expect(CharacterSpellRowMapper.parseInnateUsesSpent(rows), isEmpty);
    });

    test("lignes en double 'inné' divergentes : la valeur la plus haute est "
        "retenue, quel que soit l'ordre des lignes", () {
      final rows = [
        {'spell_id': 1, 'status': 'inné', 'innate_uses_spent': 0},
        {'spell_id': 1, 'status': 'inné', 'innate_uses_spent': 1},
      ];
      expect(CharacterSpellRowMapper.parseInnateUsesSpent(rows), {1: 1});
      expect(
        CharacterSpellRowMapper.parseInnateUsesSpent(rows.reversed.toList()),
        {1: 1},
      );
    });

    test("lignes en double 'inné' dépensée + ordinaire à 0 : la ligne "
        "ordinaire ne masque pas l'usage dépensé, quel que soit l'ordre", () {
      final rows = [
        {'spell_id': 1, 'status': 'inné', 'innate_uses_spent': 1},
        {'spell_id': 1, 'status': 'connu', 'innate_uses_spent': 0},
      ];
      expect(CharacterSpellRowMapper.parseInnateUsesSpent(rows), {1: 1});
      expect(
        CharacterSpellRowMapper.parseInnateUsesSpent(rows.reversed.toList()),
        {1: 1},
      );
    });

    test('valeur négative (impossible en base) : ramenée à 0', () {
      final rows = [
        {'spell_id': 1, 'status': 'inné', 'innate_uses_spent': -2},
      ];
      expect(CharacterSpellRowMapper.parseInnateUsesSpent(rows), {1: 0});
    });

    test('toCharacterSpellEntries reporte le compteur, 0 par défaut', () {
      final result = CharacterSpellRowMapper.toCharacterSpellEntries(
        [
          {'id': 1, 'level': 2, 'school': ''},
          {'id': 2, 'level': 2, 'school': ''},
        ],
        names: const {},
        descriptions: const {},
        statuses: const {1: 'inné', 2: 'inné'},
        classes: const [],
        innateUsesSpent: const {1: 1},
      );
      expect(result[0].innateUsesSpent, 1);
      expect(result[1].innateUsesSpent, 0);
    });
  });
}
