// Tests de bout en bout (dépôt réel + file drift en mémoire + transport HTTP
// fabriqué) du circuit hors-ligne PV/XP : écriture mise en file, relecture de
// la fiche (cache ou réseau), synchronisation au retour du réseau.
//
// Défaut d'origine (registre de dette technique, confirmé par ces tests avant
// correction) : `fetchCharacterDetail` ne tenait aucun compte de la file
// `PendingCharacterWrites`. Hors ligne, une fiche fermée puis rouverte
// réaffichait donc les PV/l'XP d'avant l'ajustement mis en file ; l'ajustement
// suivant, calculé par l'écran à partir de cette base périmée, remplaçait
// l'entrée en file (valeurs absolues, une seule entrée par personnage et par
// type) et le premier ajustement était perdu sans message.
//
// Contrairement à `character_repository_test.dart` (double HTTP sans état),
// [_FakeServer] garde ici la ligne `characters` en mémoire et applique les
// `PATCH` reçus : c'est ce qui permet de vérifier la valeur réellement partie
// vers le serveur et la valeur relue ensuite.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/core/network/connectivity_checker.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/data/pending_character_write_syncer.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/providers/character_detail_provider.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/features/characters/presentation/providers/character_write_sync_coordinator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _characterId = 'char-1';
const _ownerId = 'owner-1';
const _cacheKey = 'character_detail:$_ownerId:$_characterId';

