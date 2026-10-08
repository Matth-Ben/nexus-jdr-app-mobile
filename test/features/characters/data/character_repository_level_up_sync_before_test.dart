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
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// D35 du registre de dette technique (`docs/dette-technique.md`) :
/// `applyLevelUp` relit `characters.max_hp`/`current_hp` depuis le serveur
/// pour y ajouter `hpGain` — avant cette lecture, la méthode doit d'abord
/// forcer la synchronisation de la file hors ligne PV/XP
/// (`PendingCharacterWriteQueue`/`PendingCharacterWriteSyncer`, voir
/// `SupabaseCharacterRepository._blockIfPendingHpOrXpWrites`) et bloquer
/// l'opération si une entrée pour ce personnage y résiste encore.
///
/// Portée volontairement restreinte à ce seul garde-fou (pas une
/// réplique de la matrice complète de `applyLevelUp`, déjà couverte côté
/// écran par des doubles de `CharacterRepository` — voir
/// `presentation/level_up_screen_test.dart`) : ce fichier est le seul, à ce
/// jour, à exercer `SupabaseCharacterRepository.applyLevelUp` lui-même (sans
/// double), car c'est le seul endroit où cette synchronisation peut être
/// observée. Scénario minimal choisi en conséquence : une seule classe non
/// lanceuse (Guerrier), montée "continuer" (pas de multiclassage), aucun
/// choix — pour qu'aucune requête annexe (translations des classes
/// secondaires, emplacements de sorts, magie de pacte, ASI) ne s'ajoute au
/// journal et brouille les assertions.
///
/// Même double `SupabaseClient`/`MockClient` que
/// `character_repository_rest_test.dart` (voir sa documentation de classe
/// pour le rationale de la session factice et du journal des requêtes).
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
  const classId = 1;
  const className = 'Guerrier';

  /// Monte de niveau un personnage à une seule classe [className]
  /// (non lanceuse, "continuer", sans choix) et retourne le journal des
  /// requêtes émises. [failOn] : requêtes auxquelles le double répond par
  /// une erreur 500 (générique, transitoire — jamais un code
  /// SQLSTATE `22xxx`/`23xxx`/`42501`, voir
  /// `PendingCharacterWriteSyncer._isNonRetryable`). [journal] : journal
  /// fourni par l'appelant, pour le consulter même quand `applyLevelUp`
  /// lève.
  Future<List<_Recorded>> applyLevelUp({
    bool Function(String method, String table)? failOn,
    List<_Recorded>? journal,
  }) async {
    final recorded = journal ?? <_Recorded>[];
    final client = await _buildSignedInFakeSupabaseClient(
      ownerId: ownerId,
      recorded: recorded,
      failOn: failOn,
      tableRows: {
        'characters': [
          {'id': characterId, 'max_hp': 30, 'current_hp': 12},
        ],
        'character_classes': [
          {'id': 'cc-0', 'class_id': classId, 'level': 4},
        ],
      },
    );
    final repository = SupabaseCharacterRepository(
      client,
      cache,
      pendingWrites,
      _OnlineConnectivityChecker(),
    );

    await repository.applyLevelUp(
      characterId: characterId,
      classId: classId,
      className: className,
      isMulticlassing: false,
      hpRolled: 6,
      hpMethod: 'rolled',
      hpGain: 6,
    );
    return recorded;
  }

  // D35 : synchronisation de la file PV/XP avant la montée de niveau.
  group(
    'applyLevelUp — D35 : synchronisation de la file PV/XP avant la montée '
    'de niveau',
    () {
      test(
        'cas nominal, aucune entrée en file : comportement inchangé (la '
        'montée de niveau continue normalement, PV = 12 + 6 = 18)',
        () async {
          expect(
            await pendingWrites.forCharacter(
              ownerId: ownerId,
              characterId: characterId,
            ),
            isEmpty,
            reason: 'précondition du scénario nominal',
          );

          final recorded = await applyLevelUp();

          final charactersUpdate = recorded.firstWhere(
            (r) => r.method == 'PATCH' && r.table == 'characters',
          );
          expect(charactersUpdate.body, {'max_hp': 36, 'current_hp': 18});
          final classUpdate = recorded.firstWhere(
            (r) => r.method == 'PATCH' && r.table == 'character_classes',
          );
          expect(classUpdate.body, {'level': 5});
        },
      );

      test(
        'entrée hp en file synchronisée avec succès avant la montée de '
        'niveau : la file est vidée, puis la montée continue normalement',
        () async {
          await pendingWrites.enqueue(
            characterId: characterId,
            ownerId: ownerId,
            kind: PendingCharacterWriteKind.hp,
            payload: {'currentHp': 9, 'temporaryHp': 0},
          );

          final recorded = await applyLevelUp();

          expect(
            await pendingWrites.forCharacter(
              ownerId: ownerId,
              characterId: characterId,
            ),
            isEmpty,
            reason:
                'la synchronisation forcée en tout début de applyLevelUp '
                'doit avoir vidé la file avant que la montée de niveau ne '
                'continue',
          );
          final charactersWrites = recorded
              .where((r) => r.method == 'PATCH' && r.table == 'characters')
              .toList();
          expect(
            charactersWrites.first.body,
            {'current_hp': 9, 'temporary_hp': 0},
            reason:
                "le premier PATCH 'characters' du journal doit être celui "
                'de la synchronisation (colonnes PV de la file), avant '
                'toute écriture propre à applyLevelUp',
          );
          // La lecture `current_hp`/`max_hp` qui alimente le calcul du
          // gain de PV se fait ensuite sur `characters`, qui n'a pas
          // réellement bougé côté double (double sans état) : le gain
          // s'applique donc toujours à la valeur fixe de la fixture
          // (12 + 6 = 18), seule l'absence de blocage est vérifiée ici.
          expect(charactersWrites.last.body, {
            'max_hp': 36,
            'current_hp': 18,
          });
        },
      );

      test(
        'entrée hp en file dont la synchronisation échoue (refus '
        'transitoire) : bloque la montée de niveau avec une CharacterFailure '
        "explicite, sans rien lire ni écrire d'autre — l'entrée reste en "
        'file pour le prochain essai',
        () async {
          await pendingWrites.enqueue(
            characterId: characterId,
            ownerId: ownerId,
            kind: PendingCharacterWriteKind.hp,
            payload: {'currentHp': 9, 'temporaryHp': 0},
          );
          final journal = <_Recorded>[];

          await expectLater(
            applyLevelUp(
              journal: journal,
              failOn: (method, table) =>
                  method == 'PATCH' && table == 'characters',
            ),
            throwsA(
              isA<CharacterFailure>().having(
                (failure) => failure.message,
                'message',
                contains('en attente de synchronisation'),
              ),
            ),
          );

          expect(
            await pendingWrites.forCharacter(
              ownerId: ownerId,
              characterId: characterId,
            ),
            isNotEmpty,
            reason:
                'la synchronisation a échoué (refus transitoire) : '
                "l'entrée doit rester en file pour un prochain essai, "
                'jamais être abandonnée ni laissée de côté silencieusement',
          );
          expect(
            journal.where((r) => r.method != 'GET'),
            hasLength(1),
            reason:
                'seule la tentative de synchronisation (PATCH characters '
                'refusé) doit apparaître : applyLevelUp ne doit rien lire '
                "ni écrire de propre à lui-même une fois le blocage "
                'détecté (ni lecture des classes, ni lecture de '
                "characters)",
          );
        },
      );
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

class _OnlineConnectivityChecker implements ConnectivityChecker {
  @override
  Future<bool> hasConnection() async => true;

  @override
  Stream<bool> get onConnectivityRestored => const Stream.empty();
}

/// Même principe que `_buildSignedInFakeSupabaseClient` de
/// `character_repository_rest_test.dart` (routage par nom de table, session
/// factice sans réseau), avec en plus le journal [recorded] de chaque
/// requête.
Future<SupabaseClient> _buildSignedInFakeSupabaseClient({
  required String ownerId,
  required List<_Recorded> recorded,
  Map<String, List<Map<String, dynamic>>> tableRows = const {},
  bool Function(String method, String table)? failOn,
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
    if (failOn != null && failOn(request.method, table)) {
      return http.Response(
        jsonEncode({'message': 'erreur simulée', 'code': 'XX000'}),
        500,
        request: request,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
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
