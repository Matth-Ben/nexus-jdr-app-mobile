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
/// `SupabaseCharacterCreationRepository`, pour les 9 catalogues
/// `fetchXCatalog` (voir [_testCatalogCaching], appelé une fois par
/// catalogue dans `main()` — `fetchAlignmentCatalog` ajouté après coup, pour
/// `features/xml_import/`, voir la doc de classe d'`AlignmentOption`).
/// Aucun double factice de `SupabaseClient`
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

    // `alignments.name` est une colonne directe (pas de résolution
    // `translations`, voir la doc de classe d'`AlignmentOption`) : pas de
    // ligne `translations` dans `tableRows`, contrairement aux 8 catalogues
    // ci-dessus.
    _testCatalogCaching(
      description: 'fetchAlignmentCatalog',
      cacheKey: 'alignment_catalog',
      cache: () => cache,
      fetch: (repository) => repository.fetchAlignmentCatalog(),
      tableRows: {
        'alignments': [
          {'id': 8, 'name': 'Loyal bon'},
        ],
      },
      verifySuccess: (dynamic catalog) {
        expect(catalog.alignments, hasLength(1));
        expect(catalog.alignments.single.name, 'Loyal bon');
        expect(catalog.alignments.single.id, 8);
      },
    );
  });

  group(
    'SupabaseCharacterCreationRepository (TTL cache d\'abord si frais)',
    () {
      late AppDatabase db;
      late ReferenceDataCache cache;

      setUp(() {
        db = AppDatabase(NativeDatabase.memory());
        cache = ReferenceDataCache(db);
      });

      tearDown(() async {
        await db.close();
      });

      // Couvre le mécanisme générique (`_mappedFromFreshCache`, identique
      // pour les 9 catalogues) sur un catalogue représentatif non paramétré
      // (fetchRaceCatalog, le plus complexe : plusieurs sous-requêtes) et sur
      // le catalogue paramétré par classId (fetchSpellCatalog), plutôt que de
      // répéter les 4 scénarios sur les 9 catalogues comme le fait le groupe
      // "cache de secours" ci-dessus (qui, lui, vérifie surtout le mapping
      // spécifique à chaque catalogue — non concerné par ce chantier TTL).
      _testCatalogTtl(
        description: 'fetchRaceCatalog',
        cacheKey: 'race_catalog',
        db: () => db,
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
          'translations': [
            {'entity_id': '1', 'value': 'Humain'},
            {'entity_id': '11', 'value': 'Humain des vallées'},
          ],
        },
      );

      _testCatalogTtl(
        description:
            'fetchSpellCatalog (clé de cache paramétrée par classId, même '
            'TTL)',
        cacheKey: 'spell_catalog:1',
        db: () => db,
        cache: () => cache,
        fetch: (repository) => repository.fetchSpellCatalog(classId: 1),
        tableRows: {
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
        },
      );
    },
  );
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

