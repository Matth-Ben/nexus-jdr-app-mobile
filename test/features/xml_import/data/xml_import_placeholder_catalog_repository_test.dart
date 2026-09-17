// Tests unitaires de `SupabaseXmlImportPlaceholderCatalogRepository`, sur un
// `SupabaseClient` réel dont le transport HTTP est entièrement fabriqué
// (`package:http/testing.dart`, `MockClient`) — même principe que
// `character_creation_repository_test.dart` (voir sa doc de classe pour le
// rationale détaillé de cette technique, non répété ici).
//
// [_buildQueuedFakeSupabaseClient] diffère toutefois du double de ce
// fichier : celui-ci route uniquement par nom de table (une réponse fixe par
// table, peu importe l'ordre des requêtes) — insuffisant ici, puisque
// `findOrCreateXxx` peut émettre plusieurs requêtes différentes vers LA MÊME
// table dans un seul appel (ex. `races` : d'abord un insert, puis un select
// pour vérifier la traduction, potentiellement un delete de nettoyage). Ce
// fichier route donc par **ordre d'émission** (une file de réponses
// consommée séquentiellement), ce qui exige de connaître à l'avance l'ordre
// exact des requêtes HTTP émises par le repository — documenté sur chaque
// test. Autre différence notable : `.single()` (utilisé par ce repository,
// jamais par `character_creation_repository.dart`) exige que le corps de la
// réponse soit un objet JSON nu, pas un tableau à un élément — voir
// `PostgrestBuilder._parseResponse` (`package:postgrest`, `_maybeSingle`
// n'est vrai que pour `.maybeSingle()`, jamais pour `.single()`, qui ne fait
// que changer l'en-tête `Accept` ; un serveur PostgREST réel convertit alors
// lui-même le tableau en objet côté serveur — notre double doit donc le
// faire lui-même).

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personnages/features/character_creation/domain/race_option.dart';
import 'package:personnages/features/xml_import/data/xml_import_placeholder_catalog_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('findOrCreateRace', () {
    test('un nom déjà connu de `translations` (ilike) est retrouvé sans créer '
        'de nouvelle entrée : 2 requêtes seulement (translations puis races), '
        'aucun insert', () async {
      final captured = <_CapturedRequest>[];
      final client = _buildQueuedFakeSupabaseClient(
        responses: [
          // 1. GET translations (recherche ilike) -> une correspondance.
          _FakeResponse.list([
            {'entity_id': '7', 'value': 'Elfe Sylvestre'},
          ]),
          // 2. GET races (id=eq.7).single() -> la ligne existante.
          _FakeResponse.object({
            'id': 7,
            'ability_bonuses': {'dex': 2},
            'traits': <Map<String, dynamic>>[],
            'is_incomplete': false,
          }),
        ],
        onRequest: captured.add,
      );
      final repository = SupabaseXmlImportPlaceholderCatalogRepository(client);

      final race = await repository.findOrCreateRace('elfe sylvestre');

      expect(
        race,
        const RaceOption(
          id: 7,
          name: 'Elfe Sylvestre',
          abilityBonuses: {'dex': 2},
          traits: [],
        ),
      );
      expect(captured, hasLength(2));
      expect(captured[0].method, 'GET');
      expect(captured[0].table, 'translations');
      expect(captured[1].method, 'GET');
      expect(captured[1].table, 'races');
    });

    test(
      'recherche insensible à la casse : le filtre envoyé est bien '
      '`value=ilike.<rawName>` (sans wildcard ajouté), sur `entity_type=race`',
      () async {
        final captured = <_CapturedRequest>[];
        final client = _buildQueuedFakeSupabaseClient(
          responses: [_FakeResponse.list(const [])],
          onRequest: captured.add,
        );
        final repository = SupabaseXmlImportPlaceholderCatalogRepository(
          client,
        );

        // Le nom brut contient une apostrophe pour vérifier l'échappement
        // réel de l'URL, pas seulement un mot simple.
        await repository
            .findOrCreateRace("Race d'Ombre")
            // La création qui suit échoue forcément (une seule réponse en
            // file) : sans conséquence, seule la première requête (la
            // recherche) est vérifiée ici.
            .catchError(
              (_) => const RaceOption(
                id: 0,
                name: '',
                abilityBonuses: {},
                traits: [],
              ),
            );

        final query = captured.first.request.url.queryParameters;
        expect(query['entity_type'], 'eq.race');
        expect(query['field_name'], 'eq.name');
        expect(query['locale'], 'eq.fr');
        expect(query['value'], "ilike.Race d'Ombre");
      },
    );

    test('aucune correspondance -> crée une nouvelle entrée `races` marquée '
        'is_incomplete=true, puis sa traduction `name`', () async {
      final captured = <_CapturedRequest>[];
      final client = _buildQueuedFakeSupabaseClient(
        responses: [
          // 1. GET translations -> aucune correspondance.
          _FakeResponse.list(const []),
          // 2. POST races (insert + select + single) -> nouvelle ligne.
          _FakeResponse.object({
            'id': 42,
            'ability_bonuses': null,
            'traits': null,
            'is_incomplete': true,
          }),
          // 3. POST translations (insert, pas de .select()).
          _FakeResponse.list(const []),
        ],
        onRequest: captured.add,
      );
      final repository = SupabaseXmlImportPlaceholderCatalogRepository(client);

      final race = await repository.findOrCreateRace('Race Maison');

      expect(race.id, 42);
      expect(race.name, 'Race Maison');
      expect(race.isIncomplete, isTrue);
      expect(race.abilityBonuses, isEmpty);
      expect(race.traits, isEmpty);

      expect(captured, hasLength(3));
      expect(captured[1].method, 'POST');
      expect(captured[1].table, 'races');
      expect(captured[1].jsonBody, {'is_incomplete': true});
      expect(captured[2].method, 'POST');
      expect(captured[2].table, 'translations');
      expect(captured[2].jsonBody, {
        'entity_type': 'race',
        'entity_id': '42',
        'field_name': 'name',
        'locale': 'fr',
        'value': 'Race Maison',
      });
    });

    test('échec de l\'insert `translations` après un insert `races` réussi -> '
        'nettoie (delete) la ligne `races` fraîchement créée, puis relance '
        'l\'erreur d\'origine', () async {
      final captured = <_CapturedRequest>[];
      final client = _buildQueuedFakeSupabaseClient(
        responses: [
          _FakeResponse.list(const []),
          _FakeResponse.object({
            'id': 55,
            'ability_bonuses': null,
            'traits': null,
            'is_incomplete': true,
          }),
          _FakeResponse.error(statusCode: 403, message: 'RLS refusée'),
          // 4. DELETE races?id=eq.55 (nettoyage best-effort).
          _FakeResponse.list(const []),
        ],
        onRequest: captured.add,
      );
      final repository = SupabaseXmlImportPlaceholderCatalogRepository(client);

      await expectLater(
        repository.findOrCreateRace('Race Maison'),
        throwsA(isA<PostgrestException>()),
      );

      expect(captured, hasLength(4));
      expect(captured[3].method, 'DELETE');
      expect(captured[3].table, 'races');
      expect(captured[3].request.url.queryParameters['id'], 'eq.55');
    });
  });

  group('findOrCreateBackground', () {
    test(
      'un nom déjà connu est retrouvé sans créer de nouvelle entrée',
      () async {
        final client = _buildQueuedFakeSupabaseClient(
          responses: [
            _FakeResponse.list([
              {'entity_id': '3', 'value': 'Sage'},
            ]),
            _FakeResponse.object({
              'id': 3,
              'skill_proficiencies': ['Arcanes'],
              'tool_or_language_choices': <String, dynamic>{},
              'equipment': <String>[],
              'is_incomplete': false,
            }),
          ],
        );
        final repository = SupabaseXmlImportPlaceholderCatalogRepository(
          client,
        );

        final background = await repository.findOrCreateBackground('sage');

        expect(background.id, 3);
        expect(background.name, 'Sage');
        expect(background.skillProficiencies, ['Arcanes']);
        expect(background.isIncomplete, isFalse);
      },
    );

    test('aucune correspondance -> crée une nouvelle entrée `backgrounds` '
        'marquée is_incomplete=true, puis sa traduction `name`', () async {
      final captured = <_CapturedRequest>[];
      final client = _buildQueuedFakeSupabaseClient(
        responses: [
          _FakeResponse.list(const []),
          _FakeResponse.object({
            'id': 12,
            'skill_proficiencies': null,
            'tool_or_language_choices': null,
            'equipment': null,
            'is_incomplete': true,
          }),
          _FakeResponse.list(const []),
        ],
        onRequest: captured.add,
      );
      final repository = SupabaseXmlImportPlaceholderCatalogRepository(client);

      final background = await repository.findOrCreateBackground(
        'Historique Maison',
      );

      expect(background.id, 12);
      expect(background.name, 'Historique Maison');
      expect(background.isIncomplete, isTrue);
      expect(background.skillProficiencies, isEmpty);

      expect(captured[1].jsonBody, {'is_incomplete': true});
      expect(captured[2].jsonBody, {
        'entity_type': 'background',
        'entity_id': '12',
        'field_name': 'name',
        'locale': 'fr',
        'value': 'Historique Maison',
      });
    });
  });

  group('findOrCreateSpell', () {
    test(
      'un nom déjà connu est retrouvé sans créer de nouvelle entrée',
      () async {
        final client = _buildQueuedFakeSupabaseClient(
          responses: [
            _FakeResponse.list([
              {'entity_id': '9', 'value': 'Trait de feu'},
            ]),
            _FakeResponse.object({
              'id': 9,
              'level': 0,
              'school': 'Évocation',
              'casting_time': '1 action',
              'is_incomplete': false,
            }),
          ],
        );
        final repository = SupabaseXmlImportPlaceholderCatalogRepository(
          client,
        );

        final spell = await repository.findOrCreateSpell('trait de feu');

        expect(spell.id, 9);
        expect(spell.name, 'Trait de feu');
        expect(spell.isIncomplete, isFalse);
      },
    );

    test('aucune correspondance -> crée une nouvelle entrée `spells` avec '
        'level=0 forcé (contrainte RLS) et is_incomplete=true, puis sa '
        'traduction `name`', () async {
      final captured = <_CapturedRequest>[];
      final client = _buildQueuedFakeSupabaseClient(
        responses: [
          _FakeResponse.list(const []),
          _FakeResponse.object({
            'id': 77,
            'level': 0,
            'school': null,
            'casting_time': null,
            'is_incomplete': true,
          }),
          _FakeResponse.list(const []),
        ],
        onRequest: captured.add,
      );
      final repository = SupabaseXmlImportPlaceholderCatalogRepository(client);

      final spell = await repository.findOrCreateSpell('Sort Maison');

      expect(spell.id, 77);
      expect(spell.name, 'Sort Maison');
      expect(spell.level, 0);
      expect(spell.isIncomplete, isTrue);

      expect(captured[1].jsonBody, {'is_incomplete': true, 'level': 0});
      expect(captured[2].jsonBody, {
        'entity_type': 'spell',
        'entity_id': '77',
        'field_name': 'name',
        'locale': 'fr',
        'value': 'Sort Maison',
      });
    });
  });
}