void main() {
  late AppDatabase db;
  late ReferenceDataCache cache;
  late PendingCharacterWriteQueue pendingWrites;
  late _FakeServer server;
  late _FakeConnectivityChecker connectivity;
  late SupabaseClient client;
  late SupabaseCharacterRepository repository;
  late PendingCharacterWriteSyncer syncer;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    cache = ReferenceDataCache(db);
    pendingWrites = PendingCharacterWriteQueue(db);
    server = _FakeServer();
    connectivity = _FakeConnectivityChecker();
    client = await _buildSignedInClient(server, ownerId: _ownerId);
    repository = SupabaseCharacterRepository(
      client,
      cache,
      pendingWrites,
      connectivity,
    );
    syncer = PendingCharacterWriteSyncer(client, pendingWrites, cache);
  });

  tearDown(() async {
    await db.close();
  });

  /// Réseau coupé : l'interface est inactive (`hasConnection` faux) et toute
  /// requête lève une `SocketException`.
  void goOffline() {
    connectivity.connected = false;
    server.network = _Network.down;
  }

  void goOnline() {
    connectivity.connected = true;
    server.network = _Network.online;
  }

  Future<Map<String, dynamic>?> pendingPayload(
    PendingCharacterWriteKind kind,
  ) async {
    final pending = await pendingWrites.allForOwner(_ownerId);
    final matching = pending.where(
      (write) => write.characterId == _characterId && write.kind == kind,
    );
    return matching.isEmpty ? null : matching.single.payload;
  }

  /// "Ouvre" la fiche en ligne une première fois : peuple le cache avec
  /// l'état serveur de départ (10/12 PV, 100 XP).
  Future<void> openOnlineOnce() async {
    final detail = await repository.fetchCharacterDetail(_characterId);
    expect(detail.currentHp, 10);
    expect(detail.xp, 100);
  }

  group('hors ligne : fiche fermée puis rouverte', () {
    test('PV : la fiche relue depuis le cache affiche la valeur mise en '
        'file', () async {
      await openOnlineOnce();
      goOffline();

      final outcome = await repository.updateHp(
        characterId: _characterId,
        currentHp: 7,
        temporaryHp: 3,
      );
      expect(outcome, WriteOutcome.queued);

      final reopened = await repository.fetchCharacterDetail(_characterId);

      expect(reopened.currentHp, 7);
      expect(reopened.temporaryHp, 3);
      expect(reopened.maxHp, 12, reason: 'max_hp ne passe jamais par la file');
    });

    test('PV : deux ajustements séparés par une fermeture/réouverture se '
        'cumulent (scénario de perte)', () async {
      await openOnlineOnce();
      goOffline();

      // 1er ajustement : -3 PV (10 -> 7), calculé par l'écran depuis la
      // fiche affichée.
      await repository.updateHp(
        characterId: _characterId,
        currentHp: 10 - 3,
        temporaryHp: 0,
      );

      // Fermeture puis réouverture : l'écran repart de ce que renvoie le
      // dépôt, exactement comme `_applyHpState` (valeur absolue = base
      // relue + delta saisi).
      final reopened = await repository.fetchCharacterDetail(_characterId);
      await repository.updateHp(
        characterId: _characterId,
        currentHp: reopened.currentHp - 2,
        temporaryHp: reopened.temporaryHp,
      );

      expect(await pendingPayload(PendingCharacterWriteKind.hp), {
        'currentHp': 5,
        'temporaryHp': 0,
      });
      final again = await repository.fetchCharacterDetail(_characterId);
      expect(again.currentHp, 5);
    });

    test("XP : la fiche relue depuis le cache affiche l'XP mise en "
        'file', () async {
      await openOnlineOnce();
      goOffline();

      await repository.addXp(characterId: _characterId, newXp: 150);

      final reopened = await repository.fetchCharacterDetail(_characterId);
      expect(reopened.xp, 150);
    });

    test('XP : deux ajouts séparés par une fermeture/réouverture se '
        'cumulent (scénario de perte)', () async {
      await openOnlineOnce();
      goOffline();

      await repository.addXp(characterId: _characterId, newXp: 100 + 50);
      final reopened = await repository.fetchCharacterDetail(_characterId);
      await repository.addXp(
        characterId: _characterId,
        newXp: reopened.xp + 30,
      );

      expect(await pendingPayload(PendingCharacterWriteKind.xp), {
        'newXp': 180,
      });
      final again = await repository.fetchCharacterDetail(_characterId);
      expect(again.xp, 180);
    });

    test(
      'le cache garde le dernier état serveur connu, jamais la valeur en '
      'file (la file reste la seule source des écritures en attente)',
      () async {
        await openOnlineOnce();
        goOffline();
        await repository.updateHp(
          characterId: _characterId,
          currentHp: 7,
          temporaryHp: 0,
        );
        await repository.fetchCharacterDetail(_characterId);

        final cached = await cache.get(_cacheKey) as Map<String, dynamic>;
        expect((cached['row'] as Map)['current_hp'], 10);
      },
    );
  });

  group('retour du réseau', () {
    test('la valeur synchronisée est la dernière mise en file, la file est '
        'vidée, la fiche relue affiche la même valeur', () async {
      await openOnlineOnce();
      goOffline();
      await repository.updateHp(
        characterId: _characterId,
        currentHp: 7,
        temporaryHp: 0,
      );
      final reopened = await repository.fetchCharacterDetail(_characterId);
      await repository.updateHp(
        characterId: _characterId,
        currentHp: reopened.currentHp - 2,
        temporaryHp: 0,
      );
      await repository.addXp(characterId: _characterId, newXp: 150);
      final beforeSync = await repository.fetchCharacterDetail(_characterId);

      goOnline();
      final synced = await syncer.sync();

      expect(synced, {_characterId});
      expect(server.patchBodies, [
        {'current_hp': 5, 'temporary_hp': 0},
        {'xp': 150},
      ]);
      expect(server.characterRow['current_hp'], 5);
      expect(server.characterRow['xp'], 150);
      expect(await pendingWrites.allForOwner(_ownerId), isEmpty);

      final afterSync = await repository.fetchCharacterDetail(_characterId);
      expect(afterSync.currentHp, beforeSync.currentHp);
      expect(afterSync.currentHp, 5);
      expect(afterSync.xp, beforeSync.xp);
      expect(afterSync.xp, 150);
    });

    test('cas voisin en ligne : réseau revenu, fiche relue AVANT que la '
        'synchronisation ait abouti -> affiche la valeur en file, pas la '
        'valeur serveur encore ancienne', () async {
      await openOnlineOnce();
      goOffline();
      await repository.updateHp(
        characterId: _characterId,
        currentHp: 7,
        temporaryHp: 0,
      );
      await repository.addXp(characterId: _characterId, newXp: 150);

      goOnline();
      // Aucune synchro encore : le serveur a toujours 10 PV / 100 XP.
      final detail = await repository.fetchCharacterDetail(_characterId);

      expect(server.characterRow['current_hp'], 10);
      expect(detail.currentHp, 7);
      expect(detail.xp, 150);
    });

    test('réponse réseau plus ancienne arrivant après une écriture locale '
        'plus récente : la fiche renvoyée reflète la file', () async {
      await openOnlineOnce();

      // Lecture en vol : le serveur a déjà figé sa réponse (10 PV)...
      final gate = Completer<void>();
      server.characterReadGate = gate;
      final inFlight = repository.fetchCharacterDetail(_characterId);
      await pumpEventQueue();

      // ... quand le réseau tombe et qu'un ajustement est mis en file.
      connectivity.connected = false;
      await repository.updateHp(
        characterId: _characterId,
        currentHp: 4,
        temporaryHp: 0,
      );

      gate.complete();
      final detail = await inFlight;

      expect(detail.currentHp, 4);
    });
  });

  group('échec de synchronisation', () {
    test('écriture refusée par le serveur : la file et la fiche relue '
        'restent cohérentes, puis la synchro suivante aboutit', () async {
      await openOnlineOnce();
      goOffline();
      await repository.updateHp(
        characterId: _characterId,
        currentHp: 7,
        temporaryHp: 0,
      );
      await repository.addXp(characterId: _characterId, newXp: 150);

      connectivity.connected = true;
      server.network = _Network.writesRejected;
      final synced = await syncer.sync();

      expect(synced, isEmpty);
      expect(server.characterRow['current_hp'], 10);
      expect(await pendingPayload(PendingCharacterWriteKind.hp), {
        'currentHp': 7,
        'temporaryHp': 0,
      });
      expect(await pendingPayload(PendingCharacterWriteKind.xp), {
        'newXp': 150,
      });
      // Les lectures passent (seules les écritures sont refusées) : la
      // fiche affiche ce qui est en file, pas l'état serveur resté ancien.
      final detail = await repository.fetchCharacterDetail(_characterId);
      expect(detail.currentHp, 7);
      expect(detail.xp, 150);

      // Un nouvel ajustement repart bien de la valeur affichée.
      goOffline();
      await repository.updateHp(
        characterId: _characterId,
        currentHp: detail.currentHp - 1,
        temporaryHp: 0,
      );

      goOnline();
      expect(await syncer.sync(), {_characterId});
      expect(server.characterRow['current_hp'], 6);
      expect(server.characterRow['xp'], 150);
      expect(await pendingWrites.allForOwner(_ownerId), isEmpty);
      final after = await repository.fetchCharacterDetail(_characterId);
      expect(after.currentHp, 6);
      expect(after.xp, 150);
    });

    test('réseau toujours coupé pendant la synchro : rien ne change', () async {
      await openOnlineOnce();
      goOffline();
      await repository.updateHp(
        characterId: _characterId,
        currentHp: 7,
        temporaryHp: 0,
      );

      expect(await syncer.sync(), isEmpty);

      expect(await pendingPayload(PendingCharacterWriteKind.hp), {
        'currentHp': 7,
        'temporaryHp': 0,
      });
      final detail = await repository.fetchCharacterDetail(_characterId);
      expect(detail.currentHp, 7);
    });
  });

  group('en ligne : circuit et requêtes inchangés', () {
    test('fetchCharacterDetail sans écriture en attente : mêmes requêtes '
        "qu'avant le correctif, valeurs serveur telles quelles", () async {
      final detail = await repository.fetchCharacterDetail(_characterId);

      expect(detail.currentHp, 10);
      expect(detail.temporaryHp, 0);
      expect(detail.xp, 100);
      // Séquence relevée sur `main` avant le correctif (commit 4d00fc2) avec
      // cette même fixture : la superposition de la file ne lit que la base
      // SQLite locale, jamais le réseau.
      expect(server.requests, _baselineFetchRequests);
    });

    test('fetchCharacterDetail avec une écriture en attente : aucune requête '
        'réseau supplémentaire', () async {
      await pendingWrites.enqueue(
        characterId: _characterId,
        ownerId: _ownerId,
        kind: PendingCharacterWriteKind.hp,
        payload: {'currentHp': 7, 'temporaryHp': 0},
      );

      await repository.fetchCharacterDetail(_characterId);

      expect(server.requests, _baselineFetchRequests);
    });

    test(
      'updateHp/addXp en ligne : un seul PATCH chacun, rien en file',
      () async {
        final hpOutcome = await repository.updateHp(
          characterId: _characterId,
          currentHp: 8,
          temporaryHp: 1,
        );
        final xpOutcome = await repository.addXp(
          characterId: _characterId,
          newXp: 130,
        );

        expect(hpOutcome, WriteOutcome.synced);
        expect(xpOutcome, WriteOutcome.synced);
        expect(server.requests, ['PATCH characters', 'PATCH characters']);
        expect(server.patchBodies, [
          {'current_hp': 8, 'temporary_hp': 1},
          {'xp': 130},
        ]);
        expect(await pendingWrites.allForOwner(_ownerId), isEmpty);
      },
    );

    test('une écriture en ligne réussie remplace l\'entrée en attente du '
        'même type (valeurs absolues : l\'entrée en file est périmée), sans '
        'toucher à l\'autre type', () async {
      await openOnlineOnce();
      goOffline();
      await repository.updateHp(
        characterId: _characterId,
        currentHp: 7,
        temporaryHp: 0,
      );
      await repository.addXp(characterId: _characterId, newXp: 150);

      // Réseau revenu, synchro pas encore passée (ou en échec) : le joueur
      // ajuste ses PV en ligne à partir de la valeur affichée (7).
      goOnline();
      final detail = await repository.fetchCharacterDetail(_characterId);
      final outcome = await repository.updateHp(
        characterId: _characterId,
        currentHp: detail.currentHp - 1,
        temporaryHp: 0,
      );

      expect(outcome, WriteOutcome.synced);
      expect(server.characterRow['current_hp'], 6);
      expect(
        await pendingPayload(PendingCharacterWriteKind.hp),
        isNull,
        reason:
            "sans ce retrait, la synchro suivante réécrirait l'ancienne "
            'valeur en file (7) par-dessus la plus récente (6)',
      );
      expect(await pendingPayload(PendingCharacterWriteKind.xp), {
        'newXp': 150,
      });

      final after = await repository.fetchCharacterDetail(_characterId);
      expect(after.currentHp, 6);
      expect(after.xp, 150);

      await syncer.sync();
      expect(server.characterRow['current_hp'], 6);
      expect(server.characterRow['xp'], 150);
    });

    test('une écriture en ligne en échec ne touche pas à l\'entrée en '
        'attente', () async {
      await pendingWrites.enqueue(
        characterId: _characterId,
        ownerId: _ownerId,
        kind: PendingCharacterWriteKind.hp,
        payload: {'currentHp': 7, 'temporaryHp': 0},
      );
      server.network = _Network.writesRejected;

      await expectLater(
        repository.updateHp(
          characterId: _characterId,
          currentHp: 6,
          temporaryHp: 0,
        ),
        throwsA(isA<Exception>()),
      );

      expect(await pendingPayload(PendingCharacterWriteKind.hp), {
        'currentHp': 7,
        'temporaryHp': 0,
      });
    });
  });

  group('cloisonnement et robustesse de la superposition', () {
    test("l'écriture en attente d'un autre compte n'apparaît jamais dans la "
        'fiche du compte connecté', () async {
      await pendingWrites.enqueue(
        characterId: _characterId,
        ownerId: 'owner-2',
        kind: PendingCharacterWriteKind.hp,
        payload: {'currentHp': 1, 'temporaryHp': 9},
      );
      await pendingWrites.enqueue(
        characterId: _characterId,
        ownerId: 'owner-2',
        kind: PendingCharacterWriteKind.xp,
        payload: {'newXp': 99999},
      );

      final online = await repository.fetchCharacterDetail(_characterId);
      expect(online.currentHp, 10);
      expect(online.temporaryHp, 0);
      expect(online.xp, 100);

      server.network = _Network.down;
      final fromCache = await repository.fetchCharacterDetail(_characterId);
      expect(fromCache.currentHp, 10);
      expect(fromCache.xp, 100);
    });

    test("une écriture en ligne du compte connecté ne retire jamais l'entrée "
        "en attente d'un autre compte", () async {
      await pendingWrites.enqueue(
        characterId: _characterId,
        ownerId: 'owner-2',
        kind: PendingCharacterWriteKind.hp,
        payload: {'currentHp': 1, 'temporaryHp': 9},
      );

      await repository.updateHp(
        characterId: _characterId,
        currentHp: 8,
        temporaryHp: 0,
      );

      expect(await pendingWrites.allForOwner('owner-2'), hasLength(1));
    });

    test("l'écriture en attente d'un autre personnage du même compte n'est "
        'pas superposée', () async {
      await pendingWrites.enqueue(
        characterId: 'char-2',
        ownerId: _ownerId,
        kind: PendingCharacterWriteKind.hp,
        payload: {'currentHp': 1, 'temporaryHp': 9},
      );

      final detail = await repository.fetchCharacterDetail(_characterId);
      expect(detail.currentHp, 10);
      expect(detail.temporaryHp, 0);
    });

    test('une ligne de type inconnu dans la file ne casse ni la lecture de '
        'la fiche ni la superposition des types connus', () async {
      await db
          .into(db.pendingCharacterWrites)
          .insert(
            PendingCharacterWritesCompanion.insert(
              characterId: _characterId,
              ownerId: _ownerId,
              kind: 'type_futur',
              payload: jsonEncode({'quelconque': true}),
              queuedAt: DateTime.now(),
            ),
          );
      await pendingWrites.enqueue(
        characterId: _characterId,
        ownerId: _ownerId,
        kind: PendingCharacterWriteKind.xp,
        payload: {'newXp': 150},
      );

      final detail = await repository.fetchCharacterDetail(_characterId);
      expect(detail.currentHp, 10);
      expect(detail.xp, 150);
    });

    test('modification depuis un autre appareil pendant que des PV sont en '
        'file : la fiche affiche ce qui partira (la file), la synchro écrase '
        'la valeur serveur ("dernière écriture gagne", comportement '
        'inchangé)', () async {
      await openOnlineOnce();
      goOffline();
      await repository.updateHp(
        characterId: _characterId,
        currentHp: 7,
        temporaryHp: 0,
      );

      // Le MJ (ou un second téléphone) passe entre-temps les PV à 3 et
      // l'XP à 500 côté serveur.
      server.characterRow = {
        ...server.characterRow,
        'current_hp': 3,
        'xp': 500,
      };

      goOnline();
      final beforeSync = await repository.fetchCharacterDetail(_characterId);
      expect(beforeSync.currentHp, 7, reason: 'PV : entrée en file');
      expect(beforeSync.xp, 500, reason: "XP : rien en file, valeur serveur");

      await syncer.sync();

      expect(server.characterRow['current_hp'], 7);
      expect(server.characterRow['xp'], 500);
      final afterSync = await repository.fetchCharacterDetail(_characterId);
      expect(afterSync.currentHp, 7);
      expect(afterSync.xp, 500);
    });
  });

  // Ajouts QA (revue du correctif) — trous de couverture révélés par
  // mutation du code de production.
  group('QA : compléments de couverture', () {
    test('lecture refusée par le serveur (PostgrestException, pas une erreur '
        'de transport) : la fiche relue depuis le cache porte aussi les '
        'valeurs en file', () async {
      await openOnlineOnce();
      await pendingWrites.enqueue(
        characterId: _characterId,
        ownerId: _ownerId,
        kind: PendingCharacterWriteKind.hp,
        payload: {'currentHp': 7, 'temporaryHp': 2},
      );
      await pendingWrites.enqueue(
        characterId: _characterId,
        ownerId: _ownerId,
        kind: PendingCharacterWriteKind.xp,
        payload: {'newXp': 150},
      );

      server.network = _Network.allRejected;
      final detail = await repository.fetchCharacterDetail(_characterId);

      expect(detail.currentHp, 7);
      expect(detail.temporaryHp, 2);
      expect(detail.xp, 150);
    });

    test("un ajout d'XP en ligne en échec ne touche pas à l'entrée XP en "
        'attente', () async {
      await pendingWrites.enqueue(
        characterId: _characterId,
        ownerId: _ownerId,
        kind: PendingCharacterWriteKind.xp,
        payload: {'newXp': 150},
      );
      server.network = _Network.writesRejected;

      await expectLater(
        repository.addXp(characterId: _characterId, newXp: 180),
        throwsA(isA<Exception>()),
      );

      expect(await pendingPayload(PendingCharacterWriteKind.xp), {
        'newXp': 150,
      });
    });

    test('lecture EN LIGNE avec des écritures en attente : le cache reçoit '
        "l'état serveur brut, jamais les valeurs superposées", () async {
      await pendingWrites.enqueue(
        characterId: _characterId,
        ownerId: _ownerId,
        kind: PendingCharacterWriteKind.hp,
        payload: {'currentHp': 7, 'temporaryHp': 2},
      );
      await pendingWrites.enqueue(
        characterId: _characterId,
        ownerId: _ownerId,
        kind: PendingCharacterWriteKind.xp,
        payload: {'newXp': 150},
      );

      final detail = await repository.fetchCharacterDetail(_characterId);
      expect(detail.currentHp, 7);

      final cached = await cache.get(_cacheKey) as Map<String, dynamic>;
      final row = cached['row'] as Map;
      expect(row['current_hp'], 10);
      expect(row['temporary_hp'], 0);
      expect(row['xp'], 100);
    });
  });

  // Ajouts QA (seconde passe) — trous révélés par mutation du report dans
  // le cache et du retrait conditionnel.
  group('QA : compléments de couverture (seconde passe)', () {
    test("XP mise en file hors ligne : le cache garde l'XP serveur", () async {
      await openOnlineOnce();
      goOffline();

      await repository.addXp(characterId: _characterId, newXp: 150);

      final cached = await cache.get(_cacheKey) as Map<String, dynamic>;
      expect((cached['row'] as Map)['xp'], 100);
    });

    test("ajout d'XP en ligne en échec : le cache n'est pas modifié", () async {
      await openOnlineOnce();
      server.network = _Network.writesRejected;

      await expectLater(
        repository.addXp(characterId: _characterId, newXp: 180),
        throwsA(isA<Exception>()),
      );

      final cached = await cache.get(_cacheKey) as Map<String, dynamic>;
      expect((cached['row'] as Map)['xp'], 100);
    });

    test('report dans le cache : seules les colonnes écrites changent, le '
        'reste du payload est conservé à l\'identique', () async {
      await openOnlineOnce();
      final before = await cache.get(_cacheKey) as Map<String, dynamic>;

      await repository.updateHp(
        characterId: _characterId,
        currentHp: 8,
        temporaryHp: 2,
      );
      await repository.addXp(characterId: _characterId, newXp: 130);

      final after = await cache.get(_cacheKey) as Map<String, dynamic>;
      expect(after, {
        ...before,
        'row': {
          ...before['row'] as Map,
          'current_hp': 8,
          'temporary_hp': 2,
          'xp': 130,
        },
      });
    });

    test('XP : entrée en file relevée avant un ajout en ligne, puis remise '
        "en file à l'identique pendant qu'il est en vol -> elle n'est pas "
        'retirée', () async {
      await openOnlineOnce();
      goOffline();
      await repository.addXp(characterId: _characterId, newXp: 150);

      goOnline();
      final gate = Completer<void>();
      server.characterWriteGate = gate;
      final inFlight = repository.addXp(characterId: _characterId, newXp: 180);
      await pumpEventQueue();

      connectivity.connected = false;
      await repository.addXp(characterId: _characterId, newXp: 150);

      gate.complete();
      expect(await inFlight, WriteOutcome.synced);

      expect(await pendingPayload(PendingCharacterWriteKind.xp), {
        'newXp': 150,
      });
    });
  });

  // Ajouts QA (revue du correctif) — scénarios de perte recherchés au-delà
  // de ceux couverts par dev-flutter.
  group('QA : scénarios de perte', () {
    test('PV : écriture en ligne en vol, puis ajustement mis en file pendant '
        "qu'elle est en vol, puis succès de la première -> l'entrée en file "
        '(plus récente) ne doit pas être retirée', () async {
      await openOnlineOnce();

      // 1er tap en ligne (10 -> 8) : PATCH parti, réponse retenue.
      final gate = Completer<void>();
      server.characterWriteGate = gate;
      final inFlight = repository.updateHp(
        characterId: _characterId,
        currentHp: 8,
        temporaryHp: 0,
      );
      await pumpEventQueue();
      expect(server.characterRow['current_hp'], 8);

      // Le réseau tombe ; 2e tap (8 -> 5) : mis en file.
      connectivity.connected = false;
      final queued = await repository.updateHp(
        characterId: _characterId,
        currentHp: 5,
        temporaryHp: 0,
      );
      expect(queued, WriteOutcome.queued);

      // La réponse du 1er PATCH arrive enfin (succès).
      gate.complete();
      expect(await inFlight, WriteOutcome.synced);

      expect(
        await pendingPayload(PendingCharacterWriteKind.hp),
        {'currentHp': 5, 'temporaryHp': 0},
        reason:
            "l'entrée en file est plus récente que l'écriture en ligne qui "
            'vient de réussir : la retirer perd le 2e ajustement',
      );

      goOnline();
      await syncer.sync();
      expect(server.characterRow['current_hp'], 5);
    });

    test('XP : même ordre (ajout en ligne en vol, ajout mis en file, succès '
        "du premier) -> l'entrée en file ne doit pas être retirée", () async {
      await openOnlineOnce();

      final gate = Completer<void>();
      server.characterWriteGate = gate;
      final inFlight = repository.addXp(characterId: _characterId, newXp: 150);
      await pumpEventQueue();

      connectivity.connected = false;
      await repository.addXp(characterId: _characterId, newXp: 180);

      gate.complete();
      expect(await inFlight, WriteOutcome.synced);

      expect(await pendingPayload(PendingCharacterWriteKind.xp), {
        'newXp': 180,
      });
    });

    test('fiche fermée pendant la synchronisation, puis rouverte hors ligne : '
        'elle doit afficher la valeur synchronisée, pas le cache resté sur '
        "l'ancien état serveur", () async {
      await openOnlineOnce();
      goOffline();
      await repository.updateHp(
        characterId: _characterId,
        currentHp: 7,
        temporaryHp: 0,
      );
      await repository.addXp(characterId: _characterId, newXp: 150);

      // Réseau revenu fiche fermée : la synchro passe, personne ne relit la
      // fiche (provider autoDispose non écouté -> aucune requête).
      goOnline();
      expect(await syncer.sync(), {_characterId});
      expect(server.characterRow['current_hp'], 7);
      expect(await pendingWrites.allForOwner(_ownerId), isEmpty);

      // Le réseau retombe avant toute réouverture en ligne.
      goOffline();
      final reopened = await repository.fetchCharacterDetail(_characterId);

      expect(reopened.currentHp, 7);
      expect(reopened.xp, 150);
    });
    // D3 : même règle côté synchroniseur — une entrée mise en file pendant
    // que la synchro écrit l'entrée précédente ne doit pas être retirée
    // avec elle.
    test('synchro en vol (écrit 7), puis ajustement mis en file pendant '
        "l'écriture (5), puis succès de la synchro -> l'entrée 5 reste en "
        'file et part à la synchro suivante', () async {
      await openOnlineOnce();
      goOffline();
      await repository.updateHp(
        characterId: _characterId,
        currentHp: 7,
        temporaryHp: 0,
      );

      // Réseau revenu : la synchro lit l'entrée "7", son PATCH part, la
      // réponse est retenue.
      goOnline();
      final gate = Completer<void>();
      server.characterWriteGate = gate;
      final syncing = syncer.sync();
      await pumpEventQueue();
      expect(server.characterRow['current_hp'], 7);

      // Le réseau retombe ; nouvel ajustement (7 -> 5) mis en file.
      connectivity.connected = false;
      await repository.updateHp(
        characterId: _characterId,
        currentHp: 5,
        temporaryHp: 0,
      );

      gate.complete();
      expect(await syncing, {_characterId});

      expect(
        await pendingPayload(PendingCharacterWriteKind.hp),
        {'currentHp': 5, 'temporaryHp': 0},
        reason:
            "l'entrée lue par la synchro (7) a été remplacée entre-temps : "
            'la retirer supprimerait une valeur jamais envoyée',
      );
      // Tant que "5" n'est pas partie, la fiche l'affiche ; le cache porte
      // le dernier état confirmé par le serveur (7).
      server.network = _Network.down;
      final detail = await repository.fetchCharacterDetail(_characterId);
      expect(detail.currentHp, 5);
      final cached = await cache.get(_cacheKey) as Map<String, dynamic>;
      expect((cached['row'] as Map)['current_hp'], 7);

      goOnline();
      expect(await syncer.sync(), {_characterId});
      expect(server.characterRow['current_hp'], 5);
      expect(await pendingWrites.allForOwner(_ownerId), isEmpty);
    });

    test('une entrée remise en file à l\'identique (même contenu) pendant '
        "une écriture en ligne n'est pas retirée non plus", () async {
      await openOnlineOnce();
      goOffline();
      await repository.updateHp(
        characterId: _characterId,
        currentHp: 7,
        temporaryHp: 0,
      );

      // En ligne, synchro pas encore passée : 7 -> 6, PATCH retenu.
      goOnline();
      final gate = Completer<void>();
      server.characterWriteGate = gate;
      final inFlight = repository.updateHp(
        characterId: _characterId,
        currentHp: 6,
        temporaryHp: 0,
      );
      await pumpEventQueue();

      // Le réseau retombe ; 6 -> 7 mis en file : même contenu que
      // l'entrée relevée avant le PATCH, mais plus récente que lui.
      connectivity.connected = false;
      await repository.updateHp(
        characterId: _characterId,
        currentHp: 7,
        temporaryHp: 0,
      );

      gate.complete();
      expect(await inFlight, WriteOutcome.synced);

      expect(await pendingPayload(PendingCharacterWriteKind.hp), {
        'currentHp': 7,
        'temporaryHp': 0,
      });
    });

    // D2, variante déduite du code par QA : écriture en ligne réussie dont
    // la relecture échoue.
    test(
      'écriture en ligne réussie puis relecture en échec (réseau '
      'retombé) : la fiche relue depuis le cache porte la valeur écrite',
      () async {
        await openOnlineOnce();

        await repository.updateHp(
          characterId: _characterId,
          currentHp: 8,
          temporaryHp: 2,
        );
        await repository.addXp(characterId: _characterId, newXp: 130);
        expect(server.requests.where((r) => r.startsWith('PATCH')).length, 2);

        goOffline();
        final reopened = await repository.fetchCharacterDetail(_characterId);

        expect(reopened.currentHp, 8);
        expect(reopened.temporaryHp, 2);
        expect(reopened.xp, 130);
        expect(reopened.maxHp, 12);
        expect(reopened.name, 'Aragorn');
      },
    );

    test('écriture ou synchro réussie sans fiche en cache : aucune entrée '
        'de cache créée', () async {
      await repository.updateHp(
        characterId: _characterId,
        currentHp: 8,
        temporaryHp: 0,
      );
      await pendingWrites.enqueue(
        characterId: _characterId,
        ownerId: _ownerId,
        kind: PendingCharacterWriteKind.xp,
        payload: {'newXp': 150},
      );
      await syncer.sync();

      expect(await cache.get(_cacheKey), isNull);
    });

    test('écriture en ligne ou synchro en échec : le cache n\'est pas '
        'modifié', () async {
      await openOnlineOnce();
      await pendingWrites.enqueue(
        characterId: _characterId,
        ownerId: _ownerId,
        kind: PendingCharacterWriteKind.xp,
        payload: {'newXp': 150},
      );
      server.network = _Network.writesRejected;

      await expectLater(
        repository.updateHp(
          characterId: _characterId,
          currentHp: 8,
          temporaryHp: 0,
        ),
        throwsA(isA<Exception>()),
      );
      await syncer.sync();

      final cached = await cache.get(_cacheKey) as Map<String, dynamic>;
      expect((cached['row'] as Map)['current_hp'], 10);
      expect((cached['row'] as Map)['xp'], 100);
    });

    // Revue de code : le synchroniseur ne doit jamais envoyer un relevé de
    // la file pris avant une écriture en ligne plus récente.
    test('synchro en vol sur les PV, puis ajout d\'XP EN LIGNE qui remplace '
        "l'entrée XP en file : la synchro n'envoie pas son relevé périmé "
        '(150) par-dessus la valeur en ligne (180)', () async {
      await openOnlineOnce();
      goOffline();
      await repository.updateHp(
        characterId: _characterId,
        currentHp: 7,
        temporaryHp: 0,
      );
      await repository.addXp(characterId: _characterId, newXp: 150);

      // Réseau revenu : la synchro relève PV 7 et XP 150, envoie les PV, la
      // réponse est retenue.
      goOnline();
      final gate = Completer<void>();
      server.characterWriteGate = gate;
      final syncing = syncer.sync();
      await pumpEventQueue();
      expect(server.patchBodies, [
        {'current_hp': 7, 'temporary_hp': 0},
      ]);

      // Pendant ce temps, le joueur ajoute 30 XP en ligne (150 affichés).
      final outcome = await repository.addXp(
        characterId: _characterId,
        newXp: 180,
      );
      expect(outcome, WriteOutcome.synced);
      expect(await pendingPayload(PendingCharacterWriteKind.xp), isNull);

      gate.complete();
      await syncing;

      expect(
        server.patchBodies.where((body) => body['xp'] == 150),
        isEmpty,
        reason: "l'entrée XP 150 a été retirée par l'écriture en ligne",
      );
      expect(server.characterRow['xp'], 180);
      expect(server.characterRow['current_hp'], 7);
      expect(await pendingWrites.allForOwner(_ownerId), isEmpty);
      final cached = await cache.get(_cacheKey) as Map<String, dynamic>;
      expect((cached['row'] as Map)['xp'], 180);
    });

    test("synchro : une entrée remplacée entre le relevé et son tour d'envoi "
        'part dans sa version la plus récente, puis est retirée', () async {
      await openOnlineOnce();
      goOffline();
      await repository.updateHp(
        characterId: _characterId,
        currentHp: 7,
        temporaryHp: 0,
      );
      await repository.addXp(characterId: _characterId, newXp: 150);

      goOnline();
      final gate = Completer<void>();
      server.characterWriteGate = gate;
      final syncing = syncer.sync();
      await pumpEventQueue();

      // Le réseau retombe côté interface le temps d'un ajout mis en file.
      connectivity.connected = false;
      await repository.addXp(characterId: _characterId, newXp: 180);
      connectivity.connected = true;

      gate.complete();
      expect(await syncing, {_characterId});

      expect(server.patchBodies, [
        {'current_hp': 7, 'temporary_hp': 0},
        {'xp': 180},
      ]);
      expect(await pendingWrites.allForOwner(_ownerId), isEmpty);
    });

    // Revue de code : ordre des suites locales d'une écriture confirmée.
    test("écriture en ligne : l'entrée périmée est retirée de la file AVANT "
        'le report dans le cache', () async {
      await openOnlineOnce();
      await pendingWrites.enqueue(
        characterId: _characterId,
        ownerId: _ownerId,
        kind: PendingCharacterWriteKind.hp,
        payload: {'currentHp': 7, 'temporaryHp': 0},
      );
      final spyCache = _SpyCache(db, pendingWrites);
      final spiedRepository = SupabaseCharacterRepository(
        client,
        spyCache,
        pendingWrites,
        connectivity,
      );

      await spiedRepository.updateHp(
        characterId: _characterId,
        currentHp: 6,
        temporaryHp: 0,
      );

      expect(spyCache.pendingKindsAtUpdate, [<PendingCharacterWriteKind>[]]);
    });

    test(
      "synchro : le cache est mis à jour AVANT le retrait de l'entrée "
      '(une app tuée entre les deux rejoue une valeur égale au serveur)',
      () async {
        await openOnlineOnce();
        await pendingWrites.enqueue(
          characterId: _characterId,
          ownerId: _ownerId,
          kind: PendingCharacterWriteKind.hp,
          payload: {'currentHp': 7, 'temporaryHp': 0},
        );
        final spyCache = _SpyCache(db, pendingWrites);

        await PendingCharacterWriteSyncer(
          client,
          pendingWrites,
          spyCache,
        ).sync();

        expect(spyCache.pendingKindsAtUpdate, [
          [PendingCharacterWriteKind.hp],
        ]);
        expect(await pendingWrites.allForOwner(_ownerId), isEmpty);
      },
    );
  });

  // D33 : verrou partagé entre le dépôt (écriture en ligne) et le
  // synchroniseur (écriture de la file), par (characterId, kind) — plus
  // aucun PATCH du même type en vol en même temps pour le même personnage.
  group('D33 : verrou partagé repo/synchro', () {
    test(
      'deux ajustements PV en ligne concurrents pour le même personnage ne '
      'partent plus en parallèle : le second attend la confirmation du '
      'premier avant d\'envoyer son propre PATCH',
      () async {
        await openOnlineOnce();

        final gate = Completer<void>();
        server.characterWriteGate = gate;
        final first = repository.updateHp(
          characterId: _characterId,
          currentHp: 8,
          temporaryHp: 0,
        );
        await pumpEventQueue();
        expect(
          server.requests.where((r) => r == 'PATCH characters').length,
          1,
          reason: 'le premier PATCH est parti et en attente de réponse',
        );

        final second = repository.updateHp(
          characterId: _characterId,
          currentHp: 5,
          temporaryHp: 0,
        );
        await pumpEventQueue();
        expect(
          server.requests.where((r) => r == 'PATCH characters').length,
          1,
          reason:
              'le second appel est bloqué par le verrou (D33) : il ne doit '
              'pas encore avoir envoyé son propre PATCH',
        );

        gate.complete();
        expect(await first, WriteOutcome.synced);
        expect(await second, WriteOutcome.synced);

        expect(server.patchBodies, [
          {'current_hp': 8, 'temporary_hp': 0},
          {'current_hp': 5, 'temporary_hp': 0},
        ]);
        expect(server.characterRow['current_hp'], 5);
      },
    );

    test(
      'une synchronisation en vol et un ajustement en ligne du même type '
      'pour le même personnage ne partent plus en parallèle : l\'ajustement '
      'en ligne attend la fin de la synchro avant d\'envoyer son PATCH, et '
      'le résultat final reflète bien le dernier (le plus récent)',
      () async {
        await openOnlineOnce();
        goOffline();
        await repository.updateHp(
          characterId: _characterId,
          currentHp: 7,
          temporaryHp: 0,
        );

        goOnline();
        final gate = Completer<void>();
        server.characterWriteGate = gate;
        final syncing = syncer.sync();
        await pumpEventQueue();
        expect(
          server.requests.where((r) => r == 'PATCH characters').length,
          1,
          reason: 'la synchro a envoyé son PATCH (7) et attend la réponse',
        );

        final online = repository.updateHp(
          characterId: _characterId,
          currentHp: 3,
          temporaryHp: 0,
        );
        await pumpEventQueue();
        expect(
          server.requests.where((r) => r == 'PATCH characters').length,
          1,
          reason:
              'bloqué par le verrou (D33) : ne doit pas partir avant la fin '
              'de la synchro en vol',
        );

        gate.complete();
        expect(await syncing, {_characterId});
        expect(await online, WriteOutcome.synced);

        expect(server.patchBodies, [
          {'current_hp': 7, 'temporary_hp': 0},
          {'current_hp': 3, 'temporary_hp': 0},
        ]);
        expect(
          server.characterRow['current_hp'],
          3,
          reason:
              'le PATCH le plus récent (en ligne, 3) part bien après celui '
              'de la synchro (7), jamais en parallèle ni dans le désordre',
        );
        expect(await pendingWrites.allForOwner(_ownerId), isEmpty);
      },
    );
  });

  // D34 : compteur d'échecs, abandon après refus non rejouables consécutifs,
  // message consommable par le joueur.
  group('D34 : refus non rejouable, abandon après le seuil', () {
    test(
      'un refus non rejouable (RLS) répété SOUS le seuil est retenté à '
      'chaque synchro, sans être abandonné',
      () async {
        await openOnlineOnce();
        goOffline();
        await repository.updateHp(
          characterId: _characterId,
          currentHp: 7,
          temporaryHp: 0,
        );

        goOnline();
        server.network = _Network.writesRejected;
        server.writeErrorCode = '42501';

        for (
          var i = 0;
          i < PendingCharacterWriteQueue.abandonAfterConsecutiveFailures - 1;
          i++
        ) {
          expect(await syncer.sync(), isEmpty);
        }

        expect(
          await pendingPayload(PendingCharacterWriteKind.hp),
          {'currentHp': 7, 'temporaryHp': 0},
          reason: "toujours en file : le seuil n'est pas encore atteint",
        );
        expect(
          await pendingWrites.consumeAbandonedMessages(ownerId: _ownerId),
          isEmpty,
        );
      },
    );

    test(
      "après abandonAfterConsecutiveFailures refus non rejouables "
      "consécutifs, l'entrée est abandonnée : plus jamais retentée, plus "
      'superposée à la fiche, message consommable exactement une fois',
      () async {
        await openOnlineOnce();
        goOffline();
        await repository.updateHp(
          characterId: _characterId,
          currentHp: 7,
          temporaryHp: 0,
        );

        goOnline();
        server.network = _Network.writesRejected;
        server.writeErrorCode = '23503';

        for (
          var i = 0;
          i < PendingCharacterWriteQueue.abandonAfterConsecutiveFailures;
          i++
        ) {
          expect(await syncer.sync(), isEmpty);
        }

        expect(
          await pendingWrites.allForOwner(_ownerId),
          isEmpty,
          reason: 'abandonnée : ne doit plus apparaître comme en attente',
        );

        // Le serveur redevient joignable : plus aucun PATCH n'est retenté
        // pour cette entrée abandonnée.
        server.network = _Network.online;
        final patchCountBefore = server.patchBodies.length;
        expect(await syncer.sync(), isEmpty);
        expect(server.patchBodies.length, patchCountBefore);

        // La fiche ne la superpose plus : valeur serveur d'origine, jamais
        // écrasée puisque jamais réellement envoyée.
        final detail = await repository.fetchCharacterDetail(_characterId);
        expect(detail.currentHp, 10);

        final messages = await pendingWrites.consumeAbandonedMessages(
          ownerId: _ownerId,
        );
        expect(messages, hasLength(1));
        expect(messages.single, contains('PV'));
        expect(
          await pendingWrites.consumeAbandonedMessages(ownerId: _ownerId),
          isEmpty,
          reason: 'consommé une fois : ne doit plus jamais être signalé',
        );
      },
    );

    test(
      "un refus générique (transitoire, aucun code de contrainte/RLS) "
      "n'est jamais compté comme non rejouable : jamais abandonné même "
      'au-delà du seuil, toujours retenté (D32)',
      () async {
        await openOnlineOnce();
        goOffline();
        await repository.updateHp(
          characterId: _characterId,
          currentHp: 7,
          temporaryHp: 0,
        );

        goOnline();
        // Code par défaut du double : 'PGRST000', générique.
        server.network = _Network.writesRejected;

        for (
          var i = 0;
          i < PendingCharacterWriteQueue.abandonAfterConsecutiveFailures + 2;
          i++
        ) {
          expect(await syncer.sync(), isEmpty);
        }

        expect(await pendingPayload(PendingCharacterWriteKind.hp), {
          'currentHp': 7,
          'temporaryHp': 0,
        });
        expect(
          await pendingWrites.consumeAbandonedMessages(ownerId: _ownerId),
          isEmpty,
        );

        // Le réseau redevient disponible : la synchro aboutit normalement.
        server.network = _Network.online;
        expect(await syncer.sync(), {_characterId});
        expect(server.characterRow['current_hp'], 7);
      },
    );
  });

  group('circuit complet avec characterDetailProvider et le coordinateur de '
      'synchro (fiche ouverte/fermée = provider écouté/libéré)', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          characterRepositoryProvider.overrideWithValue(repository),
          pendingCharacterWriteSyncerProvider.overrideWithValue(syncer),
          connectivityCheckerProvider.overrideWithValue(connectivity),
        ],
      );
      addTearDown(container.dispose);
    });

    /// Ouvre la fiche (écoute `characterDetailProvider`, comme l'écran),
    /// attend la donnée, puis exécute [body] avant de la refermer (provider
    /// `autoDispose` libéré, comme à la fermeture de l'écran).
    Future<void> withOpenSheet(
      Future<void> Function(CharacterDetail detail, List<CharacterDetail> seen)
      body,
    ) async {
      final seen = <CharacterDetail>[];
      final subscription = container.listen<AsyncValue<CharacterDetail>>(
        characterDetailProvider(_characterId),
        (previous, next) {
          final value = next.value;
          if (next.hasValue && !next.isLoading && value != null) {
            seen.add(value);
          }
        },
        fireImmediately: true,
      );
      final detail = await container.read(
        characterDetailProvider(_characterId).future,
      );
      await pumpEventQueue();
      await body(detail, seen);
      subscription.close();
      await pumpEventQueue();
    }

    test('PV et XP : ajustement hors ligne, fermeture, réouverture, second '
        'ajustement, retour du réseau -> valeur serveur correcte, file '
        'vidée, aucune valeur intermédiaire affichée', () async {
      container.read(characterWriteSyncCoordinatorProvider);
      await pumpEventQueue();

      await withOpenSheet((detail, seen) async {
        expect(detail.currentHp, 10);
        expect(detail.xp, 100);
        goOffline();
        await repository.updateHp(
          characterId: _characterId,
          currentHp: detail.currentHp - 3,
          temporaryHp: 0,
        );
        await repository.addXp(
          characterId: _characterId,
          newXp: detail.xp + 50,
        );
      });

      // Réouverture hors ligne : la fiche relue repart des valeurs en file.
      await withOpenSheet((detail, seen) async {
        expect(detail.currentHp, 7);
        expect(detail.xp, 150);
        await repository.updateHp(
          characterId: _characterId,
          currentHp: detail.currentHp - 2,
          temporaryHp: 0,
        );
        await repository.addXp(
          characterId: _characterId,
          newXp: detail.xp + 30,
        );
      });

      // Troisième ouverture, toujours hors ligne, puis le réseau revient
      // pendant que la fiche est affichée.
      await withOpenSheet((detail, seen) async {
        expect(detail.currentHp, 5);
        expect(detail.xp, 180);

        goOnline();
        connectivity.emitRestored();
        await pumpEventQueue();

        expect(server.characterRow['current_hp'], 5);
        expect(server.characterRow['xp'], 180);
        expect(await pendingWrites.allForOwner(_ownerId), isEmpty);
        // Au moins deux données livrées (avant et après l'invalidation du
        // coordinateur), toutes identiques : aucun saut visible.
        expect(seen.length, greaterThanOrEqualTo(2));
        expect(seen.map((d) => d.currentHp).toSet(), {5});
        expect(seen.map((d) => d.xp).toSet(), {180});
      });
    });
  });
}

