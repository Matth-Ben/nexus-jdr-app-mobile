import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/core/network/connectivity_checker.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/data/pending_character_write_syncer.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/characters/domain/reward_item_draft.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ces tests couvrent la stratégie "réseau d'abord, cache en secours" du
/// cache local (`ReferenceDataCache`, `lib/core/cache/`) appliquée à
/// `SupabaseCharacterRepository.fetchCharacterDetail` — même principe que
/// `test/features/character_creation/data/character_creation_repository_test.dart`
/// pour les 8 catalogues de référence (voir la doc de classe de ce fichier
/// pour le rationale détaillé du double `SupabaseClient`/`MockClient`,
/// repris ici sous [_buildSignedInFakeSupabaseClient] plutôt que réutilisé
/// tel quel : ce fichier a en plus besoin d'un utilisateur authentifié —
/// `fetchCharacterDetail` appelle `_requireOwnerId()`, qui lit
/// `_client.auth.currentUser?.id` — alors que les 8 catalogues de référence
/// ne dépendent jamais de l'identité de l'appelant).
///
/// [_buildSignedInFakeSupabaseClient] connecte le client factice sans
/// aucune requête réseau, via
/// `GoTrueClient.recoverSession` : un jeton d'accès qui n'est pas un JWT
/// valide fait échouer silencieusement `Session._expiresAt` (`decodeJwtPayload`,
/// avalé par un `try/catch` interne au package `gotrue`), ce qui fait
/// retomber `Session.isExpired` sur `false` — la branche "session non
/// expirée" de `recoverSession` s'exécute alors entièrement en mémoire,
/// sans jamais appeler `MockClient`.
///
/// Ce comportement n'est pas contractuel côté `gotrue` (détail
/// d'implémentation, pas de l'API publique) : **si ce fichier se met à
/// échouer après une montée de version de `supabase_flutter`/`gotrue`,
/// commencer l'investigation ici**. Risque limité en pratique — si
/// `isExpired` devenait un jour `true`, `recoverSession` tenterait un
/// rafraîchissement réseau via `MockClient`, qui échouerait à parser une
/// réponse `[]` sur la route `token`, et `_buildSignedInFakeSupabaseClient`
/// lèverait une exception explicite dès le `setUp()` — un échec bruyant et
/// localisé à ce fichier, jamais un faux positif silencieux.
///
/// Point central de ce fichier, au-delà des 3 scénarios communs au chantier
/// précédent (succès réseau écrit le cache, échec réseau + cache retombe
/// dessus, échec réseau + aucun cache relance l'erreur d'origine) : la
/// **isolation par utilisateur** de la clé de cache
/// (`'character_detail:$ownerId:$characterId'`, jamais
/// `'character_detail:$characterId'` seul) — voir le dernier groupe de
/// `main()`.
void main() {
  group(
    'SupabaseCharacterRepository.fetchCharacterDetail (cache de secours)',
    () {
      late AppDatabase db;
      late ReferenceDataCache cache;
      late PendingCharacterWriteQueue pendingWrites;

      setUp(() {
        db = AppDatabase(NativeDatabase.memory());
        cache = ReferenceDataCache(db);
        pendingWrites = PendingCharacterWriteQueue(db);
      });

      tearDown(() async {
        await db.close();
      });

      const characterId = 'char-1';
      const ownerId = 'owner-1';
      final cacheKey = 'character_detail:$ownerId:$characterId';

      final tableRows = <String, List<Map<String, dynamic>>>{
        'characters': [
          {
            'id': characterId,
            'name': 'Aragorn',
            'portrait_url': null,
            'xp': 100,
            'current_hp': 10,
            'max_hp': 12,
            'temporary_hp': 0,
            'race_id': 1,
            'subrace_id': null,
            'race_custom_text': null,
            'background_id': 3,
            'alignment_id': 9,
            'sexe': null,
            'age': null,
            'height': null,
            'weight': null,
            'eyes': null,
            'skin': null,
            'hair': null,
            'currency_gp': 5,
            'currency_pp': 0,
            'currency_ep': 0,
            'currency_sp': 0,
            'currency_cp': 0,
            'appearance_text': '',
            'traits_text': '',
            'ideals_text': '',
            'bonds_text': '',
            'flaws_text': '',
            'backstory_text': '',
            'allies_text': '',
            'features_text': '',
            'treasure_text': '',
            'character_classes': [
              {
                'class_id': 2,
                'level': 5,
                'is_primary': true,
                'classes': {
                  'saving_throw_proficiencies': ['str', 'con'],
                  'hit_die': 10,
                },
              },
            ],
            'character_ability_scores': [
              {'ability_id': 'str', 'score': 16},
            ],
            'character_skill_proficiencies': [
              {'skill_id': 7, 'proficiency': 'maitrise'},
            ],
            'character_tool_proficiencies': [
              {'tool_id': 4, 'custom_text': null},
            ],
            'character_languages': [
              {'language_id': 5},
            ],
            'character_spells': [
              {'spell_id': 20, 'status': 'connu'},
            ],
            'character_spell_slots': [
              {'slot_level': 1, 'slots_total': 4, 'slots_used': 1},
            ],
            'character_feature_uses': [
              {'class_feature_id': 50, 'uses_remaining': 2},
            ],
            'character_inventory': [
              {
                'id': 'inv-1',
                'item_id': 6,
                'custom_name': null,
                'quantity': 2,
                'equipped': true,
                'items': {'category': 'arme', 'weight': 1.5},
              },
            ],
          },
        ],
        // Un seul endpoint `translations` sert toutes les résolutions de noms
        // (race/background/alignment/class/skill/class_feature/tool/language/
        // spell/item) : notre double ne filtre pas par query string (seulement
        // par table), donc tous les entity_id ci-dessous doivent coexister —
        // sans conséquence puisque chaque résolution ne va chercher que
        // l'entity_id qui la concerne, et tous les ids ci-dessous sont
        // distincts (voir `character_creation_repository_test.dart` pour le
        // même principe).
        'translations': [
          {'entity_id': '1', 'value': 'Humain'},
          {'entity_id': '3', 'value': 'Soldat'},
          {'entity_id': '9', 'value': 'Loyal bon'},
          {'entity_id': '2', 'value': 'Guerrier'},
          {'entity_id': '7', 'value': 'Perception'},
          {'entity_id': '50', 'value': 'Deuxième souffle'},
          {'entity_id': '4', 'value': 'Luth'},
          {'entity_id': '5', 'value': 'Elfique'},
          {'entity_id': '20', 'value': 'Bouclier'},
          {'entity_id': '6', 'value': 'Épée longue'},
        ],
        'skills': [
          {'id': 7, 'ability_id': 'wis'},
        ],
        'class_features': [
          {
            'id': 50,
            'class_id': 2,
            'level': 3,
            'uses_per_rest': {'amount': 2, 'rest_type': 'repos_court'},
          },
        ],
        'spells': [
          {'id': 20, 'level': 1, 'school': 'évocation'},
        ],
      };

      void verifyDetail(dynamic detail) {
        expect(detail.id, characterId);
        expect(detail.name, 'Aragorn');
        expect(detail.raceName, 'Humain');
        expect(detail.backgroundName, 'Soldat');
        expect(detail.alignmentName, 'Loyal bon');
        expect(detail.classes, hasLength(1));
        expect(detail.classes.single.className, 'Guerrier');
        expect(detail.classes.single.level, 5);
        expect(detail.skills.where((s) => s.id == 7).single.name, 'Perception');
        expect(
          detail.classFeatures.single.name,
          'Deuxième souffle',
          reason: 'aptitude de niveau 3, atteinte par une classe niveau 5',
        );
        expect(detail.toolProficiencyNames, ['Luth']);
        expect(detail.knownLanguageNames, ['Elfique']);
        expect(detail.spells.single.name, 'Bouclier');
        expect(detail.spellSlots.single.total, 4);
        expect(detail.inventory.single.name, 'Épée longue');
        expect(detail.inventory.single.totalWeight, 3.0);
        expect(detail.currencyGp, 5);
      }

      test(
        'succès réseau : écrit le cache (clé scopée par ownerId) et retourne '
        'la fiche mappée',
        () async {
          final client = await _buildSignedInFakeSupabaseClient(
            ownerId: ownerId,
            tableRows: tableRows,
          );
          final repository = SupabaseCharacterRepository(
            client,
            cache,
            pendingWrites,
            _AlwaysOnlineConnectivityChecker(),
          );

          final detail = await repository.fetchCharacterDetail(characterId);

          verifyDetail(detail);
          expect(
            await cache.get(cacheKey),
            isNotNull,
            reason: 'le succès réseau doit avoir peuplé le cache',
          );
        },
      );

      test('échec réseau + cache déjà présent : retombe sur le cache et '
          'produit la même fiche que le mapper direct', () async {
        final onlineClient = await _buildSignedInFakeSupabaseClient(
          ownerId: ownerId,
          tableRows: tableRows,
        );
        final onlineRepository = SupabaseCharacterRepository(
          onlineClient,
          cache,
          pendingWrites,
          _AlwaysOnlineConnectivityChecker(),
        );
        final expectedDetail = await onlineRepository.fetchCharacterDetail(
          characterId,
        );

        final offlineClient = await _buildSignedInFakeSupabaseClient(
          ownerId: ownerId,
          failureStatusCode: 500,
        );
        final offlineRepository = SupabaseCharacterRepository(
          offlineClient,
          cache,
          pendingWrites,
          _AlwaysOnlineConnectivityChecker(),
        );
        final detail = await offlineRepository.fetchCharacterDetail(
          characterId,
        );

        // Pas de comparaison `expect(detail, expectedDetail)` directe :
        // `CharacterSkillRow`/`CharacterClassFeature`/`CharacterSpellEntry`/
        // `CharacterInventoryItem`/`CharacterDetailClassRow` sont
        // volontairement des classes simples (pas `freezed`, voir leur
        // documentation de classe), sans `==` structurel — deux instances
        // aux mêmes valeurs de champs mais construites séparément (une par
        // le chemin réseau, une par le chemin cache) resteraient donc
        // toujours inégales par identité, même si `CharacterDetail`
        // lui-même est `freezed`. [verifyDetail] vérifie déjà exhaustivement
        // les champs/listes issus de la fixture partagée par les deux
        // chemins ; les assertions scalaires ci-dessous complètent en
        // comparant explicitement les deux résultats entre eux plutôt qu'à
        // des valeurs figées.
        verifyDetail(detail);
        expect(detail.id, expectedDetail.id);
        expect(detail.name, expectedDetail.name);
        expect(detail.xp, expectedDetail.xp);
        expect(detail.currentHp, expectedDetail.currentHp);
        expect(detail.maxHp, expectedDetail.maxHp);
        expect(detail.currencyGp, expectedDetail.currencyGp);
        expect(detail.raceName, expectedDetail.raceName);
        expect(detail.backgroundName, expectedDetail.backgroundName);
        expect(detail.alignmentName, expectedDetail.alignmentName);
        expect(detail.totalLevel, expectedDetail.totalLevel);
      });

      test(
        'échec réseau + aucun cache : relance l\'erreur d\'origine',
        () async {
          final client = await _buildSignedInFakeSupabaseClient(
            ownerId: ownerId,
            throwOnRequest: true,
          );
          final repository = SupabaseCharacterRepository(
            client,
            cache,
            pendingWrites,
            _AlwaysOnlineConnectivityChecker(),
          );

          await expectLater(
            repository.fetchCharacterDetail(characterId),
            throwsA(isA<CharacterFailure>()),
          );
        },
      );

      test('régression commit 7c5ab70 : la requête .select() sur `spells` ne '
          'référence jamais `description` (colonne inexistante sur cette '
          'table — vit dans `translations`), et la description d\'un sort '
          'est bien résolue de bout en bout via `translations` (jamais '
          'vide, jamais confondue avec le nom)', () async {
        String? capturedSpellsSelect;
        const spellDescription = 'Crée une barrière magique invisible.';
        final client = await _buildSignedInFakeSupabaseClient(
          ownerId: ownerId,
          tableRows: tableRows,
          onRequest: (request) {
            if (request.url.pathSegments.last == 'spells') {
              capturedSpellsSelect = request.url.queryParameters['select'];
            }
          },
          // Le double par défaut (`tableRows`) sert la même liste
          // `translations` pour toute résolution (name/description
          // confondus, voir le commentaire au-dessus de `tableRows` en
          // tête de ce fichier) : insuffisant ici pour distinguer un bug
          // où la description proviendrait par erreur de la carte des
          // noms. On route donc explicitement `field_name=description`
          // vers une valeur différente du nom ('Bouclier').
          rowsOverride: (request) {
            if (request.url.pathSegments.last == 'translations' &&
                // PostgREST encode un filtre `.eq('field_name', ...)`
                // sous la forme `field_name=eq.description` — jamais la
                // valeur brute seule.
                request.url.queryParameters['field_name'] == 'eq.description') {
              return [
                {'entity_id': '20', 'value': spellDescription},
              ];
            }
            return null;
          },
        );
        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          _AlwaysOnlineConnectivityChecker(),
        );

        final detail = await repository.fetchCharacterDetail(characterId);

        expect(
          capturedSpellsSelect,
          isNotNull,
          reason:
              'le personnage de la fixture a un sort connu : la '
              'table `spells` doit bien être interrogée',
        );
        expect(
          capturedSpellsSelect,
          isNot(contains('description')),
          reason:
              '`spells` n\'a pas de colonne `description` (vérifié '
              'contre les migrations du dépôt web) — sélectionner cette '
              'colonne directement lève une `PostgrestException` en '
              'production (régression réelle poussée sur `main` par le '
              'commit 7c5ab70, non détectée par la suite de tests '
              "d'alors faute d'assertion sur cette requête).",
        );
        expect(
          detail.spells.single.description,
          spellDescription,
          reason:
              'doit provenir de `translations` '
              '(entity_type=spell, field_name=description), jamais de '
              '`spells.description` (colonne inexistante) ni retomber '
              'silencieusement sur le nom du sort ou une chaîne vide',
        );
      });

      test('régression commit 7c5ab70 (variante `class_features`, non '
          'couverte par le test ci-dessus) : la requête .select() sur '
          '`class_features` ne référence jamais `description` (colonne '
          'inexistante sur cette table — vit dans `translations`, même '
          'principe que `spells`), et la description d\'une aptitude de '
          'classe est bien résolue de bout en bout via `translations` '
          '(jamais vide, jamais confondue avec le nom)', () async {
        String? capturedClassFeaturesSelect;
        const featureDescription =
            'Rend 1d10 + niveau de guerrier points de vie.';
        final client = await _buildSignedInFakeSupabaseClient(
          ownerId: ownerId,
          tableRows: tableRows,
          onRequest: (request) {
            if (request.url.pathSegments.last == 'class_features') {
              capturedClassFeaturesSelect =
                  request.url.queryParameters['select'];
            }
          },
          rowsOverride: (request) {
            if (request.url.pathSegments.last == 'translations' &&
                request.url.queryParameters['field_name'] == 'eq.description') {
              return [
                {'entity_id': '50', 'value': featureDescription},
              ];
            }
            return null;
          },
        );
        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          _AlwaysOnlineConnectivityChecker(),
        );

        final detail = await repository.fetchCharacterDetail(characterId);

        expect(
          capturedClassFeaturesSelect,
          isNotNull,
          reason:
              'le personnage de la fixture a une classe : la table '
              '`class_features` doit bien être interrogée',
        );
        expect(
          capturedClassFeaturesSelect,
          isNot(contains('description')),
          reason:
              '`class_features` n\'a pas de colonne `description` '
              '(vérifié contre les migrations du dépôt web) — la '
              'sélectionner directement lève une `PostgrestException` '
              '(42703) en production : régression réelle poussée sur '
              '`main` par le commit 7c5ab70, faisant échouer *tout* '
              'fetch de fiche pour un personnage classé (repli '
              'silencieux sur un cache périmé, signalée en retour '
              'utilisateur).',
        );
        expect(
          detail.classFeatures.single.description,
          featureDescription,
          reason:
              'doit provenir de `translations` (entity_type='
              'class_feature, field_name=description), jamais de '
              '`class_features.description` (colonne inexistante) ni '
              'retomber silencieusement sur le nom de l\'aptitude ou '
              'une chaîne vide',
        );
      });

      test(
        'isolation par utilisateur : un changement de compte sur le même '
        'appareil ne peut jamais lire l\'entrée de cache d\'un autre joueur',
        () async {
          // Le joueur `owner-1` ouvre sa fiche avec succès réseau : le cache
          // ne contient que 'character_detail:owner-1:char-1'.
          final ownerOneClient = await _buildSignedInFakeSupabaseClient(
            ownerId: ownerId,
            tableRows: tableRows,
          );
          await SupabaseCharacterRepository(
            ownerOneClient,
            cache,
            pendingWrites,
            _AlwaysOnlineConnectivityChecker(),
          ).fetchCharacterDetail(characterId);
          expect(await cache.get(cacheKey), isNotNull);

          // `owner-2` se connecte sur le même appareil, réseau indisponible au
          // moment où il ouvrirait (hypothétiquement) la même route
          // `characterId` : la clé de cache scopée par ownerId ('character_detail:
          // owner-2:char-1') n'existe pas — jamais de repli sur les données
          // d'`owner-1`, l'erreur d'origine doit être relancée telle quelle.
          const otherOwnerId = 'owner-2';
          final ownerTwoClient = await _buildSignedInFakeSupabaseClient(
            ownerId: otherOwnerId,
            throwOnRequest: true,
          );
          final ownerTwoRepository = SupabaseCharacterRepository(
            ownerTwoClient,
            cache,
            pendingWrites,
            _AlwaysOnlineConnectivityChecker(),
          );

          await expectLater(
            ownerTwoRepository.fetchCharacterDetail(characterId),
            throwsA(isA<CharacterFailure>()),
          );
          expect(
            await cache.get('character_detail:$otherOwnerId:$characterId'),
            isNull,
            reason:
                'aucune entrée de cache ne doit jamais exister pour owner-2 : '
                'la clé est scopée par ownerId, pas partagée entre comptes',
          );
          expect(
            await cache.get(cacheKey),
            isNotNull,
            reason:
                "l'entrée d'owner-1 doit rester intacte, jamais écrasée ni "
                'lue par owner-2',
          );
        },
      );
    },
  );

  group('SupabaseCharacterRepository.updateHp/addXp (mode hors-ligne)', () {
    late AppDatabase db;
    late ReferenceDataCache cache;
    late PendingCharacterWriteQueue pendingWrites;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      cache = ReferenceDataCache(db);
      pendingWrites = PendingCharacterWriteQueue(db);
    });

    tearDown(() async {
      await db.close();
    });

    const characterId = 'char-1';
    const ownerId = 'owner-1';

    test('updateHp : connectivité absente -> met en file sans tenter le '
        'réseau, retourne queued', () async {
      // `throwOnRequest: true` : si le repository tentait malgré tout le
      // réseau (bug), ce test échouerait avec une exception inattendue
      // plutôt qu'un faux positif silencieux.
      final client = await _buildSignedInFakeSupabaseClient(
        ownerId: ownerId,
        throwOnRequest: true,
      );
      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        _FakeConnectivityChecker(connected: false),
      );

      final outcome = await repository.updateHp(
        characterId: characterId,
        currentHp: 5,
        temporaryHp: 0,
      );

      expect(outcome, WriteOutcome.queued);
      final pending = await pendingWrites.allForOwner(ownerId);
      expect(pending, hasLength(1));
      expect(pending.single.characterId, characterId);
      expect(pending.single.kind, PendingCharacterWriteKind.hp);
      expect(pending.single.payload, {'currentHp': 5, 'temporaryHp': 0});
    });

    test('addXp : connectivité absente -> met en file sans tenter le réseau, '
        'retourne queued', () async {
      final client = await _buildSignedInFakeSupabaseClient(
        ownerId: ownerId,
        throwOnRequest: true,
      );
      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        _FakeConnectivityChecker(connected: false),
      );

      final outcome = await repository.addXp(
        characterId: characterId,
        newXp: 450,
      );

      expect(outcome, WriteOutcome.queued);
      final pending = await pendingWrites.allForOwner(ownerId);
      expect(pending, hasLength(1));
      expect(pending.single.kind, PendingCharacterWriteKind.xp);
      expect(pending.single.payload, {'newXp': 450});
    });

    test('updateHp : connectivité présente + écriture réussie -> retourne '
        'synced, rien en file', () async {
      final client = await _buildSignedInFakeSupabaseClient(ownerId: ownerId);
      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        _FakeConnectivityChecker(connected: true),
      );

      final outcome = await repository.updateHp(
        characterId: characterId,
        currentHp: 5,
        temporaryHp: 0,
      );

      expect(outcome, WriteOutcome.synced);
      expect(await pendingWrites.allForOwner(ownerId), isEmpty);
    });

    test('addXp : connectivité présente + écriture réussie -> retourne synced, '
        'rien en file', () async {
      final client = await _buildSignedInFakeSupabaseClient(ownerId: ownerId);
      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        _FakeConnectivityChecker(connected: true),
      );

      final outcome = await repository.addXp(
        characterId: characterId,
        newXp: 450,
      );

      expect(outcome, WriteOutcome.synced);
      expect(await pendingWrites.allForOwner(ownerId), isEmpty);
    });

    test('updateHp : connectivité présente + écriture réseau en échec -> '
        'relance l\'erreur normalement, rien en file (jamais un vrai bug '
        'serveur masqué derrière une mise en file silencieuse)', () async {
      final client = await _buildSignedInFakeSupabaseClient(
        ownerId: ownerId,
        failureStatusCode: 500,
      );
      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        _FakeConnectivityChecker(connected: true),
      );

      await expectLater(
        repository.updateHp(
          characterId: characterId,
          currentHp: 5,
          temporaryHp: 0,
        ),
        throwsA(isA<CharacterFailure>()),
      );
      expect(await pendingWrites.allForOwner(ownerId), isEmpty);
    });

    test('addXp : connectivité présente + écriture réseau en échec -> relance '
        'l\'erreur normalement, rien en file', () async {
      final client = await _buildSignedInFakeSupabaseClient(
        ownerId: ownerId,
        failureStatusCode: 500,
      );
      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        _FakeConnectivityChecker(connected: true),
      );

      await expectLater(
        repository.addXp(characterId: characterId, newXp: 450),
        throwsA(isA<CharacterFailure>()),
      );
      expect(await pendingWrites.allForOwner(ownerId), isEmpty);
    });
  });

  group(
    'SupabaseCharacterRepository (écritures de l\'onglet "Inventaire")',
    () {
      late AppDatabase db;
      late ReferenceDataCache cache;
      late PendingCharacterWriteQueue pendingWrites;

      setUp(() {
        db = AppDatabase(NativeDatabase.memory());
        cache = ReferenceDataCache(db);
        pendingWrites = PendingCharacterWriteQueue(db);
      });

      tearDown(() async {
        await db.close();
      });

      const characterId = 'char-1';
      const ownerId = 'owner-1';
      const inventoryId = 'inv-1';

      test('useInventoryItem : connectivité absente -> retourne queued sans '
          'tenter le réseau, jamais mise en file (même règle que castSpell/'
          'useClassFeature)', () async {
        final client = await _buildSignedInFakeSupabaseClient(
          ownerId: ownerId,
          throwOnRequest: true,
        );
        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          _FakeConnectivityChecker(connected: false),
        );

        final outcome = await repository.useInventoryItem(
          characterId: characterId,
          inventoryId: inventoryId,
          newQuantity: 1,
        );

        expect(outcome, WriteOutcome.queued);
        expect(await pendingWrites.allForOwner(ownerId), isEmpty);
      });

      test('useInventoryItem : connectivité présente + écriture réussie -> '
          'synced', () async {
        final client = await _buildSignedInFakeSupabaseClient(ownerId: ownerId);
        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          _FakeConnectivityChecker(connected: true),
        );

        final outcome = await repository.useInventoryItem(
          characterId: characterId,
          inventoryId: inventoryId,
          newQuantity: 0,
        );

        expect(outcome, WriteOutcome.synced);
      });

      test('setInventoryItemEquipped : connectivité présente + écriture '
          'réussie -> synced', () async {
        final client = await _buildSignedInFakeSupabaseClient(ownerId: ownerId);
        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          _FakeConnectivityChecker(connected: true),
        );

        final outcome = await repository.setInventoryItemEquipped(
          characterId: characterId,
          inventoryId: inventoryId,
          equipped: true,
        );

        expect(outcome, WriteOutcome.synced);
      });

      test('removeInventoryItem : connectivité présente + écriture réussie -> '
          'synced', () async {
        final client = await _buildSignedInFakeSupabaseClient(ownerId: ownerId);
        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          _FakeConnectivityChecker(connected: true),
        );

        final outcome = await repository.removeInventoryItem(
          characterId: characterId,
          inventoryId: inventoryId,
        );

        expect(outcome, WriteOutcome.synced);
      });

      test('adjustCurrency : connectivité absente -> retourne queued sans '
          'tenter le réseau, jamais mise en file', () async {
        final client = await _buildSignedInFakeSupabaseClient(
          ownerId: ownerId,
          throwOnRequest: true,
        );
        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          _FakeConnectivityChecker(connected: false),
        );

        final outcome = await repository.adjustCurrency(
          characterId: characterId,
          currency: CurrencyKind.gold,
          newAmount: 42,
        );

        expect(outcome, WriteOutcome.queued);
        expect(await pendingWrites.allForOwner(ownerId), isEmpty);
      });

      test('adjustCurrency : connectivité présente + écriture réussie -> '
          'synced', () async {
        final client = await _buildSignedInFakeSupabaseClient(ownerId: ownerId);
        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          _FakeConnectivityChecker(connected: true),
        );

        final outcome = await repository.adjustCurrency(
          characterId: characterId,
          currency: CurrencyKind.silver,
          newAmount: 12,
        );

        expect(outcome, WriteOutcome.synced);
      });

      test('adjustCurrency : connectivité présente + écriture réseau en échec '
          '-> relance CharacterFailure', () async {
        final client = await _buildSignedInFakeSupabaseClient(
          ownerId: ownerId,
          failureStatusCode: 500,
        );
        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          _FakeConnectivityChecker(connected: true),
        );

        await expectLater(
          repository.adjustCurrency(
            characterId: characterId,
            currency: CurrencyKind.gold,
            newAmount: 1,
          ),
          throwsA(isA<CharacterFailure>()),
        );
      });

      test('addInventoryItem : connectivité présente + écriture réussie -> '
          'synced', () async {
        final client = await _buildSignedInFakeSupabaseClient(ownerId: ownerId);
        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          _FakeConnectivityChecker(connected: true),
        );

        final outcome = await repository.addInventoryItem(
          characterId: characterId,
          itemId: 5,
          quantity: 2,
        );

        expect(outcome, WriteOutcome.synced);
      });

      test('addCustomInventoryItem : connectivité présente + écriture réussie '
          '-> synced', () async {
        final client = await _buildSignedInFakeSupabaseClient(ownerId: ownerId);
        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          _FakeConnectivityChecker(connected: true),
        );

        final outcome = await repository.addCustomInventoryItem(
          characterId: characterId,
          customName: 'Amulette de famille',
          quantity: 1,
        );

        expect(outcome, WriteOutcome.synced);
      });

      test('addReward : connectivité absente -> retourne queued sans tenter le '
          'réseau, jamais mise en file', () async {
        final client = await _buildSignedInFakeSupabaseClient(
          ownerId: ownerId,
          throwOnRequest: true,
        );
        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          _FakeConnectivityChecker(connected: false),
        );

        final outcome = await repository.addReward(
          characterId: characterId,
          newCurrencyTotals: const {CurrencyKind.gold: 50},
          items: const [
            RewardItemDraft(itemId: 5, displayName: 'Dague', quantity: 1),
          ],
        );

        expect(outcome, WriteOutcome.queued);
        expect(await pendingWrites.allForOwner(ownerId), isEmpty);
      });

      test('addReward : connectivité présente, monnaie et objets -> un appel '
          'currency + un appel batché objets, synced', () async {
        final client = await _buildSignedInFakeSupabaseClient(ownerId: ownerId);
        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          _FakeConnectivityChecker(connected: true),
        );

        final outcome = await repository.addReward(
          characterId: characterId,
          newCurrencyTotals: const {
            CurrencyKind.gold: 50,
            CurrencyKind.silver: 5,
          },
          items: const [
            RewardItemDraft(itemId: 5, displayName: 'Dague', quantity: 1),
            RewardItemDraft(
              customName: 'Amulette',
              displayName: 'Amulette',
              quantity: 1,
            ),
          ],
        );

        expect(outcome, WriteOutcome.synced);
      });

      test('addReward : ni monnaie ni objets (les deux vides) -> aucune '
          'écriture, synced quand même (aucun côté indésirable)', () async {
        final client = await _buildSignedInFakeSupabaseClient(
          ownerId: ownerId,
          throwOnRequest: true,
        );
        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          _FakeConnectivityChecker(connected: true),
        );

        final outcome = await repository.addReward(
          characterId: characterId,
          newCurrencyTotals: const {},
          items: const [],
        );

        // Aucun appel réseau émis (throwOnRequest ne se déclenche jamais)
        // -> confirme qu'aucune requête vide n'est envoyée.
        expect(outcome, WriteOutcome.synced);
      });

      test('fetchInventoryCatalog : résout id/nom/catégorie/coût/poids '
          'depuis items+translations', () async {
        final client = await _buildSignedInFakeSupabaseClient(
          ownerId: ownerId,
          tableRows: {
            'items': [
              {
                'id': 1,
                'category': 'arme',
                'weight': 0.5,
                'cost': {'amount': 2, 'currency': 'gp'},
              },
            ],
            'translations': [
              {'entity_id': '1', 'value': 'Dague'},
            ],
          },
        );
        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          _FakeConnectivityChecker(connected: true),
        );

        final catalog = await repository.fetchInventoryCatalog();

        expect(catalog, hasLength(1));
        expect(catalog.single.id, 1);
        expect(catalog.single.name, 'Dague');
        expect(catalog.single.category, 'arme');
        expect(catalog.single.costAmount, 2);
        expect(catalog.single.weight, 0.5);
      });
    },
  );

  group(
    'SupabaseCharacterRepository.updateStoryFields (onglet "Histoire")',
    () {
      late AppDatabase db;
      late ReferenceDataCache cache;
      late PendingCharacterWriteQueue pendingWrites;

      setUp(() {
        db = AppDatabase(NativeDatabase.memory());
        cache = ReferenceDataCache(db);
        pendingWrites = PendingCharacterWriteQueue(db);
      });

      tearDown(() async {
        await db.close();
      });

      const characterId = 'char-1';
      const ownerId = 'owner-1';

      test(
        'connectivité absente -> retourne queued sans tenter le réseau, '
        'jamais mise en file (même règle que useInventoryItem/addReward)',
        () async {
          final client = await _buildSignedInFakeSupabaseClient(
            ownerId: ownerId,
            throwOnRequest: true,
          );
          final repository = SupabaseCharacterRepository(
            client,
            cache,
            pendingWrites,
            _FakeConnectivityChecker(connected: false),
          );

          final outcome = await repository.updateStoryFields(
            characterId: characterId,
            appearanceText: 'Cheveux argentés.',
          );

          expect(outcome, WriteOutcome.queued);
          expect(await pendingWrites.allForOwner(ownerId), isEmpty);
        },
      );

      test('connectivité présente + écriture réussie -> synced, un seul UPDATE '
          'sur `characters`', () async {
        var updateRequestCount = 0;
        final client = await _buildSignedInFakeSupabaseClient(
          ownerId: ownerId,
          onRequest: (request) {
            if (request.url.pathSegments.last == 'characters' &&
                request.method == 'PATCH') {
              updateRequestCount++;
            }
          },
        );
        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          _FakeConnectivityChecker(connected: true),
        );

        final outcome = await repository.updateStoryFields(
          characterId: characterId,
          appearanceText: 'Cheveux argentés.',
          traitsText: "Curieuse jusqu'à l'imprudence.",
        );

        expect(outcome, WriteOutcome.synced);
        expect(
          updateRequestCount,
          1,
          reason:
              'les 9 colonnes appartiennent à la même ligne `characters` '
              ': un seul UPDATE doit couvrir les 9, jamais un par champ',
        );
      });

      test(
        'un champ vidé (`null`) est coalescé vers \'\' dans le payload envoyé, '
        'jamais un `null` littéral (violerait la contrainte NOT NULL de '
        '`characters.*_text`)',
        () async {
          String? capturedBody;
          final client = await _buildSignedInFakeSupabaseClient(
            ownerId: ownerId,
            onRequest: (request) {
              if (request.url.pathSegments.last == 'characters' &&
                  request.method == 'PATCH') {
                capturedBody = request.body;
              }
            },
          );
          final repository = SupabaseCharacterRepository(
            client,
            cache,
            pendingWrites,
            _FakeConnectivityChecker(connected: true),
          );

          final outcome = await repository.updateStoryFields(
            characterId: characterId,
            appearanceText: 'Cheveux argentés.',
            // Tous les 8 autres champs restent `null` (vidés par le joueur).
          );

          expect(outcome, WriteOutcome.synced);
          expect(capturedBody, isNotNull);
          final payload = jsonDecode(capturedBody!) as Map<String, dynamic>;
          expect(payload['appearance_text'], 'Cheveux argentés.');
          expect(payload['traits_text'], '');
          expect(payload['ideals_text'], '');
          expect(payload['bonds_text'], '');
          expect(payload['flaws_text'], '');
          expect(payload['backstory_text'], '');
          expect(payload['allies_text'], '');
          expect(payload['features_text'], '');
          expect(payload['treasure_text'], '');
          expect(
            payload.values,
            isNot(contains(null)),
            reason:
                'aucune des 9 colonnes ne doit jamais recevoir `null` '
                'littéral (colonnes `not null default \'\'` en base)',
          );
        },
      );

      test('connectivité présente + écriture réseau en échec -> relance '
          'CharacterFailure, rien en file', () async {
        final client = await _buildSignedInFakeSupabaseClient(
          ownerId: ownerId,
          failureStatusCode: 500,
        );
        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          _FakeConnectivityChecker(connected: true),
        );

        await expectLater(
          repository.updateStoryFields(
            characterId: characterId,
            appearanceText: 'Cheveux argentés.',
          ),
          throwsA(isA<CharacterFailure>()),
        );
        expect(await pendingWrites.allForOwner(ownerId), isEmpty);
      });
    },
  );

  group('PendingCharacterWriteSyncer.sync', () {
    late AppDatabase db;
    late PendingCharacterWriteQueue pendingWrites;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      pendingWrites = PendingCharacterWriteQueue(db);
    });

    tearDown(() async {
      await db.close();
    });

    const characterId = 'char-1';
    const ownerId = 'owner-1';

    test('écriture réseau réussie -> supprime l\'entrée en attente et retourne '
        'le characterId synchronisé', () async {
      await pendingWrites.enqueue(
        characterId: characterId,
        ownerId: ownerId,
        kind: PendingCharacterWriteKind.hp,
        payload: {'currentHp': 12, 'temporaryHp': 0},
      );
      final client = await _buildSignedInFakeSupabaseClient(ownerId: ownerId);
      final syncer = PendingCharacterWriteSyncer(client, pendingWrites);

      final synced = await syncer.sync();

      expect(synced, {characterId});
      expect(await pendingWrites.allForOwner(ownerId), isEmpty);
    });

    test('écriture réseau en échec -> conserve l\'entrée pour une prochaine '
        'tentative, ne l\'inclut pas dans le résultat', () async {
      await pendingWrites.enqueue(
        characterId: characterId,
        ownerId: ownerId,
        kind: PendingCharacterWriteKind.xp,
        payload: {'newXp': 900},
      );
      final client = await _buildSignedInFakeSupabaseClient(
        ownerId: ownerId,
        failureStatusCode: 500,
      );
      final syncer = PendingCharacterWriteSyncer(client, pendingWrites);

      final synced = await syncer.sync();

      expect(synced, isEmpty);
      final pending = await pendingWrites.allForOwner(ownerId);
      expect(pending, hasLength(1));
      expect(pending.single.characterId, characterId);
    });

    test('aucun utilisateur connecté -> ne tente rien, retourne un ensemble '
        'vide', () async {
      await pendingWrites.enqueue(
        characterId: characterId,
        ownerId: ownerId,
        kind: PendingCharacterWriteKind.hp,
        payload: {'currentHp': 12, 'temporaryHp': 0},
      );
      final anonymousClient = SupabaseClient(
        'https://fake.supabase.test',
        'fake-anon-key',
      );
      final syncer = PendingCharacterWriteSyncer(
        anonymousClient,
        pendingWrites,
      );

      final synced = await syncer.sync();

      expect(synced, isEmpty);
      expect(await pendingWrites.allForOwner(ownerId), hasLength(1));
    });

    test('isolation par utilisateur : ne synchronise jamais une écriture en '
        'attente d\'un autre compte que celui actuellement connecté', () async {
      const otherCharacterId = 'char-2';
      const otherOwnerId = 'owner-2';
      await pendingWrites.enqueue(
        characterId: characterId,
        ownerId: ownerId,
        kind: PendingCharacterWriteKind.hp,
        payload: {'currentHp': 12, 'temporaryHp': 0},
      );
      await pendingWrites.enqueue(
        characterId: otherCharacterId,
        ownerId: otherOwnerId,
        kind: PendingCharacterWriteKind.hp,
        payload: {'currentHp': 30, 'temporaryHp': 0},
      );
      // Connecté en tant qu'owner-1 uniquement.
      final client = await _buildSignedInFakeSupabaseClient(ownerId: ownerId);
      final syncer = PendingCharacterWriteSyncer(client, pendingWrites);

      final synced = await syncer.sync();

      expect(synced, {characterId});
      expect(
        await pendingWrites.allForOwner(otherOwnerId),
        hasLength(1),
        reason:
            "l'entrée d'owner-2 doit rester intacte, jamais synchronisée "
            'ni supprimée par la session d\'owner-1',
      );
    });
  });
}

