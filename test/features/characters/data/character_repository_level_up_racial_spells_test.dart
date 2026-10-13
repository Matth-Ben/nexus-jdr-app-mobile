import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/core/network/connectivity_checker.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// `SupabaseCharacterRepository.applyLevelUp` — écriture des sorts innés
/// raciaux ([racialInnateSpellIds], `_fetchAlreadyInnateSpellIds`).
///
/// Décision de Matthias du 10/10/2026, cohérente avec D43 du registre de
/// dette technique (`docs/dette-technique.md`) : un sort déjà connu
/// UNIQUEMENT via sa route ORDINAIRE (classe) garde malgré tout le droit à sa
/// ligne 'inné' séparée — les deux routes RAW sont indépendantes. Seule une
/// ligne 'inné' DÉJÀ EXISTANTE (accordée à un niveau antérieur,
/// `fetchApplicableGrants` étant cumulatif) doit empêcher une réécriture
/// (violerait l'index unique partiel dédié, D10).
///
/// Même double `SupabaseClient`/`MockClient` que
/// `character_repository_level_up_initial_spells_test.dart`, mais le
/// transport de ce fichier respecte le filtre `status=eq.<valeur>` sur
/// `character_spells` (contrairement à celui des autres fichiers de ce
/// répertoire, qui l'ignorent) : nécessaire pour distinguer une ligne 'inné'
/// déjà existante d'une ligne ordinaire du même sort, ce qui est précisément
/// le point testé ici.
void main() {
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
  const classId = 5;
  const alreadyInnateSpellId = 403; // déjà une ligne 'inné' en base.
  const dualRouteSpellId = 404; // déjà connu, mais ORDINAIRE seulement.
  const newSpellId = 405; // vrai nouveau sort inné.

  Future<SupabaseCharacterRepository> repository({
    Map<String, List<Map<String, dynamic>>> rows = const {},
    List<_Recorded>? recorded,
  }) async => SupabaseCharacterRepository(
    await _buildSignedInFakeSupabaseClient(
      ownerId: ownerId,
      recorded: recorded ?? <_Recorded>[],
      tableRows: rows,
    ),
    cache,
    pendingWrites,
    _FakeConnectivityChecker(connected: true),
  );

  group('SupabaseCharacterRepository.applyLevelUp — racialInnateSpellIds '
      '(D43)', () {
    test('un sort déjà "inné" en base (accordé à un niveau antérieur, grants '
        'cumulatifs) : jamais réécrit (éviterait de violer l\'index unique '
        'partiel dédié)', () async {
      final recorded = <_Recorded>[];
      final repo = await repository(
        recorded: recorded,
        rows: {
          'character_classes': [
            {'id': 'cc-1', 'class_id': classId, 'level': 1},
          ],
          'characters': [
            {'max_hp': 10, 'current_hp': 10},
          ],
          'character_ability_scores': [
            {'ability_id': 'cha', 'score': 14},
          ],
          'translations': [
            {'entity_id': '$classId', 'value': 'Guerrier'},
          ],
          'character_spells': [
            {
              'spell_id': alreadyInnateSpellId,
              'status': 'inné',
              'source_class_id': null,
            },
          ],
        },
      );

      await repo.applyLevelUp(
        characterId: characterId,
        classId: classId,
        className: 'Guerrier',
        isMulticlassing: false,
        hpRolled: 4,
        hpMethod: 'roll',
        hpGain: 4,
        racialInnateSpellIds: const [alreadyInnateSpellId, newSpellId],
      );

      final spellWrites = recorded
          .where((r) => r.table == 'character_spells' && r.method != 'GET')
          .toList();
      expect(spellWrites, hasLength(1));
      final insertedRows = (spellWrites.single.body! as List)
          .cast<Map<String, dynamic>>();
      expect(insertedRows.map((row) => row['spell_id']), [newSpellId]);
      expect(insertedRows.single['status'], 'inné');
    });

    test(
      'un sort déjà connu UNIQUEMENT via sa route ORDINAIRE (classe), SANS '
      'ligne \'inné\' : la ligne \'inné\' est malgré tout écrite (D43 — les '
      'deux routes sont indépendantes, aucune n\'empêche l\'autre)',
      () async {
        final recorded = <_Recorded>[];
        final repo = await repository(
          recorded: recorded,
          rows: {
            'character_classes': [
              {'id': 'cc-1', 'class_id': classId, 'level': 1},
            ],
            'characters': [
              {'max_hp': 10, 'current_hp': 10},
            ],
            'character_ability_scores': [
              {'ability_id': 'cha', 'score': 14},
            ],
            'translations': [
              {'entity_id': '$classId', 'value': 'Guerrier'},
            ],
            // Ligne ORDINAIRE existante du même sort que celui accordé par
            // la race — aucune ligne 'inné' pour ce sort.
            'character_spells': [
              {
                'spell_id': dualRouteSpellId,
                'status': 'préparé',
                'source_class_id': classId,
              },
            ],
          },
        );

        await repo.applyLevelUp(
          characterId: characterId,
          classId: classId,
          className: 'Guerrier',
          isMulticlassing: false,
          hpRolled: 4,
          hpMethod: 'roll',
          hpGain: 4,
          racialInnateSpellIds: const [dualRouteSpellId],
        );

        final spellWrites = recorded
            .where((r) => r.table == 'character_spells' && r.method != 'GET')
            .toList();
        expect(spellWrites, hasLength(1));
        final insertedRows = (spellWrites.single.body! as List)
            .cast<Map<String, dynamic>>();
        expect(insertedRows.single, {
          'character_id': characterId,
          'spell_id': dualRouteSpellId,
          'status': 'inné',
          'source_class_id': null,
        });
      },
    );
  });
}

