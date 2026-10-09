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

/// Couvre la dette D10 (`docs/dette-technique.md`) côté client, en amont de
/// la migration qui pose deux index uniques partiels sur `character_spells`
/// (au plus une ligne `'inné'`, au plus une ligne ordinaire par
/// `(character_id, spell_id)`, pas encore fusionnée/appliquée en production
/// au moment de ce correctif) : [SupabaseCharacterRepository.applyLevelUp]
/// doit filtrer `initialSpellIds` contre les sorts déjà connus du personnage
/// avant insertion, exactement comme le fait déjà `racialInnateSpellIds`
/// (voir la documentation de `applyLevelUp`) — sans ce filtre, un
/// multiclassage vers une classe dont la liste de sorts initiaux recoupe un
/// sort déjà connu via une autre classe (ex. "Soins", présent sur plusieurs
/// listes) ferait planter la montée de niveau sur une violation de
/// contrainte unique, au lieu d'ignorer silencieusement le sort déjà connu.
///
/// Même double `SupabaseClient`/`MockClient` que
/// `character_repository_innate_spells_test.dart`/
/// `character_repository_rest_test.dart` : ces tests vérifient ce qui est
/// *envoyé* à PostgREST, jamais le comportement d'une base réelle.
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
  const bardeClassId = 1;
  const occultisteClassId = 2;
  const knownSpellId = 100; // déjà connu du personnage via sa classe Barde.
  const newSpellId = 101; // vrai nouveau sort initial de l'Occultiste.

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

  group('SupabaseCharacterRepository.applyLevelUp — initialSpellIds', () {
    test(
      'multiclassage vers une classe dont un sort initial recoupe un sort '
      "déjà connu d'une autre classe : l'opération réussit, le sort déjà "
      'connu est ignoré silencieusement (jamais réécrit, statut/classe '
      "source d'origine préservés), seul le vrai nouveau sort est inséré",
      () async {
        final recorded = <_Recorded>[];
        final repo = await repository(
          recorded: recorded,
          rows: {
            'character_classes': [
              {'id': 'cc-barde', 'class_id': bardeClassId, 'level': 1},
            ],
            'characters': [
              {'max_hp': 10, 'current_hp': 10},
            ],
            'character_ability_scores': [
              {'ability_id': 'cha', 'score': 14},
            ],
            'translations': [
              {'entity_id': '$bardeClassId', 'value': 'Barde'},
            ],
            // Lu par [_fetchKnownSpellIds] avant l'insertion des sorts
            // initiaux : ce sort est déjà connu, via une AUTRE classe
            // (`source_class_id` = Barde, pas Occultiste).
            'character_spells': [
              {
                'spell_id': knownSpellId,
                'status': 'connu',
                'source_class_id': bardeClassId,
              },
            ],
          },
        );

        final result = await repo.applyLevelUp(
          characterId: characterId,
          classId: occultisteClassId,
          className: 'Occultiste',
          isMulticlassing: true,
          hpRolled: 4,
          hpMethod: 'roll',
          hpGain: 4,
          initialSpellIds: const [knownSpellId, newSpellId],
        );

        // L'opération réussit (pas d'exception) et le niveau est bien
        // appliqué — rien ne doit bloquer la montée de niveau à cause du
        // sort déjà connu.
        expect(result.newLevel, 2);
        expect(result.newMaxHp, 14);
        expect(result.newCurrentHp, 14);

        // Une seule écriture sur `character_spells`, et elle ne contient que
        // le vrai nouveau sort : le sort déjà connu n'est jamais réécrit
        // (ni réinséré, ni mis à jour), il garde donc forcément son statut
        // et sa classe source d'origine (Barde) intacts.
        final spellWrites = recorded
            .where((r) => r.table == 'character_spells' && r.method != 'GET')
            .toList();
        expect(spellWrites, hasLength(1));
        final insertedRows = (spellWrites.single.body! as List)
            .cast<Map<String, dynamic>>();
        expect(insertedRows.map((row) => row['spell_id']), [newSpellId]);
        expect(insertedRows.single, {
          'character_id': characterId,
          'spell_id': newSpellId,
          'status': 'connu',
          'source_class_id': occultisteClassId,
        });
      },
    );

    test(
      'aucun recoupement : les deux sorts initiaux sont insérés normalement '
      '(non-régression)',
      () async {
        final recorded = <_Recorded>[];
        final repo = await repository(
          recorded: recorded,
          rows: {
            'character_classes': [
              {'id': 'cc-barde', 'class_id': bardeClassId, 'level': 1},
            ],
            'characters': [
              {'max_hp': 10, 'current_hp': 10},
            ],
            'character_ability_scores': [
              {'ability_id': 'cha', 'score': 14},
            ],
            'translations': [
              {'entity_id': '$bardeClassId', 'value': 'Barde'},
            ],
            'character_spells': <Map<String, dynamic>>[],
          },
        );

        await repo.applyLevelUp(
          characterId: characterId,
          classId: occultisteClassId,
          className: 'Occultiste',
          isMulticlassing: true,
          hpRolled: 4,
          hpMethod: 'roll',
          hpGain: 4,
          initialSpellIds: const [knownSpellId, newSpellId],
        );

        final spellWrites = recorded
            .where((r) => r.table == 'character_spells' && r.method != 'GET')
            .toList();
        expect(spellWrites, hasLength(1));
        final insertedIds = (spellWrites.single.body! as List)
            .cast<Map<String, dynamic>>()
            .map((row) => row['spell_id'])
            .toSet();
        expect(insertedIds, {knownSpellId, newSpellId});
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

/// Même double que `character_repository_innate_spells_test.dart`/
/// `character_repository_rest_test.dart` : routage par nom de table, session
/// factice sans réseau, journal [recorded] des requêtes. Les lignes
/// configurées via [tableRows] sont retournées pour TOUTE requête `GET` sur
/// la table correspondante, indépendamment des filtres de la requête (les
/// filtres ne sont pas réinterprétés côté double) — suffisant ici, chaque
/// table n'étant lue qu'une seule fois par scénario.
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
    final rows = tableRows[table] ?? const <Map<String, dynamic>>[];
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
