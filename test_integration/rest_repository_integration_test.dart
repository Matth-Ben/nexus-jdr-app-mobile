import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/rest_type.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/test_environment.dart';

/// Tests d'intégration de `SupabaseCharacterRepository.applyRest`
/// (repos court/long, onglet "Personnage") — voir
/// `character_repository_integration_test.dart` pour le rationale général de
/// ce dossier.
///
/// Classes/aptitudes résolues dynamiquement (voir `setUpAll`) plutôt que via
/// `ReferenceContent` (qui ne garantit qu'*une* classe/aptitude
/// quelconque) : ces tests ont besoin d'aptitudes avec un `rest_type`
/// précis ('repos_court'/'repos_long'), et — vérifié contre le contenu
/// actuel du stack local — aucune classe seedée n'a les deux à la fois, donc
/// deux classes distinctes sont utilisées (une par `rest_type`), même
/// rationale que `level_up_repository_integration_test.dart::classIdByName`
/// pour "Clerc"/"Guerrier".
void main() {
  group('SupabaseCharacterRepository — repos (intégration)', () {
    late SupabaseClient client;
    late String ownerId;
    // Base drift en mémoire : ce fichier n'exerce jamais le chemin de
    // secours "cache" de `fetchCharacterDetail` (couvert par les tests
    // unitaires de `character_repository_test.dart`), seulement le
    // constructeur de `SupabaseCharacterRepository`, qui prend désormais un
    // `ReferenceDataCache` en dépendance.
    late AppDatabase cacheDb;
    late ReferenceDataCache cache;
    late PendingCharacterWriteQueue pendingWrites;

    // Classe/aptitude 'repos_court' à amount non nul.
    late Object shortRestClassId;
    late int shortRestClassLevel;
    late int shortRestFeatureId;
    late int shortRestAmount;

    // Classe/aptitude 'repos_long' à amount non nul.
    late Object longRestClassId;
    late int longRestClassLevel;
    late int longRestFeatureId;
    late int longRestAmount;

    setUpAll(() async {
      client = createTestSupabaseClient();
      await signUpTestUser(client);
      ownerId = client.auth.currentUser!.id;
      cacheDb = AppDatabase(NativeDatabase.memory());
      cache = ReferenceDataCache(cacheDb);
      pendingWrites = PendingCharacterWriteQueue(cacheDb);

      final rows = await client
          .from('class_features')
          .select('class_id, level, id, uses_per_rest');

      Map<String, dynamic>? shortFeature;
      Map<String, dynamic>? longFeature;
      for (final row in rows) {
        final usesPerRest = row['uses_per_rest'] as Map<String, dynamic>?;
        if (row['class_id'] == null || usesPerRest == null) continue;
        // `amount` peut être `null` même quand `uses_per_rest` est renseigné
        // (cas réel constaté côté seed, ex. `class_features.id = 6`) : ces
        // aptitudes ne sont jamais rechargées par `applyRest` (voir
        // `_rechargedAmount`, `character_repository.dart`) — pas ce dont ces
        // 2 variables ont besoin ici, donc exclues.
        if (usesPerRest['amount'] == null) continue;

        if (shortFeature == null && usesPerRest['rest_type'] == 'repos_court') {
          shortFeature = row;
        }
        if (longFeature == null && usesPerRest['rest_type'] == 'repos_long') {
          longFeature = row;
        }
        if (shortFeature != null && longFeature != null) break;
      }
      expect(
        shortFeature,
        isNotNull,
        reason:
            "Aucune class_features avec uses_per_rest.rest_type = "
            "'repos_court' et amount non nul côté seed — vérifier "
            'supabase db reset côté dépôt web.',
      );
      expect(
        longFeature,
        isNotNull,
        reason:
            "Aucune class_features avec uses_per_rest.rest_type = "
            "'repos_long' et amount non nul côté seed — vérifier "
            'supabase db reset côté dépôt web.',
      );

      shortRestClassId = shortFeature!['class_id'] as Object;
      shortRestClassLevel = (shortFeature['level'] as num).toInt();
      shortRestFeatureId = (shortFeature['id'] as num).toInt();
      shortRestAmount =
          ((shortFeature['uses_per_rest'] as Map<String, dynamic>)['amount']
                  as num)
              .toInt();

      longRestClassId = longFeature!['class_id'] as Object;
      longRestClassLevel = (longFeature['level'] as num).toInt();
      longRestFeatureId = (longFeature['id'] as num).toInt();
      longRestAmount =
          ((longFeature['uses_per_rest'] as Map<String, dynamic>)['amount']
                  as num)
              .toInt();
    });

    tearDownAll(() async {
      await cacheDb.close();
    });

    /// `classes.id` dont le nom traduit `fr` vaut exactement [name] — même
    /// helper que `level_up_repository_integration_test.dart`, nécessaire
    /// ici pour les tests du groupe "recalcul character_spell_slots"
    /// ci-dessous : `_resetSpellSlots` (`character_repository.dart`)
    /// recalcule les totaux via `SpellSlotProgression.slotsForLevel`, qui
    /// n'attend que des noms de classe précis ("Clerc"...), jamais
    /// `shortRestClassId`/`longRestClassId` (résolues ci-dessus sur un tout
    /// autre critère : avoir une aptitude `repos_court`/`repos_long`, sans
    /// rapport avec le fait d'être une classe lanceuse de sorts).
    Future<Object> classIdByName(String name) async {
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
      return translation!['entity_id'] as Object;
    }

    test(
      'applyRest(long) restaure les PV au maximum, remet temporary_hp à 0, '
      "et recharge une aptitude 'repos_long' de la classe primaire, même "
      "sans aucune ligne character_spell_slots/character_feature_uses "
      'préexistante (gap pré-existant : jamais initialisées à la création)',
      () async {
        final character = await client
            .from('characters')
            .insert({
              'owner_id': ownerId,
              'name': 'Test Intégration Repos Long',
              'current_hp': 4,
              'max_hp': 22,
              'temporary_hp': 5,
            })
            .select('id')
            .single();
        final characterId = character['id'] as String;
        addTearDown(() async {
          await client.from('characters').delete().eq('id', characterId);
        });

        await client.from('character_classes').insert({
          'character_id': characterId,
          'class_id': longRestClassId,
          'level': longRestClassLevel,
          'is_primary': true,
        });

        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        // `className` volontairement fictif : ce test porte sur les PV et
        // les aptitudes, jamais sur `character_spell_slots` — un nom qui ne
        // correspond à aucune classe connue de `SpellSlotProgression`
        // garantit qu'aucun emplacement de sorts n'est recalculé, sans
        // dépendre du statut lanceur réel de `longRestClassId` (résolue sur
        // un tout autre critère, voir `classIdByName` ci-dessus).
        await repository.applyRest(
          characterId: characterId,
          type: RestType.long,
          className: 'Aucune Classe Lanceuse',
        );

        final characterRow = await client
            .from('characters')
            .select('current_hp, temporary_hp')
            .eq('id', characterId)
            .single();
        expect(characterRow['current_hp'], 22);
        expect(characterRow['temporary_hp'], 0);

        // Aucune ligne character_spell_slots créée : `className` fictif
        // (voir plus haut), aucune classe lanceuse ne correspond, donc
        // `SpellSlotProgression.slotsForLevel` retourne 9 zéros et
        // `_resetSpellSlots` n'upserte rien — voir le groupe "recalcul
        // character_spell_slots" plus bas pour le cas d'un vrai lanceur.
        final slotRows = await client
            .from('character_spell_slots')
            .select('slot_level')
            .eq('character_id', characterId);
        expect(slotRows, isEmpty);

        final longUse = await client
            .from('character_feature_uses')
            .select('uses_remaining')
            .eq('character_id', characterId)
            .eq('class_feature_id', longRestFeatureId)
            .single();
        expect(longUse['uses_remaining'], longRestAmount);
      },
    );

    test("applyRest(long) avec un className fictif (aucune classe lanceuse "
        'correspondante) ne touche jamais une ligne character_spell_slots '
        'déjà existante, mais écrase bien les character_feature_uses déjà '
        'existants avec leur plein total', () async {
      final character = await client
          .from('characters')
          .insert({
            'owner_id': ownerId,
            'name': 'Test Intégration Repos Long Existant',
            'current_hp': 10,
            'max_hp': 20,
            'temporary_hp': 2,
          })
          .select('id')
          .single();
      final characterId = character['id'] as String;
      addTearDown(() async {
        await client.from('characters').delete().eq('id', characterId);
      });

      await client.from('character_classes').insert({
        'character_id': characterId,
        'class_id': longRestClassId,
        'level': longRestClassLevel,
        'is_primary': true,
      });
      await client.from('character_spell_slots').insert({
        'character_id': characterId,
        'slot_level': 1,
        'slots_total': 4,
        'slots_used': 3,
      });
      await client.from('character_feature_uses').insert({
        'character_id': characterId,
        'class_feature_id': longRestFeatureId,
        'uses_remaining': 0,
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
        className: 'Aucune Classe Lanceuse',
      );

      // Inchangé : `longRestClassId` n'a aucune raison d'être une classe
      // lanceuse de sorts (résolue sur son aptitude `repos_long`, sans
      // rapport), et `className` ci-dessus est délibérément fictif.
      final slotRow = await client
          .from('character_spell_slots')
          .select('slots_total, slots_used')
          .eq('character_id', characterId)
          .single();
      expect(slotRow['slots_total'], 4);
      expect(slotRow['slots_used'], 3);

      final longUse = await client
          .from('character_feature_uses')
          .select('uses_remaining')
          .eq('character_id', characterId)
          .eq('class_feature_id', longRestFeatureId)
          .single();
      expect(longUse['uses_remaining'], longRestAmount);
    });

    test("applyRest(long) recharge aussi une aptitude 'repos_court' de la "
        'classe primaire — règle 5e RAW : un repos long recharge tout ce '
        "qu'un repos court recharge, et plus", () async {
      final character = await client
          .from('characters')
          .insert({
            'owner_id': ownerId,
            'name': 'Test Intégration Repos Long recharge repos_court',
            'current_hp': 5,
            'max_hp': 15,
          })
          .select('id')
          .single();
      final characterId = character['id'] as String;
      addTearDown(() async {
        await client.from('characters').delete().eq('id', characterId);
      });

      await client.from('character_classes').insert({
        'character_id': characterId,
        'class_id': shortRestClassId,
        'level': shortRestClassLevel,
        'is_primary': true,
      });
      await client.from('character_feature_uses').insert({
        'character_id': characterId,
        'class_feature_id': shortRestFeatureId,
        'uses_remaining': 0,
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
        className: 'Aucune Classe Lanceuse',
      );

      final shortUse = await client
          .from('character_feature_uses')
          .select('uses_remaining')
          .eq('character_id', characterId)
          .eq('class_feature_id', shortRestFeatureId)
          .single();
      expect(shortUse['uses_remaining'], shortRestAmount);
    });

    test(
      "applyRest(short) réinitialise une aptitude 'repos_court' de la "
      'classe primaire, sans toucher aux PV ni à character_spell_slots',
      () async {
        final character = await client
            .from('characters')
            .insert({
              'owner_id': ownerId,
              'name': 'Test Intégration Repos Court',
              'current_hp': 10,
              'max_hp': 20,
              'temporary_hp': 2,
            })
            .select('id')
            .single();
        final characterId = character['id'] as String;
        addTearDown(() async {
          await client.from('characters').delete().eq('id', characterId);
        });

        await client.from('character_classes').insert({
          'character_id': characterId,
          'class_id': shortRestClassId,
          'level': shortRestClassLevel,
          'is_primary': true,
        });
        await client.from('character_spell_slots').insert({
          'character_id': characterId,
          'slot_level': 1,
          'slots_total': 4,
          'slots_used': 3,
        });
        await client.from('character_feature_uses').insert({
          'character_id': characterId,
          'class_feature_id': shortRestFeatureId,
          'uses_remaining': 0,
        });

        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        // `className` sans effet pour un repos court (`_resetSpellSlots`
        // n'est appelé que pour `RestType.long`, voir `applyRest`).
        await repository.applyRest(
          characterId: characterId,
          type: RestType.short,
          className: 'Peu importe (repos court)',
        );

        final characterRow = await client
            .from('characters')
            .select('current_hp, temporary_hp')
            .eq('id', characterId)
            .single();
        expect(characterRow['current_hp'], 10);
        expect(characterRow['temporary_hp'], 2);

        final slotRow = await client
            .from('character_spell_slots')
            .select('slots_used')
            .eq('character_id', characterId)
            .single();
        expect(slotRow['slots_used'], 3);

        final shortUse = await client
            .from('character_feature_uses')
            .select('uses_remaining')
            .eq('character_id', characterId)
            .eq('class_feature_id', shortRestFeatureId)
            .single();
        expect(shortUse['uses_remaining'], shortRestAmount);
      },
    );

    test("applyRest(short) ne réinitialise jamais une aptitude 'repos_long' de "
        'la classe primaire', () async {
      final character = await client
          .from('characters')
          .insert({
            'owner_id': ownerId,
            'name': "Test Intégration Repos Court n'affecte pas repos_long",
            'current_hp': 10,
            'max_hp': 20,
          })
          .select('id')
          .single();
      final characterId = character['id'] as String;
      addTearDown(() async {
        await client.from('characters').delete().eq('id', characterId);
      });

      await client.from('character_classes').insert({
        'character_id': characterId,
        'class_id': longRestClassId,
        'level': longRestClassLevel,
        'is_primary': true,
      });
      await client.from('character_feature_uses').insert({
        'character_id': characterId,
        'class_feature_id': longRestFeatureId,
        'uses_remaining': 0,
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
        className: 'Peu importe (repos court)',
      );

      final longUse = await client
          .from('character_feature_uses')
          .select('uses_remaining')
          .eq('character_id', characterId)
          .eq('class_feature_id', longRestFeatureId)
          .single();
      // Inchangé : un repos court ne recharge jamais une aptitude
      // 'repos_long'.
      expect(longUse['uses_remaining'], 0);
    });

    test("applyRest n'échoue pas et n'écrit aucune ligne "
        "character_feature_uses pour une aptitude dont uses_per_rest est "
        "renseigné mais dont l'amount est null (cas réel constaté côté seed, "
        'traité comme une aptitude passive)', () async {
      // Filtré côté client plutôt que via un filtre PostgREST sur un champ
      // JSON imbriqué (`uses_per_rest->>amount`), pour ne pas dépendre
      // d'une syntaxe de filtre JSON précise du package `postgrest`.
      final allFeatureRows = await client
          .from('class_features')
          .select('id, class_id, level, uses_per_rest');
      final nullAmountRow = allFeatureRows
          .cast<Map<String, dynamic>?>()
          .firstWhere((row) {
            final usesPerRest = row!['uses_per_rest'] as Map<String, dynamic>?;
            return usesPerRest != null && usesPerRest['amount'] == null;
          }, orElse: () => null);
      expect(
        nullAmountRow,
        isNotNull,
        reason:
            "Aucune class_features avec uses_per_rest renseigné et "
            "amount null côté seed — ce cas particulier (constaté lors du "
            "développement de cette fonctionnalité, class_features.id = "
            "6 sur le stack local d'origine) n'existe peut-être plus : ce "
            "test peut être retiré si supabase db reset ne le reproduit "
            'plus jamais.',
      );

      final featureId = (nullAmountRow!['id'] as num).toInt();
      final classId = nullAmountRow['class_id'] as Object;
      final level = (nullAmountRow['level'] as num).toInt();

      final character = await client
          .from('characters')
          .insert({
            'owner_id': ownerId,
            'name': 'Test Intégration Repos Amount Null',
            'current_hp': 10,
            'max_hp': 20,
          })
          .select('id')
          .single();
      final characterId = character['id'] as String;
      addTearDown(() async {
        await client.from('characters').delete().eq('id', characterId);
      });

      await client.from('character_classes').insert({
        'character_id': characterId,
        'class_id': classId,
        'level': level,
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
        className: 'Aucune Classe Lanceuse',
      );

      final featureUseRows = await client
          .from('character_feature_uses')
          .select('class_feature_id')
          .eq('character_id', characterId)
          .eq('class_feature_id', featureId);
      expect(featureUseRows, isEmpty);
    });

    group('isolation cross-utilisateur (RLS + filtre owner_id)', () {
      // Même rationale que les groupes équivalents des autres fichiers
      // d'intégration : un échec explicite (RLS) est acceptable, mais le
      // personnage de l'*autre* joueur ne doit jamais être modifié.
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
              'name': 'Test Intégration Isolation Repos',
              'current_hp': 5,
              'max_hp': 20,
              'temporary_hp': 3,
            })
            .select('id')
            .single();
        characterId = character['id'] as String;
        await client.from('character_classes').insert({
          'character_id': characterId,
          'class_id': longRestClassId,
          'level': longRestClassLevel,
          'is_primary': true,
        });
      });

      tearDown(() async {
        await client.from('characters').delete().eq('id', characterId);
      });

      test('applyRest(long) appelé depuis la session d\'un autre joueur ne '
          'modifie jamais le personnage visé', () async {
        final otherRepository = SupabaseCharacterRepository(
          otherClient,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        try {
          await otherRepository.applyRest(
            characterId: characterId,
            type: RestType.long,
            className: 'Aucune Classe Lanceuse',
          );
        } catch (_) {
          // Idem — voir la documentation du groupe.
        }

        final characterRow = await client
            .from('characters')
            .select('current_hp, temporary_hp')
            .eq('id', characterId)
            .single();
        expect(characterRow['current_hp'], 5);
        expect(characterRow['temporary_hp'], 3);

        final featureRows = await client
            .from('character_feature_uses')
            .select('class_feature_id')
            .eq('character_id', characterId);
        expect(featureRows, isEmpty);
      });

      test('applyRest(short) appelé depuis la session d\'un autre joueur '
          "n'insère jamais de ligne character_feature_uses pour le "
          'personnage visé', () async {
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
            className: 'Peu importe (repos court)',
          );
        } catch (_) {
          // Idem.
        }

        final featureRows = await client
            .from('character_feature_uses')
            .select('class_feature_id')
            .eq('character_id', characterId);
        expect(featureRows, isEmpty);
      });
    });

    group('recalcul character_spell_slots pour un vrai lanceur (repos long)', () {
      // Décision chef de projet (revue QA) : `_resetSpellSlots` doit
      // recalculer les totaux via `SpellSlotProgression.slotsForLevel`
      // (même fonction que la montée de niveau), pas se contenter de
      // remettre à 0 les lignes déjà existantes — un personnage lanceur qui
      // n'a jamais monté de niveau via l'app n'a autrement aucune ligne
      // `character_spell_slots`, et un repos long resterait sans effet.
      // "Clerc" (lanceur complet, voir `SpellSlotProgression`) plutôt que
      // `longRestClassId`/`shortRestClassId` (résolues plus haut sur un
      // tout autre critère, sans rapport avec le fait d'être lanceur de
      // sorts) — voir `classIdByName` ci-dessus.
      test("applyRest(long) upserte character_spell_slots depuis zéro pour un "
          "personnage lanceur qui n'a jamais monté de niveau via l'app (aucune "
          'ligne préexistante)', () async {
        final clercId = await classIdByName('Clerc');

        final character = await client
            .from('characters')
            .insert({
              'owner_id': ownerId,
              'name': 'Test Intégration Repos Long Sorts (gap)',
              'current_hp': 5,
              'max_hp': 10,
            })
            .select('id')
            .single();
        final characterId = character['id'] as String;
        addTearDown(() async {
          await client.from('characters').delete().eq('id', characterId);
        });

        // Clerc niveau 1 : SpellSlotProgression donne [2, 0, 0, ...].
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
        await repository.applyRest(
          characterId: characterId,
          type: RestType.long,
          className: 'Clerc',
        );

        final slotRows = await client
            .from('character_spell_slots')
            .select('slot_level, slots_total, slots_used')
            .eq('character_id', characterId)
            .order('slot_level', ascending: true);
        expect(slotRows, hasLength(1));
        expect(slotRows.single['slot_level'], 1);
        expect(slotRows.single['slots_total'], 2);
        expect(slotRows.single['slots_used'], 0);
      });

      test('applyRest(long) recalcule complètement une ligne '
          'character_spell_slots déjà existante mais désormais incorrecte '
          '(slots_total corrigé, pas seulement slots_used remis à 0), et crée '
          "les paliers manquants", () async {
        final clercId = await classIdByName('Clerc');

        final character = await client
            .from('characters')
            .insert({
              'owner_id': ownerId,
              'name': 'Test Intégration Repos Long Sorts (recalcul)',
              'current_hp': 5,
              'max_hp': 10,
            })
            .select('id')
            .single();
        final characterId = character['id'] as String;
        addTearDown(() async {
          await client.from('characters').delete().eq('id', characterId);
        });

        // Clerc niveau 3 : SpellSlotProgression donne [4, 2, 0, ...].
        await client.from('character_classes').insert({
          'character_id': characterId,
          'class_id': clercId,
          'level': 3,
          'is_primary': true,
        });
        // Ligne préexistante volontairement incorrecte (total 1 au lieu
        // de 4 — simule un personnage jamais recalculé par l'app depuis
        // sa création/import), pour prouver un vrai recalcul plutôt qu'un
        // simple `UPDATE ... SET slots_used = 0`.
        await client.from('character_spell_slots').insert({
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
        await repository.applyRest(
          characterId: characterId,
          type: RestType.long,
          className: 'Clerc',
        );

        final slotRows = await client
            .from('character_spell_slots')
            .select('slot_level, slots_total, slots_used')
            .eq('character_id', characterId)
            .order('slot_level', ascending: true);
        expect(slotRows, hasLength(2));
        expect(slotRows[0]['slot_level'], 1);
        expect(slotRows[0]['slots_total'], 4);
        expect(slotRows[0]['slots_used'], 0);
        expect(slotRows[1]['slot_level'], 2);
        expect(slotRows[1]['slots_total'], 2);
        expect(slotRows[1]['slots_used'], 0);
      });
    });
  });
}
