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

/// Test de régression pour le correctif urgent documenté par D86 du registre
/// de dette technique (`docs/dette-technique.md`) : malgré le correctif Moine
/// de PR #150, `SupabaseCharacterRepository.fetchAvailableElementalDisciplines`
/// et le bloc `elementalDisciplineNames` d'`applyLevelUp` résolvaient la ligne
/// `class_features` (`choice_type = 'discipline_elementaire'`, id793 en base
/// réelle) via `.eq('class_id', classId)` — alors que `class_id` est NULL sur
/// cette ligne de sous-classe (seul `subclass_id` est rempli, confirmé par
/// D85). `col = valeur` ne matche structurellement jamais une colonne NULL en
/// PostgREST/SQL : ce filtre ne retrouvait donc JAMAIS cette ligne.
///
/// Ce double `SupabaseClient`/`MockClient` est volontairement DIFFÉRENT des
/// autres fichiers `character_repository_level_up_*_test.dart` de ce
/// répertoire (qui ignorent les filtres de requête) : contrairement à eux,
/// celui-ci applique réellement le filtre `eq.<valeur>` sur `class_features`,
/// avec la sémantique SQL exacte (une colonne NULL ne correspond jamais à un
/// `eq`) — c'est précisément ce comportement qui a produit la régression, et
/// qui doit être reproduit ici pour que ce test ait un sens.
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
  const classId = 9; // Moine.
  const subclassId = 66; // Voie des quatre éléments.
  const disciplineFeatureId = 793;

  // Ligne `class_features` telle que confirmée en base réelle par lecture
  // directe (D85/D86) : `class_id` NULL, seul `subclass_id` rempli.
  final disciplineFeatureRow = {
    'id': disciplineFeatureId,
    'class_id': null,
    'subclass_id': subclassId,
    'choice_type': 'discipline_elementaire',
  };

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

  group('SupabaseCharacterRepository.applyLevelUp — elementalDisciplineNames '
      '(D86)', () {
    test("résout la ligne `class_features` malgré `class_id` NULL (seul "
        '`subclass_id` rempli) : la montée de niveau réussit et la discipline '
        'est écrite — ÉCHOUERAIT (CharacterFailure) avec un filtre '
        "`.eq('class_id', classId)` sur cette résolution", () async {
      final recorded = <_Recorded>[];
      final repo = await repository(
        recorded: recorded,
        rows: {
          'character_classes': [
            {'id': 'cc-1', 'class_id': classId, 'level': 2},
          ],
          'characters': [
            {'max_hp': 10, 'current_hp': 10},
          ],
          'class_features': [disciplineFeatureRow],
        },
      );

      final result = await repo.applyLevelUp(
        characterId: characterId,
        classId: classId,
        className: 'Moine',
        isMulticlassing: false,
        hpRolled: 4,
        hpMethod: 'roll',
        hpGain: 4,
        elementalDisciplineNames: const ['Souffle du dragon'],
      );

      expect(result.newLevel, 3);

      final optionWrites = recorded
          .where(
            (r) => r.table == 'character_class_options' && r.method != 'GET',
          )
          .toList();
      expect(optionWrites, hasLength(1));
      final insertedRows = (optionWrites.single.body! as List)
          .cast<Map<String, dynamic>>();
      expect(insertedRows.single, {
        'character_id': characterId,
        'class_feature_id': disciplineFeatureId,
        'level': 3,
        'chosen_value': 'Souffle du dragon',
      });
    });
  });

  group(
    'SupabaseCharacterRepository.fetchAvailableElementalDisciplines (D86)',
    () {
      test('une discipline déjà choisie à un palier précédent est exclue du '
          "catalogue — resterait TOUJOURS proposée (jamais exclue) avec un "
          "filtre `.eq('class_id', classId)` sur cette résolution", () async {
        final repo = await repository(
          rows: {
            'class_features': [disciplineFeatureRow],
            // Déjà choisie au niveau 3.
            'character_class_options': [
              {
                'chosen_value': 'Souffle du dragon',
                'class_feature_id': disciplineFeatureId,
              },
            ],
            'class_options': [
              {'id': 1, 'min_level': 3},
              {'id': 2, 'min_level': 6},
            ],
            'translations': [
              {'entity_id': '1', 'value': 'Souffle du dragon'},
              {'entity_id': '2', 'value': 'Poing qui frappe comme la foudre'},
            ],
          },
        );

        final options = await repo.fetchAvailableElementalDisciplines(
          characterId: characterId,
          classId: classId,
          subclassId: subclassId,
          targetLevel: 6,
        );

        expect(options, hasLength(1));
        expect(options.single.name, 'Poing qui frappe comme la foudre');
      });
    },
  );
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

/// Même principe que les autres doubles `character_repository_level_up_*` de
/// ce répertoire (routage par nom de table, session factice sans réseau,
/// journal [recorded]), mais celui-ci applique réellement le filtre
/// `eq.<valeur>` sur `class_features` (voir la documentation de ce fichier) —
/// avec la sémantique SQL exacte : une colonne NULL ne correspond jamais à un
/// `eq`, quelle que soit la valeur comparée. Les autres tables ignorent les
/// filtres de la requête (suffisant ici, chaque autre table n'étant lue
/// qu'une seule fois par scénario, même simplification que les autres
/// fichiers de ce répertoire).
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
    if (request.method == 'GET' && table == 'class_features') {
      for (final entry in request.url.queryParameters.entries) {
        if (entry.key == 'select' || entry.key == 'order') {
          continue;
        }
        rows = [
          for (final row in rows)
            if (_matchesEq(row, entry)) row,
        ];
      }
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

/// Sémantique SQL/PostgREST exacte d'un `eq.<valeur>` : une colonne NULL ne
/// correspond JAMAIS à un `eq`, quelle que soit la valeur comparée — c'est
/// précisément ce comportement qui a produit la régression D86
/// (`class_features.class_id` NULL face à `.eq('class_id', classId)`).
bool _matchesEq(Map<String, dynamic> row, MapEntry<String, String> filter) {
  if (!filter.value.startsWith('eq.')) {
    return true;
  }
  final rowValue = row[filter.key];
  if (rowValue == null) {
    return false;
  }
  final expected = filter.value.substring('eq.'.length);
  return rowValue.toString() == expected;
}
