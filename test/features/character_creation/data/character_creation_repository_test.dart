import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/features/character_creation/data/character_creation_repository.dart';
import 'package:personnages/features/character_creation/domain/character_creation_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ces tests couvrent la stratégie "réseau d'abord, cache en secours" du
/// cache local (`ReferenceDataCache`, `lib/core/cache/`) sur
/// `SupabaseCharacterCreationRepository`, pour les 8 catalogues
/// `fetchXCatalog` (voir [_testCatalogCaching], appelé une fois par
/// catalogue dans `main()`). Aucun double factice de `SupabaseClient`
/// lui-même n'existait déjà dans ce dépôt avant cette tâche (voir
/// `test_integration/README.md` : les repositories `Supabase*` sont
/// d'ordinaire exercés contre un vrai stack Supabase local dans
/// `test_integration/`, jamais mockés dans `flutter test`) — construire un
/// faux `PostgrestFilterBuilder`/`SupabaseQueryBuilder` compatible aurait été
/// fragile (classes concrètes, pas des interfaces). [_buildFakeSupabaseClient]
/// fake plutôt au niveau du transport HTTP (`http.Client`, déjà injectable
/// dans `SupabaseClient`, voir sa doc) avec `package:http/testing.dart`
/// (`MockClient`) : un vrai `SupabaseClient`/`PostgrestClient` tourne, seule
/// la réponse HTTP est fabriquée.
///
/// Note sur la vitesse de ces tests : `PostgrestClientOptions.retryEnabled`
/// n'a **aucun effet** sur les requêtes émises par `.from(table)` — bug/
/// limitation constatée en écrivant ce fichier : `SupabaseClient.from()`
/// construit un `SupabaseQueryBuilder` sans jamais lui transmettre
/// `retryEnabled`/`retryCount` (voir `package:supabase/src
/// /supabase_query_builder.dart`), contrairement à `SupabaseClient.rest`
/// (jamais utilisé par ce dépôt, qui n'appelle que `.from(...)`). Une requête
/// qui échoue par une exception Dart brute (`throwOnRequest`) subit donc
/// malgré tout les 3 tentatives par défaut de Postgrest (délais 1s/2s/4s,
/// ~7s au total) — accepté volontairement sur les 8 tests "aucun cache"
/// (un par catalogue, pour prouver que n'importe quelle exception, pas
/// seulement `PostgrestException`, déclenche le repli cache), mais évité sur
/// les scénarios "cache déjà présent" via [failureStatusCode] : un code HTTP
/// hors de `PostgrestClient.defaultRetryableStatusCodes` (`503`/`520`)
/// produit une `PostgrestException` **sans aucune retentative**, donc
/// instantanément — le chemin de repli testé (relire le cache, remapper) est
/// rigoureusement le même quel que soit le type d'exception intercepté par
/// le repository (voir `SupabaseCharacterCreationRepository._mappedFromCache`,
/// appelé depuis les deux clauses `catch`).
void main() {
  group('SupabaseCharacterCreationRepository (cache de secours)', () {
    late AppDatabase db;
    late ReferenceDataCache cache;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      cache = ReferenceDataCache(db);
    });

    tearDown(() async {
      await db.close();
    });

    _testCatalogCaching(
      description:
          'fetchRaceCatalog (plusieurs sous-requêtes : races, '
          'subraces, translations x2)',
      cacheKey: 'race_catalog',
      cache: () => cache,
      fetch: (repository) => repository.fetchRaceCatalog(),
      tableRows: {
        'races': [
          {
            'id': 1,
            'ability_bonuses': {'dex': 2},
            'traits': <Map<String, dynamic>>[],
          },
        ],
        'subraces': [
          {
            'id': 11,
            'race_id': 1,
            'ability_bonuses': {'int': 1},
            'traits': <Map<String, dynamic>>[],
          },
        ],
        // Un seul endpoint `translations` sert les deux requêtes
        // (entity_type='race' ET entity_type='subrace') : notre double ne
        // filtre pas par query string (seulement par table), donc les deux
        // entity_id ci-dessous doivent coexister — sans conséquence sur le
        // mapping puisque chaque catalogue ne va chercher que l'entity_id
        // qui le concerne (voir `RaceRowMapper.toRaceOption`/
        // `toSubraceOption`).
        'translations': [
          {'entity_id': '1', 'value': 'Humain'},
          {'entity_id': '11', 'value': 'Humain des vallées'},
        ],
      },
      verifySuccess: (dynamic catalog) {
        expect(catalog.races, hasLength(1));
        expect(catalog.races.single.name, 'Humain');
        expect(catalog.subraces, hasLength(1));
        expect(catalog.subraces.single.name, 'Humain des vallées');
      },
    );

    _testCatalogCaching(
      description: 'fetchClassCatalog',
      cacheKey: 'class_catalog',
      cache: () => cache,
      fetch: (repository) => repository.fetchClassCatalog(),
      tableRows: {
        'classes': [
          {
            'id': 2,
            'hit_die': 10,
            'skill_choices': {'count': 0, 'choices': <String>[]},
            'tool_proficiencies': <String>[],
          },
        ],
        // Sert à la fois `field_name='name'` et `field_name='description'`
        // (notre double ne filtre pas par query string) — sans conséquence,
        // ce test n'assert que sur `name`, voir la doc de classe.
        'translations': [
          {'entity_id': '2', 'value': 'Guerrier'},
        ],
      },
      verifySuccess: (dynamic catalog) {
        expect(catalog.classes, hasLength(1));
        expect(catalog.classes.single.name, 'Guerrier');
        expect(catalog.classes.single.hitDie, 10);
      },
    );

    _testCatalogCaching(
      description: 'fetchBackgroundCatalog',
      cacheKey: 'background_catalog',
      cache: () => cache,
      fetch: (repository) => repository.fetchBackgroundCatalog(),
      tableRows: {
        'backgrounds': [
          {
            'id': 3,
            'skill_proficiencies': ['Perception'],
            'tool_or_language_choices': <String, dynamic>{},
            'equipment': ['Une arme'],
          },
        ],
        // Sert `name`/`feature_name`/`feature_description` (notre double ne
        // filtre pas par query string) — sans conséquence, ce test n'assert
        // que sur `name`/`skillProficiencies`, voir la doc de classe.
        'translations': [
          {'entity_id': '3', 'value': 'Soldat'},
        ],
      },
      verifySuccess: (dynamic catalog) {
        expect(catalog.backgrounds, hasLength(1));
        expect(catalog.backgrounds.single.name, 'Soldat');
        expect(catalog.backgrounds.single.skillProficiencies, ['Perception']);
      },
    );

    _testCatalogCaching(
      description: 'fetchToolCatalog',
      cacheKey: 'tool_catalog',
      cache: () => cache,
      fetch: (repository) => repository.fetchToolCatalog(),
      tableRows: {
        'tools': [
          {'id': 4, 'category': 'instrument'},
        ],
        'translations': [
          {'entity_id': '4', 'value': 'Luth'},
        ],
      },
      verifySuccess: (dynamic catalog) {
        expect(catalog.tools, hasLength(1));
        expect(catalog.tools.single.name, 'Luth');
        expect(catalog.tools.single.category, 'instrument');
      },
    );

    _testCatalogCaching(
      description: 'fetchLanguageCatalog',
      cacheKey: 'language_catalog',
      cache: () => cache,
      fetch: (repository) => repository.fetchLanguageCatalog(),
      tableRows: {
        'languages': [
          {'id': 5, 'type': 'standard'},
        ],
        'translations': [
          {'entity_id': '5', 'value': 'Elfique'},
        ],
      },
      verifySuccess: (dynamic catalog) {
        expect(catalog.languages, hasLength(1));
        expect(catalog.languages.single.name, 'Elfique');
        expect(catalog.languages.single.type, 'standard');
      },
    );

    group('fetchSpellCatalog (clé de cache paramétrée par classId)', () {
      final tableRowsForClass1 = <String, List<Map<String, dynamic>>>{
        'spell_classes': [
          {'spell_id': 5},
        ],
        'spells': [
          {
            'id': 5,
            'level': 1,
            'school': 'évocation',
            'casting_time': '1 action',
          },
        ],
        'translations': [
          {'entity_id': '5', 'value': 'Projectile magique'},
        ],
      };

      _testCatalogCaching(
        description: 'chemin de secours',
        cacheKey: 'spell_catalog:1',
        cache: () => cache,
        fetch: (repository) => repository.fetchSpellCatalog(classId: 1),
        tableRows: tableRowsForClass1,
        verifySuccess: (dynamic catalog) {
          expect(catalog.spells, hasLength(1));
          expect(catalog.spells.single.name, 'Projectile magique');
        },
      );

      test('succès réseau : écrit une entrée de cache dédiée à classId, sans '
          'écraser celle d\'une autre classe', () async {
        final repository = SupabaseCharacterCreationRepository(
          _buildFakeSupabaseClient(tableRows: tableRowsForClass1),
          cache,
        );

        await repository.fetchSpellCatalog(classId: 1);

        expect(await cache.get('spell_catalog:1'), isNotNull);
        expect(
          await cache.get('spell_catalog:2'),
          isNull,
          reason:
              'la clé de cache doit être paramétrée par classId, pas '
              'partagée entre classes',
        );
      });
    });

    _testCatalogCaching(
      description: 'fetchItemCatalog',
      cacheKey: 'item_catalog',
      cache: () => cache,
      fetch: (repository) => repository.fetchItemCatalog(),
      tableRows: {
        'items': [
          {
            'id': 6,
            'category': 'arme',
            'cost': {'amount': 15, 'currency': 'gp'},
          },
        ],
        'translations': [
          {'entity_id': '6', 'value': 'Épée longue'},
        ],
      },
      verifySuccess: (dynamic catalog) {
        expect(catalog.items, hasLength(1));
        expect(catalog.items.single.name, 'Épée longue');
        expect(catalog.items.single.costAmount, 15);
      },
    );

    _testCatalogCaching(
      description: 'fetchSkillCatalog',
      cacheKey: 'skill_catalog',
      cache: () => cache,
      fetch: (repository) => repository.fetchSkillCatalog(),
      tableRows: {
        'skills': [
          {'id': 7, 'ability_id': 'wis'},
        ],
        'translations': [
          {'entity_id': '7', 'value': 'Perception'},
        ],
      },
      verifySuccess: (dynamic catalog) {
        expect(catalog.skills, hasLength(1));
        expect(catalog.skills.single.name, 'Perception');
        expect(catalog.skills.single.abilityId, 'wis');
      },
    );
  });
}

