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

    test('classFeatures : tri alphabétique (demande utilisateur, 2026-10-03), '
        'pas par niveau d\'acquisition — cohérent avec la fiche du '
        'propriétaire', () {
      final detail = mapSharedCharacterJson({
        'character': {'id': 'char-1', 'name': 'Test'},
        'class_features': [
          {'id': 50, 'name': 'Deuxième souffle', 'level': 3},
          // Niveau 5 (postérieure), mais son nom la place AVANT
          // alphabétiquement — prouve que l'ordre final est par nom.
          {'id': 51, 'name': 'Action surhumaine', 'level': 5},
        ],
      });

      expect(detail.classFeatures.map((f) => f.name), [
        'Action surhumaine',
        'Deuxième souffle',
      ]);
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

      expect(detail.armorProficiencyNames.toSet(), {
        'légère',
        'moyenne',
        'lourde',
      });
      expect(detail.weaponProficiencyNames.toSet(), {
        'courant',
        'arbalète de poing',
      });
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
            'requires_attunement': true,
            'is_attuned': true,
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
      expect(item.requiresAttunement, isTrue);
      expect(item.isAttuned, isTrue);
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
      expect(detail.galleryPhotos, isEmpty);
      expect(detail.journalEntries, isEmpty);
    });

    test('mappe la galerie de photos et le journal de campagne, triés du '
        'plus récent au plus ancien', () {
      final detail = mapSharedCharacterJson({
        'character': {'id': 'char-1', 'name': 'Test'},
        'photos': [
          {
            'id': 'photo-1',
            'url': 'https://example.com/1.png',
            'created_at': '2026-09-01T10:00:00Z',
          },
          {
            'id': 'photo-2',
            'url': 'https://example.com/2.png',
            'created_at': '2026-09-05T10:00:00Z',
          },
        ],
        'journal_entries': [
          {
            'id': 'entry-1',
            'body': 'Première note.',
            'created_at': '2026-09-01T10:00:00Z',
          },
          {
            'id': 'entry-2',
            'body': 'Seconde note.',
            'created_at': '2026-09-05T10:00:00Z',
          },
        ],
      });

      expect(detail.galleryPhotos, hasLength(2));
      expect(detail.galleryPhotos[0].id, 'photo-2');
      expect(detail.galleryPhotos[1].id, 'photo-1');
      expect(detail.journalEntries, hasLength(2));
      expect(detail.journalEntries[0].id, 'entry-2');
      expect(detail.journalEntries[1].id, 'entry-1');
    });
    group('sorts accordés par une sous-classe', () {
      Map<String, dynamic> spellRow(int id, String name) => {
        'spell_id': id,
        'spell_name': name,
        'level': 1,
        'school': 'Invocation',
        'status': 'connu',
      };

      test('ajoute un sort accordé absent de character_spells', () {
        final detail = mapSharedCharacterJson({
          'character': {'id': 'char-1', 'name': 'Test'},
          'classes': [
            {'class_id': 3, 'class_name': 'Clerc', 'level': 1},
          ],
          'spells': <Map<String, dynamic>>[],
          'subclass_spells': [
            {...spellRow(7, 'Bénédiction'), 'class_id': 3},
          ],
        });

        final spell = detail.spells.single;
        expect(spell.name, 'Bénédiction');
        expect(spell.status, 'préparé');
        expect(spell.grantSource?.label, 'Domaine');
        expect(spell.isPersisted, isFalse);
      });

      test('un sort choisi ET accordé apparaît une seule fois, accordé', () {
        final detail = mapSharedCharacterJson({
          'character': {'id': 'char-1', 'name': 'Test'},
          'classes': [
            {'class_id': 7, 'class_name': 'Paladin', 'level': 3},
          ],
          'spells': [spellRow(9, 'Sanctuaire')],
          'subclass_spells': [
            {...spellRow(9, 'Sanctuaire'), 'class_id': 7},
          ],
        });

        final spell = detail.spells.single;
        expect(spell.status, 'préparé');
        expect(spell.grantSource?.label, 'Serment');
        expect(spell.isPersisted, isTrue);
      });

      test('sans subclass_spells (ancien RPC), rien ne change', () {
        final detail = mapSharedCharacterJson({
          'character': {'id': 'char-1', 'name': 'Test'},
          'spells': [spellRow(9, 'Sanctuaire')],
        });

        expect(detail.spells.single.grantSource, isNull);
        expect(detail.spells.single.status, 'connu');
      });
    });
  });

  // Même règle que la fiche du propriétaire : un sort d'une classe à sorts
  // connus ne se prépare pas. `source_class_id` n'est exploité que s'il est
  // renvoyé par le RPC `get_shared_character` (non vérifiable d'ici).
  group('mapSharedCharacterJson : requiresPreparation', () {
    Map<String, dynamic> cls(int id, String name) => {
      'class_id': id,
      'class_name': name,
      'level': 3,
      'is_primary': id == 1,
    };
    Map<String, dynamic> spell(
      int id, {
      String status = 'connu',
      int level = 1,
      int? source,
      bool withSource = true,
    }) => {
      'spell_id': id,
      'spell_name': 'S$id',
      'level': level,
      'status': status,
      if (withSource) 'source_class_id': source,
    };
    Map<int, bool> requires(Map<String, dynamic> json) => {
      for (final entry in mapSharedCharacterJson(json).spells)
        entry.id: entry.requiresPreparation,
    };

    test('Barde seul, RPC sans source_class_id : aucun sort à préparer', () {
      expect(
        requires({
          'classes': [cls(1, 'Barde')],
          'spells': [spell(1, withSource: false), spell(2, withSource: false)],
        }),
        {1: false, 2: false},
      );
    });

    test('Clerc seul, RPC sans source_class_id : tout reste à préparer', () {
      expect(
        requires({
          'classes': [cls(2, 'Clerc')],
          'spells': [spell(1, withSource: false)],
        }),
        {1: true},
      );
    });

    test('Barde + Clerc, RPC sans source_class_id : repli sur les classes du '
        'personnage, tout reste à préparer', () {
      expect(
        requires({
          'classes': [cls(1, 'Barde'), cls(2, 'Clerc')],
          'spells': [spell(1, withSource: false), spell(2, withSource: false)],
        }),
        {1: true, 2: true},
      );
    });

    test('JSON sans classes, ou classe au nom absent (repli "Classe") : à '
        'préparer, comme avant le correctif', () {
      expect(
        requires({
          'spells': [spell(1, withSource: false)],
        }),
        {1: true},
      );
      expect(
        requires({
          'classes': [
            {'class_id': 1, 'level': 3, 'is_primary': true},
          ],
          'spells': [spell(1, source: 1)],
        }),
        {1: true},
      );
    });

    test('Barde + Clerc, source_class_id renvoyé : tranché par l\'origine', () {
      final detail = mapSharedCharacterJson({
        'classes': [cls(1, 'Barde'), cls(2, 'Clerc')],
        'spells': [
          spell(1, source: 1),
          spell(2, source: 2),
          spell(3),
          spell(4, status: 'préparé', source: 1),
          spell(5, status: 'préparé', source: 2),
        ],
      });
      expect(
        {for (final s in detail.spells) s.id: s.requiresPreparation},
        {1: false, 2: true, 3: true, 4: false, 5: true},
      );
      // Seul le sort de Clerc préparé compte.
      expect(detail.preparedSpellCount, 1);
    });
  });
}
