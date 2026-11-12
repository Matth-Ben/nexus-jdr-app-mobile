// Tests de caractérisation (P7, PR 0) de `ArmorClassRowResolver` (lignes
// PostgREST brutes) : valeurs attendues EXPLICITES, croisées avec la fiche
// (`CharacterDetail.armorClass`) et le groupe/la liste pour les objets à
// `ac_bonus`. Complète `armor_class_parity_test.dart`.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/armor_class_row_resolver.dart';
import 'package:personnages/features/characters/data/character_row_mapper.dart';
import 'package:personnages/features/groups/data/group_member_row_mapper.dart';

Map<String, dynamic> _inv(
  String id,
  Map<String, dynamic> items, {
  bool equipped = true,
  bool attuned = false,
  int? itemId = 1,
}) => {
  'id': id,
  'item_id': itemId,
  'quantity': 1,
  'equipped': equipped,
  'is_attuned': attuned,
  'items': items,
};

Map<String, dynamic> _armorRow(
  String dexBonus,
  int base, {
  bool equipped = true,
}) => _inv('armor', {
  'category': 'armure',
  'armor_properties': {'ac_base': base, 'ac_dex_bonus': dexBonus},
}, equipped: equipped);

Map<String, dynamic> _shieldRow() => _inv('shield', {
  'category': 'bouclier',
  'armor_properties': {'ac_base': 2, 'ac_dex_bonus': 'aucun'},
}, itemId: 2);

Map<String, dynamic> _bonusRow(
  String id,
  int bonus,
  String kind, {
  bool requiresAttunement = false,
  bool attuned = false,
  bool equipped = true,
}) => _inv(
  id,
  {
    'category': 'objet_magique',
    'ac_bonus': bonus,
    'ac_bonus_kind': kind,
    'requires_attunement': requiresAttunement,
  },
  attuned: attuned,
  equipped: equipped,
  itemId: id.hashCode,
);

List<Map<String, dynamic>> _scores({
  int dex = 14,
  int con = 12,
  int wis = 10,
}) => [
  {'ability_id': 'dex', 'score': dex},
  {'ability_id': 'con', 'score': con},
  {'ability_id': 'wis', 'score': wis},
];

int _row(
  Map<String, dynamic> character, {
  Map<String, String> classNames = const {},
  Map<String, String> subclassNames = const {},
  Map<String, String> classFeatureNames = const {},
}) => ArmorClassRowResolver.fromCharacterRow(
  character,
  classNames: classNames,
  subclassNames: subclassNames,
  classFeatureNames: classFeatureNames,
);

