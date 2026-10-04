import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/features/character_creation/data/character_creation_repository.dart';
import 'package:personnages/features/character_creation/domain/background_option.dart';
import 'package:personnages/features/character_creation/domain/character_creation_draft.dart';
import 'package:personnages/features/character_creation/domain/character_creation_failure.dart';
import 'package:personnages/features/character_creation/domain/class_option.dart';
import 'package:personnages/features/character_creation/domain/item_catalog.dart';
import 'package:personnages/features/character_creation/domain/language_catalog.dart';
import 'package:personnages/features/character_creation/domain/language_option.dart';
import 'package:personnages/features/character_creation/domain/race_catalog.dart';
import 'package:personnages/features/character_creation/domain/skill_catalog.dart';
import 'package:personnages/features/character_creation/domain/spell_catalog.dart';
import 'package:personnages/features/character_creation/domain/tool_catalog.dart';
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
        cacheKey: 'spell_catalog_v2:1',
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

        expect(await cache.get('spell_catalog_v2:1'), isNotNull);
        expect(
          await cache.get('spell_catalog_v2:2'),
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

    _testCatalogCaching(
      description: 'fetchAlignmentCatalog',
      cacheKey: 'alignment_catalog',
      cache: () => cache,
      fetch: (repository) => repository.fetchAlignmentCatalog(),
      tableRows: {
        'alignments': [
          {'id': 8},
        ],
        'translations': [
          {'entity_id': '8', 'value': 'Loyal bon'},
        ],
      },
      verifySuccess: (dynamic catalog) {
        expect(catalog.alignments, hasLength(1));
        expect(catalog.alignments.single.name, 'Loyal bon');
        expect(catalog.alignments.single.id, 8);
      },
    );

    group('filtrage du contenu marqué is_incomplete', () {
      // Un seul test par catalogue suffit : le filtre vit dans
      // `_mapXxxCatalogPayload`, le même mapper que celui utilisé sur le
      // chemin de lecture depuis le cache (`_mappedFromCache`/
      // `_mappedFromFreshCache`) — voir la doc de classe de
      // `SupabaseCharacterCreationRepository`.
      test('fetchRaceCatalog omet une race is_incomplete: true', () async {
        final repository = SupabaseCharacterCreationRepository(
          _buildFakeSupabaseClient(
            tableRows: {
              'races': [
                {
                  'id': 1,
                  'ability_bonuses': {'dex': 2},
                  'traits': <Map<String, dynamic>>[],
                  'is_incomplete': false,
                },
                {
                  'id': 26,
                  'ability_bonuses': <String, dynamic>{},
                  'traits': <Map<String, dynamic>>[],
                  'is_incomplete': true,
                },
              ],
              'subraces': const <Map<String, dynamic>>[],
              'translations': [
                {'entity_id': '1', 'value': 'Humain'},
                {'entity_id': '26', 'value': 'Conil'},
              ],
            },
          ),
          cache,
        );

        final catalog = await repository.fetchRaceCatalog();

        expect(catalog.races, hasLength(1));
        expect(catalog.races.single.name, 'Humain');
      });

      test(
        'fetchBackgroundCatalog omet un historique is_incomplete: true',
        () async {
          final repository = SupabaseCharacterCreationRepository(
            _buildFakeSupabaseClient(
              tableRows: {
                'backgrounds': [
                  {
                    'id': 3,
                    'skill_proficiencies': ['Perception'],
                    'tool_or_language_choices': <String, dynamic>{},
                    'equipment': ['Une arme'],
                    'is_incomplete': false,
                  },
                  {
                    'id': 4,
                    'skill_proficiencies': <String>[],
                    'tool_or_language_choices': <String, dynamic>{},
                    'equipment': <String>[],
                    'is_incomplete': true,
                  },
                ],
                'translations': [
                  {'entity_id': '3', 'value': 'Soldat'},
                  {'entity_id': '4', 'value': 'Incomplet'},
                ],
              },
            ),
            cache,
          );

          final catalog = await repository.fetchBackgroundCatalog();

          expect(catalog.backgrounds, hasLength(1));
          expect(catalog.backgrounds.single.name, 'Soldat');
        },
      );

      test('fetchSpellCatalog omet un sort is_incomplete: true', () async {
        final repository = SupabaseCharacterCreationRepository(
          _buildFakeSupabaseClient(
            tableRows: {
              'spell_classes': [
                {'spell_id': 5},
                {'spell_id': 6},
              ],
              'spells': [
                {
                  'id': 5,
                  'level': 1,
                  'school': 'évocation',
                  'casting_time': '1 action',
                  'is_incomplete': false,
                },
                {
                  'id': 6,
                  'level': 1,
                  'school': 'évocation',
                  'casting_time': '1 action',
                  'is_incomplete': true,
                },
              ],
              'translations': [
                {'entity_id': '5', 'value': 'Projectile magique'},
                {'entity_id': '6', 'value': 'Sort incomplet'},
              ],
            },
          ),
          cache,
        );

        final catalog = await repository.fetchSpellCatalog(classId: 1);

        expect(catalog.spells, hasLength(1));
        expect(catalog.spells.single.name, 'Projectile magique');
      });
    });

    group('tri alphabétique normalisé des catalogues (accents ignorés)', () {
      // Sous `String.compareTo` brut, "Élémentaire" se classerait APRÈS
      // "Zénith" ou tout nom commençant par une lettre non accentuée
      // tardive (« É » a un point de code UTF-16 supérieur à la plupart des
      // lettres ASCII) — `FrenchTextNormalizer` corrige ce travers. Chaque
      // test ci-dessous fournit volontairement les lignes dans l'ordre
      // INVERSE de l'ordre alphabétique attendu, pour prouver que le tri est
      // bien appliqué (et pas juste "déjà dans le bon ordre par hasard").

      test(
        'fetchRaceCatalog : races triées, sous-races triées par race',
        () async {
          final repository = SupabaseCharacterCreationRepository(
            _buildFakeSupabaseClient(
              tableRows: {
                'races': [
                  {
                    'id': 2,
                    'ability_bonuses': <String, dynamic>{},
                    'traits': <Map<String, dynamic>>[],
                  },
                  {
                    'id': 1,
                    'ability_bonuses': <String, dynamic>{},
                    'traits': <Map<String, dynamic>>[],
                  },
                ],
                'subraces': [
                  {
                    'id': 12,
                    'race_id': 1,
                    'ability_bonuses': <String, dynamic>{},
                    'traits': <Map<String, dynamic>>[],
                  },
                  {
                    'id': 11,
                    'race_id': 1,
                    'ability_bonuses': <String, dynamic>{},
                    'traits': <Map<String, dynamic>>[],
                  },
                ],
                'translations': [
                  {'entity_id': '1', 'value': 'Élémentin'},
                  {'entity_id': '2', 'value': 'Zéphyrien'},
                  {'entity_id': '11', 'value': 'Zéphyrien des sables'},
                  {'entity_id': '12', 'value': 'Élémentin des cavernes'},
                ],
              },
            ),
            cache,
          );

          final catalog = await repository.fetchRaceCatalog();

          expect(catalog.races.map((r) => r.name), ['Élémentin', 'Zéphyrien']);
          expect(catalog.subracesOf(1).map((s) => s.name), [
            'Élémentin des cavernes',
            'Zéphyrien des sables',
          ]);
        },
      );

      test('fetchRaceCatalog : races de base avant races d\'extension, '
          'alphabétique dans chaque groupe (retour utilisateur du '
          '03/10/2026) — lignes volontairement désordonnées (extension triée '
          'avant base alphabétiquement si on ignorait le regroupement, pour '
          'prouver que le groupe prime bien sur le nom)', () async {
        final repository = SupabaseCharacterCreationRepository(
          _buildFakeSupabaseClient(
            tableRows: {
              'races': [
                {
                  'id': 1,
                  'source': 'Eberron / Monstres du Multivers',
                  'ability_bonuses': <String, dynamic>{},
                  'traits': <Map<String, dynamic>>[],
                },
                {
                  'id': 2,
                  'source': 'Manuel des Joueurs',
                  'ability_bonuses': <String, dynamic>{},
                  'traits': <Map<String, dynamic>>[],
                },
                {
                  'id': 3,
                  'source': 'Manuel des Joueurs (2024)',
                  'ability_bonuses': <String, dynamic>{},
                  'traits': <Map<String, dynamic>>[],
                },
                {
                  'id': 4,
                  'source': 'Strixhaven : un programme de chaos',
                  'ability_bonuses': <String, dynamic>{},
                  'traits': <Map<String, dynamic>>[],
                },
              ],
              'subraces': <Map<String, dynamic>>[],
              'translations': [
                // "Aasimar" (extension) alphabétiquement avant "Elfe" et
                // "Humain" (base) : si le tri restait purement
                // alphabétique, il apparaîtrait en tête de liste.
                {'entity_id': '1', 'value': 'Aasimar'},
                {'entity_id': '2', 'value': 'Humain'},
                {'entity_id': '3', 'value': 'Elfe'},
                {'entity_id': '4', 'value': 'Zariel'},
              ],
            },
          ),
          cache,
        );

        final catalog = await repository.fetchRaceCatalog();

        expect(catalog.races.map((r) => r.name), [
          'Elfe',
          'Humain',
          'Aasimar',
          'Zariel',
        ]);
        expect(catalog.races.map((r) => r.isCoreSource), [
          true,
          true,
          false,
          false,
        ]);
      });

      test('fetchClassCatalog : classes triées', () async {
        final repository = SupabaseCharacterCreationRepository(
          _buildFakeSupabaseClient(
            tableRows: {
              'classes': [
                {
                  'id': 2,
                  'hit_die': 8,
                  'skill_choices': {'count': 0, 'choices': <String>[]},
                  'tool_proficiencies': <String>[],
                },
                {
                  'id': 1,
                  'hit_die': 10,
                  'skill_choices': {'count': 0, 'choices': <String>[]},
                  'tool_proficiencies': <String>[],
                },
              ],
              'translations': [
                {'entity_id': '1', 'value': 'Éclaireur'},
                {'entity_id': '2', 'value': 'Zélote'},
              ],
            },
          ),
          cache,
        );

        final catalog = await repository.fetchClassCatalog();

        expect(catalog.classes.map((c) => c.name), ['Éclaireur', 'Zélote']);
      });

      test('fetchBackgroundCatalog : historiques triés', () async {
        final repository = SupabaseCharacterCreationRepository(
          _buildFakeSupabaseClient(
            tableRows: {
              'backgrounds': [
                {
                  'id': 2,
                  'skill_proficiencies': <String>[],
                  'tool_or_language_choices': <String, dynamic>{},
                  'equipment': <String>[],
                },
                {
                  'id': 1,
                  'skill_proficiencies': <String>[],
                  'tool_or_language_choices': <String, dynamic>{},
                  'equipment': <String>[],
                },
              ],
              'translations': [
                {'entity_id': '1', 'value': 'Érudit de guerre'},
                {'entity_id': '2', 'value': 'Zingaro'},
              ],
            },
          ),
          cache,
        );

        final catalog = await repository.fetchBackgroundCatalog();

        expect(catalog.backgrounds.map((b) => b.name), [
          'Érudit de guerre',
          'Zingaro',
        ]);
      });

      test('fetchToolCatalog : outils triés', () async {
        final repository = SupabaseCharacterCreationRepository(
          _buildFakeSupabaseClient(
            tableRows: {
              'tools': [
                {'id': 2, 'category': 'instrument'},
                {'id': 1, 'category': 'instrument'},
              ],
              'translations': [
                {'entity_id': '1', 'value': 'Épinette'},
                {'entity_id': '2', 'value': 'Zampogna'},
              ],
            },
          ),
          cache,
        );

        final catalog = await repository.fetchToolCatalog();

        expect(catalog.tools.map((t) => t.name), ['Épinette', 'Zampogna']);
      });

      test('fetchLanguageCatalog : langues triées', () async {
        final repository = SupabaseCharacterCreationRepository(
          _buildFakeSupabaseClient(
            tableRows: {
              'languages': [
                {'id': 2, 'type': 'standard'},
                {'id': 1, 'type': 'standard'},
              ],
              'translations': [
                {'entity_id': '1', 'value': 'Élfique ancien'},
                {'entity_id': '2', 'value': 'Zahari'},
              ],
            },
          ),
          cache,
        );

        final catalog = await repository.fetchLanguageCatalog();

        expect(catalog.languages.map((l) => l.name), [
          'Élfique ancien',
          'Zahari',
        ]);
      });

      test('fetchSpellCatalog : sorts triés (harmonisation accents)', () async {
        final repository = SupabaseCharacterCreationRepository(
          _buildFakeSupabaseClient(
            tableRows: {
              'spell_classes': [
                {'spell_id': 2},
                {'spell_id': 1},
              ],
              'spells': [
                {
                  'id': 2,
                  'level': 1,
                  'school': 'évocation',
                  'casting_time': '1 action',
                },
                {
                  'id': 1,
                  'level': 1,
                  'school': 'évocation',
                  'casting_time': '1 action',
                },
              ],
              'translations': [
                {'entity_id': '1', 'value': 'Éclair'},
                {'entity_id': '2', 'value': 'Zone de silence'},
              ],
            },
          ),
          cache,
        );

        final catalog = await repository.fetchSpellCatalog(classId: 1);

        expect(catalog.spells.map((s) => s.name), [
          'Éclair',
          'Zone de silence',
        ]);
      });
    });

    group('non-régression : catalogues qui doivent garder leur ordre '
        'canonique (pas de tri alphabétique)', () {
      test('fetchSkillCatalog : conserve l\'ordre `id` (ordre du Manuel des '
          'Joueurs, groupé par caractéristique)', () async {
        final repository = SupabaseCharacterCreationRepository(
          _buildFakeSupabaseClient(
            tableRows: {
              'skills': [
                {'id': 1, 'ability_id': 'str'},
                {'id': 2, 'ability_id': 'wis'},
              ],
              'translations': [
                // Volontairement "en désordre alphabétique" : Perception
                // (id 2) devrait rester APRÈS Athlétisme (id 1) même si
                // "Athlétisme" > "Perception" n'est pas le cas ici — on
                // force l'inverse pour être sûr qu'aucun tri alphabétique
                // n'est appliqué.
                {'entity_id': '1', 'value': 'Zoologie (Athlétisme)'},
                {'entity_id': '2', 'value': 'Alchimie (Perception)'},
              ],
            },
          ),
          cache,
        );

        final catalog = await repository.fetchSkillCatalog();

        expect(catalog.skills.map((s) => s.name), [
          'Zoologie (Athlétisme)',
          'Alchimie (Perception)',
        ]);
      });

      test('fetchAlignmentCatalog : conserve l\'ordre `id` (grille classique '
          'Loyal/Neutre/Chaotique x Bon/Neutre/Mauvais)', () async {
        final repository = SupabaseCharacterCreationRepository(
          _buildFakeSupabaseClient(
            tableRows: {
              'alignments': [
                {'id': 1},
                {'id': 2},
              ],
              'translations': [
                // Même principe que le test skills ci-dessus : "Zélé" (id 1)
                // avant "Altruiste" (id 2) alors que l'ordre alphabétique
                // voudrait l'inverse.
                {'entity_id': '1', 'value': 'Zélé (Loyal bon)'},
                {'entity_id': '2', 'value': 'Altruiste (Loyal neutre)'},
              ],
            },
          ),
          cache,
        );

        final catalog = await repository.fetchAlignmentCatalog();

        expect(catalog.alignments.map((a) => a.name), [
          'Zélé (Loyal bon)',
          'Altruiste (Loyal neutre)',
        ]);
      });

      test('fetchItemCatalog : conserve l\'ordre `id` (trié ailleurs, à '
          'l\'affichage — equipment_step_screen.dart)', () async {
        final repository = SupabaseCharacterCreationRepository(
          _buildFakeSupabaseClient(
            tableRows: {
              'items': [
                {
                  'id': 1,
                  'category': 'arme',
                  'cost': {'amount': 1, 'currency': 'gp'},
                },
                {
                  'id': 2,
                  'category': 'arme',
                  'cost': {'amount': 1, 'currency': 'gp'},
                },
              ],
              'translations': [
                {'entity_id': '1', 'value': 'Zweihänder'},
                {'entity_id': '2', 'value': 'Arbalète'},
              ],
            },
          ),
          cache,
        );

        final catalog = await repository.fetchItemCatalog();

        expect(catalog.items.map((i) => i.name), ['Zweihänder', 'Arbalète']);
      });
    });

    test(
      'régression : la requête .select() sur `alignments` ne référence '
      'jamais `name` (colonne inexistante sur cette table — vit dans '
      '`translations`, même principe que les 8 autres catalogues '
      'ci-dessus) — `02-modele-donnees.md` la documente à tort comme une '
      'exception, régression réelle poussée sur `main` faisant échouer '
      'l\'import XML avec `column alignments.name does not exist` (42703)',
      () async {
        String? capturedAlignmentsSelect;
        final client = _buildFakeSupabaseClient(
          tableRows: {
            'alignments': [
              {'id': 8},
            ],
            'translations': [
              {'entity_id': '8', 'value': 'Loyal bon'},
            ],
          },
          onRequest: (request) {
            if (request.url.pathSegments.last == 'alignments') {
              capturedAlignmentsSelect = request.url.queryParameters['select'];
            }
          },
        );
        final repository = SupabaseCharacterCreationRepository(client, cache);

        final catalog = await repository.fetchAlignmentCatalog();

        expect(capturedAlignmentsSelect, isNotNull);
        expect(capturedAlignmentsSelect, isNot(contains('name')));
        expect(catalog.alignments.single.name, 'Loyal bon');
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
        cacheKey: 'spell_catalog_v2:1',
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
          onRequest: (_) => networkCallCount++,
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

  group('SupabaseCharacterCreationRepository.createCharacter — sorts innés '
      'raciaux', () {
    // JWT factice (exp lointain) : `recoverSession` l'accepte sans réseau —
    // même principe que `subclass_choice_repository_test.dart`.
    String jwt() {
      String part(Map<String, Object> json) =>
          base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
      return '${part({'alg': 'HS256', 'typ': 'JWT'})}.'
          '${part({'sub': 'user-1', 'exp': 4102444800})}.sig';
    }

    // Transport HTTP fabriqué dédié (pas [_buildFakeSupabaseClient], qui
    // encode toujours [tableRows] sous forme de tableau JSON) : l'insert
    // `characters` utilise `.select('id').single()`, qui attend un OBJET
    // JSON unique en réponse (jamais un tableau) — même principe que
    // `subclass_choice_repository_test.dart::_client`.
    Future<SupabaseClient> signedInClient({
      required Map<String, List<Map<String, dynamic>>> tableRows,
      void Function(http.Request request)? onRequest,
    }) async {
      final client = SupabaseClient(
        'https://fake.supabase.test',
        'fake-anon-key',
        httpClient: MockClient((request) async {
          onRequest?.call(request);
          final table = request.url.pathSegments.last;
          final Object body = table == 'characters'
              ? const {'id': 'char-1'}
              : (tableRows[table] ?? const <Map<String, dynamic>>[]);
          return http.Response(
            jsonEncode(body),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
        postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
        authOptions: const AuthClientOptions(
          authFlowType: AuthFlowType.implicit,
        ),
      );
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
      return client;
    }

    // Brouillon/catalogues minimaux : aucun choix de sorts de classe/
    // compétences/outils/langues/équipement, pour qu'aucune autre table que
    // `characters`/`character_classes`/`character_level_hp`/
    // `character_spells` ne soit jamais écrite — même principe que
    // `subclass_choice_repository_test.dart::classInsertBody`.
    const classOption = ClassOption(
      id: 3,
      name: 'Clerc',
      description: '',
      hitDie: 8,
    );
    const backgroundOption = BackgroundOption(
      id: 1,
      name: 'Acolyte',
      skillProficiencies: [],
      featureName: '',
      featureDescription: '',
    );

    Future<List<Map<String, dynamic>>> createAndCaptureSpellInserts({
      required CharacterCreationDraft draft,
      required Map<String, List<Map<String, dynamic>>> tableRows,
    }) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final spellInserts = <Map<String, dynamic>>[];
      final client = await signedInClient(
        tableRows: tableRows,
        onRequest: (request) {
          if (request.method == 'POST' &&
              request.url.pathSegments.last == 'character_spells') {
            final body = jsonDecode(request.body);
            spellInserts.addAll(
              (body as List).map(
                (row) => Map<String, dynamic>.from(row as Map),
              ),
            );
          }
        },
      );

      await SupabaseCharacterCreationRepository(
        client,
        ReferenceDataCache(db),
      ).createCharacter(
        draft: draft,
        characterName: 'Test',
        raceCatalog: const RaceCatalog(races: [], subraces: []),
        classOption: classOption,
        backgroundOption: backgroundOption,
        skillCatalog: const SkillCatalog(skills: []),
        toolCatalog: const ToolCatalog(tools: []),
        languageCatalog: const LanguageCatalog(languages: []),
        spellCatalog: const SpellCatalog(spells: []),
        itemCatalog: const ItemCatalog(items: []),
      );

      return spellInserts;
    }

    test(
      'Tieffelin : Thaumaturgie accordée dès la création (niveau 1)',
      () async {
        final spellInserts = await createAndCaptureSpellInserts(
          draft: const CharacterCreationDraft(classId: 3, raceId: 9),
          tableRows: {
            'racial_innate_spells': const [
              {'spell_id': 24, 'subrace_id': null, 'character_level': 1},
            ],
            'translations': const [
              {'entity_id': '24', 'value': 'Thaumaturgie'},
            ],
          },
        );

        expect(spellInserts, hasLength(1));
        expect(spellInserts.single['spell_id'], 24);
        expect(spellInserts.single['status'], 'inné');
        expect(spellInserts.single['source_class_id'], isNull);
      },
    );

    test(
      "Drow : Ténèbres (niveau 5) PAS accordée dès la création (niveau 1)",
      () async {
        // Simule la vraie restriction serveur `character_level <= 1` : la
        // ligne Ténèbres (`character_level: 5`) n'est donc jamais renvoyée
        // à ce niveau, ce double de transport HTTP ne filtrant pas
        // lui-même par query string (voir la doc de classe de ce fichier).
        final spellInserts = await createAndCaptureSpellInserts(
          draft: const CharacterCreationDraft(
            classId: 3,
            raceId: 2,
            subraceId: 3,
          ),
          tableRows: const {'racial_innate_spells': [], 'translations': []},
        );

        expect(spellInserts, isEmpty);
      },
    );

    test('Génasi : sort de sa sous-race accordé dès la création', () async {
      final spellInserts = await createAndCaptureSpellInserts(
        draft: const CharacterCreationDraft(
          classId: 3,
          raceId: 23,
          subraceId: 25,
        ),
        tableRows: {
          'racial_innate_spells': const [
            {'spell_id': 77, 'subrace_id': 25, 'character_level': 1},
          ],
          'translations': const [
            {'entity_id': '77', 'value': 'Lévitation'},
          ],
        },
      );

      expect(spellInserts, hasLength(1));
      expect(spellInserts.single['spell_id'], 77);
      expect(spellInserts.single['status'], 'inné');
    });

    test('race personnalisée (raceId nul) : aucune lecture de sorts innés '
        'raciaux', () async {
      final spellInserts = await createAndCaptureSpellInserts(
        draft: const CharacterCreationDraft(
          classId: 3,
          raceCustomText: 'Race maison',
        ),
        tableRows: const {},
      );

      expect(spellInserts, isEmpty);
    });
  });

  group(
    'SupabaseCharacterCreationRepository.createCharacter — langue Commune',
    () {
      // Même principe que le harnais JWT/transport HTTP du groupe "sorts
      // innés raciaux" ci-dessus (`signedInClient`), dupliqué ici plutôt que
      // factorisé : ce groupe n'a besoin que de capturer les inserts
      // `character_languages`, pas `character_spells`.
      String jwt() {
        String part(Map<String, Object> json) =>
            base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
        return '${part({'alg': 'HS256', 'typ': 'JWT'})}.'
            '${part({'sub': 'user-1', 'exp': 4102444800})}.sig';
      }

      Future<SupabaseClient> signedInClient({
        required Map<String, List<Map<String, dynamic>>> tableRows,
        void Function(http.Request request)? onRequest,
      }) async {
        final client = SupabaseClient(
          'https://fake.supabase.test',
          'fake-anon-key',
          httpClient: MockClient((request) async {
            onRequest?.call(request);
            final table = request.url.pathSegments.last;
            final Object body = table == 'characters'
                ? const {'id': 'char-1'}
                : (tableRows[table] ?? const <Map<String, dynamic>>[]);
            return http.Response(
              jsonEncode(body),
              200,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }),
          postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
          authOptions: const AuthClientOptions(
            authFlowType: AuthFlowType.implicit,
          ),
        );
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
        return client;
      }

      const classOption = ClassOption(
        id: 3,
        name: 'Clerc',
        description: '',
        hitDie: 8,
      );
      const languageCatalog = LanguageCatalog(
        languages: [
          LanguageOption(id: 1, name: 'Commun', type: 'standard'),
          LanguageOption(id: 2, name: 'Elfique', type: 'standard'),
        ],
      );

      Future<List<Map<String, dynamic>>> createAndCaptureLanguageInserts({
        required CharacterCreationDraft draft,
        required BackgroundOption backgroundOption,
      }) async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final languageInserts = <Map<String, dynamic>>[];
        final client = await signedInClient(
          tableRows: const {},
          onRequest: (request) {
            if (request.method == 'POST' &&
                request.url.pathSegments.last == 'character_languages') {
              final body = jsonDecode(request.body);
              languageInserts.addAll(
                (body as List).map(
                  (row) => Map<String, dynamic>.from(row as Map),
                ),
              );
            }
          },
        );

        await SupabaseCharacterCreationRepository(
          client,
          ReferenceDataCache(db),
        ).createCharacter(
          draft: draft,
          characterName: 'Test',
          raceCatalog: const RaceCatalog(races: [], subraces: []),
          classOption: classOption,
          backgroundOption: backgroundOption,
          skillCatalog: const SkillCatalog(skills: []),
          toolCatalog: const ToolCatalog(tools: []),
          languageCatalog: languageCatalog,
          spellCatalog: const SpellCatalog(spells: []),
          itemCatalog: const ItemCatalog(items: []),
        );

        return languageInserts;
      }

      test('historique sans langue bonus (quota nul) : Commun est quand même '
          'insérée', () async {
        final inserts = await createAndCaptureLanguageInserts(
          draft: const CharacterCreationDraft(classId: 3),
          backgroundOption: const BackgroundOption(
            id: 1,
            name: 'Acolyte',
            skillProficiencies: [],
            featureName: '',
            featureDescription: '',
          ),
        );

        expect(inserts, hasLength(1));
        expect(inserts.single['language_id'], 1);
      });

      test('historique avec une langue bonus choisie : Commun ET la langue '
          'bonus sont insérées', () async {
        final inserts = await createAndCaptureLanguageInserts(
          draft: const CharacterCreationDraft(
            classId: 3,
            backgroundLanguageChoices: ['Elfique'],
          ),
          backgroundOption: const BackgroundOption(
            id: 1,
            name: 'Acolyte',
            skillProficiencies: [],
            featureName: '',
            featureDescription: '',
            languageChoiceCount: 1,
          ),
        );

        expect(
          inserts.map((row) => row['language_id']),
          containsAll(<int>[1, 2]),
        );
        expect(inserts, hasLength(2));
      });
    },
  );
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
  // strictement aucun (voir le groupe "TTL (cache d'abord si frais)"), et
  // aux tests de régression de colonne d'inspecter la query string
  // `select=...` réellement envoyée (voir la régression `alignments.name`
  // ci-dessus, même principe que `character_repository_test.dart`).
  void Function(http.Request request)? onRequest,
}) {
  Future<http.Response> handler(http.Request request) async {
    onRequest?.call(request);
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