/// Une requête HTTP capturée par [_buildQueuedFakeSupabaseClient.onRequest]
/// — [table] est le dernier segment du chemin (`/rest/v1/<table>`), même
/// convention que `character_creation_repository_test.dart`. [jsonBody]
/// décode le corps envoyé (`null` pour une requête sans corps, ex. GET/DELETE).
class _CapturedRequest {
  _CapturedRequest(this.request)
    : table = request.url.pathSegments.last,
      jsonBody = request.body.isEmpty
          ? null
          : jsonDecode(request.body) as Map<String, dynamic>;

  final http.Request request;
  final String table;
  final Map<String, dynamic>? jsonBody;

  String get method => request.method;
}

/// Une réponse HTTP canned consommée dans l'ordre par
/// [_buildQueuedFakeSupabaseClient] — voir la doc de classe en tête de ce
/// fichier pour le rationale de cette approche "file" plutôt que "routage
/// par table".
class _FakeResponse {
  const _FakeResponse._(this.body, this.statusCode);

  /// Réponse tableau JSON (`[...]`) — utilisée pour toute requête PostgREST
  /// sans `.single()` (recherches `translations`, inserts nus sans
  /// `.select()`, deletes de nettoyage).
  factory _FakeResponse.list(List<Map<String, dynamic>> rows) =>
      _FakeResponse._(rows, 200);

