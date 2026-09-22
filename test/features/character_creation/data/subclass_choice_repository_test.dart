import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/features/character_creation/data/character_creation_repository.dart';
import 'package:personnages/features/character_creation/data/subclass_choice_repository.dart';
import 'package:personnages/features/character_creation/data/subclass_choice_row_mapper.dart';
import 'package:personnages/features/character_creation/domain/background_option.dart';
import 'package:personnages/features/character_creation/domain/character_creation_draft.dart';
import 'package:personnages/features/character_creation/domain/character_creation_failure.dart';
import 'package:personnages/features/character_creation/domain/class_option.dart';
import 'package:personnages/features/character_creation/domain/item_catalog.dart';
import 'package:personnages/features/character_creation/domain/language_catalog.dart';
import 'package:personnages/features/character_creation/domain/race_catalog.dart';
import 'package:personnages/features/character_creation/domain/skill_catalog.dart';
import 'package:personnages/features/character_creation/domain/spell_catalog.dart';
import 'package:personnages/features/character_creation/domain/tool_catalog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// `SupabaseClient` réel dont seul le transport HTTP est fabriqué (même
/// principe que `character_creation_repository_test.dart`). [handler] reçoit
/// chaque requête et renvoie le corps JSON de la réponse.
SupabaseClient _client(
  Object Function(http.Request request) handler, {
  int status = 200,
}) {
  return SupabaseClient(
    'https://fake.supabase.test',
    'fake-anon-key',
    httpClient: MockClient((request) async {
      return http.Response(
        jsonEncode(handler(request)),
        status,
        request: request,
        headers: {'content-type': 'application/json'},
      );
    }),
    postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );
}

