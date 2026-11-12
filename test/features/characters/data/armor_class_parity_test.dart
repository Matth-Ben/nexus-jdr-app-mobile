// Parité de la Classe d'Armure (P18) : pour un même personnage, la fiche
// (`CharacterDetail.armorClass` + `armorClassBonus`), l'onglet « Membres »
// (`GroupMemberRowMapper`) et la liste (`CharacterRowMapper`) doivent
// afficher EXACTEMENT la même valeur — les trois passent par
// `ArmorClassResolver`, aucune copie de la logique.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/character_inventory_row_mapper.dart';
import 'package:personnages/features/characters/data/character_row_mapper.dart';
import 'package:personnages/features/characters/domain/character_class_choice.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/groups/data/group_member_row_mapper.dart';

typedef _Case = ({
  String label,
  Map<String, dynamic> character,
  Map<String, String> classNames,
  Map<String, String> subclassNames,
  Map<String, String> classFeatureNames,
});

Map<String, dynamic> _armor(
  String dexBonus,
  int base, {
  bool equipped = true,
}) => {
  'id': 'inv-armor',
  'item_id': 1,
  'quantity': 1,
  'equipped': equipped,
  'items': {
    'category': 'armure',
    'armor_properties': {'ac_base': base, 'ac_dex_bonus': dexBonus},
  },
};

Map<String, dynamic> _shield() => {
  'id': 'inv-shield',
  'item_id': 2,
  'quantity': 1,
  'equipped': true,
  'items': {
    'category': 'bouclier',
    'armor_properties': {'ac_base': 2, 'ac_dex_bonus': 'aucun'},
  },
};

List<Map<String, dynamic>> _scores({
  int dex = 14,
  int con = 12,
  int wis = 10,
}) => [
  {'ability_id': 'dex', 'score': dex},
  {'ability_id': 'con', 'score': con},
  {'ability_id': 'wis', 'score': wis},
];

final List<_Case> _cases = [
  (
    label: 'armure intermédiaire + Dex plafonnée + bonus manuel',
    character: {
      'armor_class_bonus': 1,
      'character_classes': [
        {'class_id': 1, 'level': 3, 'is_primary': true},
      ],
      'character_ability_scores': _scores(dex: 18),
      'character_inventory': [_armor('max_2', 12), _shield()],
    },
    classNames: {'1': 'Clerc'},
    subclassNames: <String, String>{},
    classFeatureNames: <String, String>{},
  ),
  (
    label: 'Barbare sans armure (10 + Dex + Con)',
    character: {
      'armor_class_bonus': 0,
      'character_classes': [
        {'class_id': 2, 'level': 4, 'is_primary': true},
      ],
      'character_ability_scores': _scores(dex: 14, con: 16),
    },
    classNames: {'2': 'Barbare'},
    subclassNames: <String, String>{},
    classFeatureNames: <String, String>{},
  ),
  (
    label: 'Ensorceleur Lignage draconique (13 + Dex)',
    character: {
      'armor_class_bonus': 0,
      'character_classes': [
        {'class_id': 3, 'subclass_id': 5, 'level': 3, 'is_primary': true},
      ],
      'character_ability_scores': _scores(dex: 14),
    },
    classNames: {'3': 'Ensorceleur'},
    subclassNames: {'5': 'Lignage draconique'},
    classFeatureNames: <String, String>{},
  ),
  (
    label: 'Guerrier, style Défense, armure lourde, malus -1',
    character: {
      'armor_class_bonus': -1,
      'character_classes': [
        {'class_id': 4, 'level': 2, 'is_primary': true},
      ],
      'character_ability_scores': _scores(dex: 8),
      'character_class_options': [
        {'class_feature_id': 100, 'chosen_value': 'Défense'},
      ],
      'character_inventory': [_armor('aucun', 16)],
    },
    classNames: {'4': 'Guerrier'},
    subclassNames: <String, String>{},
    classFeatureNames: {'100': 'Style de combat'},
  ),
  (
    label: '« Défense » d\'une autre aptitude : pas de bonus',
    character: {
      'armor_class_bonus': 0,
      'character_classes': [
        {'class_id': 4, 'level': 2, 'is_primary': true},
      ],
      'character_ability_scores': _scores(dex: 14),
      'character_class_options': [
        {'class_feature_id': 200, 'chosen_value': 'Défense'},
      ],
      'character_inventory': [_armor('max_2', 12)],
    },
    classNames: {'4': 'Guerrier'},
    subclassNames: <String, String>{},
    classFeatureNames: {'200': 'Métamagie'},
  ),
  (
    label: 'armure non équipée, sans classe',
    character: {
      'armor_class_bonus': 3,
      'character_classes': <Map<String, dynamic>>[],
      'character_ability_scores': _scores(dex: 12),
      'character_inventory': [_armor('aucun', 18, equipped: false)],
    },
    classNames: <String, String>{},
    subclassNames: <String, String>{},
    classFeatureNames: <String, String>{},
  ),
];