/// Toujours "connecté" — utilisé par les groupes de tests qui n'exercent pas
/// le comportement hors-ligne lui-même (ex. le cache de secours de
/// `fetchCharacterDetail`), pour que `updateHp`/`addXp` (quand appelées)
/// suivent le chemin réseau nominal.
class _AlwaysOnlineConnectivityChecker implements ConnectivityChecker {
  @override
  Future<bool> hasConnection() async => true;

  @override
  Stream<bool> get onConnectivityRestored => const Stream.empty();
}

/// Double entièrement contrôlé par le test — voir le groupe "mode
/// hors-ligne" ci-dessus.
class _FakeConnectivityChecker implements ConnectivityChecker {
  _FakeConnectivityChecker({required this.connected});

  final bool connected;

  @override
  Future<bool> hasConnection() async => connected;

  @override
  Stream<bool> get onConnectivityRestored => const Stream.empty();
}

/// Fabrique un `SupabaseClient` réel, mais dont le transport HTTP est
/// entièrement fabriqué (`MockClient`), authentifié en mémoire (sans requête
/// réseau) pour l'utilisateur [ownerId] — voir la doc de classe en tête de ce
/// fichier pour le rationale des deux mécanismes (transport HTTP fabriqué +
/// authentification en mémoire via `recoverSession`).
///
/// [tableRows] route chaque requête par le dernier segment de son chemin
/// (`/rest/v1/<table>`), sans tenir compte du reste de la query string —
/// même principe et mêmes limites que
/// `character_creation_repository_test.dart::_buildFakeSupabaseClient`, dont
/// la documentation détaille [throwOnRequest]/[failureStatusCode].
Future<SupabaseClient> _buildSignedInFakeSupabaseClient({
  required String ownerId,
  Map<String, List<Map<String, dynamic>>> tableRows = const {},
  bool throwOnRequest = false,
  int? failureStatusCode,
  // Observateur best-effort de chaque requête sortante — sert par ex. à
  // capturer la query string `select` réellement envoyée pour une table
  // donnée (voir le test de non-régression "la requête .select() sur
  // `spells` ne référence que des colonnes réelles" ci-dessous), sans
  // avoir à dupliquer tout ce double pour un seul test.
  void Function(http.Request request)? onRequest,
  // Permet à un test de router une requête précise vers des lignes
  // différentes de [tableRows] selon sa query string (ex. `field_name` sur
  // `translations`, que le routage par défaut ci-dessous ignore
  // volontairement — voir la doc de ce double). Retourne `null` pour
  // retomber sur [tableRows] sans rien changer au comportement des tests
  // existants qui ne fournissent pas ce paramètre.
  List<Map<String, dynamic>>? Function(http.Request request)? rowsOverride,
}) async {
  Future<http.Response> handler(http.Request request) async {
    onRequest?.call(request);
    if (throwOnRequest) {
      throw const SocketException('Pas de réseau (double de test).');
    }
    if (failureStatusCode != null) {
      return http.Response(
        jsonEncode({
          'message': 'Erreur simulée (double de test).',
          'code': 'PGRST000',
        }),
        failureStatusCode,
        request: request,
        headers: {'content-type': 'application/json'},
      );
    }
    final table = request.url.pathSegments.last;
    final rows =
        rowsOverride?.call(request) ??
        tableRows[table] ??
        const <Map<String, dynamic>>[];
    return http.Response(
      jsonEncode(rows),
      200,
      request: request,
      headers: {'content-type': 'application/json'},
    );
  }

  final client = SupabaseClient(
    'https://fake.supabase.test',
    'fake-anon-key',
    httpClient: MockClient(handler),
    postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );

  // Authentifie [client] sans jamais passer par `MockClient` : un
  // `access_token` qui n'est pas un JWT valide fait échouer silencieusement
  // le décodage de sa date d'expiration côté package `gotrue`
  // (`Session._expiresAt`), ce qui fait retomber `Session.isExpired` sur
  // `false` — `recoverSession` prend alors la branche "session non expirée"
  // et s'exécute entièrement en mémoire (voir la doc de classe).
  await client.auth.recoverSession(
    jsonEncode({
      'access_token': 'fake-access-token-$ownerId',
      'token_type': 'bearer',
      'user': {'id': ownerId},
    }),
  );

  return client;
}
