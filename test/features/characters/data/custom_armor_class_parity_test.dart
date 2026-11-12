// Parité de la CA avec une armure/un bouclier PERSONNALISÉ (P7, PR 3) : pour la
// même ligne `character_inventory` brute, la fiche (`CharacterDetail`), le
// groupe (`GroupMemberRowMapper`), la liste (`CharacterRowMapper`) et la fiche
// partagée donnent la MÊME CA, avec des valeurs attendues explicites.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/armor_class_row_resolver.dart';
import 'package:personnages/features/characters/data/character_inventory_row_mapper.dart';
import 'package:personnages/features/characters/data/character_row_mapper.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/groups/data/group_member_row_mapper.dart';

Map<String, dynamic> _customRow(
  String id, {
  required String kind,
  int? acBase,
  String? category,
  int? magic,
  bool equipped = true,
  bool requiresAttunement = false,
  bool attuned = false,
}) => {
  'id': id,
  'item_id': null,
  'custom_name': id,
  'quantity': 1,
  'equipped': equipped,
  'is_attuned': attuned,
  'custom_kind': kind,
  'custom_ac_base': acBase,
  'custom_armor_category': category,
  'custom_magic_bonus': magic,
  'custom_requires_attunement': requiresAttunement,
};

Map<String, dynamic> _catalogShield() => {
  'id': 'cat-shield',
  'item_id': 2,
  'quantity': 1,
  'equipped': true,
  'items': {
    'category': 'bouclier',
    'armor_properties': {'ac_base': 2, 'ac_dex_bonus': 'aucun'},
  },
};

List<Map<String, dynamic>> _scores({int dex = 16}) => [
  {'ability_id': 'dex', 'score': dex},
  {'ability_id': 'con', 'score': 12},
  {'ability_id': 'wis', 'score': 10},
];

Map<String, dynamic> _character(
  List<Map<String, dynamic>> inventory, {
  int dex = 16,
  int bonus = 0,
}) => {
  'armor_class_bonus': bonus,
  'character_classes': [
    {'class_id': 1, 'level': 3, 'is_primary': true},
  ],
  'character_ability_scores': _scores(dex: dex),
  'character_inventory': inventory,
};

const _classNames = {'1': 'Guerrier'};

CharacterDetail _detail(Map<String, dynamic> character) => CharacterDetail(
  id: 'c',
  name: 'Parité',
  classes: const [
    CharacterDetailClassRow(
      classId: 1,
      className: 'Guerrier',
      level: 3,
      isPrimary: true,
      savingThrowProficiencies: [],
      hitDie: 10,
    ),
  ],
  xp: 0,
  currentHp: 1,
  maxHp: 1,
  temporaryHp: 0,
  abilityScores: {
    for (final row
        in (character['character_ability_scores'] as List)
            .cast<Map<String, dynamic>>())
      row['ability_id'] as String: row['score'] as int,
  },
  inventory: CharacterInventoryRowMapper.toCharacterInventoryItems(
    (character['character_inventory'] as List).cast<Map<String, dynamic>>(),
    names: const {},
    descriptions: const {},
  ),
  armorClassBonus: (character['armor_class_bonus'] as int?) ?? 0,
);

/// (fiche, groupe, liste, résolveur de lignes).
({int sheet, int group, int list, int rows}) _acs(
  Map<String, dynamic> character,
) {
  final detail = _detail(character);
  final member = GroupMemberRowMapper.toGroupMember(
    {
      'id': 'm',
      'character_id': 'c',
      'user_id': 'u',
      'role': 'owner',
      'is_game_master': false,
      'characters': {'name': 'Parité', ...character},
    },
    raceNames: const {},
    classNames: _classNames,
    subclassNames: const {},
    classFeatureNames: const {},
  );
  final summary = CharacterRowMapper.toSummary(
    {'id': 'c', 'name': 'Parité', ...character},
    raceNames: const {},
    classNames: _classNames,
    subclassNames: const {},
    classFeatureNames: const {},
  );
  return (
    sheet: detail.armorClass + detail.armorClassBonus,
    group: member.armorClass!,
    list: summary.armorClass!,
    rows: ArmorClassRowResolver.fromCharacterRow(
      character,
      classNames: _classNames,
      subclassNames: const {},
      classFeatureNames: const {},
    ),
  );
}

