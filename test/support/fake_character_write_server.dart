import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Requête reçue (ou tentée) par [FakeCharacterWriteServer].
class RecordedRequest {
  RecordedRequest({
    required this.method,
    required this.table,
    required this.body,
    required this.applied,
    this.query = const {},
  });

  final String method;
  final String table;

  /// Corps JSON décodé (`null` pour un `GET`).
  final Object? body;

  /// `true` si l'effet a été appliqué à l'état du serveur (même quand la
  /// réponse a ensuite été perdue, voir [FakeCharacterWriteServer.failAfterApply]).
  final bool applied;

  /// Paramètres de requête (filtres PostgREST `id=eq...`, `owner_id=eq...`).
  final Map<String, String> query;

  bool get isWrite => method != 'GET';

  @override
  String toString() => '$method $table ${applied ? "applied" : "not-applied"}';
}

/// Faux serveur PostgREST en mémoire pour les écritures de personnage
/// (harnais de la file hors-ligne), branché sur un vrai [SupabaseClient]
/// via [buildSignedInClient].
///
/// État : une ligne `characters` ([characterRow], fusionnée par chaque
/// `PATCH characters`). Les autres tables écrites (`character_spell_slots`...)
/// sont seulement journalisées. Les lectures de `characters` renvoient la
/// ligne (objet si `Accept: ...object+json`, liste sinon).
///
/// Table à état ([tables]) : un `POST` avec un `id` déjà présent répond `23505`
/// (hors `upsert`), un `DELETE` retire les lignes qui passent les filtres.
///
/// Pannes programmables, comptées en **requêtes d'écriture** (tout sauf
/// `GET`), consommées dans l'ordre failBefore, failAfterApply, rejectWith :
/// - [failBefore] : la requête n'arrive pas (`SocketException`, rien
///   appliqué) ;
/// - [failAfterApply] : la requête est appliquée mais la réponse est perdue
///   (`SocketException` levée après application) : cas critique D184 ;
/// - [rejectWith] : refus serveur avec un SQLSTATE (`42501`, `23503`,
///   `22003`...), rien appliqué ; reste actif tant que [clearRejection]
///   n'est pas appelé ;
/// - [concurrentChange] : modification faite par un autre client, appliquée
///   immédiatement à [characterRow] (sans journal : elle n'est pas issue de
///   l'app testée).
///
/// [requests] est le journal complet ; [appliedWrites] sert à compter les
/// doublons d'effet.
class FakeCharacterWriteServer {
  FakeCharacterWriteServer({Map<String, dynamic>? characterRow})
    : characterRow =
          characterRow ??
          {
            'id': 'char-1',
            'owner_id': 'owner-1',
            'xp': 100,
            'current_hp': 10,
            'max_hp': 12,
            'temporary_hp': 0,
          };

  Map<String, dynamic> characterRow;

  /// Tables enfants à état (T5a) : lignes de `character_spells`,
  /// `character_inventory`... (clé = nom de table). Une table **présente** ici
  /// est simulée : `GET` filtré (`eq.`/`neq.`), `PATCH` appliqué aux seules
  /// lignes qui passent les filtres (zéro ligne = réponse `[]`, rien
  /// appliqué), `POST` ajoute des lignes. Une table absente garde le
  /// comportement historique (simple journal).
  final Map<String, List<Map<String, dynamic>>> tables = {};

  /// Réseau totalement coupé : toute requête lève une `SocketException`.
  bool down = false;

  final List<RecordedRequest> requests = [];

  int _failBefore = 0;
  int _failAfterApply = 0;
  String? _rejectSqlstate;

  /// Appelé après chaque requête d'écriture appliquée (avant la perte
  /// éventuelle de réponse) : permet à un test d'injecter un
  /// [concurrentChange] au moment précis voulu.
  FutureOr<void> Function(RecordedRequest request)? onWriteApplied;

  List<RecordedRequest> get writes =>
      requests.where((r) => r.isWrite).toList(growable: false);

  List<RecordedRequest> get appliedWrites =>
      requests.where((r) => r.isWrite && r.applied).toList(growable: false);

  void failBefore(int n) => _failBefore = n;

  void failAfterApply(int n) => _failAfterApply = n;

  void rejectWith(String sqlstate) => _rejectSqlstate = sqlstate;

  void clearRejection() => _rejectSqlstate = null;

  /// Modification par un autre client : fusionnée dans [characterRow].
  void concurrentChange(Map<String, dynamic> columns) {
    characterRow = {...characterRow, ...columns};
  }

