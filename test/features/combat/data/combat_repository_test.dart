// Tests de `SupabaseCombatRepository` : `SupabaseClient` réel, transport HTTP
// entièrement fabriqué via `MockClient` (même stratégie que
// `group_repository_test.dart`). Vérifie les paramètres `p_*` exacts, le
// mapping des retours, l'absence d'écriture directe sur les tables et le
// refus hors ligne sans appel réseau.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personnages/features/combat/data/combat_repository.dart';
import 'package:personnages/features/combat/domain/combat_enums.dart';
import 'package:personnages/features/combat/domain/combat_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../support/fake_connectivity_checker.dart';

Map<String, dynamic> _combatJson({String status = 'active'}) => {
  'id': 'combat-1',
  'group_id': 'group-1',
  'status': status,
  'round': 1,
  'current_participant_id': null,
  'started_by': 'user-1',
  'created_at': '2026-11-14T09:00:00+00:00',
  'ended_at': status == 'ended' ? '2026-11-14T10:00:00+00:00' : null,
};

Map<String, dynamic> _participantJson(
  String id, {
  int? initiative,
  int sortOrder = 1,
  String status = 'active',
}) => {
  'id': id,
  'combat_id': 'combat-1',
  'group_id': 'group-1',
  'character_id': null,
  'user_id': null,
  'name': 'Gobelin',
  'kind': 'npc',
  'initiative': initiative,
  'sort_order': sortOrder,
  'status': status,
  'created_at': '2026-11-14T09:00:00+00:00',
};

