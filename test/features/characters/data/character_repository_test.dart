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
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/characters/domain/reward_item_draft.dart';
import 'package:personnages/features/characters/domain/spell_grant_source.dart';
import 'package:personnages/features/characters/domain/spell_status_formatter.dart';
import 'package:personnages/features/characters/domain/weapon_slot.dart';
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

      test('classFeatures : tri alphabétique (demande utilisateur, '
          '2026-10-03), pas par niveau d\'acquisition', () async {
        // Copie locale de `tableRows` (jamais mutée en place : les deux
        // clés ci-dessous sont réaffectées à de nouvelles listes) pour ne
        // pas affecter les autres tests de ce groupe qui réutilisent la
        // même fixture partagée.
        final features2ndRows =
            Map<String, List<Map<String, dynamic>>>.from(tableRows)..addAll({
              'class_features': [
                {
                  'id': 50,
                  'class_id': 2,
                  'level': 3,
                  'uses_per_rest': {'amount': 2, 'rest_type': 'repos_court'},
                },
                // Niveau 5 (postérieure à "Deuxième souffle", niveau 3), mais
                // son nom la place AVANT alphabétiquement — prouve que
                // l'ordre final est par nom, pas par niveau d'acquisition.
                {'id': 51, 'class_id': 2, 'level': 5},
              ],
              'translations': [
                ...tableRows['translations']!,
                {'entity_id': '51', 'value': 'Action surhumaine'},
              ],
            });
        final client = await _buildSignedInFakeSupabaseClient(
          ownerId: ownerId,
          tableRows: features2ndRows,
        );
        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          _AlwaysOnlineConnectivityChecker(),
        );

        final detail = await repository.fetchCharacterDetail(characterId);

        expect(detail.classFeatures.map((f) => f.name), [
          'Action surhumaine',
          'Deuxième souffle',
        ]);
      });

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

    test(
      'updateHp : connectivité présente mais requête réseau qui expire '
      '(dette D12) -> met en file comme une absence de connectivité, '
      'retourne queued sans lever d\'exception',
      () async {
        final client = await _buildSignedInFakeSupabaseClient(
          ownerId: ownerId,
          throwTimeoutOnRequest: true,
        );
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

        expect(outcome, WriteOutcome.queued);
        final pending = await pendingWrites.allForOwner(ownerId);
        expect(pending, hasLength(1));
        expect(pending.single.kind, PendingCharacterWriteKind.hp);
        expect(pending.single.payload, {'currentHp': 5, 'temporaryHp': 0});
      },
    );

    test(
      'addXp : connectivité présente mais requête réseau qui expire '
      '(dette D12) -> met en file comme une absence de connectivité, '
      'retourne queued sans lever d\'exception',
      () async {
        final client = await _buildSignedInFakeSupabaseClient(
          ownerId: ownerId,
          throwTimeoutOnRequest: true,
        );
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

        expect(outcome, WriteOutcome.queued);
        final pending = await pendingWrites.allForOwner(ownerId);
        expect(pending, hasLength(1));
        expect(pending.single.kind, PendingCharacterWriteKind.xp);
        expect(pending.single.payload, {'newXp': 450});
      },
    );
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

      test(
        'setInventoryItemEquipped(equipped: true) : payload sans la clé '
        '`weapon_slot` (armure/bouclier équipé, jamais un set d\'arme)',
        () async {
          String? capturedBody;
          final client = await _buildSignedInFakeSupabaseClient(
            ownerId: ownerId,
            onRequest: (request) {
              if (request.url.pathSegments.last == 'character_inventory' &&
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

          final outcome = await repository.setInventoryItemEquipped(
            characterId: characterId,
            inventoryId: inventoryId,
            equipped: true,
          );

          expect(outcome, WriteOutcome.synced);
          expect(capturedBody, isNotNull);
          final payload = jsonDecode(capturedBody!) as Map<String, dynamic>;
          expect(payload, {'equipped': true});
          expect(
            payload.containsKey('weapon_slot'),
            isFalse,
            reason:
                'équiper une armure/un bouclier ne doit jamais envoyer '
                '`weapon_slot` (réservé aux armes via equipWeaponToSlot)',
          );
        },
      );

      test('setInventoryItemEquipped(equipped: false) : payload avec '
          '`weapon_slot: null` (déséquiper efface le set d\'arme)', () async {
        String? capturedBody;
        final client = await _buildSignedInFakeSupabaseClient(
          ownerId: ownerId,
          onRequest: (request) {
            if (request.url.pathSegments.last == 'character_inventory' &&
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

        final outcome = await repository.setInventoryItemEquipped(
          characterId: characterId,
          inventoryId: inventoryId,
          equipped: false,
        );

        expect(outcome, WriteOutcome.synced);
        expect(capturedBody, isNotNull);
        final payload = jsonDecode(capturedBody!) as Map<String, dynamic>;
        expect(payload, {'equipped': false, 'weapon_slot': null});
      });

      test('equipWeaponToSlot : connectivité absente -> retourne queued sans '
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

        final outcome = await repository.equipWeaponToSlot(
          characterId: characterId,
          inventoryId: inventoryId,
          slot: WeaponSlot.principal,
        );

        expect(outcome, WriteOutcome.queued);
        expect(await pendingWrites.allForOwner(ownerId), isEmpty);
      });

      test('equipWeaponToSlot : connectivité présente + écriture réussie -> '
          'synced', () async {
        final client = await _buildSignedInFakeSupabaseClient(ownerId: ownerId);
        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          _FakeConnectivityChecker(connected: true),
        );

        final outcome = await repository.equipWeaponToSlot(
          characterId: characterId,
          inventoryId: inventoryId,
          slot: WeaponSlot.secondary,
        );

        expect(outcome, WriteOutcome.synced);
      });

      test('equipWeaponToSlot : payload exactement `{equipped: true, '
          'weapon_slot: <slot>}`', () async {
        String? capturedBody;
        final client = await _buildSignedInFakeSupabaseClient(
          ownerId: ownerId,
          onRequest: (request) {
            if (request.url.pathSegments.last == 'character_inventory' &&
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

        final outcome = await repository.equipWeaponToSlot(
          characterId: characterId,
          inventoryId: inventoryId,
          slot: WeaponSlot.secondary,
        );

        expect(outcome, WriteOutcome.synced);
        expect(capturedBody, isNotNull);
        final payload = jsonDecode(capturedBody!) as Map<String, dynamic>;
        expect(payload, {
          'equipped': true,
          'weapon_slot': WeaponSlot.secondary.value,
        });
      });

      test('setInventoryItemAttuned : connectivité présente + écriture '
          'réussie -> synced', () async {
        final client = await _buildSignedInFakeSupabaseClient(ownerId: ownerId);
        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          _FakeConnectivityChecker(connected: true),
        );

        final outcome = await repository.setInventoryItemAttuned(
          characterId: characterId,
          inventoryId: inventoryId,
          attuned: true,
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

      test(
        'fetchInventoryCatalog : omet une arme naturelle de race (jamais '
        'ajoutable manuellement, voir ItemRowMapper.isNaturalWeapon)',
        () async {
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
                {
                  'id': 120,
                  'category': 'arme',
                  'weight': 0,
                  'cost': null,
                  'weapon_properties': {
                    'properties': ['à deux mains', 'naturelle'],
                  },
                },
              ],
              'translations': [
                {'entity_id': '1', 'value': 'Dague'},
                {'entity_id': '120', 'value': 'Griffes félines'},
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
          expect(catalog.single.name, 'Dague');
        },
      );
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

      test('addJournalEntry : connectivité absente -> retourne queued sans '
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

        final outcome = await repository.addJournalEntry(
          characterId: characterId,
          body: 'Note de séance.',
        );

        expect(outcome, WriteOutcome.queued);
        expect(await pendingWrites.allForOwner(ownerId), isEmpty);
      });

      test('addJournalEntry : connectivité présente + écriture réussie -> '
          'synced', () async {
        final client = await _buildSignedInFakeSupabaseClient(ownerId: ownerId);
        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          _FakeConnectivityChecker(connected: true),
        );

        final outcome = await repository.addJournalEntry(
          characterId: characterId,
          body: 'Note de séance.',
        );

        expect(outcome, WriteOutcome.synced);
      });

      test('updateJournalEntry : connectivité présente + écriture réussie '
          '-> synced', () async {
        final client = await _buildSignedInFakeSupabaseClient(ownerId: ownerId);
        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          _FakeConnectivityChecker(connected: true),
        );

        final outcome = await repository.updateJournalEntry(
          characterId: characterId,
          entryId: 'entry-1',
          body: 'Note modifiée.',
        );

        expect(outcome, WriteOutcome.synced);
      });

      test('removeJournalEntry : connectivité présente + écriture réussie '
          '-> synced', () async {
        final client = await _buildSignedInFakeSupabaseClient(ownerId: ownerId);
        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          _FakeConnectivityChecker(connected: true),
        );

        final outcome = await repository.removeJournalEntry(
          characterId: characterId,
          entryId: 'entry-1',
        );

        expect(outcome, WriteOutcome.synced);
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
      final syncer = PendingCharacterWriteSyncer(
        client,
        pendingWrites,
        ReferenceDataCache(db),
      );

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
      final syncer = PendingCharacterWriteSyncer(
        client,
        pendingWrites,
        ReferenceDataCache(db),
      );

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
        ReferenceDataCache(db),
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
      final syncer = PendingCharacterWriteSyncer(
        client,
        pendingWrites,
        ReferenceDataCache(db),
      );

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

  group('SupabaseCharacterRepository.fetchCharacterDetail (sorts de '
      'sous-classe)', () {
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

    Map<String, List<Map<String, dynamic>>> clericRows({
      int level = 5,
      int? subclassId = 30,
    }) => {
      'characters': [
        {
          'id': characterId,
          'name': 'Soren',
          'xp': 0,
          'current_hp': 10,
          'max_hp': 10,
          'temporary_hp': 0,
          'race_id': null,
          'character_classes': [
            {
              'class_id': 2,
              'subclass_id': subclassId,
              'level': level,
              'is_primary': true,
              'classes': {'saving_throw_proficiencies': [], 'hit_die': 8},
            },
          ],
          'character_spells': [
            {'spell_id': 20, 'status': 'connu', 'is_favorite': false},
            {'spell_id': 22, 'status': 'connu', 'is_favorite': true},
          ],
        },
      ],
      'translations': [
        {'entity_id': '2', 'value': 'Clerc'},
        {'entity_id': '30', 'value': 'Domaine de la Vie'},
        {'entity_id': '20', 'value': 'Bouclier'},
        {'entity_id': '21', 'value': 'Bénédiction'},
        {'entity_id': '22', 'value': 'Soins'},
        {'entity_id': '23', 'value': 'Revigorer'},
        {'entity_id': '24', 'value': 'Protection contre la mort'},
      ],
      'subclass_spells': [
        {'subclass_id': 30, 'spell_id': 21, 'class_level': 1},
        {'subclass_id': 30, 'spell_id': 22, 'class_level': 3},
        {'subclass_id': 30, 'spell_id': 23, 'class_level': 5},
        {'subclass_id': 30, 'spell_id': 24, 'class_level': 7},
      ],
      'spells': [
        for (final id in [20, 21, 22, 23, 24])
          {'id': id, 'level': 1 + (id - 20) ~/ 2, 'school': 'évocation'},
      ],
    };

    // Le double ignore la query string : on ne renvoie pour `spells` que les
    // ids réellement demandés (`id=in.(..)`), comme le vrai PostgREST — sinon
    // le sort de niveau 7 (non atteint) reviendrait à tort.
    List<Map<String, dynamic>>? onlyRequestedSpells(
      http.Request request,
      Map<String, List<Map<String, dynamic>>> rows,
    ) {
      if (request.url.pathSegments.last != 'spells') return null;
      final filter = request.url.queryParameters['id'] ?? '';
      final wanted = RegExp(r'\d+')
          .allMatches(filter)
          .map((m) => int.parse(m.group(0)!))
          .toSet();
      return [
        for (final row in rows['spells']!)
          if (wanted.contains(row['id'])) row,
      ];
    }

    Future<SupabaseCharacterRepository> repositoryFor(
      Map<String, List<Map<String, dynamic>>> rows,
    ) async => SupabaseCharacterRepository(
      await _buildSignedInFakeSupabaseClient(
        ownerId: ownerId,
        tableRows: rows,
        rowsOverride: (request) => onlyRequestedSpells(request, rows),
      ),
      cache,
      pendingWrites,
      _AlwaysOnlineConnectivityChecker(),
    );

    void verifyGranted(dynamic detail) {
      final byName = {for (final spell in detail.spells) spell.name: spell};
      expect(byName.keys.toSet(), {
        'Bouclier',
        'Bénédiction',
        'Soins',
        'Revigorer',
      });
      // Sort de domaine sans ligne character_spells : dérivé pur.
      expect(byName['Bénédiction'].grantSource, SpellGrantSource.domain);
      expect(byName['Bénédiction'].status, 'préparé');
      expect(byName['Bénédiction'].isPersisted, isFalse);
      // Sort choisi ET accordé : une seule entrée, favori conservé.
      expect(byName['Soins'].grantSource, SpellGrantSource.domain);
      expect(byName['Soins'].isPersisted, isTrue);
      expect(byName['Soins'].isFavorite, isTrue);
      expect(byName['Revigorer'].grantSource, SpellGrantSource.domain);
      // Sort ordinaire inchangé, jamais compté comme préparé.
      expect(byName['Bouclier'].grantSource, isNull);
      expect(byName['Bouclier'].status, 'connu');
      expect(detail.preparedSpellCount, 0);
    }

    test('dérive les sorts de domaine atteints (niveau de classe 5, pas 7) '
        'sans doublon', () async {
      final repository = await repositoryFor(clericRows());
      verifyGranted(await repository.fetchCharacterDetail(characterId));
    });

    test('hors ligne : le cache restitue les mêmes sorts accordés', () async {
      await (await repositoryFor(clericRows()))
          .fetchCharacterDetail(characterId);

      final offline = SupabaseCharacterRepository(
        await _buildSignedInFakeSupabaseClient(
          ownerId: ownerId,
          failureStatusCode: 500,
        ),
        cache,
        pendingWrites,
        _AlwaysOnlineConnectivityChecker(),
      );
      verifyGranted(await offline.fetchCharacterDetail(characterId));
    });

    test('sans sous-classe : aucune requête subclass_spells, aucun sort '
        'accordé', () async {
      final requestedTables = <String>[];
      final rows = clericRows(subclassId: null);
      final repository = SupabaseCharacterRepository(
        await _buildSignedInFakeSupabaseClient(
          ownerId: ownerId,
          tableRows: rows,
          onRequest: (request) =>
              requestedTables.add(request.url.pathSegments.last),
          rowsOverride: (request) => onlyRequestedSpells(request, rows),
        ),
        cache,
        pendingWrites,
        _AlwaysOnlineConnectivityChecker(),
      );

      final detail = await repository.fetchCharacterDetail(characterId);

      expect(requestedTables, isNot(contains('subclass_spells')));
      expect(detail.grantedSpells, isEmpty);
      expect(detail.spells.map((spell) => spell.name).toSet(), {
        'Bouclier',
        'Soins',
      });
    });

    test('un ancien cache sans subclassSpellRows ne plante pas', () async {
      final repository = await repositoryFor(clericRows());
      await repository.fetchCharacterDetail(characterId);
      final key = 'character_detail:$ownerId:$characterId';
      final payload = Map<String, dynamic>.from(
        await cache.get(key) as Map<String, dynamic>,
      )..remove('subclassSpellRows');
      await cache.put(key, payload);

      final offline = SupabaseCharacterRepository(
        await _buildSignedInFakeSupabaseClient(
          ownerId: ownerId,
          failureStatusCode: 500,
        ),
        cache,
        pendingWrites,
        _AlwaysOnlineConnectivityChecker(),
      );
      final detail = await offline.fetchCharacterDetail(characterId);

      expect(detail.grantedSpells, isEmpty);
    });
  });

  group('SupabaseCharacterRepository.fetchCharacterDetail (sorts des classes '
      'à sorts connus)', () {
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
    const cacheKey = 'character_detail:$ownerId:$characterId';
    const bardeId = 1;
    const clercId = 2;

    // 20 : sort de Barde 'connu'. 21 : sort de Clerc 'connu'. 22 : sort
    // 'préparé' sans origine. 23 : sort de Barde passé à 'préparé' par le
    // joueur. 24 : sort mineur. 25 : sort inné, sans origine.
    Map<String, List<Map<String, dynamic>>> rowsFor(List<int> classIds) => {
      'characters': [
        {
          'id': characterId,
          'name': 'Lia',
          'xp': 0,
          'current_hp': 10,
          'max_hp': 10,
          'temporary_hp': 0,
          'race_id': null,
          'character_classes': [
            for (final classId in classIds)
              {
                'class_id': classId,
                'subclass_id': null,
                'level': 3,
                'is_primary': classId == classIds.first,
                'classes': {'saving_throw_proficiencies': [], 'hit_die': 8},
              },
          ],
          'character_spells': [
            {
              'spell_id': 20,
              'status': 'connu',
              'is_favorite': false,
              'source_class_id': bardeId,
            },
            {
              'spell_id': 21,
              'status': 'connu',
              'is_favorite': false,
              'source_class_id': clercId,
            },
            {
              'spell_id': 22,
              'status': 'préparé',
              'is_favorite': false,
              'source_class_id': null,
            },
            {
              'spell_id': 23,
              'status': 'préparé',
              'is_favorite': false,
              'source_class_id': bardeId,
            },
            {
              'spell_id': 24,
              'status': 'connu',
              'is_favorite': false,
              'source_class_id': bardeId,
            },
            {
              'spell_id': 25,
              'status': 'inné',
              'is_favorite': false,
              'source_class_id': null,
            },
          ],
        },
      ],
      'translations': [
        {'entity_id': '1', 'value': 'Barde'},
        {'entity_id': '2', 'value': 'Clerc'},
        for (final id in [20, 21, 22, 23, 24, 25])
          {'entity_id': '$id', 'value': 'S$id'},
      ],
      'spells': [
        for (final id in [20, 21, 22, 23, 25])
          {'id': id, 'level': 1, 'school': ''},
        {'id': 24, 'level': 0, 'school': ''},
      ],
    };

    Future<SupabaseCharacterRepository> online(
      Map<String, List<Map<String, dynamic>>> rows, {
      void Function(http.Request request)? onRequest,
    }) async => SupabaseCharacterRepository(
      await _buildSignedInFakeSupabaseClient(
        ownerId: ownerId,
        tableRows: rows,
        onRequest: onRequest,
      ),
      cache,
      pendingWrites,
      _AlwaysOnlineConnectivityChecker(),
    );

    Future<SupabaseCharacterRepository> offline() async =>
        SupabaseCharacterRepository(
          await _buildSignedInFakeSupabaseClient(
            ownerId: ownerId,
            failureStatusCode: 500,
          ),
          cache,
          pendingWrites,
          _AlwaysOnlineConnectivityChecker(),
        );

    /// Réécrit le cache comme l'aurait laissé une version antérieure à la
    /// lecture de `source_class_id`.
    Future<void> stripSourceClassIdFromCache() async {
      final payload = Map<String, dynamic>.from(
        await cache.get(cacheKey) as Map<String, dynamic>,
      );
      final row = Map<String, dynamic>.from(payload['row'] as Map);
      row['character_spells'] = [
        for (final spellRow in row['character_spells'] as List)
          Map<String, dynamic>.from(spellRow as Map)..remove('source_class_id'),
      ];
      payload['row'] = row;
      await cache.put(cacheKey, payload);
    }

    Map<String, bool> requiresByName(CharacterDetail detail) => {
      for (final spell in detail.spells) spell.name: spell.requiresPreparation,
    };
    Map<String, bool> castableByName(CharacterDetail detail) => {
      for (final spell in detail.spells)
        spell.name: SpellStatusFormatter.canCast(spell),
    };

    void verifyMixed(CharacterDetail detail) {
      expect(requiresByName(detail), {
        'S20': false,
        'S21': true,
        'S22': true,
        'S23': false,
        'S24': false,
        'S25': true,
      });
      expect(castableByName(detail), {
        'S20': true,
        'S21': false,
        'S22': true,
        'S23': true,
        'S24': true,
        'S25': true,
      });
      // S22 seul : S23 (Barde, 'préparé' en base) ne compte pas.
      expect(detail.preparedSpellCount, 1);
      final byName = {for (final spell in detail.spells) spell.name: spell};
      expect(SpellStatusFormatter.canTogglePrepared(byName['S20']!), isFalse);
      expect(SpellStatusFormatter.canTogglePrepared(byName['S23']!), isFalse);
      expect(SpellStatusFormatter.canTogglePrepared(byName['S21']!), isTrue);
      // Sort inné : ni bascule ni sous-titre, comme avant.
      expect(SpellStatusFormatter.canTogglePrepared(byName['S25']!), isFalse);
      expect(SpellStatusFormatter.subtitle(byName['S25']!), isNull);
    }

    test(
      'le select de la fiche relit character_spells.source_class_id',
      () async {
        String? select;
        final repository = await online(
          rowsFor([bardeId]),
          onRequest: (request) {
            if (request.url.pathSegments.last == 'characters') {
              select = request.url.queryParameters['select'];
            }
          },
        );

        await repository.fetchCharacterDetail(characterId);

        expect(
          select!.replaceAll(RegExp(r'\s+'), ''),
          contains(
            'character_spells(spell_id,status,is_favorite,source_class_id,',
          ),
        );
      },
    );

    test('Barde seul : tous les sorts sont lançables sans préparation, aucun '
        'n\'est compté comme préparé', () async {
      final detail = await (await online(rowsFor([bardeId])))
          .fetchCharacterDetail(characterId);

      expect(requiresByName(detail).values, everyElement(isFalse));
      expect(castableByName(detail).values, everyElement(isTrue));
      expect(
        detail.spells.any(SpellStatusFormatter.canTogglePrepared),
        isFalse,
      );
      expect(detail.preparedSpellCount, 0);
      expect(detail.preparedSpellLimit, isNull);
    });

    test(
      'Clerc seul : rien ne change, un sort "connu" reste à préparer',
      () async {
        final detail = await (await online(rowsFor([clercId])))
            .fetchCharacterDetail(characterId);

        // Les origines "Barde" (classe absente du personnage) sont ignorées.
        expect(requiresByName(detail).values, everyElement(isTrue));
        expect(castableByName(detail)['S20'], isFalse);
        expect(castableByName(detail)['S21'], isFalse);
        expect(detail.preparedSpellCount, 2);
      },
    );

    test('Barde + Clerc : tranché par source_class_id, origine inconnue à '
        'préparer', () async {
      verifyMixed(
        await (await online(rowsFor([bardeId, clercId])))
            .fetchCharacterDetail(characterId),
      );
    });

    test('hors ligne : le cache restitue la même dérivation', () async {
      await (await online(rowsFor([bardeId, clercId])))
          .fetchCharacterDetail(characterId);

      verifyMixed(await (await offline()).fetchCharacterDetail(characterId));
    });

    test('ancien cache sans source_class_id, Barde + Clerc : tout sort '
        'retombe sur "origine inconnue" (à préparer), sans erreur', () async {
      await (await online(rowsFor([bardeId, clercId])))
          .fetchCharacterDetail(characterId);
      await stripSourceClassIdFromCache();

      final detail = await (await offline()).fetchCharacterDetail(characterId);

      expect(requiresByName(detail).values, everyElement(isTrue));
      // Comportement d'avant le correctif : S20/S21 'connu' non lançables.
      expect(castableByName(detail)['S20'], isFalse);
      expect(detail.preparedSpellCount, 2);
    });

    test('ancien cache sans source_class_id, Barde seul : la classe du '
        'personnage suffit', () async {
      await (await online(rowsFor([bardeId])))
          .fetchCharacterDetail(characterId);
      await stripSourceClassIdFromCache();

      final detail = await (await offline()).fetchCharacterDetail(characterId);

      expect(requiresByName(detail).values, everyElement(isFalse));
      expect(castableByName(detail).values, everyElement(isTrue));
    });

    test('lignes en double pour un même sort (aucune contrainte d\'unicité) : '
        'une origine "Barde" suffit, quel que soit l\'ordre', () async {
      for (final reversed in [false, true]) {
        final rows = rowsFor([bardeId, clercId]);
        final duplicates = [
          {
            'spell_id': 20,
            'status': 'connu',
            'is_favorite': false,
            'source_class_id': clercId,
          },
          {
            'spell_id': 20,
            'status': 'connu',
            'is_favorite': false,
            'source_class_id': null,
          },
          {
            'spell_id': 20,
            'status': 'connu',
            'is_favorite': false,
            'source_class_id': bardeId,
          },
        ];
        rows['characters']!.single['character_spells'] = reversed
            ? duplicates.reversed.toList()
            : duplicates;

        final detail = await (await online(rows))
            .fetchCharacterDetail(characterId);

        final spell = detail.spells.singleWhere((s) => s.name == 'S20');
        expect(
          spell.requiresPreparation,
          isFalse,
          reason: 'reversed=$reversed',
        );
        expect(SpellStatusFormatter.canCast(spell), isTrue);
      }
    });
  });

  // `setSpellPrepared` ne doit jamais toucher une ligne au statut 'inné' :
  // un sort inné n'a pas de notion de préparation, et le faire passer à
  // 'préparé' puis 'connu' est sans retour possible depuis l'app.
  group('SupabaseCharacterRepository.setSpellPrepared (lignes innées)', () {
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
    const spellId = 20;

    /// Double minimal de la table `character_spells` pour UN sort : applique
    /// le filtre `status` de la requête (`neq.`/`in.`), comme PostgREST, et
    /// renvoie les lignes touchées.
    Future<SupabaseCharacterRepository> repositoryOver(
      List<Map<String, dynamic>> table,
      List<String> methods,
    ) async {
      bool matches(Map<String, dynamic> row, http.Request request) {
        final filter = request.url.queryParameters['status'];
        if (filter == null) return true;
        final status = row['status'] as String;
        if (filter.startsWith('neq.')) return status != filter.substring(4);
        if (filter.startsWith('eq.')) return status == filter.substring(3);
        if (filter.startsWith('in.')) {
          return filter
              .substring(4, filter.length - 1)
              .split(',')
              .map((value) => value.replaceAll('"', ''))
              .contains(status);
        }
        fail('filtre status inattendu : $filter');
      }

      return SupabaseCharacterRepository(
        await _buildSignedInFakeSupabaseClient(
          ownerId: ownerId,
          rowsOverride: (request) {
            if (request.url.pathSegments.last != 'character_spells') {
              return null;
            }
            methods.add(request.method);
            switch (request.method) {
              case 'PATCH':
                final patch = jsonDecode(request.body) as Map<String, dynamic>;
                final touched = [
                  for (final row in table)
                    if (matches(row, request)) row,
                ];
                for (final row in touched) {
                  row.addAll(patch);
                }
                return [
                  for (final row in touched) {'id': row['id']},
                ];
              case 'POST':
                final inserted = Map<String, dynamic>.from(
                  jsonDecode(request.body) as Map,
                )..['id'] = 'new-${table.length}';
                table.add(inserted);
                return const [];
              default:
                return [
                  for (final row in table)
                    if (matches(row, request)) {'id': row['id']},
                ];
            }
          },
        ),
        cache,
        pendingWrites,
        _AlwaysOnlineConnectivityChecker(),
      );
    }

    Map<String, dynamic> line(String id, String status) => {
      'id': id,
      'character_id': characterId,
      'spell_id': spellId,
      'status': status,
    };
    List<String> statusesOf(List<Map<String, dynamic>> table) => [
      for (final row in table) row['status'] as String,
    ];

    test('une seule ligne "inné", demande de préparer : rien n\'est écrit, '
        'aucune ligne en double insérée', () async {
      final table = [line('a', 'inné')];
      final methods = <String>[];
      final repository = await repositoryOver(table, methods);

      final outcome = await repository.setSpellPrepared(
        characterId: characterId,
        spellId: spellId,
        prepared: true,
      );

      expect(statusesOf(table), ['inné']);
      expect(methods, isNot(contains('POST')));
      expect(outcome, WriteOutcome.synced);
    });

    test('une seule ligne "inné", demande de dé-préparer : rien n\'est '
        'écrit', () async {
      final table = [line('a', 'inné')];
      final repository = await repositoryOver(table, <String>[]);

      await repository.setSpellPrepared(
        characterId: characterId,
        spellId: spellId,
        prepared: false,
      );

      expect(statusesOf(table), ['inné']);
    });

    test('lignes en double "inné" + "connu" : seule la ligne non innée est '
        'préparée, puis dé-préparée', () async {
      final table = [line('a', 'inné'), line('b', 'connu')];
      final methods = <String>[];
      final repository = await repositoryOver(table, methods);

      await repository.setSpellPrepared(
        characterId: characterId,
        spellId: spellId,
        prepared: true,
      );
      expect(statusesOf(table), ['inné', 'préparé']);

      await repository.setSpellPrepared(
        characterId: characterId,
        spellId: spellId,
        prepared: false,
      );
      expect(statusesOf(table), ['inné', 'connu']);
      expect(methods, isNot(contains('POST')));
    });

    test('ligne "connu" : passe à "préparé" (inchangé)', () async {
      final table = [line('a', 'connu')];
      final repository = await repositoryOver(table, <String>[]);

      await repository.setSpellPrepared(
        characterId: characterId,
        spellId: spellId,
        prepared: true,
      );

      expect(statusesOf(table), ['préparé']);
    });

    test('aucune ligne (sort de la liste de classe jamais préparé) : la '
        'ligne "préparé" est créée (inchangé)', () async {
      final table = <Map<String, dynamic>>[];
      final repository = await repositoryOver(table, <String>[]);

      await repository.setSpellPrepared(
        characterId: characterId,
        spellId: spellId,
        prepared: true,
      );

      expect(statusesOf(table), ['préparé']);
      expect(table.single['spell_id'], spellId);
      expect(table.single['character_id'], characterId);
    });

    test('aucune ligne, demande de dé-préparer : rien n\'est créé '
        '(inchangé)', () async {
      final table = <Map<String, dynamic>>[];
      final repository = await repositoryOver(table, <String>[]);

      await repository.setSpellPrepared(
        characterId: characterId,
        spellId: spellId,
        prepared: false,
      );

      expect(table, isEmpty);
    });
  });

  group('SupabaseCharacterRepository.fetchCharacterDetail (arme de pacte)', () {
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

    Map<String, List<Map<String, dynamic>>> warlockRows({
      String pact = 'lame',
      bool withPactWeapon = true,
    }) => {
      'characters': [
        {
          'id': characterId,
          'name': 'Sylas',
          'xp': 0,
          'current_hp': 10,
          'max_hp': 10,
          'temporary_hp': 0,
          'race_id': null,
          'character_classes': [
            {
              'class_id': 2,
              'subclass_id': 31,
              'level': 3,
              'is_primary': true,
              'classes': {'saving_throw_proficiencies': [], 'hit_die': 8},
            },
          ],
          'character_class_options': [
            {'class_feature_id': 60, 'level': 3, 'chosen_value': pact},
          ],
        },
      ],
      'class_features': [
        {'id': 60, 'class_id': 2, 'level': 3},
      ],
      'translations': [
        {'entity_id': '2', 'value': 'Occultiste'},
        {'entity_id': '31', 'value': 'Lame maudite'},
        {'entity_id': '60', 'value': 'Faveur de pacte'},
        {'entity_id': '77', 'value': 'Rapière'},
      ],
      'character_pact_weapons': [
        if (withPactWeapon) {'item_id': 77},
      ],
      'items': [
        {
          'id': 77,
          'category': 'arme',
          'weapon_properties': {
            'damage_dice': '1d8',
            'damage_type': 'perforant',
            'properties': ['finesse'],
          },
        },
      ],
    };

    Future<SupabaseCharacterRepository> repositoryFor(
      Map<String, List<Map<String, dynamic>>> rows, {
      List<String>? requestedTables,
    }) async => SupabaseCharacterRepository(
      await _buildSignedInFakeSupabaseClient(
        ownerId: ownerId,
        tableRows: rows,
        onRequest: requestedTables == null
            ? null
            : (request) => requestedTables.add(request.url.pathSegments.last),
      ),
      cache,
      pendingWrites,
      _AlwaysOnlineConnectivityChecker(),
    );

    Future<SupabaseCharacterRepository> offlineRepository() async =>
        SupabaseCharacterRepository(
          await _buildSignedInFakeSupabaseClient(
            ownerId: ownerId,
            failureStatusCode: 500,
          ),
          cache,
          pendingWrites,
          _AlwaysOnlineConnectivityChecker(),
        );

    void verifyPactWeapon(dynamic detail) {
      expect(detail.hasBladePact, isTrue);
      expect(detail.hasCursedBladeSubclass, isTrue);
      expect(detail.pactWeapon.id, 77);
      expect(detail.pactWeapon.name, 'Rapière');
      expect(detail.pactWeapon.damageLabel, '1d8 perforant');
      expect(detail.pactWeapon.properties, ['finesse']);
      expect(detail.inventory, isEmpty);
    }

    test(
      'Pacte de la lame avec forme choisie : la forme est chargée',
      () async {
        final repository = await repositoryFor(warlockRows());
        verifyPactWeapon(await repository.fetchCharacterDetail(characterId));
      },
    );

    test('hors ligne : le cache restitue la même forme', () async {
      await (await repositoryFor(warlockRows()))
          .fetchCharacterDetail(characterId);
      verifyPactWeapon(
        await (await offlineRepository()).fetchCharacterDetail(characterId),
      );
    });

    test(
      'un ancien cache sans donnée d\'arme de pacte reste lisible',
      () async {
        await (await repositoryFor(warlockRows()))
            .fetchCharacterDetail(characterId);
        final payload =
            Map<String, dynamic>.from(
                await cache.get(cacheKey) as Map<String, dynamic>,
              )
              ..remove('pactWeaponItemRow')
              ..remove('pactWeaponNameRows');
        await cache.put(cacheKey, payload);

        final detail = await (await offlineRepository()).fetchCharacterDetail(
          characterId,
        );

        expect(detail.hasBladePact, isTrue);
        expect(detail.pactWeapon, isNull);
      },
    );

    test('Pacte de la lame sans forme choisie : pactWeapon nul, items non '
        'interrogé', () async {
      final requested = <String>[];
      final repository = await repositoryFor(
        warlockRows(withPactWeapon: false),
        requestedTables: requested,
      );

      final detail = await repository.fetchCharacterDetail(characterId);

      expect(detail.hasBladePact, isTrue);
      expect(detail.pactWeapon, isNull);
      expect(requested, contains('character_pact_weapons'));
      expect(requested, isNot(contains('items')));
    });

    test('autre pacte : aucune requête character_pact_weapons', () async {
      final requested = <String>[];
      final repository = await repositoryFor(
        warlockRows(pact: 'chaine'),
        requestedTables: requested,
      );

      final detail = await repository.fetchCharacterDetail(characterId);

      expect(detail.hasBladePact, isFalse);
      expect(detail.pactWeapon, isNull);
      expect(requested, isNot(contains('character_pact_weapons')));
    });
  });

  group('SupabaseCharacterRepository.fetchLevelUpLevelData', () {
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

    const ownerId = 'owner-1';

    Future<SupabaseCharacterRepository> repositoryFor(
      Map<String, List<Map<String, dynamic>>> tableRows,
    ) async => SupabaseCharacterRepository(
      await _buildSignedInFakeSupabaseClient(
        ownerId: ownerId,
        tableRows: tableRows,
      ),
      cache,
      pendingWrites,
      _AlwaysOnlineConnectivityChecker(),
    );

    // Régression : `class_features.choice_type = 'amelioration_caracteristiques'`
    // (ASI, niveaux 4/8/12/16/19) a été ajouté en base après l'écriture de
    // `LevelUpBlockRules.resolvedChoiceTypes`, qui ne le connaît pas —
    // bloquait tout le flux de montée de niveau avec "Clerc niveau 4 :
    // Amélioration Caractéristique" avant ce correctif.
    test("amelioration_caracteristiques (ASI) n'est jamais choisi comme ligne "
        'de choix : traité comme une aptitude automatique', () async {
      final repository = await repositoryFor({
        'class_features': [
          {
            'id': 186,
            'class_id': 3,
            'level': 4,
            'choice_type': 'amelioration_caracteristiques',
            'uses_per_rest': null,
          },
        ],
        'translations': [
          {'entity_id': '186', 'value': 'Amélioration de caractéristiques'},
        ],
      });

      final data = await repository.fetchLevelUpLevelData(
        classId: 3,
        targetLevel: 4,
      );

      expect(data.choiceType, isNull);
      expect(data.choiceClassFeatureId, isNull);
      expect(data.automaticFeatures, hasLength(1));
      expect(
        data.automaticFeatures.single.name,
        'Amélioration de caractéristiques',
      );
    });

    test('une vraie ligne de choix (ex. sous_classe) reste la ligne de choix, '
        'exclue des aptitudes automatiques', () async {
      final repository = await repositoryFor({
        'class_features': [
          {
            'id': 9,
            'class_id': 3,
            'level': 1,
            'choice_type': 'sous_classe',
            'uses_per_rest': null,
          },
        ],
        'subclasses': const [],
      });

      final data = await repository.fetchLevelUpLevelData(
        classId: 3,
        targetLevel: 1,
      );

      expect(data.choiceType, 'sous_classe');
      expect(data.choiceClassFeatureId, 9);
      expect(data.automaticFeatures, isEmpty);
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
  // Simule le scénario D12 (`TimeoutHttpClient`,
  // `core/network/timeout_http_client.dart`) : une requête qui expire lève
  // une `TimeoutException`, contrairement à [throwOnRequest]
  // (`SocketException`, absence de réseau "franche"). Ce double ne passe
  // jamais réellement par `TimeoutHttpClient` (le transport est entièrement
  // fabriqué, voir [MockClient] ci-dessous) — il simule directement
  // l'exception que ce client lèverait, déjà vérifiée bout en bout par
  // `test/core/network/timeout_http_client_test.dart`.
  bool throwTimeoutOnRequest = false,
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
    if (throwTimeoutOnRequest) {
      throw TimeoutException('Requête expirée (double de test).');
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