CharacterDetail _detailOf(_Case c) {
  final character = c.character;
  final classRows = (character['character_classes'] as List)
      .cast<Map<String, dynamic>>();
  return CharacterDetail(
    id: 'c',
    name: 'Parité',
    classes: [
      for (final row in classRows)
        CharacterDetailClassRow(
          classId: row['class_id'] as Object,
          className: c.classNames[row['class_id'].toString()]!,
          level: row['level'] as int,
          isPrimary: row['is_primary'] == true,
          savingThrowProficiencies: const [],
          hitDie: 8,
          subclassName: c.subclassNames[row['subclass_id']?.toString()],
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
      ((character['character_inventory'] as List?) ?? const [])
          .cast<Map<String, dynamic>>(),
      names: const {},
      descriptions: const {},
    ),
    classChoices: [
      for (final option
          in ((character['character_class_options'] as List?) ?? const [])
              .cast<Map<String, dynamic>>())
        if (c.classFeatureNames[option['class_feature_id'].toString()] != null)
          CharacterClassChoice(
            featureName:
                c.classFeatureNames[option['class_feature_id'].toString()]!,
            chosenValue: option['chosen_value'] as String,
          ),
    ],
    armorClassBonus: (character['armor_class_bonus'] as int?) ?? 0,
  );
}

void main() {
  for (final c in _cases) {
    test('fiche = groupe = liste : ${c.label}', () {
      final detail = _detailOf(c);
      final onSheet = detail.armorClass + detail.armorClassBonus;

      final member = GroupMemberRowMapper.toGroupMember(
        {
          'id': 'm',
          'character_id': 'c',
          'user_id': 'u',
          'role': 'owner',
          'is_game_master': false,
          'characters': {'name': 'Parité', ...c.character},
        },
        raceNames: const {},
        classNames: c.classNames,
        subclassNames: c.subclassNames,
        classFeatureNames: c.classFeatureNames,
      );

      final summary = CharacterRowMapper.toSummary(
        {'id': 'c', 'name': 'Parité', ...c.character},
        raceNames: const {},
        classNames: c.classNames,
        subclassNames: c.subclassNames,
        classFeatureNames: c.classFeatureNames,
      );

      expect(member.armorClass, onSheet, reason: 'groupe vs fiche');
      expect(summary.armorClass, onSheet, reason: 'liste vs fiche');
    });
  }

  test('valeurs attendues explicites (garde contre un résolveur faux '
      'identique partout)', () {
    int listAc(_Case c) => CharacterRowMapper.toSummary(
      {'id': 'c', 'name': 'x', ...c.character},
      raceNames: const {},
      classNames: c.classNames,
      subclassNames: c.subclassNames,
      classFeatureNames: c.classFeatureNames,
    ).armorClass!;
    // Clerc : 12 + 2 (Dex plafonnée) + 2 (bouclier) + 1 (bonus) = 17.
    expect(listAc(_cases[0]), 17);
    // Barbare : 10 + 2 (Dex 14) + 3 (Con 16) = 15.
    expect(listAc(_cases[1]), 15);
    // Lignage draconique : 13 + 2 = 15.
    expect(listAc(_cases[2]), 15);
    // Guerrier Défense : 16 (armure lourde, Dex ignorée) + 1 (Défense)
    // - 1 (malus) = 16.
    expect(listAc(_cases[3]), 16);
    // Défense d'une autre aptitude : 12 + 2 = 14.
    expect(listAc(_cases[4]), 14);
    // Non équipée : 10 + 1 (Dex 12) + 3 (bonus) = 14.
    expect(listAc(_cases[5]), 14);
  });
}