/// Une requête PostgREST observée par le double de test.
class _Recorded {
  _Recorded({
    required this.method,
    required this.table,
    required this.query,
    required this.body,
  });

  final String method;
  final String table;
  final Map<String, String> query;

  /// Corps JSON décodé, `null` pour une requête sans corps.
  final Object? body;

  @override
  String toString() => '$method $table $query $body';
}

class _FakeConnectivityChecker implements ConnectivityChecker {
  _FakeConnectivityChecker({required this.connected});

  final bool connected;

  @override
  Future<bool> hasConnection() async => connected;

  @override
  Stream<bool> get onConnectivityRestored => const Stream.empty();
}

/// Même principe que
/// `character_repository_level_up_initial_spells_test.dart` (routage par nom
/// de table, session factice sans réseau, journal [recorded] des requêtes),
/// SAUF pour `character_spells` en GET : applique le filtre
/// `status=eq.<valeur>` de la requête sur les lignes configurées, plutôt que
/// de les renvoyer toutes indistinctement — nécessaire pour ce fichier (voir
/// sa documentation de classe).
Future<SupabaseClient> _buildSignedInFakeSupabaseClient({
  required String ownerId,
  required List<_Recorded> recorded,
  Map<String, List<Map<String, dynamic>>> tableRows = const {},
}) async {
  Future<http.Response> handler(http.Request request) async {
    final table = request.url.pathSegments.last;
    recorded.add(
      _Recorded(
        method: request.method,
        table: table,
        query: request.url.queryParameters,
        body: request.body.isEmpty ? null : jsonDecode(request.body),
      ),
    );
    var rows = tableRows[table] ?? const <Map<String, dynamic>>[];
    final statusFilter = request.url.queryParameters['status'];
    if (request.method == 'GET' &&
        table == 'character_spells' &&
        statusFilter != null &&
        statusFilter.startsWith('eq.')) {
      final expected = statusFilter.substring('eq.'.length);
      rows = [
        for (final row in rows)
          if (row['status'] == expected) row,
      ];
    }
    return http.Response(
      jsonEncode(request.method == 'GET' ? rows : const <Object>[]),
      200,
      request: request,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  final client = SupabaseClient(
    'https://fake.supabase.test',
    'fake-anon-key',
    httpClient: MockClient(handler),
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