class _Harness {
  _Harness({
    this.body = const <String, dynamic>{},
    this.statusCode = 200,
    bool connected = true,
  }) : connectivity = FakeConnectivityChecker(connected: connected) {
    client = SupabaseClient(
      'https://fake.supabase.test',
      'fake-anon-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode(body),
          statusCode,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
      postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
    repository = SupabaseCombatRepository(client, connectivity);
  }

  Object body;
  final int statusCode;
  final FakeConnectivityChecker connectivity;
  final List<http.Request> requests = [];
  late final SupabaseClient client;
  late final SupabaseCombatRepository repository;

  http.Request get last => requests.last;
  Map<String, dynamic> get lastBody =>
      jsonDecode(last.body) as Map<String, dynamic>;
}

void main() {
  group('lecture', () {
    test('fetchActiveCombat : une seule requête embarquée sur combats, '
        'filtrée par groupe et statut actif', () async {
      final h = _Harness(
        body: [
          {
            ..._combatJson(),
            'combat_participants': [
              _participantJson('p1', initiative: 12),
              _participantJson('p2'),
            ],
          },
        ],
      );

      final snapshot = await h.repository.fetchActiveCombat('group-1');

      expect(h.requests, hasLength(1));
      expect(h.last.method, 'GET');
      expect(h.last.url.path, endsWith('/rest/v1/combats'));
      expect(h.last.url.queryParameters['group_id'], 'eq.group-1');
      expect(h.last.url.queryParameters['status'], 'eq.active');
      final select = h.last.url.queryParameters['select']!;
      expect(select, contains('combat_participants('));
      expect(select, isNot(contains('hp')));
      expect(snapshot, isNotNull);
      expect(snapshot!.combat.id, 'combat-1');
      expect(snapshot.participants.map((p) => p.id), ['p1', 'p2']);
      expect(snapshot.participants.first.initiative, 12);
    });

    test('fetchActiveCombat : aucun combat -> null', () async {
      final h = _Harness(body: const <dynamic>[]);
      expect(await h.repository.fetchActiveCombat('group-1'), isNull);
    });

    test('fetchActiveCombat : erreur serveur -> CombatFailure', () async {
      final h = _Harness(
        body: {'message': 'not_authenticated', 'code': '28000'},
        statusCode: 400,
      );
      await expectLater(
        h.repository.fetchActiveCombat('group-1'),
        throwsA(
          isA<CombatFailure>().having(
            (f) => f.kind,
            'kind',
            CombatFailureKind.notAuthenticated,
          ),
        ),
      );
    });
  });

  group('écritures : RPC et paramètres p_*', () {
    void expectRpc(_Harness h, String name, Map<String, dynamic> params) {
      expect(h.requests, hasLength(1));
      expect(h.last.method, 'POST');
      expect(h.last.url.path, endsWith('/rest/v1/rpc/$name'));
      expect(h.lastBody, params);
    }

    test('startCombat', () async {
      final h = _Harness(body: _combatJson());
      final combat = await h.repository.startCombat('group-1');
      expectRpc(h, 'start_combat', {'p_group_id': 'group-1'});
      expect(combat.id, 'combat-1');
      expect(combat.status, CombatStatus.active);
    });

    test('endCombat', () async {
      final h = _Harness(body: _combatJson(status: 'ended'));
      final combat = await h.repository.endCombat('combat-1');
      expectRpc(h, 'end_combat', {'p_combat_id': 'combat-1'});
      expect(combat.status, CombatStatus.ended);
    });

    test('setMyInitiative', () async {
      final h = _Harness(body: _participantJson('p1', initiative: 17));
      final p = await h.repository.setMyInitiative(
        combatId: 'combat-1',
        initiative: 17,
      );
      expectRpc(h, 'set_my_initiative', {
        'p_combat_id': 'combat-1',
        'p_initiative': 17,
      });
      expect(p.initiative, 17);
    });

    test('setParticipantInitiative envoie null pour effacer', () async {
      final h = _Harness(body: _participantJson('p1'));
      final p = await h.repository.setParticipantInitiative(
        participantId: 'p1',
        initiative: null,
      );
      expectRpc(h, 'set_participant_initiative', {
        'p_participant_id': 'p1',
        'p_initiative': null,
      });
      expect(p.initiative, isNull);
    });

    test('addNpcParticipants', () async {
      final h = _Harness(
        body: [
          _participantJson('p1', initiative: 9, sortOrder: 1),
          _participantJson('p2', initiative: 9, sortOrder: 2),
        ],
      );
      final list = await h.repository.addNpcParticipants(
        combatId: 'combat-1',
        baseName: 'Gobelin',
        initiative: 9,
        count: 2,
      );
      expectRpc(h, 'add_npc_participants', {
        'p_combat_id': 'combat-1',
        'p_base_name': 'Gobelin',
        'p_initiative': 9,
        'p_count': 2,
      });
      expect(list.map((p) => p.id), ['p1', 'p2']);
    });

    test('addNpcParticipants : défauts count=1, initiative null', () async {
      final h = _Harness(body: [_participantJson('p1')]);
      await h.repository.addNpcParticipants(
        combatId: 'combat-1',
        baseName: 'Ogre',
      );
      expectRpc(h, 'add_npc_participants', {
        'p_combat_id': 'combat-1',
        'p_base_name': 'Ogre',
        'p_initiative': null,
        'p_count': 1,
      });
    });

    test('removeParticipant', () async {
      final h = _Harness(body: _participantJson('p1', status: 'removed'));
      final p = await h.repository.removeParticipant('p1');
      expectRpc(h, 'remove_participant', {'p_participant_id': 'p1'});
      expect(p.status, ParticipantStatus.removed);
    });

    test('reorderParticipant', () async {
      final h = _Harness(
        body: [
          _participantJson('p2', sortOrder: 1),
          _participantJson('p1', sortOrder: 2),
        ],
      );
      final list = await h.repository.reorderParticipant(
        participantId: 'p1',
        newSortOrder: 2,
      );
      expectRpc(h, 'reorder_participant', {
        'p_participant_id': 'p1',
        'p_new_sort_order': 2,
      });
      expect(list.map((p) => p.id), ['p2', 'p1']);
    });

    test('aucune écriture directe sur les tables (POST/PATCH/DELETE) : '
        'toutes les écritures passent par /rpc/', () async {
      final h = _Harness(body: _combatJson());
      await h.repository.startCombat('g');
      h.body = _combatJson(status: 'ended');
      await h.repository.endCombat('c');
      h.body = _participantJson('p');
      await h.repository.setMyInitiative(combatId: 'c', initiative: 1);
      await h.repository.setParticipantInitiative(
        participantId: 'p',
        initiative: 1,
      );
      await h.repository.removeParticipant('p');
      h.body = [_participantJson('p')];
      await h.repository.addNpcParticipants(combatId: 'c', baseName: 'n');
      await h.repository.reorderParticipant(
        participantId: 'p',
        newSortOrder: 1,
      );
      expect(h.requests, hasLength(7));
      for (final request in h.requests) {
        expect(request.url.path, contains('/rest/v1/rpc/'));
      }
    });

    test('erreur RPC -> CombatFailure typé (message + SQLSTATE)', () async {
      final h = _Harness(
        body: {'message': 'no_game_master', 'code': 'P0001'},
        statusCode: 400,
      );
      await expectLater(
        h.repository.startCombat('group-1'),
        throwsA(
          isA<CombatFailure>()
              .having((f) => f.kind, 'kind', CombatFailureKind.noGameMaster)
              .having((f) => f.sqlState, 'sqlState', 'P0001'),
        ),
      );
    });

    test('code non reconnu -> unknown', () async {
      final h = _Harness(
        body: {'message': 'nouveau_code', 'code': 'P0001'},
        statusCode: 400,
      );
      await expectLater(
        h.repository.endCombat('c'),
        throwsA(
          isA<CombatFailure>().having(
            (f) => f.kind,
            'kind',
            CombatFailureKind.unknown,
          ),
        ),
      );
    });
  });

  group('hors ligne', () {
    test('chaque écriture lève offline sans aucun appel réseau', () async {
      final h = _Harness(connected: false);
      final calls = <String, Future<Object?> Function()>{
        'start': () => h.repository.startCombat('g'),
        'end': () => h.repository.endCombat('c'),
        'mine': () =>
            h.repository.setMyInitiative(combatId: 'c', initiative: 1),
        'set': () => h.repository.setParticipantInitiative(
          participantId: 'p',
          initiative: 1,
        ),
        'add': () =>
            h.repository.addNpcParticipants(combatId: 'c', baseName: 'n'),
        'remove': () => h.repository.removeParticipant('p'),
        'reorder': () => h.repository.reorderParticipant(
          participantId: 'p',
          newSortOrder: 1,
        ),
      };
      for (final entry in calls.entries) {
        await expectLater(
          entry.value(),
          throwsA(
            isA<CombatFailure>().having(
              (f) => f.kind,
              entry.key,
              CombatFailureKind.offline,
            ),
          ),
        );
      }
      expect(h.requests, isEmpty);
    });
  });
}
