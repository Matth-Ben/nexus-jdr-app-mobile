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
/// Couvre aussi D43 (décision de Matthias du 12/10/2026, symétrique de celle
/// du 10/10/2026 sur `racialInnateSpellIds`) : ce filtre ne doit PLUS exclure
/// un sort déjà connu UNIQUEMENT via sa route INNÉE (trait racial) — seule
/// une ligne ORDINAIRE déjà existante doit bloquer la réécriture (voir le
/// groupe de tests dédié plus bas).
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
  const magicienClassId = 3;
  const fighterClassId = 4;

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

    test('aucun recoupement : les deux sorts initiaux sont insérés normalement '
        '(non-régression)', () async {
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
    });
  });

  // D43 du registre de dette technique (`docs/dette-technique.md`), décision
  // de Matthias du 12/10/2026 : symétrique de celle du 10/10/2026 sur
  // `racialInnateSpellIds` (voir `character_repository_level_up_racial_spells_test.dart`)
  // — un sort déjà connu UNIQUEMENT via sa route INNÉE (trait racial) garde
  // malgré tout le droit à sa ligne ORDINAIRE séparée.
  group('SupabaseCharacterRepository.applyLevelUp — initialSpellIds (D43)', () {
    const alreadyInnateSpellId = 200; // déjà inné, AUCUNE ligne ordinaire.

    test('un sort initial qui coïncide avec un sort déjà connu UNIQUEMENT via '
        'sa route INNÉE (aucune ligne ordinaire) : la ligne ORDINAIRE est '
        'malgré tout écrite (les deux routes sont indépendantes)', () async {
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
          // Ligne 'inné' existante pour ce sort — AUCUNE ligne ordinaire.
          'character_spells': [
            {
              'spell_id': alreadyInnateSpellId,
              'status': 'inné',
              'source_class_id': null,
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
        initialSpellIds: const [alreadyInnateSpellId],
      );

      expect(result.newLevel, 2);

      final spellWrites = recorded
          .where((r) => r.table == 'character_spells' && r.method != 'GET')
          .toList();
      expect(spellWrites, hasLength(1));
      final insertedRows = (spellWrites.single.body! as List)
          .cast<Map<String, dynamic>>();
      expect(insertedRows.single, {
        'character_id': characterId,
        'spell_id': alreadyInnateSpellId,
        'status': 'connu',
        'source_class_id': occultisteClassId,
      });
    });
  });

  // D79 du registre de dette technique (`docs/dette-technique.md`), troisième
  // site corrigé : [SpellcastingRules.statusFor] marque TOUT nouveau sort de
  // niveau >= 1 d'une classe à préparation comme `'préparé'`, sans jamais
  // tenir compte du vrai plafond RAW (`PreparedSpellsLimit.limitFor`) — en
  // pratique, seul le Magicien emprunte ce chemin pour des sorts de niveau
  // >= 1 (croissance du grimoire, voir
  // `domain/spells_known_progression.dart::SpellsKnownProgression
  // .spellsKnownByLevel`). [SupabaseCharacterRepository.applyLevelUp] doit
  // désormais rétrograder l'excédent vers `'connu'`, exactement comme
  // `CharacterCreationRepository.createCharacter`/`CharacterEditPlanner.plan`
  // (mêmes deux premiers sites, déjà corrigés) — à ceci près que le plafond
  // doit ici tenir compte du TOTAL déjà préparé par les niveaux précédents,
  // pas seulement des sorts ajoutés à CE niveau.
  group('SupabaseCharacterRepository.applyLevelUp — plafond de préparation '
      'du Magicien (D79)', () {
    test('montée de niveau du Magicien : le grimoire grandit de 2 sorts, mais '
        'le plafond de préparation (déjà atteint par les niveaux précédents) '
        "rétrograde les deux nouveaux sorts en 'connu' plutôt que de les "
        "marquer 'préparé'", () async {
      final recorded = <_Recorded>[];
      const firstNewSpellId = 501;
      const secondNewSpellId = 502;
      final repo = await repository(
        recorded: recorded,
        rows: {
          // Magicien niveau 4 -> 5 (continue, pas un multiclassage).
          'character_classes': [
            {'id': 'cc-wizard', 'class_id': magicienClassId, 'level': 4},
          ],
          'characters': [
            {'max_hp': 30, 'current_hp': 30},
          ],
          // Intelligence 8 (modificateur -1) : limite RAW au niveau 5 =
          // 5 (niveau de classe) + (-1) = 4.
          'character_ability_scores': [
            {'ability_id': 'int', 'score': 8},
          ],
          // 4 sorts de niveau >= 1 déjà préparés par ce personnage pour
          // le Magicien (venant de niveaux précédents) : la limite (4) est
          // déjà atteinte avant même ce niveau.
          'character_spells': [
            for (final id in [400, 401, 402, 403])
              {
                'spell_id': id,
                'status': 'préparé',
                'source_class_id': magicienClassId,
                'spells': {'level': 1},
              },
          ],
          // Niveaux des deux nouveaux sorts de grimoire (niveau 1, donc
          // comptabilisables — jamais un cantrip).
          'spells': [
            {'id': firstNewSpellId, 'level': 1},
            {'id': secondNewSpellId, 'level': 1},
          ],
        },
      );

      final result = await repo.applyLevelUp(
        characterId: characterId,
        classId: magicienClassId,
        className: 'Magicien',
        isMulticlassing: false,
        hpRolled: 4,
        hpMethod: 'roll',
        hpGain: 4,
        initialSpellIds: const [firstNewSpellId, secondNewSpellId],
      );

      expect(result.newLevel, 5);

      final spellWrites = recorded
          .where((r) => r.table == 'character_spells' && r.method != 'GET')
          .toList();
      expect(spellWrites, hasLength(1));
      final insertedRows = (spellWrites.single.body! as List)
          .cast<Map<String, dynamic>>();
      expect(insertedRows, [
        {
          'character_id': characterId,
          'spell_id': firstNewSpellId,
          'status': 'connu',
          'source_class_id': magicienClassId,
        },
        {
          'character_id': characterId,
          'spell_id': secondNewSpellId,
          'status': 'connu',
          'source_class_id': magicienClassId,
        },
      ]);
    });

    // Point relevé par `code-reviewer` avant merge (`docs/dette-technique.md`,
    // entrée D79, troisième site) : le premier correctif de ce troisième site
    // appelait [_preparedSpellCountsByClass] sans `excludedSpellIds` —
    // contrairement au site déjà correct de D77
    // (`_resolvePreparingClassAndEnforceLimit`), qui exclut les sorts
    // "toujours préparés" d'une sous-classe (`subclass_spells`, `grant_kind
    // = 'always_prepared'`) pour ne jamais les compter en double avec une
    // ligne ordinaire `character_spells` à 'préparé'. Sous-classe de
    // Magicien FICTIVE pour ce test (aucune n'accorde `'always_prepared'` en
    // base à ce jour, non vérifié en production par manque d'accès lecture
    // — le code doit rester défensif indépendamment de ce constat).
    test(
      "un sort déjà 'préparé' par ailleurs accordé 'toujours préparé' par la "
      "sous-classe du personnage ne doit jamais compter deux fois dans le "
      'plafond : exclu du compteur, il libère de la place pour un nouveau '
      'sort de grimoire',
      () async {
        final recorded = <_Recorded>[];
        const firstNewSpellId = 501;
        const secondNewSpellId = 502;
        const wizardSubclassId = 900;
        // Parmi les 4 sorts déjà 'préparé' ci-dessous, celui-ci est AUSSI
        // accordé 'toujours préparé' par la sous-classe du personnage —
        // recoupement (D77) : sans l'exclusion, il est compté deux fois.
        const alwaysPreparedSpellId = 403;
        final repo = await repository(
          recorded: recorded,
          rows: {
            // Magicien niveau 4 -> 5 (continue, pas un multiclassage),
            // sous-classe déjà choisie (atteinte dès le niveau 2, donc déjà
            // active au niveau 4).
            'character_classes': [
              {
                'id': 'cc-wizard',
                'class_id': magicienClassId,
                'level': 4,
                'subclass_id': wizardSubclassId,
              },
            ],
            'characters': [
              {'max_hp': 30, 'current_hp': 30},
            ],
            // Intelligence 8 (modificateur -1) : limite RAW au niveau 5 =
            // 5 (niveau de classe) + (-1) = 4, identique au premier test de
            // ce groupe.
            'character_ability_scores': [
              {'ability_id': 'int', 'score': 8},
            ],
            // 4 sorts de niveau >= 1 déjà préparés par ce personnage pour
            // le Magicien — mais un seul doit réellement compter dans la
            // limite une fois [alwaysPreparedSpellId] exclu : 3/4, une place
            // reste donc libre avant même ce niveau.
            'character_spells': [
              for (final id in [400, 401, 402, alwaysPreparedSpellId])
                {
                  'spell_id': id,
                  'status': 'préparé',
                  'source_class_id': magicienClassId,
                  'spells': {'level': 1},
                },
            ],
            // Sort "toujours préparé" de la sous-classe du personnage,
            // accordé dès le niveau de classe 2 (déjà atteint au niveau 4) —
            // même table/`grant_kind` que D77.
            'subclass_spells': [
              {
                'subclass_id': wizardSubclassId,
                'spell_id': alwaysPreparedSpellId,
                'class_level': 2,
                'grant_kind': 'always_prepared',
              },
            ],
            // Niveaux des deux nouveaux sorts de grimoire (niveau 1, donc
            // comptabilisables — jamais un cantrip).
            'spells': [
              {'id': firstNewSpellId, 'level': 1},
              {'id': secondNewSpellId, 'level': 1},
            ],
          },
        );

        final result = await repo.applyLevelUp(
          characterId: characterId,
          classId: magicienClassId,
          className: 'Magicien',
          isMulticlassing: false,
          hpRolled: 4,
          hpMethod: 'roll',
          hpGain: 4,
          initialSpellIds: const [firstNewSpellId, secondNewSpellId],
        );

        expect(result.newLevel, 5);

        final spellWrites = recorded
            .where((r) => r.table == 'character_spells' && r.method != 'GET')
            .toList();
        expect(spellWrites, hasLength(1));
        final insertedRows = (spellWrites.single.body! as List)
            .cast<Map<String, dynamic>>();
        // Compteur réel 3/4 (place libre) : le premier nouveau sort reste
        // 'préparé', seul le second excède la limite — sans l'exclusion du
        // sort "toujours préparé" (compteur erroné 4/4, limite déjà
        // atteinte), les deux auraient été rétrogradés en 'connu'.
        expect(insertedRows, [
          {
            'character_id': characterId,
            'spell_id': firstNewSpellId,
            'status': 'préparé',
            'source_class_id': magicienClassId,
          },
          {
            'character_id': characterId,
            'spell_id': secondNewSpellId,
            'status': 'connu',
            'source_class_id': magicienClassId,
          },
        ]);
      },
    );

    test('multiclassage tardif (après le niveau 1 total) vers le Magicien : le '
        'plafond de préparation RAW du niveau 1 de la classe (pas le quota de '
        'sélection) rétrograde malgré tout l\'excédent en \'connu\'', () async {
      final recorded = <_Recorded>[];
      const firstSpellId = 501;
      const secondSpellId = 502;
      const thirdSpellId = 503;
      final repo = await repository(
        recorded: recorded,
        rows: {
          // Personnage déjà Guerrier niveau 5, multiclasse en Magicien
          // pour la première fois (niveau 1 de cette nouvelle classe) —
          // ne passe jamais par `CharacterEditPlanner` (réservé au niveau
          // 1 TOTAL), seulement par cette méthode.
          'character_classes': [
            {'id': 'cc-fighter', 'class_id': fighterClassId, 'level': 5},
          ],
          'characters': [
            {'max_hp': 40, 'current_hp': 40},
          ],
          // Intelligence 13 (prérequis Magicien rempli, modificateur +1) ;
          // Force 14 (prérequis Guerrier déjà possédé toujours rempli).
          'character_ability_scores': [
            {'ability_id': 'int', 'score': 13},
            {'ability_id': 'str', 'score': 14},
          ],
          'translations': [
            {'entity_id': '$fighterClassId', 'value': 'Guerrier'},
          ],
          'character_spells': <Map<String, dynamic>>[],
          // Niveau 1 de Magicien : limite RAW = 1 (niveau de classe) + 1
          // (modificateur d'Intelligence) = 2, pour 3 sorts choisis.
          'spells': [
            {'id': firstSpellId, 'level': 1},
            {'id': secondSpellId, 'level': 1},
            {'id': thirdSpellId, 'level': 1},
          ],
        },
      );

      final result = await repo.applyLevelUp(
        characterId: characterId,
        classId: magicienClassId,
        className: 'Magicien',
        isMulticlassing: true,
        hpRolled: 4,
        hpMethod: 'roll',
        hpGain: 4,
        initialSpellIds: const [firstSpellId, secondSpellId, thirdSpellId],
      );

      expect(result.newLevel, 6);

      final spellWrites = recorded
          .where((r) => r.table == 'character_spells' && r.method != 'GET')
          .toList();
      expect(spellWrites, hasLength(1));
      final insertedRows = (spellWrites.single.body! as List)
          .cast<Map<String, dynamic>>();
      expect(insertedRows, [
        {
          'character_id': characterId,
          'spell_id': firstSpellId,
          'status': 'préparé',
          'source_class_id': magicienClassId,
        },
        {
          'character_id': characterId,
          'spell_id': secondSpellId,
          'status': 'préparé',
          'source_class_id': magicienClassId,
        },
        {
          'character_id': characterId,
          'spell_id': thirdSpellId,
          'status': 'connu',
          'source_class_id': magicienClassId,
        },
      ]);
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

/// Même double que `character_repository_innate_spells_test.dart`/
/// `character_repository_rest_test.dart` : routage par nom de table, session
/// factice sans réseau, journal [recorded] des requêtes. Les lignes
/// configurées via [tableRows] sont retournées pour TOUTE requête `GET` sur
/// la table correspondante, SAUF `character_spells`, dont le filtre
/// `status=eq.<v>`/`status=neq.<v>` EST appliqué (voir
/// `character_repository_level_up_racial_spells_test.dart`, même besoin :
/// distinguer une ligne 'inné' d'une ligne ordinaire du même sort, dette D43)
/// — les autres tables ignorent les filtres de la requête, suffisant ici,
/// chaque autre table n'étant lue qu'une seule fois par scénario.
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
    final statusFilter = request.url.queryParameters['status'];
    if (request.method == 'GET' &&
        table == 'character_spells' &&
        statusFilter != null) {
      if (statusFilter.startsWith('eq.')) {
        final expected = statusFilter.substring('eq.'.length);
        rows = [
          for (final row in rows)
            if (row['status'] == expected) row,
        ];
      } else if (statusFilter.startsWith('neq.')) {
        final excluded = statusFilter.substring('neq.'.length);
        rows = [
          for (final row in rows)
            if (row['status'] != excluded) row,
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
