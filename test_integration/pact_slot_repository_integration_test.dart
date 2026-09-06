import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/rest_type.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/test_environment.dart';

/// Tests d'intégration de la magie de pacte de l'Occultiste
/// (`character_pact_slots`, table séparée de `character_spell_slots` — voir
/// `domain/spell_slot_progression.dart`) : montée de niveau
/// (`applyLevelUp`/`_upsertPactSlot`), repos court ET long
/// (`applyRest`/`_resetPactSlot`) et lancer de sort
/// (`castSpell(isPactSlot: true)`) — voir
/// `level_up_repository_integration_test.dart`/
/// `rest_repository_integration_test.dart` pour le rationale général de ce
/// dossier et l'équivalent pour `character_spell_slots`.
void main() {
  group('SupabaseCharacterRepository — magie de pacte (intégration)', () {
    late SupabaseClient client;
    late String ownerId;
    late AppDatabase cacheDb;
    late ReferenceDataCache cache;
    late PendingCharacterWriteQueue pendingWrites;

    setUpAll(() async {
      client = createTestSupabaseClient();
      await signUpTestUser(client);
      ownerId = client.auth.currentUser!.id;
      cacheDb = AppDatabase(NativeDatabase.memory());
      cache = ReferenceDataCache(cacheDb);
      pendingWrites = PendingCharacterWriteQueue(cacheDb);
    });

    tearDownAll(() async {
      await cacheDb.close();
    });

    /// `classes.id` dont le nom traduit `fr` vaut exactement [name] — même
    /// helper que les autres fichiers d'intégration de ce dossier.
    /// `translations.entity_id` est `text` (clé générique partagée par
    /// toutes les entités traduites), mais `classes.id`/
    /// `character_classes.class_id` sont des `integer` côté schéma réel —
    /// `applyLevelUp`/`_classIdAsInt` s'attendent à un `num`, jamais un
    /// `String` (même piège déjà documenté dans
    /// `level_up_repository_integration_test.dart::classIdByName`) : parsé
    /// en `int` ici plutôt que de propager la chaîne brute.
    Future<int> classIdByName(String name) async {
      final translation = await client
          .from('translations')
          .select('entity_id')
          .eq('entity_type', 'class')
          .eq('field_name', 'name')
          .eq('locale', 'fr')
          .eq('value', name)
          .maybeSingle();
      expect(
        translation,
        isNotNull,
        reason:
            'Aucune classe "$name" trouvée côté seed — vérifier '
            'supabase db reset côté dépôt web (ce nom est attendu tel '
            'quel par domain/spell_slot_progression.dart).',
      );
      return int.parse(translation!['entity_id'] as String);
    }

    late Object occultisteId;
    late Object clercId;

    setUpAll(() async {
      occultisteId = await classIdByName('Occultiste');
      clercId = await classIdByName('Clerc');
    });

    group('applyLevelUp', () {
      test('dip Occultiste (multiclassage niveau 1) écrit character_pact_slots '
          '(slot_level: 1, slots_total: 1, slots_used: 0)', () async {
        final guerrierId = await classIdByName('Guerrier');
        final character = await client
            .from('characters')
            .insert({
              'owner_id': ownerId,
              'name': 'Test Intégration Pacte Dip',
              'max_hp': 10,
              'current_hp': 10,
            })
            .select('id')
            .single();
        final characterId = character['id'] as String;
        addTearDown(() async {
          await client.from('characters').delete().eq('id', characterId);
        });

        await client.from('character_classes').insert({
          'character_id': characterId,
          'class_id': guerrierId,
          'level': 2,
          'is_primary': true,
        });
        await client.from('character_ability_scores').insert([
          // 'str' >= 13 : prérequis Guerrier (classe déjà possédée),
          // revérifié par `applyLevelUp` même pour une classe non ciblée
          // par ce multiclassage (défense en profondeur, voir
          // `MulticlassPrerequisites`).
          {'character_id': characterId, 'ability_id': 'str', 'score': 15},
          {'character_id': characterId, 'ability_id': 'cha', 'score': 14},
        ]);

        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        await repository.applyLevelUp(
          characterId: characterId,
          classId: occultisteId,
          className: 'Occultiste',
          isMulticlassing: true,
          hpRolled: 4,
          hpMethod: 'lance',
          hpGain: 4,
        );

        final pactRow = await client
            .from('character_pact_slots')
            .select('slot_level, slots_total, slots_used')
            .eq('character_id', characterId)
            .single();
        expect(pactRow['slot_level'], 1);
        expect(pactRow['slots_total'], 1);
        expect(pactRow['slots_used'], 0);

        // Aucun effet sur character_spell_slots : la magie de pacte reste
        // toujours séparée (voir SpellSlotProgression.pactMagicFor).
        final slotRows = await client
            .from('character_spell_slots')
            .select('slot_level')
            .eq('character_id', characterId);
        expect(slotRows, isEmpty);
      });

      test(
        'progression Occultiste (niveau 1 -> 2) recalcule '
        'character_pact_slots et préserve slots_used déjà consommé',
        () async {
          final character = await client
              .from('characters')
              .insert({
                'owner_id': ownerId,
                'name': 'Test Intégration Pacte Progression',
                'max_hp': 10,
                'current_hp': 10,
              })
              .select('id')
              .single();
          final characterId = character['id'] as String;
          addTearDown(() async {
            await client.from('characters').delete().eq('id', characterId);
          });

          await client.from('character_classes').insert({
            'character_id': characterId,
            'class_id': occultisteId,
            'level': 1,
            'is_primary': true,
          });
          // Niveau 1 : 1 charge — simule la charge déjà consommée.
          await client.from('character_pact_slots').insert({
            'character_id': characterId,
            'slot_level': 1,
            'slots_total': 1,
            'slots_used': 1,
          });

          final repository = SupabaseCharacterRepository(
            client,
            cache,
            pendingWrites,
            const AlwaysOnlineConnectivityChecker(),
          );
          await repository.applyLevelUp(
            characterId: characterId,
            classId: occultisteId,
            className: 'Occultiste',
            isMulticlassing: false,
            hpRolled: 4,
            hpMethod: 'lance',
            hpGain: 4,
          );

          // Niveau 2 : 2 charges, niveau 1 — slots_used préservé (clampé à
          // min(1, 2) = 1).
          final pactRow = await client
              .from('character_pact_slots')
              .select('slot_level, slots_total, slots_used')
              .eq('character_id', characterId)
              .single();
          expect(pactRow['slot_level'], 1);
          expect(pactRow['slots_total'], 2);
          expect(pactRow['slots_used'], 1);
        },
      );

      test('monter de niveau dans une classe autre que Occultiste ne touche '
          'jamais character_pact_slots', () async {
        final character = await client
            .from('characters')
            .insert({
              'owner_id': ownerId,
              'name': 'Test Intégration Pacte Autre Classe',
              'max_hp': 10,
              'current_hp': 10,
            })
            .select('id')
            .single();
        final characterId = character['id'] as String;
        addTearDown(() async {
          await client.from('characters').delete().eq('id', characterId);
        });

        await client.from('character_classes').insert({
          'character_id': characterId,
          'class_id': clercId,
          'level': 1,
          'is_primary': true,
        });

        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        await repository.applyLevelUp(
          characterId: characterId,
          classId: clercId,
          className: 'Clerc',
          isMulticlassing: false,
          hpRolled: 4,
          hpMethod: 'lance',
          hpGain: 4,
        );

        final pactRows = await client
            .from('character_pact_slots')
            .select('character_id')
            .eq('character_id', characterId);
        expect(pactRows, isEmpty);
      });
    });

    group('applyRest', () {
      test(
        'repos COURT recharge character_pact_slots (slots_used remis à 0) '
        'SANS toucher character_spell_slots (classe Occultiste primaire)',
        () async {
          final character = await client
              .from('characters')
              .insert({
                'owner_id': ownerId,
                'name': 'Test Intégration Pacte Repos Court',
                'max_hp': 10,
                'current_hp': 10,
              })
              .select('id')
              .single();
          final characterId = character['id'] as String;
          addTearDown(() async {
            await client.from('characters').delete().eq('id', characterId);
          });

          await client.from('character_classes').insert({
            'character_id': characterId,
            'class_id': occultisteId,
            'level': 3,
            'is_primary': true,
          });
          await client.from('character_pact_slots').insert({
            'character_id': characterId,
            'slot_level': 2,
            'slots_total': 2,
            'slots_used': 2,
          });
          await client.from('character_spell_slots').insert({
            'character_id': characterId,
            'slot_level': 1,
            'slots_total': 4,
            'slots_used': 3,
          });

          final repository = SupabaseCharacterRepository(
            client,
            cache,
            pendingWrites,
            const AlwaysOnlineConnectivityChecker(),
          );
          await repository.applyRest(
            characterId: characterId,
            type: RestType.short,
            className: 'Occultiste',
          );

          final pactRow = await client
              .from('character_pact_slots')
              .select('slot_level, slots_total, slots_used')
              .eq('character_id', characterId)
              .single();
          expect(pactRow['slot_level'], 2);
          expect(pactRow['slots_total'], 2);
          expect(pactRow['slots_used'], 0);

          // Emplacements classiques inchangés : un repos court ne les
          // recharge jamais (contrairement à la magie de pacte).
          final classicRow = await client
              .from('character_spell_slots')
              .select('slots_used')
              .eq('character_id', characterId)
              .eq('slot_level', 1)
              .single();
          expect(classicRow['slots_used'], 3);
        },
      );

      test('repos LONG recharge à la fois character_pact_slots ET '
          'character_spell_slots', () async {
        final character = await client
            .from('characters')
            .insert({
              'owner_id': ownerId,
              'name': 'Test Intégration Pacte Repos Long',
              'max_hp': 10,
              'current_hp': 10,
            })
            .select('id')
            .single();
        final characterId = character['id'] as String;
        addTearDown(() async {
          await client.from('characters').delete().eq('id', characterId);
        });

        await client.from('character_classes').insert({
          'character_id': characterId,
          'class_id': occultisteId,
          'level': 3,
          'is_primary': true,
        });
        await client.from('character_pact_slots').insert({
          'character_id': characterId,
          'slot_level': 2,
          'slots_total': 2,
          'slots_used': 2,
        });

        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        await repository.applyRest(
          characterId: characterId,
          type: RestType.long,
          className: 'Occultiste',
        );

        final pactRow = await client
            .from('character_pact_slots')
            .select('slots_used')
            .eq('character_id', characterId)
            .single();
        expect(pactRow['slots_used'], 0);

        // Occultiste n'est pas un lanceur "non-pacte" : aucune ligne
        // character_spell_slots n'est créée pour lui (voir
        // SpellSlotProgression.slotsForLevel), mais le repos long ne doit
        // pas échouer pour autant.
        final classicRows = await client
            .from('character_spell_slots')
            .select('slot_level')
            .eq('character_id', characterId);
        expect(classicRows, isEmpty);
      });

      test('repos court recharge character_pact_slots même quand Occultiste '
          'est une classe SECONDAIRE (multiclassage)', () async {
        final guerrierId = await classIdByName('Guerrier');
        final character = await client
            .from('characters')
            .insert({
              'owner_id': ownerId,
              'name': 'Test Intégration Pacte Repos Secondaire',
              'max_hp': 15,
              'current_hp': 15,
            })
            .select('id')
            .single();
        final characterId = character['id'] as String;
        addTearDown(() async {
          await client.from('characters').delete().eq('id', characterId);
        });

        await client.from('character_classes').insert({
          'character_id': characterId,
          'class_id': guerrierId,
          'level': 5,
          'is_primary': true,
        });
        await client.from('character_classes').insert({
          'character_id': characterId,
          'class_id': occultisteId,
          'level': 2,
          'is_primary': false,
        });
        await client.from('character_pact_slots').insert({
          'character_id': characterId,
          'slot_level': 1,
          'slots_total': 2,
          'slots_used': 2,
        });

        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        // `className` = la classe primaire (Guerrier), comme le fait
        // l'appelant réel (`character_detail_screen.dart::_applyRest`,
        // `detail.primaryClass?.className`) — la résolution de l'Occultiste
        // ne doit JAMAIS dépendre de ce paramètre, seulement de
        // `character_classes` (toutes les classes).
        await repository.applyRest(
          characterId: characterId,
          type: RestType.short,
          className: 'Guerrier',
        );

        final pactRow = await client
            .from('character_pact_slots')
            .select('slots_total, slots_used')
            .eq('character_id', characterId)
            .single();
        expect(pactRow['slots_total'], 2);
        expect(pactRow['slots_used'], 0);
      });

      test('repos sans Occultiste parmi les classes du personnage ne crée '
          'jamais de ligne character_pact_slots', () async {
        final character = await client
            .from('characters')
            .insert({
              'owner_id': ownerId,
              'name': 'Test Intégration Pacte Absent',
              'max_hp': 10,
              'current_hp': 10,
            })
            .select('id')
            .single();
        final characterId = character['id'] as String;
        addTearDown(() async {
          await client.from('characters').delete().eq('id', characterId);
        });

        await client.from('character_classes').insert({
          'character_id': characterId,
          'class_id': clercId,
          'level': 3,
          'is_primary': true,
        });

        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        await repository.applyRest(
          characterId: characterId,
          type: RestType.long,
          className: 'Clerc',
        );

        final pactRows = await client
            .from('character_pact_slots')
            .select('character_id')
            .eq('character_id', characterId);
        expect(pactRows, isEmpty);
      });
    });

    group('castSpell(isPactSlot: true)', () {
      test('écrit character_pact_slots.slots_used sans toucher '
          'character_spell_slots', () async {
        final character = await client
            .from('characters')
            .insert({
              'owner_id': ownerId,
              'name': 'Test Intégration Pacte castSpell',
              'max_hp': 10,
              'current_hp': 10,
            })
            .select('id')
            .single();
        final characterId = character['id'] as String;
        addTearDown(() async {
          await client.from('characters').delete().eq('id', characterId);
        });

        await client.from('character_pact_slots').insert({
          'character_id': characterId,
          'slot_level': 2,
          'slots_total': 2,
          'slots_used': 0,
        });
        await client.from('character_spell_slots').insert({
          'character_id': characterId,
          'slot_level': 2,
          'slots_total': 3,
          'slots_used': 0,
        });

        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        await repository.castSpell(
          characterId: characterId,
          slotLevel: 2,
          slotsUsed: 1,
          isPactSlot: true,
        );

        final pactRow = await client
            .from('character_pact_slots')
            .select('slots_used')
            .eq('character_id', characterId)
            .single();
        expect(pactRow['slots_used'], 1);

        final classicRow = await client
            .from('character_spell_slots')
            .select('slots_used')
            .eq('character_id', characterId)
            .eq('slot_level', 2)
            .single();
        expect(classicRow['slots_used'], 0);
      });
    });

    group('isolation cross-utilisateur (RLS + filtre owner_id)', () {
      late SupabaseClient otherClient;
      late String characterId;

      setUpAll(() async {
        otherClient = createTestSupabaseClient();
        await signUpTestUser(otherClient);
      });

      setUp(() async {
        final character = await client
            .from('characters')
            .insert({
              'owner_id': ownerId,
              'name': 'Test Intégration Isolation Pacte',
              'max_hp': 10,
              'current_hp': 10,
            })
            .select('id')
            .single();
        characterId = character['id'] as String;
        await client.from('character_classes').insert({
          'character_id': characterId,
          'class_id': occultisteId,
          'level': 3,
          'is_primary': true,
        });
        await client.from('character_pact_slots').insert({
          'character_id': characterId,
          'slot_level': 2,
          'slots_total': 2,
          'slots_used': 1,
        });
      });

      tearDown(() async {
        await client.from('characters').delete().eq('id', characterId);
      });

      test('applyRest appelé depuis la session d\'un autre joueur ne modifie '
          'jamais character_pact_slots du personnage visé', () async {
        final otherRepository = SupabaseCharacterRepository(
          otherClient,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        try {
          await otherRepository.applyRest(
            characterId: characterId,
            type: RestType.short,
            className: 'Occultiste',
          );
        } catch (_) {
          // Un échec explicite (RLS) est acceptable — voir le rationale du
          // groupe équivalent des autres fichiers d'intégration.
        }

        final pactRow = await client
            .from('character_pact_slots')
            .select('slots_used')
            .eq('character_id', characterId)
            .single();
        expect(pactRow['slots_used'], 1);
      });

      test(
        'castSpell(isPactSlot: true) appelé depuis la session d\'un autre '
        'joueur ne modifie jamais character_pact_slots du personnage visé',
        () async {
          final otherRepository = SupabaseCharacterRepository(
            otherClient,
            cache,
            pendingWrites,
            const AlwaysOnlineConnectivityChecker(),
          );
          try {
            await otherRepository.castSpell(
              characterId: characterId,
              slotLevel: 2,
              slotsUsed: 2,
              isPactSlot: true,
            );
          } catch (_) {
            // Idem.
          }

          final pactRow = await client
              .from('character_pact_slots')
              .select('slots_used')
              .eq('character_id', characterId)
              .single();
          expect(pactRow['slots_used'], 1);
        },
      );

      test('applyLevelUp(dip Occultiste) appelé depuis la session d\'un autre '
          'joueur n\'insère jamais de ligne character_pact_slots pour le '
          'personnage visé', () async {
        final guerrierId = await classIdByName('Guerrier');
        final otherCharacter = await client
            .from('characters')
            .insert({
              'owner_id': ownerId,
              'name': 'Test Intégration Isolation Pacte Dip',
              'max_hp': 10,
              'current_hp': 10,
            })
            .select('id')
            .single();
        final otherCharacterId = otherCharacter['id'] as String;
        addTearDown(() async {
          await client.from('characters').delete().eq('id', otherCharacterId);
        });
        await client.from('character_classes').insert({
          'character_id': otherCharacterId,
          'class_id': guerrierId,
          'level': 2,
          'is_primary': true,
        });
        await client.from('character_ability_scores').insert([
          {'character_id': otherCharacterId, 'ability_id': 'str', 'score': 15},
          {'character_id': otherCharacterId, 'ability_id': 'cha', 'score': 14},
        ]);

        final otherRepository = SupabaseCharacterRepository(
          otherClient,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        try {
          await otherRepository.applyLevelUp(
            characterId: otherCharacterId,
            classId: occultisteId,
            className: 'Occultiste',
            isMulticlassing: true,
            hpRolled: 4,
            hpMethod: 'lance',
            hpGain: 4,
          );
        } catch (_) {
          // Idem.
        }

        final pactRows = await client
            .from('character_pact_slots')
            .select('character_id')
            .eq('character_id', otherCharacterId);
        expect(pactRows, isEmpty);
      });
    });
  });
}