/// Génère les 3 tests du groupe "TTL (cache d'abord si frais)" pour un
/// catalogue donné, sur le même principe que [_testCatalogCaching] : cache
/// frais (< 48h) sert directement le cache sans le moindre appel réseau ;
/// cache périmé (>= 48h) déclenche malgré tout une nouvelle tentative
/// réseau (qui réécrit le cache avec un `cachedAt` frais) ; réseau en échec
/// + cache périmé existant retombe quand même dessus plutôt que de ne rien
/// retourner (non-régression explicite du comportement "cache de secours"
/// déjà couvert par [_testCatalogCaching], mais avec un cache volontairement
/// périmé cette fois — voir la consigne de la tâche qui a introduit ce TTL :
/// "le TTL ne doit jamais faire disparaître un cache existant").
void _testCatalogTtl({
  required String description,
  required String cacheKey,
  required AppDatabase Function() db,
  required ReferenceDataCache Function() cache,
  required Future<dynamic> Function(CharacterCreationRepository repository)
  fetch,
  required Map<String, List<Map<String, dynamic>>> tableRows,
}) {
  group(description, () {
    test('cache frais (< 48h) : retourne le cache directement, sans le '
        'moindre appel réseau', () async {
      final onlineRepository = SupabaseCharacterCreationRepository(
        _buildFakeSupabaseClient(tableRows: tableRows),
        cache(),
      );
      final expectedCatalog = await fetch(onlineRepository);

      var networkCallCount = 0;
      final repositoryWithFreshCache = SupabaseCharacterCreationRepository(
        _buildFakeSupabaseClient(
          tableRows: tableRows,
          onRequest: () => networkCallCount++,
        ),
        cache(),
      );
      final catalog = await fetch(repositoryWithFreshCache);

      expect(catalog, expectedCatalog);
      expect(
        networkCallCount,
        0,
        reason:
            'une entrée de cache fraîche (< 48h) ne doit déclencher '
            'aucune requête réseau',
      );
    });

    test('cache périmé (>= 48h) : retente le réseau, ce qui réécrit une '
        'entrée de cache fraîche', () async {
      final onlineRepository = SupabaseCharacterCreationRepository(
        _buildFakeSupabaseClient(tableRows: tableRows),
        cache(),
      );
      await fetch(onlineRepository);
      await _backdateCacheEntry(
        db(),
        cacheKey,
        olderThan: const Duration(hours: 49),
      );
      expect(
        await cache().getFresh(cacheKey, maxAge: const Duration(hours: 48)),
        isNull,
        reason: 'le backdatage de test doit avoir rendu l\'entrée périmée',
      );

      final repositoryWithStaleCache = SupabaseCharacterCreationRepository(
        _buildFakeSupabaseClient(tableRows: tableRows),
        cache(),
      );
      await fetch(repositoryWithStaleCache);

      expect(
        await cache().getFresh(cacheKey, maxAge: const Duration(hours: 48)),
        isNotNull,
        reason:
            'un cache périmé doit avoir déclenché une nouvelle tentative '
            'réseau, qui réécrit le cache avec un cachedAt frais (comme '
            'avant ce chantier TTL, voir _writeCacheBestEffort)',
      );
    });

    test('réseau en échec + cache périmé existant : retombe dessus quand même '
        'plutôt que de ne rien retourner', () async {
      final onlineRepository = SupabaseCharacterCreationRepository(
        _buildFakeSupabaseClient(tableRows: tableRows),
        cache(),
      );
      final expectedCatalog = await fetch(onlineRepository);
      await _backdateCacheEntry(
        db(),
        cacheKey,
        olderThan: const Duration(hours: 49),
      );

      final offlineRepository = SupabaseCharacterCreationRepository(
        _buildFakeSupabaseClient(failureStatusCode: 500),
        cache(),
      );
      final catalog = await fetch(offlineRepository);

      expect(
        catalog,
        expectedCatalog,
        reason:
            'le TTL ne doit jamais faire disparaître un cache existant, '
            'seulement décider s\'il faut le rafraîchir en priorité',
      );
    });
  });
}

/// Réécrit directement (hors `ReferenceDataCache`, en accédant à [db]) le
/// `cachedAt` de l'entrée [key] pour qu'elle paraisse plus vieille que
/// [olderThan] — `ReferenceDataCache.put` fixe toujours `cachedAt:
/// DateTime.now()` (voir sa doc), donc inutilisable ici pour fabriquer une
/// entrée déjà périmée sans attendre 48h réelles. Suppose qu'une entrée pour
/// [key] existe déjà (typiquement écrite par un premier fetch réseau réussi
/// dans le test appelant) : conserve son payload tel quel, ne change que
/// [cachedAt].
Future<void> _backdateCacheEntry(
  AppDatabase db,
  String key, {
  required Duration olderThan,
}) async {
  final existing = await (db.select(
    db.cachedReferenceEntries,
  )..where((row) => row.key.equals(key))).getSingle();
  await db
      .into(db.cachedReferenceEntries)
      .insertOnConflictUpdate(
        CachedReferenceEntriesCompanion.insert(
          key: key,
          payload: existing.payload,
          cachedAt: DateTime.now().subtract(olderThan),
        ),
      );
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
  // Invoqué pour **chaque** requête HTTP effectivement émise par le
  // `SupabaseClient` construit ici, avant toute décision de réponse
  // (succès/échec) — permet aux tests TTL de compter précisément les appels
  // réseau, notamment pour prouver qu'un cache frais n'en déclenche
  // strictement aucun (voir le groupe "TTL (cache d'abord si frais)").
  void Function()? onRequest,
}) {
  Future<http.Response> handler(http.Request request) async {
    onRequest?.call();
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