/// Génère les 3 tests communs à tous les catalogues `fetchXCatalog` (voir la
/// doc de classe en tête de ce fichier) : succès réseau (écrit le cache),
/// échec réseau + cache déjà présent (retombe dessus, même catalogue que le
/// mapper direct), échec réseau + aucun cache (relance l'erreur d'origine).
/// Factorise la répétition entre les 8 catalogues plutôt que de la dupliquer
/// intégralement 8 fois — seuls [tableRows]/[cacheKey]/[fetch]/[verifySuccess]
/// varient d'un catalogue à l'autre.
///
/// [cache] est un accesseur (pas une valeur directe) parce que la variable
/// `cache` de `main()` est réassignée à une base drift en mémoire fraîche
/// avant **chaque** test (`setUp`), pas une seule fois pour tout le fichier —
/// cette fonction ne construit les groupes de tests qu'une fois à la
/// déclaration de `main()`, donc capturer `cache` par valeur figerait
/// l'instance de la toute première exécution.
void _testCatalogCaching({
  required String description,
  required String cacheKey,
  required ReferenceDataCache Function() cache,
  required Future<dynamic> Function(CharacterCreationRepository repository)
  fetch,
  required Map<String, List<Map<String, dynamic>>> tableRows,
  required void Function(dynamic catalog) verifySuccess,
}) {
  group(description, () {
    test(
      'succès réseau : écrit le cache et retourne le catalogue mappé',
      () async {
        final repository = SupabaseCharacterCreationRepository(
          _buildFakeSupabaseClient(tableRows: tableRows),
          cache(),
        );

        final catalog = await fetch(repository);

        verifySuccess(catalog);
        expect(
          await cache().get(cacheKey),
          isNotNull,
          reason: 'le succès réseau doit avoir peuplé le cache',
        );
      },
    );

    test('échec réseau + cache déjà présent : retombe sur le cache et '
        'produit le même catalogue que le mapper direct', () async {
      final onlineRepository = SupabaseCharacterCreationRepository(
        _buildFakeSupabaseClient(tableRows: tableRows),
        cache(),
      );
      final expectedCatalog = await fetch(onlineRepository);

      final offlineRepository = SupabaseCharacterCreationRepository(
        _buildFakeSupabaseClient(failureStatusCode: 500),
        cache(),
      );
      final catalog = await fetch(offlineRepository);

      expect(catalog, expectedCatalog);
    });

    test('échec réseau + aucun cache : relance l\'erreur d\'origine', () async {
      final repository = SupabaseCharacterCreationRepository(
        _buildFakeSupabaseClient(throwOnRequest: true),
        cache(),
      );

      await expectLater(
        fetch(repository),
        throwsA(isA<CharacterCreationFailure>()),
      );
    });
  });
}