/// Requêtes émises par un `fetchCharacterDetail` réussi sur la fixture de ce
/// fichier — relevées sur `main` avant le correctif.
const _baselineFetchRequests = <String>[
  'GET characters',
  'GET translations',
  'GET races',
  'GET translations',
  'GET translations',
  'GET translations',
  'GET skills',
  'GET class_features',
];

enum _Network {
  /// Tout répond normalement.
  online,

  /// Toute requête lève une `SocketException` (interface coupée).
  down,

  /// Les lectures passent, les écritures sont refusées (HTTP 500).
  writesRejected,

  /// Toute requête (lecture comme écriture) est refusée par le serveur
  /// (HTTP 500) : contrairement à [down], le dépôt reçoit une
  /// `PostgrestException`, pas une erreur de transport.
  allRejected,
}

/// Double de serveur PostgREST avec état : garde la ligne `characters` en
/// mémoire, applique les `PATCH`, journalise chaque requête.
class _FakeServer {
  _Network network = _Network.online;

  /// `'<MÉTHODE> <table>'` par requête reçue, dans l'ordre.
  final List<String> requests = [];

  /// Corps JSON de chaque `PATCH characters` accepté, dans l'ordre.
  final List<Map<String, dynamic>> patchBodies = [];

  /// Si non nul, la prochaine lecture de `characters` fige sa réponse puis
  /// attend ce verrou avant de la renvoyer (réponse "plus ancienne" qui
  /// arrive tard).
  Completer<void>? characterReadGate;