void main() {
  late AppDatabase cacheDb;
  late ReferenceDataCache cache;

  setUp(() {
    cacheDb = AppDatabase(NativeDatabase.memory());
    cache = ReferenceDataCache(cacheDb);
  });

  tearDown(() => cacheDb.close());

  group('SubclassChoiceRowMapper', () {
    test('collectConcernedClassIds ne garde que le niveau 1, '
        "choice_type 'sous_classe' et subclass_id nul", () {
      final ids = SubclassChoiceRowMapper.collectConcernedClassIds([
        {
          'class_id': 3,
          'level': 1,
          'choice_type': 'sous_classe',
          'subclass_id': null,
        },
        {
          'class_id': 4,
          'level': 3,
          'choice_type': 'sous_classe',
          'subclass_id': null,
        },
        {
          'class_id': 5,
          'level': 1,
          'choice_type': 'style_combat',
          'subclass_id': null,
        },
        {
          'class_id': 6,
          'level': 1,
          'choice_type': 'sous_classe',
          'subclass_id': 99,
        },
        {'level': 1, 'choice_type': 'sous_classe'},
      ]);
      expect(ids, {3});
    });

    test('toCatalog : classe concernée sans sous-classe -> clé à liste vide, '
        'noms/descriptions résolus, description vide -> null', () {
      final catalog = SubclassChoiceRowMapper.toCatalog(
        concernedClassIds: {3, 7},
        subclassRows: [
          {'id': 31, 'class_id': 3, 'available_from_level': 1},
          {'id': 32, 'class_id': 3, 'available_from_level': 1},
          {'id': 33, 'class_id': 3, 'available_from_level': 3},
          {'id': 34, 'class_id': 8, 'available_from_level': 1},
        ],
        names: {'31': 'Vie'},
        descriptions: {'31': 'Soigne.', '32': '  '},
      );

      expect(catalog.isConcerned(3), isTrue);
      expect(catalog.isConcerned(7), isTrue);
      expect(catalog.isConcerned(8), isFalse);
      expect(catalog.optionsFor(7), isEmpty);
      expect(catalog.optionsFor(9), isNull);

      final options = catalog.optionsFor(3)!;
      expect(options.map((o) => o.id), [31, 32]);
      expect(options[0].name, 'Vie');
      expect(options[0].description, 'Soigne.');
      expect(options[1].name, 'Sous-classe #32');
      expect(options[1].description, isNull);
      expect(catalog.nameOf(classId: 3, subclassId: 31), 'Vie');
      expect(catalog.nameOf(classId: 3, subclassId: 99), isNull);
      expect(catalog.nameOf(classId: 9, subclassId: 31), isNull);
    });
  });

  group('SupabaseSubclassChoiceRepository', () {
    test('la liste des classes concernées vient de class_features (niveau 1, '
        "choice_type 'sous_classe', subclass_id nul), pas d'un nom", () async {
      final requests = <http.Request>[];
      final client = _client((request) {
        requests.add(request);
        switch (request.url.pathSegments.last) {
          case 'class_features':
            return [
              {
                'class_id': 12,
                'level': 1,
                'choice_type': 'sous_classe',
                'subclass_id': null,
              },
            ];
          case 'subclasses':
            return [
              {'id': 121, 'class_id': 12, 'available_from_level': 1},
            ];
          case 'translations':
            final field = request.url.queryParameters['field_name'];
            return [
              {
                'entity_id': '121',
                'value': field == 'eq.name'
                    ? 'Archifée'
                    : 'Un patron féerique.',
              },
            ];
        }
        return const [];
      });

      final catalog = await SupabaseSubclassChoiceRepository(
        client,
        cache,
      ).fetchLevelOneSubclassChoices();

      expect(catalog.isConcerned(12), isTrue);
      expect(catalog.optionsFor(12)!.single.name, 'Archifée');
      expect(catalog.optionsFor(12)!.single.description, 'Un patron féerique.');

      final features = requests.firstWhere(
        (r) => r.url.pathSegments.last == 'class_features',
      );
      expect(features.url.queryParameters['level'], 'eq.1');
      expect(features.url.queryParameters['choice_type'], 'eq.sous_classe');
      expect(features.url.queryParameters['subclass_id'], 'is.null');
      final subclasses = requests.firstWhere(
        (r) => r.url.pathSegments.last == 'subclasses',
      );
      expect(subclasses.url.queryParameters['class_id'], 'in.(12)');
      expect(subclasses.url.queryParameters['available_from_level'], 'eq.1');
    });

    test('aucune classe concernée : catalogue vide, aucune requête '
        'subclasses/translations', () async {
      final tables = <String>[];
      final client = _client((request) {
        tables.add(request.url.pathSegments.last);
        return const <Map<String, dynamic>>[];
      });

      final catalog = await SupabaseSubclassChoiceRepository(
        client,
        cache,
      ).fetchLevelOneSubclassChoices();

      expect(catalog.optionsByClassId, isEmpty);
      expect(tables, ['class_features']);
    });

    test('erreur HTTP : CharacterCreationFailure', () async {
      final client = _client(
        (request) => {'message': 'boom', 'code': 'PGRST000'},
        status: 500,
      );

      expect(
        SupabaseSubclassChoiceRepository(
          client,
          cache,
        ).fetchLevelOneSubclassChoices(),
        throwsA(isA<CharacterCreationFailure>()),
      );
    });
  });

  group('SupabaseSubclassChoiceRepository — hors-ligne (cache)', () {
    Object okHandler(http.Request request) {
      switch (request.url.pathSegments.last) {
        case 'class_features':
          return [
            {
              'class_id': 12,
              'level': 1,
              'choice_type': 'sous_classe',
              'subclass_id': null,
            },
          ];
        case 'subclasses':
          return [
            {'id': 121, 'class_id': 12, 'available_from_level': 1},
          ];
        case 'translations':
          return [
            {'entity_id': '121', 'value': 'Archifée'},
          ];
      }
      return const [];
    }

    test('cache frais : aucune requête réseau', () async {
      await SupabaseSubclassChoiceRepository(
        _client(okHandler),
        cache,
      ).fetchLevelOneSubclassChoices();

      var requests = 0;
      final offline = _client((request) {
        requests++;
        return const [];
      });
      final catalog = await SupabaseSubclassChoiceRepository(
        offline,
        cache,
      ).fetchLevelOneSubclassChoices();

      expect(requests, 0);
      expect(catalog.optionsFor(12)!.single.name, 'Archifée');
    });

    test('cache périmé + échec réseau : retombe sur le cache', () async {
      await SupabaseSubclassChoiceRepository(
        _client(okHandler),
        cache,
      ).fetchLevelOneSubclassChoices();
      final entry = await cacheDb
          .select(cacheDb.cachedReferenceEntries)
          .getSingle();
      await cacheDb
          .into(cacheDb.cachedReferenceEntries)
          .insertOnConflictUpdate(
            CachedReferenceEntriesCompanion.insert(
              key: entry.key,
              payload: entry.payload,
              cachedAt: DateTime.now().subtract(const Duration(hours: 49)),
            ),
          );

      var requests = 0;
      final failing = _client((request) {
        requests++;
        return {'message': 'boom', 'code': 'PGRST000'};
      }, status: 500);
      final catalog = await SupabaseSubclassChoiceRepository(
        failing,
        cache,
      ).fetchLevelOneSubclassChoices();

      expect(requests, greaterThan(0));
      expect(catalog.isConcerned(12), isTrue);
      expect(catalog.optionsFor(12)!.single.name, 'Archifée');
    });

    test('ni réseau ni cache : CharacterCreationFailure', () async {
      final failing = _client(
        (request) => {'message': 'boom', 'code': 'PGRST000'},
        status: 500,
      );
      expect(
        SupabaseSubclassChoiceRepository(
          failing,
          cache,
        ).fetchLevelOneSubclassChoices(),
        throwsA(isA<CharacterCreationFailure>()),
      );
    });
  });

  group('createCharacter écrit character_classes.subclass_id', () {
    // JWT factice (exp lointain) : `recoverSession` l'accepte sans réseau.
    String jwt() {
      String part(Map<String, Object> json) =>
          base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
      return '${part({'alg': 'HS256', 'typ': 'JWT'})}.'
          '${part({'sub': 'user-1', 'exp': 4102444800})}.sig';
    }

    Future<Map<String, dynamic>> classInsertBody({int? subclassId}) async {
      Map<String, dynamic>? classInsert;
      final client = _client((request) {
        final table = request.url.pathSegments.last;
        if (request.method == 'POST') {
          final body = jsonDecode(request.body);
          if (table == 'character_classes') {
            classInsert = Map<String, dynamic>.from(body as Map);
          }
          if (table == 'characters') return {'id': 'char-1'};
        }
        return const <Map<String, dynamic>>[];
      });
      await client.auth.recoverSession(
        jsonEncode({
          'access_token': jwt(),
          'refresh_token': 'r',
          'token_type': 'bearer',
          'expires_in': 3600,
          'expires_at': 4102444800,
          'user': {
            'id': 'user-1',
            'aud': 'authenticated',
            'app_metadata': <String, dynamic>{},
            'user_metadata': <String, dynamic>{},
            'created_at': '2026-01-01T00:00:00Z',
          },
        }),
      );

      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await SupabaseCharacterCreationRepository(
        client,
        ReferenceDataCache(db),
      ).createCharacter(
        draft: CharacterCreationDraft(classId: 3, subclassId: subclassId),
        characterName: 'Test',
        raceCatalog: const RaceCatalog(races: [], subraces: []),
        classOption: const ClassOption(
          id: 3,
          name: 'Clerc',
          description: '',
          hitDie: 8,
        ),
        backgroundOption: const BackgroundOption(
          id: 1,
          name: 'Acolyte',
          skillProficiencies: [],
          featureName: '',
          featureDescription: '',
        ),
        skillCatalog: const SkillCatalog(skills: []),
        toolCatalog: const ToolCatalog(tools: []),
        languageCatalog: const LanguageCatalog(languages: []),
        spellCatalog: const SpellCatalog(spells: []),
        itemCatalog: const ItemCatalog(items: []),
      );
      return classInsert!;
    }

    test('sous-classe choisie : subclass_id = son id', () async {
      final body = await classInsertBody(subclassId: 31);
      expect(body['class_id'], 3);
      expect(body['subclass_id'], 31);
      expect(body['level'], 1);
    });

    test(
      'sans sous-classe : subclass_id nul (autres classes inchangées)',
      () async {
        final body = await classInsertBody();
        expect(body['subclass_id'], isNull);
      },
    );
  });
}
