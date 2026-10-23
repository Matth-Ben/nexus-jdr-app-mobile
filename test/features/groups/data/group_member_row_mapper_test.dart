import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/groups/data/group_member_row_mapper.dart';
import 'package:personnages/features/groups/domain/group_role.dart';

Map<String, dynamic> _row({
  String? characterId = 'char-1',
  String userId = 'user-1',
  String? role = 'owner',
  bool isGameMaster = false,
  String? displayName,
  Map<String, dynamic>? character,
}) {
  return {
    'character_id': characterId,
    'user_id': userId,
    'role': role,
    'is_game_master': isGameMaster,
    'display_name': displayName,
    'characters': character,
  };
}

void main() {
  group('GroupMemberRowMapper.collectRaceIds / collectClassIds', () {
    test('collecte les identifiants uniques présents', () {
      final rows = [
        _row(
          character: {
            'race_id': 'race-1',
            'character_classes': [
              {'class_id': 'class-1', 'level': 3, 'is_primary': true},
            ],
          },
        ),
        _row(
          characterId: 'char-2',
          character: {
            'race_id': 'race-1',
            'character_classes': [
              {'class_id': 'class-2', 'level': 1, 'is_primary': true},
            ],
          },
        ),
      ];

      expect(GroupMemberRowMapper.collectRaceIds(rows), {'race-1'});
      expect(GroupMemberRowMapper.collectClassIds(rows), {
        'class-1',
        'class-2',
      });
    });

    test('ignore les personnages sans race_id/character_classes', () {
      final rows = [_row(character: {})];
      expect(GroupMemberRowMapper.collectRaceIds(rows), isEmpty);
      expect(GroupMemberRowMapper.collectClassIds(rows), isEmpty);
    });
  });

  group('GroupMemberRowMapper.toGroupMember', () {
    test('mappe une ligne complète, classe primaire résolue', () {
      final row = _row(
        role: 'owner',
        character: {
          'name': 'Sylvi',
          'portrait_url': 'https://example.com/p.png',
          'current_hp': 8,
          'max_hp': 20,
          'temporary_hp': 2,
          'is_dead': false,
          'race_id': 'race-1',
          'character_classes': [
            {'class_id': 'class-1', 'level': 2, 'is_primary': false},
            {'class_id': 'class-2', 'level': 3, 'is_primary': true},
          ],
        },
      );

      final member = GroupMemberRowMapper.toGroupMember(
        row,
        raceNames: const {'race-1': 'Elfe'},
        classNames: const {'class-1': 'Guerrier', 'class-2': 'Rôdeur'},
      );

      expect(member.characterId, 'char-1');
      expect(member.isGameMaster, isFalse);
      expect(member.isAwaitingCharacter, isFalse);
      expect(member.userId, 'user-1');
      expect(member.role, GroupRole.owner);
      expect(member.name, 'Sylvi');
      expect(member.portraitUrl, 'https://example.com/p.png');
      expect(member.raceName, 'Elfe');
      expect(member.className, 'Rôdeur');
      expect(member.level, 5);
      expect(member.currentHp, 8);
      expect(member.maxHp, 20);
      expect(member.temporaryHp, 2);
      expect(member.isDead, isFalse);
    });

    test('utilise la première classe si aucune n\'est marquée primaire', () {
      final row = _row(
        role: 'membre',
        character: {
          'name': 'Bob',
          'current_hp': 1,
          'max_hp': 1,
          'temporary_hp': 0,
          'race_id': 'race-1',
          'character_classes': [
            {'class_id': 'class-1', 'level': 1, 'is_primary': false},
          ],
        },
      );

      final member = GroupMemberRowMapper.toGroupMember(
        row,
        raceNames: const {'race-1': 'Humain'},
        classNames: const {'class-1': 'Barde'},
      );

      expect(member.className, 'Barde');
      expect(member.role, GroupRole.membre);
    });

    test('champs manquants -> défauts sûrs (jamais de null non attendu)', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(character: {}),
        raceNames: const {},
        classNames: const {},
      );

      expect(member.name, '');
      expect(member.portraitUrl, isNull);
      expect(member.raceName, isNull);
      expect(member.className, isNull);
      expect(member.level, 0);
      expect(member.currentHp, 0);
      expect(member.maxHp, 0);
      expect(member.temporaryHp, 0);
      expect(member.isDead, isFalse);
    });

    test('is_dead vrai correctement propagé', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(character: {'is_dead': true}),
        raceNames: const {},
        classNames: const {},
      );
      expect(member.isDead, isTrue);
    });
  });

  group('GroupMemberRowMapper.toGroupMember — MJ volontaire', () {
    test('character_id null + is_game_master true -> GroupMember.isGameMaster, '
        'champs personnage tous null', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(characterId: null, isGameMaster: true, character: null),
        raceNames: const {},
        classNames: const {},
      );

      expect(member.characterId, isNull);
      expect(member.isGameMaster, isTrue);
      expect(member.isAwaitingCharacter, isFalse);
      expect(member.userId, 'user-1');
      expect(member.portraitUrl, isNull);
      expect(member.raceName, isNull);
      expect(member.className, isNull);
      expect(member.level, isNull);
      expect(member.currentHp, isNull);
      expect(member.maxHp, isNull);
      expect(member.temporaryHp, isNull);
      expect(member.isDead, isNull);
    });

    test('nom résolu via group_members_display_name -> utilisé tel quel', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(
          characterId: null,
          isGameMaster: true,
          displayName: 'Brunhilde la MJ',
          character: null,
        ),
        raceNames: const {},
        classNames: const {},
      );

      expect(member.name, 'Brunhilde la MJ');
      expect(member.accountDisplayName, 'Brunhilde la MJ');
    });

    test('nom résolu vide/blanc -> repli "MJ"', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(
          characterId: null,
          isGameMaster: true,
          displayName: '   ',
          character: null,
        ),
        raceNames: const {},
        classNames: const {},
      );

      expect(member.name, 'MJ');
      expect(member.accountDisplayName, isNull);
    });

    test('nom absent -> repli "MJ"', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(characterId: null, isGameMaster: true, character: null),
        raceNames: const {},
        classNames: const {},
      );

      expect(member.name, 'MJ');
    });
  });

  group('GroupMemberRowMapper.toGroupMember — orphelin', () {
    test('character_id null + is_game_master false -> isAwaitingCharacter, '
        'jamais isGameMaster', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(characterId: null, character: null),
        raceNames: const {},
        classNames: const {},
      );

      expect(member.characterId, isNull);
      expect(member.isGameMaster, isFalse);
      expect(member.isAwaitingCharacter, isTrue);
    });

    test('nom résolu via group_members_display_name -> utilisé tel quel', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(
          characterId: null,
          displayName: 'Eldrin le rescapé',
          character: null,
        ),
        raceNames: const {},
        classNames: const {},
      );

      expect(member.name, 'Eldrin le rescapé');
    });

    test('nom absent -> repli "En attente d\'un personnage", JAMAIS "MJ"', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(characterId: null, character: null),
        raceNames: const {},
        classNames: const {},
      );

      expect(member.name, "En attente d'un personnage");
    });

    test('nom résolu vide/blanc -> même repli, jamais "MJ"', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(characterId: null, displayName: '   ', character: null),
        raceNames: const {},
        classNames: const {},
      );

      expect(member.name, "En attente d'un personnage");
    });
  });

  group('GroupMemberRowMapper.toGroupMember — armorClass/armorClassBonus', () {
    test('avec armure équipée, Dex plafonnée, aucun bonus manuel', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(
          character: {
            'name': 'Sylvi',
            'armor_class_bonus': 0,
            'character_ability_scores': [
              {'ability_id': 'dex', 'score': 18},
            ],
            'character_inventory': [
              {
                'id': 'inv-1',
                'item_id': 1,
                'quantity': 1,
                'equipped': true,
                'items': {
                  'category': 'armure',
                  'armor_properties': {'ac_base': 12, 'ac_dex_bonus': 'max_2'},
                },
              },
            ],
          },
        ),
        raceNames: const {},
        classNames: const {},
      );

      // 12 (base) + 2 (dex +4, plafonné à 2) + 0 (bonus manuel).
      expect(member.armorClass, 14);
      expect(member.armorClassBonus, 0);
    });

    test('sans armure équipée -> 10 + Dex (repli RAW de base)', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(
          character: {
            'name': 'Sylvi',
            'character_ability_scores': [
              {'ability_id': 'dex', 'score': 14},
            ],
          },
        ),
        raceNames: const {},
        classNames: const {},
      );

      expect(member.armorClass, 12);
      expect(member.armorClassBonus, 0);
    });

    test('armor_class_bonus manuel non nul -> additionné au total, exposé '
        'séparément pour le suffixe signé', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(
          character: {
            'name': 'Sylvi',
            'armor_class_bonus': 2,
            'character_ability_scores': [
              {'ability_id': 'dex', 'score': 10},
            ],
          },
        ),
        raceNames: const {},
        classNames: const {},
      );

      // 10 (base, Dex +0) + 2 (bonus manuel).
      expect(member.armorClass, 12);
      expect(member.armorClassBonus, 2);
    });

    test('armor_class_bonus manuel négatif -> soustrait au total', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(
          character: {
            'name': 'Sylvi',
            'armor_class_bonus': -1,
            'character_ability_scores': [
              {'ability_id': 'dex', 'score': 10},
            ],
          },
        ),
        raceNames: const {},
        classNames: const {},
      );

      expect(member.armorClass, 9);
      expect(member.armorClassBonus, -1);
    });

    test('style de combat Défense résolu via class_feature_id -> +1 avec '
        'armure équipée', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(
          character: {
            'name': 'Sylvi',
            'character_ability_scores': [
              {'ability_id': 'dex', 'score': 14},
            ],
            'character_class_options': [
              {'class_feature_id': 100, 'chosen_value': 'Défense'},
            ],
            'character_inventory': [
              {
                'id': 'inv-1',
                'item_id': 1,
                'quantity': 1,
                'equipped': true,
                'items': {
                  'category': 'armure',
                  'armor_properties': {'ac_base': 12, 'ac_dex_bonus': 'max_2'},
                },
              },
            ],
          },
        ),
        raceNames: const {},
        classNames: const {},
        classFeatureNames: const {'100': 'Style de combat'},
      );

      // 12 (base) + 2 (dex, plafonné) + 1 (Défense).
      expect(member.armorClass, 15);
    });

    test('régression : "Défense" venant d\'une aptitude autre que "Style de '
        'combat" n\'accorde PAS le bonus (même garde-fou que '
        'CharacterDetail.armorClass)', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(
          character: {
            'name': 'Sylvi',
            'character_ability_scores': [
              {'ability_id': 'dex', 'score': 14},
            ],
            'character_class_options': [
              {'class_feature_id': 200, 'chosen_value': 'Défense'},
            ],
            'character_inventory': [
              {
                'id': 'inv-1',
                'item_id': 1,
                'quantity': 1,
                'equipped': true,
                'items': {
                  'category': 'armure',
                  'armor_properties': {'ac_base': 12, 'ac_dex_bonus': 'max_2'},
                },
              },
            ],
          },
        ),
        raceNames: const {},
        classNames: const {},
        // `class_feature_id: 200` résout en "Métamagie", pas "Style de
        // combat" : pas de bonus de Défense.
        classFeatureNames: const {'200': 'Métamagie'},
      );

      // 12 (base) + 2 (dex, plafonné) — PAS +1 de Défense.
      expect(member.armorClass, 14);
    });

    test('Résilience draconique (sous-classe) résolue via subclassNames -> '
        '13 + Dex sans armure', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(
          character: {
            'name': 'Sylvi',
            'character_ability_scores': [
              {'ability_id': 'dex', 'score': 14},
            ],
            'character_classes': [
              {'class_id': 1, 'subclass_id': 5, 'level': 3, 'is_primary': true},
            ],
          },
        ),
        raceNames: const {},
        classNames: const {'1': 'Ensorceleur'},
        subclassNames: const {'5': 'Lignage draconique'},
      );

      // 13 (base Résilience draconique) + 2 (dex).
      expect(member.armorClass, 15);
    });

    test('MJ volontaire -> armorClass et armorClassBonus tous deux null', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(characterId: null, isGameMaster: true, character: null),
        raceNames: const {},
        classNames: const {},
      );

      expect(member.armorClass, isNull);
      expect(member.armorClassBonus, isNull);
    });

    test('orphelin -> armorClass et armorClassBonus tous deux null', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(characterId: null, character: null),
        raceNames: const {},
        classNames: const {},
      );

      expect(member.armorClass, isNull);
      expect(member.armorClassBonus, isNull);
    });
  });

  group('GroupMemberRowMapper.collectSubclassIds', () {
    test('collecte les subclass_id non nuls de tous les membres', () {
      final rows = [
        _row(
          character: {
            'character_classes': [
              {'class_id': 1, 'subclass_id': 5, 'level': 3},
            ],
          },
        ),
        _row(
          characterId: 'char-2',
          character: {
            'character_classes': [
              {'class_id': 2, 'level': 1},
            ],
          },
        ),
      ];

      expect(GroupMemberRowMapper.collectSubclassIds(rows), {'5'});
    });
  });

  group('GroupMemberRowMapper.collectClassFeatureIds', () {
    test('collecte les class_feature_id non nuls de character_class_options '
        'de tous les membres', () {
      final rows = [
        _row(
          character: {
            'character_class_options': [
              {'class_feature_id': 100, 'chosen_value': 'Défense'},
              {'class_feature_id': 200, 'chosen_value': 'feu'},
            ],
          },
        ),
      ];

      expect(GroupMemberRowMapper.collectClassFeatureIds(rows), {'100', '200'});
    });
  });
}