  /// Réponse objet JSON (`{...}`) — utilisée pour toute requête PostgREST
  /// avec `.single()` (voir la doc de classe : indispensable, un tableau à 1
  /// élément ferait planter le parsing de `package:postgrest`).
  factory _FakeResponse.object(Map<String, dynamic> row) =>
      _FakeResponse._(row, 200);

  /// Réponse d'erreur PostgREST (ex. RLS refusée) — corps au format attendu
  /// par `PostgrestException.fromJson`.
  factory _FakeResponse.error({required int statusCode, String? message}) =>
      _FakeResponse._({
        'message': message ?? 'Erreur simulée (double de test).',
        'code': 'PGRST000',
      }, statusCode);

  final Object body;
  final int statusCode;
}

/// Fabrique un `SupabaseClient` réel dont le transport HTTP consomme
/// [responses] dans l'ordre exact des requêtes émises — voir la doc de
/// classe en tête de ce fichier. Une requête au-delà de [responses] fait
/// échouer le test immédiatement (`StateError`) plutôt que de boucler ou de
/// retourner une réponse par défaut trompeuse.
SupabaseClient _buildQueuedFakeSupabaseClient({
  required List<_FakeResponse> responses,
  void Function(_CapturedRequest request)? onRequest,
}) {
  var index = 0;

  Future<http.Response> handler(http.Request request) async {
    onRequest?.call(_CapturedRequest(request));
    if (index >= responses.length) {
      throw StateError(
        'Requête HTTP inattendue (file de réponses épuisée) : '
        '${request.method} ${request.url}',
      );
    }
    final response = responses[index++];
    return http.Response(
      jsonEncode(response.body),
      response.statusCode,
      // `request:` indispensable, voir `character_creation_repository_test
      // .dart._buildFakeSupabaseClient`.
      request: request,
      headers: {'content-type': 'application/json'},
    );
  }

  return SupabaseClient(
    'https://fake.supabase.test',
    'fake-anon-key',
    httpClient: MockClient(handler),
    postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );
}