void main() {
  group('bonusOf / hasData', () {
    test('armor_class_bonus : absent ou null -> 0, sinon la valeur', () {
      expect(ArmorClassRowResolver.bonusOf(const {}), 0);
      expect(ArmorClassRowResolver.bonusOf({'armor_class_bonus': null}), 0);
      expect(ArmorClassRowResolver.bonusOf({'armor_class_bonus': 3}), 3);
      expect(ArmorClassRowResolver.bonusOf({'armor_class_bonus': -2}), -2);
    });

    test('hasData : vrai seulement si character_ability_scores est une '
        'liste (même vide)', () {
      expect(ArmorClassRowResolver.hasData(const {}), isFalse);
      expect(
        ArmorClassRowResolver.hasData({'character_ability_scores': null}),
        isFalse,
      );
      expect(
        ArmorClassRowResolver.hasData({
          'character_ability_scores': const <Map<String, dynamic>>[],
        }),
        isTrue,
      );
    });
  });

  group('fromCharacterRow : valeurs explicites', () {
    test('ligne vide / scores absents : 10, pas de crash', () {
      expect(_row(const {}), 10);
      expect(_row({'character_ability_scores': const []}), 10);
    });

    test('scores sans valeur exploitable ignorés : Dex 10 par défaut', () {
      expect(
        _row({
          'character_ability_scores': [
            {'ability_id': 'dex', 'score': null},
            {'ability_id': null, 'score': 18},
          ],
        }),
        10,
      );
    });

    test('sans armure : 10 + Dex 14 = 12 ; + bonus manuel -2 = 10', () {
      expect(_row({'character_ability_scores': _scores()}), 12);
      expect(
        _row({'character_ability_scores': _scores(), 'armor_class_bonus': -2}),
        10,
      );
    });

    test('armure intermédiaire 14, Dex 20 : 14 + 2 (plafond) = 16', () {
      expect(
        _row({
          'character_ability_scores': _scores(dex: 20),
          'character_inventory': [_armorRow('max_2', 14)],
        }),
        16,
      );
    });

    test('armure non équipée : ignorée', () {
      expect(
        _row({
          'character_ability_scores': _scores(),
          'character_inventory': [_armorRow('aucun', 18, equipped: false)],
        }),
        12,
      );
    });

    test('noms de classe non résolus : aucune Défense sans armure', () {
      final character = {
        'character_ability_scores': _scores(con: 16),
        'character_classes': [
          {'class_id': 2, 'level': 1},
        ],
      };
      expect(_row(character), 12);
      expect(_row(character, classNames: {'2': 'Barbare'}), 15);
      expect(_row(character, classNames: {'2': 'Guerrier'}), 12);
    });

    test('Moine : 10 + Dex + Sag, perdu avec un bouclier', () {
      final base = {
        'character_ability_scores': _scores(wis: 16),
        'character_classes': [
          {'class_id': 5, 'level': 1},
        ],
      };
      expect(_row(base, classNames: {'5': 'Moine'}), 15);
      expect(
        _row(
          {
            ...base,
            'character_inventory': [_shieldRow()],
          },
          classNames: {'5': 'Moine'},
        ),
        14, // 10 + 2 + 2, sans la Sagesse
      );
    });

    test('Style de combat : seule la valeur de l\'aptitude « Style de '
        'combat » compte', () {
      final character = {
        'character_ability_scores': _scores(),
        'character_inventory': [_armorRow('max_2', 13)],
        'character_class_options': [
          {'class_feature_id': 7, 'chosen_value': 'Défense'},
          {'class_feature_id': null, 'chosen_value': 'Défense'},
        ],
      };
      expect(_row(character, classFeatureNames: {'7': 'Style de combat'}), 16);
      expect(_row(character, classFeatureNames: {'7': 'Métamagie'}), 15);
      expect(_row(character), 15);
    });
  });

  group('fromCharacterRow : objets à ac_bonus (lecture des colonnes '
      'items.ac_bonus*)', () {
    test('quatre variantes, Dex 14, sans armure', () {
      Map<String, dynamic> character(Map<String, dynamic> item) => {
        'character_ability_scores': _scores(),
        'character_inventory': [item],
      };
      expect(_row(character(_bonusRow('a', 1, 'toujours'))), 13);
      expect(_row(character(_bonusRow('b', 1, 'avec_armure'))), 12);
      expect(_row(character(_bonusRow('c', 2, 'sans_armure_ni_bouclier'))), 14);
      expect(_row(character(_bonusRow('d', 15, 'base_sans_armure'))), 17);
    });

    test('avec armure 13 (max_2) et bouclier, Dex 14', () {
      Map<String, dynamic> character(Map<String, dynamic> item) => {
        'character_ability_scores': _scores(),
        'character_inventory': [_armorRow('max_2', 13), _shieldRow(), item],
      };
      expect(_row(character(_bonusRow('a', 1, 'toujours'))), 18);
      expect(_row(character(_bonusRow('b', 1, 'avec_armure'))), 18);
      expect(_row(character(_bonusRow('c', 2, 'sans_armure_ni_bouclier'))), 17);
      expect(_row(character(_bonusRow('d', 15, 'base_sans_armure'))), 17);
    });

    test('harmonisation : non harmonisé -> suspendu (12), harmonisé -> '
        'actif (13) ; non équipé -> ignoré', () {
      Map<String, dynamic> character(Map<String, dynamic> item) => {
        'character_ability_scores': _scores(),
        'character_inventory': [item],
      };
      expect(
        _row(
          character(_bonusRow('a', 1, 'toujours', requiresAttunement: true)),
        ),
        12,
      );
      expect(
        _row(
          character(
            _bonusRow(
              'a',
              1,
              'toujours',
              requiresAttunement: true,
              attuned: true,
            ),
          ),
        ),
        13,
      );
      expect(
        _row(
          character(
            _bonusRow(
              'a',
              1,
              'toujours',
              requiresAttunement: true,
              attuned: true,
              equipped: false,
            ),
          ),
        ),
        12,
      );
    });

    test(
      'objet personnalisé (item_id nul, aucune ligne items) : sans effet',
      () {
        expect(
          _row({
            'character_ability_scores': _scores(),
            'character_inventory': [
              {
                'id': 'perso',
                'item_id': null,
                'custom_name': 'Anneau maison',
                'quantity': 1,
                'equipped': true,
                'is_attuned': true,
              },
            ],
          }),
          12,
        );
      },
    );
  });

  group('parité liste / groupe avec les objets à bonus (valeurs '
      'explicites)', () {
    test('armure magique + anneau harmonisé + bonus manuel : 13 + 2 + 2 + 1 '
        '+ 1 = 19 partout', () {
      final character = {
        'armor_class_bonus': 1,
        'character_classes': const <Map<String, dynamic>>[],
        'character_ability_scores': _scores(),
        'character_inventory': [
          _armorRow('max_2', 13),
          _shieldRow(),
          _bonusRow(
            'anneau',
            1,
            'toujours',
            requiresAttunement: true,
            attuned: true,
          ),
          _bonusRow('cape', 1, 'toujours', requiresAttunement: true),
        ],
      };
      expect(_row(character), 19);

      final summary = CharacterRowMapper.toSummary(
        {'id': 'c', 'name': 'x', ...character},
        raceNames: const {},
        classNames: const {},
        subclassNames: const {},
        classFeatureNames: const {},
      );
      expect(summary.armorClass, 19);

      final member = GroupMemberRowMapper.toGroupMember(
        {
          'id': 'm',
          'character_id': 'c',
          'user_id': 'u',
          'role': 'owner',
          'is_game_master': false,
          'characters': {'name': 'x', ...character},
        },
        raceNames: const {},
        classNames: const {},
        subclassNames: const {},
        classFeatureNames: const {},
      );
      expect(member.armorClass, 19);
    });
  });
}