  /// Si non nul, le prochain `PATCH characters` est appliqué côté serveur
  /// puis sa réponse attend ce verrou (écriture en ligne "en vol").
  Completer<void>? characterWriteGate;

  /// Code d'erreur Postgres/PostgREST renvoyé quand [network] vaut
  /// [_Network.writesRejected] — `'PGRST000'` (erreur générique, transitoire
  /// du point de vue de `PendingCharacterWriteSyncer._isNonRetryable`) par
  /// défaut ; les tests D34 le changent pour simuler un refus non rejouable
  /// (ex. `'42501'` RLS, `'23503'` contrainte de clé étrangère).
  String writeErrorCode = 'PGRST000';

  Map<String, dynamic> characterRow = {
    'id': _characterId,
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
  };

  static const _otherTables = <String, List<Map<String, dynamic>>>{
    'translations': [
      {'entity_id': '1', 'value': 'Humain'},
      {'entity_id': '3', 'value': 'Soldat'},
      {'entity_id': '9', 'value': 'Loyal bon'},
      {'entity_id': '2', 'value': 'Guerrier'},
    ],
  };

  Future<http.Response> handle(http.Request request) async {
    final table = request.url.pathSegments.last;
    requests.add('${request.method} $table');

    if (network == _Network.down) {
      throw const SocketException('Pas de réseau (double de test).');
    }

    if (network == _Network.allRejected) {
      return _json(request, {
        'message': 'Serveur en erreur (double de test).',
        'code': 'PGRST000',
      }, statusCode: 500);
    }

    final isWrite = request.method != 'GET';
    if (isWrite) {
      if (network == _Network.writesRejected) {
        return _json(request, {
          'message': 'Écriture refusée (double de test).',
          'code': writeErrorCode,
        }, statusCode: 500);
      }
      if (table == 'characters') {
        final body = Map<String, dynamic>.from(jsonDecode(request.body) as Map);
        patchBodies.add(body);
        characterRow = {...characterRow, ...body};
        final gate = characterWriteGate;
        if (gate != null) {
          characterWriteGate = null;
          await gate.future;
        }
      }
      return _json(request, const <Object>[]);
    }

    if (table == 'characters') {
      final snapshot = [Map<String, dynamic>.from(characterRow)];
      final gate = characterReadGate;
      if (gate != null) {
        characterReadGate = null;
        await gate.future;
      }
      return _json(request, snapshot);
    }
    return _json(request, _otherTables[table] ?? const <Object>[]);
  }