  Future<http.Response> handle(http.Request request) async {
    final table = request.url.pathSegments.last;
    final isWrite = request.method != 'GET';
    final body = request.body.isEmpty ? null : jsonDecode(request.body);

    RecordedRequest record({required bool applied}) {
      final entry = RecordedRequest(
        method: request.method,
        table: table,
        body: body,
        applied: applied,
        query: request.url.queryParameters,
      );
      requests.add(entry);
      return entry;
    }

    if (down) {
      record(applied: false);
      throw const SocketException('Réseau coupé (faux serveur).');
    }

    if (!isWrite) {
      record(applied: false);
      final stateful = tables[table];
      if (stateful != null) {
        final matching = _matching(stateful, request.url.queryParameters);
        final asObject = (request.headers['Accept'] ?? '').contains(
          'object+json',
        );
        if (asObject) {
          return matching.isEmpty
              ? _json(request, {
                  'message': 'Aucune ligne',
                  'code': 'PGRST116',
                }, statusCode: 406)
              : _json(request, matching.first);
        }
        return _json(request, matching);
      }
      if (table == 'characters') {
        final asObject = (request.headers['Accept'] ?? '').contains(
          'object+json',
        );
        return _json(request, asObject ? characterRow : [characterRow]);
      }
      return _json(request, const <Object>[]);
    }

    if (_failBefore > 0) {
      _failBefore--;
      record(applied: false);
      throw const SocketException('Requête perdue avant envoi (faux serveur).');
    }

    final sqlstate = _rejectSqlstate;
    if (sqlstate != null) {
      record(applied: false);
      return _json(request, {
        'message': 'Refus ($sqlstate) simulé par le faux serveur.',
        'code': sqlstate,
      }, statusCode: 400);
    }

    // `.select('id')` après un `PATCH` (en-tête `Prefer: return=representation`) :
    // comme PostgREST, les filtres `id`/`owner_id` décident des lignes
    // affectées ; zéro ligne = rien d'appliqué, réponse `[]` (RLS silencieuse
    // ou personnage disparu). Sans ce `Prefer`, comportement historique.
    final wantsRepresentation =
        request.method == 'PATCH' &&
        (request.headers['Prefer'] ?? '').contains('return=representation');
    if (table == 'characters' && wantsRepresentation) {
      final idFilter = request.url.queryParameters['id'];
      final ownerFilter = request.url.queryParameters['owner_id'];
      final matches =
          (idFilter == null || idFilter == 'eq.${characterRow['id']}') &&
          (ownerFilter == null ||
              ownerFilter == 'eq.${characterRow['owner_id']}');
      if (!matches) {
        record(applied: false);
        return _json(request, const <Object>[]);
      }
    }

    final statefulRows = tables[table];
    if (statefulRows != null) {
      if (request.method == 'POST') {
        final inserted = body is List ? body : [body];
        // Clé primaire explicite déjà présente (hors `upsert`, qui fusionne) :
        // `23505`, comme PostgreSQL (T4 : UUID client du journal).
        final merges = (request.headers['Prefer'] ?? '').contains(
          'resolution=merge-duplicates',
        );
        if (!merges) {
          for (final entry in inserted) {
            final id = entry is Map ? entry['id'] : null;
            if (id != null && statefulRows.any((row) => row['id'] == id)) {
              record(applied: false);
              return _json(request, {
                'message':
                    'duplicate key value violates unique constraint '
                    '"${table}_pkey" (faux serveur).',
                'code': '23505',
              }, statusCode: 409);
            }
          }
        }
        for (final entry in inserted) {
          statefulRows.add({
            'id': 'row-${statefulRows.length + 1}',
            ...Map<String, dynamic>.from(entry as Map),
          });
        }
      } else if (request.method == 'DELETE') {
        // Zéro ligne correspondante : rien à supprimer, pas une erreur.
        final matching = _matching(statefulRows, request.url.queryParameters);
        statefulRows.removeWhere(matching.contains);
      } else if (request.method == 'PATCH') {
        final matching = _matching(statefulRows, request.url.queryParameters);
        if (matching.isEmpty) {
          record(applied: false);
          return _json(request, const <Object>[]);
        }
        for (final row in matching) {
          row.addAll(Map<String, dynamic>.from(body as Map));
        }
      }
    }

    if (table == 'characters' && body is Map) {
      characterRow = {...characterRow, ...Map<String, dynamic>.from(body)};
    }
    final applied = record(applied: true);
    await onWriteApplied?.call(applied);

    if (_failAfterApply > 0) {
      _failAfterApply--;
      throw const SocketException(
        'Réponse perdue après application (faux serveur).',
      );
    }
    if (table == 'characters' && wantsRepresentation) {
      return _json(request, [
        {'id': characterRow['id']},
      ]);
    }
    if (statefulRows != null && wantsRepresentation) {
      return _json(request, [
        for (final row in _matching(statefulRows, request.url.queryParameters))
          {'id': row['id']},
      ]);
    }
    return _json(request, const <Object>[]);
  }

  /// Lignes de [rows] qui passent les filtres PostgREST `col=eq.v`/`col=neq.v`
  /// de [query] (les autres paramètres — `select`, `limit`... — sont ignorés).
  static List<Map<String, dynamic>> _matching(
    List<Map<String, dynamic>> rows,
    Map<String, String> query,
  ) {
    const reserved = {'select', 'limit', 'order', 'offset'};
    return [
      for (final row in rows)
        if (query.entries.every((filter) {
          if (reserved.contains(filter.key)) return true;
          final value = filter.value;
          if (value.startsWith('eq.')) {
            return '${row[filter.key]}' == value.substring(3);
          }
          if (value.startsWith('neq.')) {
            return '${row[filter.key]}' != value.substring(4);
          }
          return true;
        }))
          row,
    ];
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

/// [SupabaseClient] dont le transport HTTP est [server] et dont la session
/// de [ownerId] est restaurée en mémoire (aucune requête).
Future<SupabaseClient> buildSignedInClient(
  FakeCharacterWriteServer server, {
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
