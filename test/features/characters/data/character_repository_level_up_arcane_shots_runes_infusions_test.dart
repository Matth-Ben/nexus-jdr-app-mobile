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
import 'package:personnages/features/characters/domain/level_up_infusion_swap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Couvre les 3 mécaniques jamais câblées côté Guerrier (Archer arcanique/
/// Chevalier runique)/Artificier — même famille que le Moine Voie des quatre
/// éléments (D85/D86) et le Guerrier Maître de guerre (D85), voir
/// `docs/dette-technique.md`. Vérifie en particulier que la résolution de la
/// ligne `class_features` se fait via `choice_type` SEUL pour les 2
/// aptitudes de SOUS-CLASSE (`'tir_arcanique'`/`'rune'`, même prudence que
/// `fetchAvailableManeuvers`) — jamais `.eq('class_id', classId)`, qui ne
/// matche structurellement jamais une ligne de sous-classe (`class_id` NULL,
/// D85) — et que l'échange RAW-exact d'infusion (`domain/
/// level_up_infusion_swap.dart`, D93) écrit un DELETE puis un INSERT séparés,
/// jamais un simple `UPDATE`.
///
/// Même double `SupabaseClient`/`MockClient` « léger » que
/// `character_repository_level_up_initial_spells_test.dart`, mais qui
/// respecte réellement les filtres `.eq(...)` demandés (voir
/// [_rowMatchesEqFilters] — D105 de `docs/dette-technique.md`, corrigé :
/// avant cette correction, TOUS les filtres étaient ignorés, ce qui rendait
/// les propriétés documentées ci-dessus non vérifiées). Les filtres non
/// `.eq(...)` (`.order(...)`, `.lte(...)`, `.inFilter(...)`) restent
/// ignorés : suffisant ici, chaque scénario ne lit chaque table qu'une seule
/// fois.
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
  const fighterClassId = 4;
  const arcaneArcherSubclassId = 50;
  const runeKnightSubclassId = 52;
  const artificerClassId = 13;
  const arcaneShotFeatureId = 95;
  const runeFeatureId = 97;
  const infusionFeatureId = 1296;

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

  group('SupabaseCharacterRepository.fetchAvailableArcaneShots', () {
    test('résout la ligne class_features via choice_type SEUL et exclut '
        'les tirs arcaniques déjà connus (chosen_value déjà résolu)', () async {
      final repo = await repository(
        rows: {
          'class_features': [
            // Leurres (D105 de `docs/dette-technique.md`) : d'autres
            // `choice_type`, placés AVANT la ligne réelle — si le code
            // résolvait sans filtrer par `choice_type` (ex. premier élément
            // arbitraire), ce serait une de ces 2 lignes qui serait
            // choisie, ce qui ferait échouer les assertions ci-dessous
            // (classId introuvable dans `character_class_options`, donc
            // "Tir explosif" ne serait jamais exclu comme déjà connu).
            {
              'id': runeFeatureId,
              'class_id': null,
              'subclass_id': runeKnightSubclassId,
              'choice_type': 'rune',
            },
            {
              'id': infusionFeatureId,
              'class_id': artificerClassId,
              'subclass_id': null,
              'choice_type': 'infusion',
            },
            {
              'id': arcaneShotFeatureId,
              'class_id': null,
              'subclass_id': arcaneArcherSubclassId,
              'choice_type': 'tir_arcanique',
            },
          ],
          'character_class_options': [
            {
              'chosen_value': 'Tir explosif',
              'class_feature_id': arcaneShotFeatureId,
            },
          ],
          'class_options': [
            {'id': 1, 'min_level': 3},
            {'id': 2, 'min_level': 3},
          ],
          'translations': [
            {'entity_id': '1', 'value': 'Tir explosif'},
            {'entity_id': '2', 'value': 'Décharge foudroyante'},
          ],
        },
      );

      final options = await repo.fetchAvailableArcaneShots(
        characterId: characterId,
        classId: fighterClassId,
        subclassId: arcaneArcherSubclassId,
        targetLevel: 3,
      );

      expect(options, hasLength(1));
      expect(options.single.name, 'Décharge foudroyante');
    });

    test('ligne class_features introuvable : aucun tir arcanique jamais '
        'considéré "déjà connu" (liste vide, pas d\'exception)', () async {
      final repo = await repository(
        rows: {
          'class_features': const [],
          'class_options': [
            {'id': 1, 'min_level': 3},
          ],
          'translations': [
            {'entity_id': '1', 'value': 'Tir explosif'},
          ],
        },
      );

      final options = await repo.fetchAvailableArcaneShots(
        characterId: characterId,
        classId: fighterClassId,
        subclassId: arcaneArcherSubclassId,
        targetLevel: 3,
      );

      expect(options, hasLength(1));
    });
  });

  group('SupabaseCharacterRepository.fetchAvailableRunes', () {
    test('résout la ligne class_features via choice_type SEUL et exclut '
        'les runes déjà connues', () async {
      final repo = await repository(
        rows: {
          'class_features': [
            // Leurres (même principe que [fetchAvailableArcaneShots]
            // ci-dessus, D105 de `docs/dette-technique.md`), placés AVANT
            // la ligne réelle.
            {
              'id': arcaneShotFeatureId,
              'class_id': null,
              'subclass_id': arcaneArcherSubclassId,
              'choice_type': 'tir_arcanique',
            },
            {
              'id': infusionFeatureId,
              'class_id': artificerClassId,
              'subclass_id': null,
              'choice_type': 'infusion',
            },
            {
              'id': runeFeatureId,
              'class_id': null,
              'subclass_id': runeKnightSubclassId,
              'choice_type': 'rune',
            },
          ],
          'character_class_options': [
            {
              'chosen_value': 'Rune de Cloué',
              'class_feature_id': runeFeatureId,
            },
          ],
          'class_options': [
            {'id': 1, 'min_level': 3},
            {'id': 2, 'min_level': 7},
          ],
          'translations': [
            {'entity_id': '1', 'value': 'Rune de Cloué'},
            {'entity_id': '2', 'value': 'Rune de Feu'},
          ],
        },
      );

      final options = await repo.fetchAvailableRunes(
        characterId: characterId,
        classId: fighterClassId,
        subclassId: runeKnightSubclassId,
        targetLevel: 10,
      );

      expect(options, hasLength(1));
      expect(options.single.name, 'Rune de Feu');
    });
  });

  group('SupabaseCharacterRepository.fetchAvailableInfusions', () {
    test('exclut les infusions déjà connues et résout le prérequis textuel '
        'de support d\'objet', () async {
      final repo = await repository(
        rows: {
          'class_features': [
            // Leurres (même principe que [fetchAvailableArcaneShots]
            // ci-dessus, D105 de `docs/dette-technique.md`), placés AVANT
            // la ligne réelle.
            {
              'id': arcaneShotFeatureId,
              'class_id': null,
              'subclass_id': arcaneArcherSubclassId,
              'choice_type': 'tir_arcanique',
            },
            {
              'id': runeFeatureId,
              'class_id': null,
              'subclass_id': runeKnightSubclassId,
              'choice_type': 'rune',
            },
            {
              'id': infusionFeatureId,
              'class_id': artificerClassId,
              'subclass_id': null,
              'choice_type': 'infusion',
            },
          ],
          'character_class_options': [
            {
              'chosen_value': 'Armure renforcée',
              'class_feature_id': infusionFeatureId,
            },
          ],
          'class_options': [
            {
              'id': 1,
              'min_level': 2,
              'prerequisites': {'text': 'Armure'},
            },
            {
              'id': 2,
              'min_level': 2,
              'prerequisites': {'text': 'Arme'},
            },
          ],
          'translations': [
            {'entity_id': '1', 'value': 'Armure renforcée'},
            {'entity_id': '2', 'value': 'Lame enchantée'},
          ],
        },
      );

      final options = await repo.fetchAvailableInfusions(
        characterId: characterId,
        classId: artificerClassId,
        targetLevel: 2,
      );

      expect(options, hasLength(1));
      expect(options.single.name, 'Lame enchantée');
      expect(options.single.prerequisiteText, 'Arme');
    });
  });

  group('SupabaseCharacterRepository.fetchKnownInfusionNames', () {
    test('renvoie les chosen_value de la ligne infusion', () async {
      final repo = await repository(
        rows: {
          'class_features': [
            // Leurres (même principe que [fetchAvailableArcaneShots]
            // ci-dessus, D105 de `docs/dette-technique.md`), placés AVANT
            // la ligne réelle.
            {
              'id': arcaneShotFeatureId,
              'class_id': null,
              'subclass_id': arcaneArcherSubclassId,
              'choice_type': 'tir_arcanique',
            },
            {
              'id': runeFeatureId,
              'class_id': null,
              'subclass_id': runeKnightSubclassId,
              'choice_type': 'rune',
            },
            {
              'id': infusionFeatureId,
              'class_id': artificerClassId,
              'subclass_id': null,
              'choice_type': 'infusion',
            },
          ],
          'character_class_options': [
            {
              'chosen_value': 'Armure renforcée',
              'class_feature_id': infusionFeatureId,
            },
          ],
        },
      );

      final names = await repo.fetchKnownInfusionNames(
        characterId: characterId,
      );

      expect(names, ['Armure renforcée']);
    });

    test(
      'ligne class_features introuvable : liste vide, pas d\'exception',
      () async {
        final repo = await repository(rows: {'class_features': const []});

        final names = await repo.fetchKnownInfusionNames(
          characterId: characterId,
        );

        expect(names, isEmpty);
      },
    );
  });

  group('SupabaseCharacterRepository.applyLevelUp — arcaneShotNames/'
      'runeNames/infusionNames', () {
    test('écrit chaque liste avec le class_feature_id résolu par son propre '
        'choice_type', () async {
      final recorded = <_Recorded>[];
      final repo = await repository(
        recorded: recorded,
        rows: {
          'character_classes': [
            {'id': 'cc-1', 'class_id': fighterClassId, 'level': 2},
          ],
          'characters': [
            {'max_hp': 10, 'current_hp': 10},
          ],
          'class_features': [
            // Leurres (D105 de `docs/dette-technique.md`) : d'autres
            // `choice_type`, placés AVANT la ligne réelle — si la
            // résolution ignorait `choice_type` (ex. premier élément
            // arbitraire plutôt que la ligne filtrée), l'écriture viserait
            // `runeFeatureId`/`infusionFeatureId` au lieu
            // d'`arcaneShotFeatureId`, faisant échouer l'assertion
            // ci-dessous.
            {
              'id': runeFeatureId,
              'class_id': null,
              'subclass_id': runeKnightSubclassId,
              'choice_type': 'rune',
            },
            {
              'id': infusionFeatureId,
              'class_id': artificerClassId,
              'subclass_id': null,
              'choice_type': 'infusion',
            },
            {
              'id': arcaneShotFeatureId,
              'class_id': null,
              'subclass_id': arcaneArcherSubclassId,
              'choice_type': 'tir_arcanique',
            },
          ],
        },
      );

      final result = await repo.applyLevelUp(
        characterId: characterId,
        classId: fighterClassId,
        className: 'Guerrier',
        isMulticlassing: false,
        hpRolled: 4,
        hpMethod: 'roll',
        hpGain: 4,
        arcaneShotNames: const ['Tir explosif', 'Décharge foudroyante'],
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
      expect(insertedRows, [
        {
          'character_id': characterId,
          'class_feature_id': arcaneShotFeatureId,
          'level': 3,
          'chosen_value': 'Tir explosif',
        },
        {
          'character_id': characterId,
          'class_feature_id': arcaneShotFeatureId,
          'level': 3,
          'chosen_value': 'Décharge foudroyante',
        },
      ]);
    });

    test('runeNames résout sa PROPRE ligne class_features (choice_type '
        "'rune'), indépendante de celle des tirs arcaniques", () async {
      final recorded = <_Recorded>[];
      final repo = await repository(
        recorded: recorded,
        rows: {
          'character_classes': [
            {'id': 'cc-1', 'class_id': fighterClassId, 'level': 9},
          ],
          'characters': [
            {'max_hp': 10, 'current_hp': 10},
          ],
          'class_features': [
            // Leurres (même principe que le test précédent, D105 de
            // `docs/dette-technique.md`), placés AVANT la ligne réelle.
            {
              'id': arcaneShotFeatureId,
              'class_id': null,
              'subclass_id': arcaneArcherSubclassId,
              'choice_type': 'tir_arcanique',
            },
            {
              'id': infusionFeatureId,
              'class_id': artificerClassId,
              'subclass_id': null,
              'choice_type': 'infusion',
            },
            {
              'id': runeFeatureId,
              'class_id': null,
              'subclass_id': runeKnightSubclassId,
              'choice_type': 'rune',
            },
          ],
        },
      );

      await repo.applyLevelUp(
        characterId: characterId,
        classId: fighterClassId,
        className: 'Guerrier',
        isMulticlassing: false,
        hpRolled: 4,
        hpMethod: 'roll',
        hpGain: 4,
        runeNames: const ['Rune de Feu'],
      );

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
        'class_feature_id': runeFeatureId,
        'level': 10,
        'chosen_value': 'Rune de Feu',
      });
    });

    test('infusionNames résout sa PROPRE ligne class_features (choice_type '
        "'infusion'), aptitude de CLASSE", () async {
      final recorded = <_Recorded>[];
      final repo = await repository(
        recorded: recorded,
        rows: {
          'character_classes': [
            {'id': 'cc-1', 'class_id': artificerClassId, 'level': 1},
          ],
          'characters': [
            {'max_hp': 10, 'current_hp': 10},
          ],
          'class_features': [
            // Leurres (même principe que les 2 tests précédents, D105 de
            // `docs/dette-technique.md`), placés AVANT la ligne réelle.
            {
              'id': arcaneShotFeatureId,
              'class_id': null,
              'subclass_id': arcaneArcherSubclassId,
              'choice_type': 'tir_arcanique',
            },
            {
              'id': runeFeatureId,
              'class_id': null,
              'subclass_id': runeKnightSubclassId,
              'choice_type': 'rune',
            },
            {
              'id': infusionFeatureId,
              'class_id': artificerClassId,
              'subclass_id': null,
              'choice_type': 'infusion',
            },
          ],
        },
      );

      await repo.applyLevelUp(
        characterId: characterId,
        classId: artificerClassId,
        className: 'Artificier',
        isMulticlassing: false,
        hpRolled: 4,
        hpMethod: 'roll',
        hpGain: 4,
        infusionNames: const ['Armure renforcée'],
      );

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
        'class_feature_id': infusionFeatureId,
        'level': 2,
        'chosen_value': 'Armure renforcée',
      });
    });

    test('ligne class_features introuvable pour tir_arcanique : '
        'CharacterFailure explicite', () async {
      final repo = await repository(
        rows: {
          'character_classes': [
            {'id': 'cc-1', 'class_id': fighterClassId, 'level': 2},
          ],
          'characters': [
            {'max_hp': 10, 'current_hp': 10},
          ],
          'class_features': const [],
        },
      );

      await expectLater(
        repo.applyLevelUp(
          characterId: characterId,
          classId: fighterClassId,
          className: 'Guerrier',
          isMulticlassing: false,
          hpRolled: 4,
          hpMethod: 'roll',
          hpGain: 4,
          arcaneShotNames: const ['Tir explosif'],
        ),
        throwsA(isA<CharacterFailure>()),
      );
    });
  });

  group('SupabaseCharacterRepository.applyLevelUp — infusionSwap (D93)', () {
    test('supprime la ligne connue par id puis insère la nouvelle au '
        'niveau COURANT (jamais un UPDATE)', () async {
      final recorded = <_Recorded>[];
      final repo = await repository(
        recorded: recorded,
        rows: {
          'character_classes': [
            {'id': 'cc-1', 'class_id': artificerClassId, 'level': 4},
          ],
          'characters': [
            {'max_hp': 10, 'current_hp': 10},
          ],
          'class_features': [
            // Leurres (même principe que les tests `applyLevelUp` —
            // `arcaneShotNames`/`runeNames`/`infusionNames` ci-dessus, D105
            // de `docs/dette-technique.md`), placés AVANT la ligne réelle.
            {
              'id': arcaneShotFeatureId,
              'class_id': null,
              'subclass_id': arcaneArcherSubclassId,
              'choice_type': 'tir_arcanique',
            },
            {
              'id': runeFeatureId,
              'class_id': null,
              'subclass_id': runeKnightSubclassId,
              'choice_type': 'rune',
            },
            {
              'id': infusionFeatureId,
              'class_id': artificerClassId,
              'subclass_id': null,
              'choice_type': 'infusion',
            },
          ],
          // Ligne déjà connue, apprise au niveau 2 — jamais réutilisée pour
          // porter le niveau de la nouvelle infusion (voir l'assertion sur
          // `level: 5` ci-dessous, niveau COURANT après ce niveau 5).
          'character_class_options': [
            {
              'id': 'cco-1',
              'chosen_value': 'Armure renforcée',
              'class_feature_id': infusionFeatureId,
              'level': 2,
            },
          ],
        },
      );

      final result = await repo.applyLevelUp(
        characterId: characterId,
        classId: artificerClassId,
        className: 'Artificier',
        isMulticlassing: false,
        hpRolled: 4,
        hpMethod: 'roll',
        hpGain: 4,
        infusionSwap: const LevelUpInfusionSwap(
          removedName: 'Armure renforcée',
          addedName: 'Lame enchantée',
        ),
      );

      expect(result.newLevel, 5);

      final deletes = recorded
          .where(
            (r) => r.table == 'character_class_options' && r.method == 'DELETE',
          )
          .toList();
      expect(deletes, hasLength(1));
      expect(deletes.single.query['id'], 'eq.cco-1');

      final inserts = recorded
          .where(
            (r) => r.table == 'character_class_options' && r.method == 'POST',
          )
          .toList();
      expect(inserts, hasLength(1));
      expect(inserts.single.body, {
        'character_id': characterId,
        'class_feature_id': infusionFeatureId,
        'level': 5,
        'chosen_value': 'Lame enchantée',
      });
    });

    test('infusion retirée introuvable parmi les infusions connues : '
        'CharacterFailure explicite, aucune écriture', () async {
      final recorded = <_Recorded>[];
      final repo = await repository(
        recorded: recorded,
        rows: {
          'character_classes': [
            {'id': 'cc-1', 'class_id': artificerClassId, 'level': 4},
          ],
          'characters': [
            {'max_hp': 10, 'current_hp': 10},
          ],
          'class_features': [
            {
              'id': infusionFeatureId,
              'class_id': artificerClassId,
              'subclass_id': null,
              'choice_type': 'infusion',
            },
          ],
          'character_class_options': const [],
        },
      );

      await expectLater(
        repo.applyLevelUp(
          characterId: characterId,
          classId: artificerClassId,
          className: 'Artificier',
          isMulticlassing: false,
          hpRolled: 4,
          hpMethod: 'roll',
          hpGain: 4,
          infusionSwap: const LevelUpInfusionSwap(
            removedName: 'Infusion fantôme',
            addedName: 'Lame enchantée',
          ),
        ),
        throwsA(isA<CharacterFailure>()),
      );

      final writes = recorded
          .where(
            (r) => r.table == 'character_class_options' && r.method != 'GET',
          )
          .toList();
      expect(writes, isEmpty);
    });
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

/// Double « léger » (même principe que
/// `character_repository_level_up_initial_spells_test.dart`) : les lignes
/// configurées via [tableRows] sont retournées pour TOUTE requête `GET` sur
/// la table correspondante, sans appliquer les filtres de la requête —
/// suffisant ici, chaque table n'étant lue qu'une seule fois par scénario
/// (le comportement `choice_type` SEUL vs `.eq('class_id', classId)` est
/// déjà vérifié au niveau du CODE, pas de la simulation SQL, contrairement à
/// `character_repository_level_up_elemental_disciplines_test.dart`).
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
    final configuredRows = tableRows[table] ?? const <Map<String, dynamic>>[];
    final rows = request.method == 'GET'
        ? configuredRows
              .where(
                (row) => _rowMatchesEqFilters(row, request.url.queryParameters),
              )
              .toList()
        : const <Map<String, dynamic>>[];
    return http.Response(
      jsonEncode(rows),
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

/// Un filtre `.eq(colonne, valeur)` PostgREST s'encode `colonne=eq.valeur`
/// dans la query string (ex. `.eq('choice_type', 'rune')` devient
/// `choice_type=eq.rune`) — reconnu ici via le préfixe `eq.`. Une ligne qui
/// NE DÉCLARE PAS la colonne filtrée est considérée comme passant le filtre
/// (beaucoup de fixtures de ce fichier omettent délibérément les colonnes
/// non pertinentes pour leur scénario, ex. `subclass_id`/`option_type` sur
/// des lignes `class_options` — ne pas les exiger évite de devoir réécrire
/// toutes les fixtures existantes) ; une ligne qui déclare la colonne doit
/// avoir exactement la valeur demandée. Les filtres `.inFilter(...)`
/// (encodés `in.(...)`), `.lte(...)`, `.order(...)` restent ignorés (hors
/// périmètre de D105).
bool _rowMatchesEqFilters(Map<String, dynamic> row, Map<String, String> query) {
  for (final entry in query.entries) {
    if (!entry.value.startsWith('eq.')) continue;
    if (!row.containsKey(entry.key)) continue;
    final expected = entry.value.substring(3);
    if (row[entry.key]?.toString() != expected) return false;
  }
  return true;
}