  static http.Response _json(
    http.Request request,
    Object body, {
    int statusCode = 200,
  }) {
    return http.Response(
      jsonEncode(body),
      statusCode,
      request: request,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}

/// Cache espion : relève, au moment précis où une écriture confirmée est
/// reportée dans le cache, les types encore en file pour [_characterId].
class _SpyCache extends ReferenceDataCache {
  _SpyCache(super.db, this._queue);

  final PendingCharacterWriteQueue _queue;
  final List<List<PendingCharacterWriteKind>> pendingKindsAtUpdate = [];

  @override
  Future<void> updateIfPresent(
    String key,
    Object? Function(Object? payload) transform,
  ) async {
    final pending = await _queue.forCharacter(
      ownerId: _ownerId,
      characterId: _characterId,
    );
    pendingKindsAtUpdate.add([for (final write in pending) write.kind]);
    await super.updateIfPresent(key, transform);
  }
}

class _FakeConnectivityChecker implements ConnectivityChecker {
  bool connected = true;
  final _restored = StreamController<bool>.broadcast();

  @override
  Future<bool> hasConnection() async => connected;

  @override
  Stream<bool> get onConnectivityRestored => _restored.stream;

  void emitRestored() => _restored.add(true);
}

/// Même mécanisme que `character_repository_test.dart::
/// _buildSignedInFakeSupabaseClient` (transport HTTP fabriqué, session
/// restaurée en mémoire sans requête) — voir sa documentation.
Future<SupabaseClient> _buildSignedInClient(
  _FakeServer server, {
  required String ownerId,
}) async {
  final client = SupabaseClient(
    'https://fake.supabase.test',
    'fake-anon-key',
    httpClient: MockClient(server.handle),
    postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );
  await client.auth.recoverSession(
    jsonEncode({
      'access_token': 'fake-access-token-$ownerId',
      'token_type': 'bearer',
      'user': {'id': ownerId},
    }),
  );
  return client;
}