/// Fabrique un `SupabaseClient` réel, mais dont le transport HTTP est
/// entièrement fabriqué (`MockClient`, voir la doc de classe en tête de ce
/// fichier). [tableRows] route chaque requête par le dernier segment de son
/// chemin (`/rest/v1/<table>`, donc par nom de table PostgREST), sans tenir
/// compte du reste de la query string (`select`/`eq`/`order`/`inFilter`) —
/// suffisant ici puisque ce fichier teste la logique de cache de
/// `SupabaseCharacterCreationRepository`, pas le filtrage PostgREST
/// lui-même (déjà couvert par `test_integration/`).
///
/// [throwOnRequest] simule une coupure réseau totale (n'importe quelle
/// requête échoue par une exception Dart brute, pas une réponse HTTP), pour
/// exercer le chemin de secours "cache" — voir la consigne de la tâche qui a
/// introduit ce cache ("échec réseau, n'importe quelle exception") ; lent
/// (~7s, voir la doc de classe en tête de ce fichier), réservé aux tests qui
/// ont explicitement besoin de ce type d'exception précis.
///
/// [failureStatusCode] simule un échec réseau plus rapide à tester : une
/// vraie réponse HTTP en erreur (`PostgrestException` côté repository), avec
/// un code hors de `PostgrestClient.defaultRetryableStatusCodes` pour ne
/// déclencher aucune retentative (voir la doc de classe).
SupabaseClient _buildFakeSupabaseClient({
  Map<String, List<Map<String, dynamic>>> tableRows = const {},
  bool throwOnRequest = false,
  int? failureStatusCode,
}) {
  Future<http.Response> handler(http.Request request) async {
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
    final rows = tableRows[table] ?? const <Map<String, dynamic>>[];
    return http.Response(
      jsonEncode(rows),
      200,
      // `request:` est indispensable : `PostgrestBuilder._parseResponse`
      // fait `response.request!.method` sans vérification — un
      // `http.Response` construit sans `request` fait planter le parsing
      // avec un obscur "Null check operator used on a null value" (constaté
      // en écrivant ce double, avant d'ajouter ce paramètre).
      request: request,
      headers: {'content-type': 'application/json'},
    );
  }

  return SupabaseClient(
    'https://fake.supabase.test',
    'fake-anon-key',
    httpClient: MockClient(handler),
    postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
    // Flow `implicit` plutôt que le `pkce` par défaut, même rationale que
    // `test_environment.dart` (`test_integration/support/`) : PKCE a besoin
    // d'un `GotrueAsyncStorage` (typiquement `shared_preferences`), un
    // plugin Flutter indisponible dans un test VM pur — sans lui, chaque
    // requête passait par plusieurs secondes de tentatives avant d'échouer
    // silencieusement (constaté en écrivant ce double).
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );
}