void _expectAll(Map<String, dynamic> character, int expected, String reason) {
  final acs = _acs(character);
  expect(acs.sheet, expected, reason: 'fiche : $reason');
  expect(acs.group, expected, reason: 'groupe : $reason');
  expect(acs.list, expected, reason: 'liste : $reason');
  expect(acs.rows, expected, reason: 'lignes : $reason');
}

void main() {
  group('même CA sur la fiche, le groupe et la liste (Dex 16 = +3)', () {
    test('armure légère 11 : 14', () {
      _expectAll(
        _character([
          _customRow('a', kind: 'armure', acBase: 11, category: 'legere'),
        ]),
        14,
        'légère',
      );
    });

    test('armure intermédiaire 14 : 16 (Dex plafonnée)', () {
      _expectAll(
        _character([
          _customRow(
            'a',
            kind: 'armure',
            acBase: 14,
            category: 'intermediaire',
          ),
        ]),
        16,
        'intermédiaire',
      );
    });

    test('armure lourde 16 : 16 (Dex ignorée)', () {
      _expectAll(
        _character([
          _customRow('a', kind: 'armure', acBase: 16, category: 'lourde'),
        ]),
        16,
        'lourde',
      );
    });

    test('armure lourde 16 +2 magique : 18', () {
      _expectAll(
        _character([
          _customRow(
            'a',
            kind: 'armure',
            acBase: 16,
            category: 'lourde',
            magic: 2,
          ),
        ]),
        18,
        'magique',
      );
    });

    test('armure légère 11 +2 à harmonisation non faite : bonus suspendu '
        '(14), faite (16)', () {
      _expectAll(
        _character([
          _customRow(
            'a',
            kind: 'armure',
            acBase: 11,
            category: 'legere',
            magic: 2,
            requiresAttunement: true,
          ),
        ]),
        14,
        'suspendu',
      );
      _expectAll(
        _character([
          _customRow(
            'a',
            kind: 'armure',
            acBase: 11,
            category: 'legere',
            magic: 2,
            requiresAttunement: true,
            attuned: true,
          ),
        ]),
        16,
        'harmonisé',
      );
    });

    test('bouclier +2 seul : 15 ; +2 magique +1 : 16', () {
      _expectAll(
        _character([_customRow('s', kind: 'bouclier', acBase: 2)]),
        15,
        'bouclier',
      );
      _expectAll(
        _character([_customRow('s', kind: 'bouclier', acBase: 2, magic: 1)]),
        16,
        'bouclier magique',
      );
    });

    test('armure personnalisée + bouclier du catalogue : 11 + 3 + 2 = 16', () {
      _expectAll(
        _character([
          _customRow('a', kind: 'armure', acBase: 11, category: 'legere'),
          _catalogShield(),
        ]),
        16,
        'mixte',
      );
    });

    test('deux armures équipées : la première (14, pas 18)', () {
      _expectAll(
        _character([
          _customRow('a', kind: 'armure', acBase: 11, category: 'legere'),
          _customRow('b', kind: 'armure', acBase: 18, category: 'lourde'),
        ]),
        14,
        'deux armures',
      );
    });

    test('Dex négative (6 = -2) : légère 11 = 9 ; bonus manuel +1 = 10', () {
      _expectAll(
        _character([
          _customRow('a', kind: 'armure', acBase: 11, category: 'legere'),
        ], dex: 6),
        9,
        'Dex négative',
      );
      _expectAll(
        _character(
          [_customRow('a', kind: 'armure', acBase: 11, category: 'legere')],
          dex: 6,
          bonus: 1,
        ),
        10,
        'Dex négative + bonus manuel',
      );
    });

    test('armure non équipée, ancienne ligne sans custom_kind, arme '
        'magique : CA inchangée (13)', () {
      _expectAll(
        _character([
          _customRow(
            'a',
            kind: 'armure',
            acBase: 18,
            category: 'lourde',
            equipped: false,
          ),
          {
            'id': 'old',
            'item_id': null,
            'custom_name': 'Vieil objet',
            'quantity': 1,
            'equipped': true,
          },
          _customRow('w', kind: 'arme', magic: 3),
        ]),
        13,
        'sans effet',
      );
    });

    test('armure sans catégorie (donnée incomplète) : hors calcul (13)', () {
      _expectAll(
        _character([_customRow('a', kind: 'armure', acBase: 18, magic: 3)]),
        13,
        'incomplète',
      );
    });
  });
}
