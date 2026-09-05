import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/rest_type.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/test_environment.dart';

/// Tests d'intégration de la règle RAW 5e "dépenser un dé de vie"
/// (`SupabaseCharacterRepository.applyRest`, [RestType.short] avec
/// `diceSpent`/`appliedGain`) et de la récupération de dés de vie au repos
/// long (`character_classes.hit_dice_spent`) — voir
/// `rest_repository_integration_test.dart` pour le rationale général de ce
/// dossier et pour les scénarios déjà couverts (PV/emplacements de sorts/
/// aptitudes rechargeables), non dupliqués ici.
///
/// `className` toujours fictif dans ce fichier (aucun test ici ne porte sur
/// `character_spell_slots`) — même convention que
/// `rest_repository_integration_test.dart`.
void main() {
  group('SupabaseCharacterRepository.applyRest — dés de vie (intégration)', () {
    late SupabaseClient client;
    late String ownerId;
    late AppDatabase cacheDb;
    late ReferenceDataCache cache;
    late PendingCharacterWriteQueue pendingWrites;
    late Object anyClassId;

    setUpAll(() async {
      client = createTestSupabaseClient();
      await signUpTestUser(client);
      ownerId = client.auth.currentUser!.id;
      cacheDb = AppDatabase(NativeDatabase.memory());
      cache = ReferenceDataCache(cacheDb);
      pendingWrites = PendingCharacterWriteQueue(cacheDb);

      // N'importe quelle classe convient : ces tests ne portent que sur
      // `character_classes.level`/`hit_dice_spent`, jamais sur une aptitude
      // ou un statut de lanceur de sorts précis.
      final classRow = await client
          .from('classes')
          .select('id')
          .order('id')
          .limit(1)
          .single();
      anyClassId = classRow['id'] as Object;
    });

    tearDownAll(() async {
      await cacheDb.close();
    });

    /// Crée un personnage + sa ligne `character_classes` primaire avec
    /// [level]/[hitDiceSpent] imposés, PV [currentHp]/[maxHp] imposés —
    /// retourne l'id du personnage. `addTearDown` supprime le personnage en
    /// fin de test (RLS en cascade sur `character_classes`).
    Future<String> createCharacter({
      required int currentHp,
      required int maxHp,
      required int level,
      int hitDiceSpent = 0,
    }) async {
      final character = await client
          .from('characters')
          .insert({
            'owner_id': ownerId,
            'name': 'Test Intégration Dés de Vie',
            'current_hp': currentHp,
            'max_hp': maxHp,
          })
          .select('id')
          .single();
      final characterId = character['id'] as String;
      addTearDown(() async {
        await client.from('characters').delete().eq('id', characterId);
      });

      await client.from('character_classes').insert({
        'character_id': characterId,
        'class_id': anyClassId,
        'level': level,
        'is_primary': true,
        'hit_dice_spent': hitDiceSpent,
      });

      return characterId;
    }

    Future<Map<String, dynamic>> fetchCharacterHp(String characterId) async {
      return client
          .from('characters')
          .select('current_hp, max_hp')
          .eq('id', characterId)
          .single();
    }

    Future<int> fetchHitDiceSpent(String characterId) async {
      final row = await client
          .from('character_classes')
          .select('hit_dice_spent')
          .eq('character_id', characterId)
          .single();
      return (row['hit_dice_spent'] as num).toInt();
    }

    group('repos court (RestType.short) avec diceSpent > 0', () {
      test('incrémente hit_dice_spent et ajoute appliedGain à current_hp, '
          're-clampé à max_hp par sécurité même si un appliedGain trop élevé '
          'lui était transmis', () async {
        final characterId = await createCharacter(
          currentHp: 10,
          maxHp: 20,
          level: 5,
          hitDiceSpent: 1,
        );

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
          diceSpent: 2,
          // Volontairement au-delà de la marge réelle (10) : le dépôt
          // doit re-clamper à `max_hp`, jamais faire confiance à
          // l'appelant (voir la doc de `applyRest`).
          appliedGain: 15,
        );

        final characterRow = await fetchCharacterHp(characterId);
        expect(characterRow['current_hp'], 20);
        expect(await fetchHitDiceSpent(characterId), 3);
      });

      test('incrémente hit_dice_spent même quand appliedGain vaut 0 (PV déjà '
          'au maximum) : un dé de vie dépensé reste dépensé (RAW)', () async {
        final characterId = await createCharacter(
          currentHp: 20,
          maxHp: 20,
          level: 4,
        );

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
          diceSpent: 1,
        );

        final characterRow = await fetchCharacterHp(characterId);
        expect(characterRow['current_hp'], 20);
        expect(await fetchHitDiceSpent(characterId), 1);
      });

      test('hit_dice_spent ne dépasse jamais level, même si diceSpent transmis '
          'dépasse la marge réelle (cohérent avec la contrainte SQL '
          'hit_dice_spent <= level)', () async {
        final characterId = await createCharacter(
          currentHp: 5,
          maxHp: 20,
          level: 3,
          hitDiceSpent: 2,
        );

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
          diceSpent: 5,
          appliedGain: 4,
        );

        expect(await fetchHitDiceSpent(characterId), 3);
      });

      test('diceSpent = 0 (valeur par défaut) ne touche ni current_hp ni '
          'hit_dice_spent', () async {
        final characterId = await createCharacter(
          currentHp: 10,
          maxHp: 20,
          level: 5,
          hitDiceSpent: 2,
        );

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

        final characterRow = await fetchCharacterHp(characterId);
        expect(characterRow['current_hp'], 10);
        expect(await fetchHitDiceSpent(characterId), 2);
      });

      test('personnage sans aucune ligne character_classes (gap '
          'preexistant documente sur applyRest) : ne plante jamais, '
          'applique quand meme appliedGain a current_hp (deja calcule '
          'par l appelant, non conditionne a une classe primaire), '
          'sans jamais tenter d ecrire hit_dice_spent (aucune ligne a '
          'mettre a jour)', () async {
        final character = await client
            .from('characters')
            .insert({
              'owner_id': ownerId,
              'name': 'Test Integration Sans Classe',
              'current_hp': 10,
              'max_hp': 20,
            })
            .select('id')
            .single();
        final characterId = character['id'] as String;
        addTearDown(() async {
          await client.from('characters').delete().eq('id', characterId);
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
          diceSpent: 2,
          appliedGain: 5,
        );

        final characterRow = await fetchCharacterHp(characterId);
        expect(characterRow['current_hp'], 15);
      });
    });

    group('repos long (RestType.long) : récupération RAW des dés de vie', () {
      test(
        'restored = max(1, level ~/ 2) : level 5, 5 dés dépensés -> 3',
        () async {
          final characterId = await createCharacter(
            currentHp: 1,
            maxHp: 30,
            level: 5,
            hitDiceSpent: 5,
          );

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

          // max(1, 5 ~/ 2) = max(1, 2) = 2 -> 5 - 2 = 3.
          expect(await fetchHitDiceSpent(characterId), 3);
        },
      );

      test('niveau 1 : au moins 1 dé récupéré (le plancher "au moins 1" '
          "s'applique même à un petit niveau)", () async {
        final characterId = await createCharacter(
          currentHp: 1,
          maxHp: 10,
          level: 1,
          hitDiceSpent: 1,
        );

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

        // max(1, 1 ~/ 2) = max(1, 0) = 1 -> 1 - 1 = 0.
        expect(await fetchHitDiceSpent(characterId), 0);
      });

      test('jamais négatif : la récupération ne dépasse pas hit_dice_spent '
          '(niveau 10, seulement 3 dés dépensés)', () async {
        final characterId = await createCharacter(
          currentHp: 1,
          maxHp: 50,
          level: 10,
          hitDiceSpent: 3,
        );

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

        // max(1, 10 ~/ 2) = 5, mais seulement 3 dés étaient dépensés ->
        // max(0, 3 - 5) = 0, jamais négatif.
        expect(await fetchHitDiceSpent(characterId), 0);
      });

      test('aucun dé dépensé (hit_dice_spent déjà à 0) : rien à récupérer, '
          'reste à 0', () async {
        final characterId = await createCharacter(
          currentHp: 1,
          maxHp: 20,
          level: 5,
        );

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

        expect(await fetchHitDiceSpent(characterId), 0);
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
        characterId = await createCharacter(
          currentHp: 10,
          maxHp: 20,
          level: 5,
          hitDiceSpent: 1,
        );
      });

      test("applyRest(short, diceSpent > 0) appelé depuis la session d'un "
          'autre joueur ne modifie jamais current_hp/hit_dice_spent du '
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
            diceSpent: 2,
            appliedGain: 8,
          );
        } catch (_) {
          // Un échec explicite (RLS) est acceptable ici — seul un
          // personnage réellement modifié serait un problème.
        }

        final characterRow = await fetchCharacterHp(characterId);
        expect(characterRow['current_hp'], 10);
        expect(await fetchHitDiceSpent(characterId), 1);
      });
    });
  });
}
