// Tests unitaires du mapper JSON → `CharacterDetail` de la vue de partage
// en lecture seule (`mapSharedCharacterJson`) — voir sa documentation de
// classe pour les écarts assumés avec la fiche authentifiée (adventures
// toujours vide, skills reconstruites depuis les 18 compétences D&D 5e).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_sharing/domain/shared_character_mapper.dart';

void main() {
  group('mapSharedCharacterJson', () {
    test('mappe les champs de base du personnage', () {
      final detail = mapSharedCharacterJson({
        'character': {
          'id': 'char-1',
          'name': 'Halltesse Ambrelune',
          'race_name': 'Elfe',
          'subrace_name': 'Haut-elfe',
          'background_name': 'Sage',
          'alignment_name': 'Neutre bon',
          'xp': 7000,
          'current_hp': 18,
          'max_hp': 30,
          'temporary_hp': 2,
          'is_dead': false,
          'inspiration': true,
          'race_speed': 9,
        },
        'classes': [
          {
            'class_id': 3,
            'class_name': 'Magicienne',
            'level': 5,
            'is_primary': true,
            'saving_throw_proficiencies': ['int', 'wis'],
            'hit_die': 6,
            'hit_dice_spent': 1,
            'armor_proficiencies': <String>[],
            'weapon_proficiencies': ['dague', 'arbalète légère'],
          },
        ],
        'ability_scores': [
          {'ability_id': 'int', 'score': 18},
          {'ability_id': 'dex', 'score': 14},
        ],
      });

      expect(detail.id, 'char-1');
      expect(detail.name, 'Halltesse Ambrelune');
      expect(detail.raceName, 'Elfe');
      expect(detail.subraceName, 'Haut-elfe');
      expect(detail.backgroundName, 'Sage');
      expect(detail.alignmentName, 'Neutre bon');
      expect(detail.xp, 7000);
      expect(detail.currentHp, 18);
      expect(detail.maxHp, 30);
      expect(detail.temporaryHp, 2);
      expect(detail.isDead, false);
      expect(detail.inspiration, true);
      expect(detail.speed, 9);
      expect(detail.classes, hasLength(1));
      expect(detail.classes.single.className, 'Magicienne');
      expect(detail.classes.single.level, 5);
      expect(detail.weaponProficiencyNames, ['dague', 'arbalète légère']);
      expect(detail.abilityScores, {'int': 18, 'dex': 14});
    });

    test('reconstruit les 18 compétences avec la maîtrise réelle appliquée '
        'sur celles renvoyées par le RPC, "aucune" ailleurs', () {
      final detail = mapSharedCharacterJson({
        'character': {'id': 'char-1', 'name': 'Test'},
        'skill_proficiencies': [
          {'skill_name': 'Arcanes', 'proficiency': 'expertise'},
          {'skill_name': 'Perception', 'proficiency': 'maîtrisé'},
        ],
      });

      expect(detail.skills, hasLength(18));
      final arcanes = detail.skills.firstWhere((s) => s.name == 'Arcanes');
      expect(arcanes.proficiency, 'expertise');
      expect(arcanes.abilityId, 'int');
      final perception = detail.skills.firstWhere(
        (s) => s.name == 'Perception',
      );
      expect(perception.proficiency, 'maîtrisé');
      final athletisme = detail.skills.firstWhere(
        (s) => s.name == 'Athlétisme',
      );
      expect(athletisme.proficiency, 'aucune');
    });

    test('adventures reste toujours vide (jamais renvoyé par le RPC, voir '
        'sa doc de classe)', () {
      final detail = mapSharedCharacterJson({
        'character': {'id': 'char-1', 'name': 'Test'},
      });

      expect(detail.adventures, isEmpty);
    });

    test('fusionne les tokens de maîtrise d\'armure/armes de toutes les '
        'classes (multiclassage), dédupliqués', () {
      final detail = mapSharedCharacterJson({
        'character': {'id': 'char-1', 'name': 'Test'},
        'classes': [
          {
            'class_id': 1,
            'class_name': 'Guerrier',
            'level': 3,
            'is_primary': true,
            'armor_proficiencies': ['légère', 'moyenne', 'lourde'],
            'weapon_proficiencies': ['courant'],
          },
          {
            'class_id': 2,
            'class_name': 'Roublard',
            'level': 2,
            'is_primary': false,
            'armor_proficiencies': ['légère'],
            'weapon_proficiencies': ['courant', 'arbalète de poing'],
          },
        ],
      });

      expect(
        detail.armorProficiencyNames.toSet(),
        {'légère', 'moyenne', 'lourde'},
      );
      expect(
        detail.weaponProficiencyNames.toSet(),
        {'courant', 'arbalète de poing'},
      );
    });

    test('mappe les sorts avec leurs détails complets', () {
      final detail = mapSharedCharacterJson({
        'character': {'id': 'char-1', 'name': 'Test'},
        'spells': [
          {
            'spell_id': 42,
            'spell_name': 'Boule de feu',
            'level': 3,
            'school': 'évocation',
            'status': 'préparé',
            'casting_time': '1 action',
            'range': '45 mètres',
            'components': {'v': true, 's': true, 'm': false},
            'duration': 'instantanée',
            'concentration': false,
            'description': 'Une explosion de flammes.',
          },
        ],
      });

      expect(detail.spells, hasLength(1));
      final spell = detail.spells.single;
      expect(spell.id, 42);
      expect(spell.name, 'Boule de feu');
      expect(spell.level, 3);
      expect(spell.school, 'évocation');
      expect(spell.status, 'préparé');
      expect(spell.description, 'Une explosion de flammes.');
    });

    test('mappe l\'inventaire, y compris un objet du catalogue avec '
        'propriétés d\'arme', () {
      final detail = mapSharedCharacterJson({
        'character': {'id': 'char-1', 'name': 'Test'},
        'inventory': [
          {
            'id': 'inv-1',
            'item_id': 7,
            'item_name': 'Épée longue',
            'category': 'arme',
            'quantity': 1,
            'equipped': true,
            'weight': 1.5,
            'weapon_properties': {
              'damage_dice': '1d8',
              'damage_type': 'tranchant',
              'properties': ['versatile'],
              'range': null,
            },
          },
        ],
      });

      expect(detail.inventory, hasLength(1));
      final item = detail.inventory.single;
      expect(item.name, 'Épée longue');
      expect(item.equipped, true);
      expect(item.totalWeight, 1.5);
      expect(item.weaponProperties?.damageDice, '1d8');
      expect(item.weaponProperties?.properties, ['versatile']);
    });

    test('renvoie une fiche exploitable même avec un json quasi vide '
        '(character absent)', () {
      final detail = mapSharedCharacterJson(const {});

      expect(detail.id, '');
      expect(detail.name, '');
      expect(detail.classes, isEmpty);
      expect(detail.skills, hasLength(18));
      expect(detail.spells, isEmpty);
      expect(detail.inventory, isEmpty);
      expect(detail.inspiration, isFalse);
      expect(detail.speed, isNull);
    });
  });
}
