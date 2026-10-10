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
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/character_spell_slot.dart';
import 'package:personnages/features/characters/domain/innate_spell_usage.dart';
import 'package:personnages/features/characters/domain/spell_cast_block_reason.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Compteur d'usage des sorts innés de niveau >= 1
/// (`character_spells.innate_uses_spent`, D08) côté dépôt : lecture
/// (`select`, mapping, cache antérieur, lignes en double) et écriture
/// (`setInnateSpellUsesSpent`). La remise à zéro au repos long est couverte
/// par `character_repository_rest_test.dart`.
///
/// Même double `SupabaseClient`/`MockClient` que
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
  const cacheKey = 'character_detail:$ownerId:$characterId';

  // 30 : sort inné de niveau 2. 31 : sort mineur inné. 32 : sort ordinaire.
  Map<String, dynamic> spellLine(
    int spellId,
    String status, {
    int? innateUsesSpent = 0,
  }) => {
    'spell_id': spellId,
    'status': status,
    'is_favorite': false,
    'source_class_id': null,
    'innate_uses_spent': ?innateUsesSpent,
  };

  Map<String, List<Map<String, dynamic>>> rowsWith(
    List<Map<String, dynamic>> characterSpells,
  ) => {
    'characters': [
      {
        'id': characterId,
        'name': 'Lia',
        'xp': 0,
        'current_hp': 10,
        'max_hp': 10,
        'temporary_hp': 0,
        'race_id': null,
        'character_classes': <Map<String, dynamic>>[],
        'character_spells': characterSpells,
      },
    ],
    'translations': [
      for (final id in [30, 31, 32]) {'entity_id': '$id', 'value': 'S$id'},
    ],
    'spells': [
      {'id': 30, 'level': 2, 'school': ''},
      {'id': 31, 'level': 0, 'school': ''},
      {'id': 32, 'level': 1, 'school': ''},
    ],
  };

  Future<SupabaseCharacterRepository> repository({
    Map<String, List<Map<String, dynamic>>> rows = const {},
    List<_Recorded>? recorded,
    bool connected = true,
    bool Function(String method, String table)? failOn,
  }) async => SupabaseCharacterRepository(
    await _buildSignedInFakeSupabaseClient(
      ownerId: ownerId,
      recorded: recorded ?? <_Recorded>[],
      tableRows: rows,
      failOn: failOn,
    ),
    cache,
    pendingWrites,
    _FakeConnectivityChecker(connected: connected),
  );

  CharacterSpellEntry spellOf(CharacterDetail detail, int id) =>
      detail.spells.singleWhere((spell) => spell.id == id);

  group('fetchCharacterDetail — innate_uses_spent', () {
    test(
      'le select de la fiche relit character_spells.innate_uses_spent',
      () async {
        final recorded = <_Recorded>[];
        final repo = await repository(
          rows: rowsWith([spellLine(30, 'inné')]),
          recorded: recorded,
        );

        await repo.fetchCharacterDetail(characterId);

        final select = recorded
            .firstWhere((r) => r.table == 'characters' && r.method == 'GET')
            .query['select']!
            .replaceAll(RegExp(r'\s+'), '');
        expect(
          select,
          contains(
            'character_spells(spell_id,status,is_favorite,source_class_id,'
            'innate_uses_spent)',
          ),
        );
      },
    );

    test('usage dépensé : mappé, sort bloqué avec la raison "déjà utilisé" '
        'même avec un emplacement libre', () async {
      final repo = await repository(
        rows: rowsWith([spellLine(30, 'inné', innateUsesSpent: 1)]),
      );

      final spell = spellOf(await repo.fetchCharacterDetail(characterId), 30);

      expect(spell.innateUsesSpent, 1);
      expect(InnateSpellUsage.isLimited(spell), isTrue);
      expect(
        SpellCastBlockReason.of(
          spell: spell,
          spellSlots: const [CharacterSpellSlot(level: 2, total: 1, used: 0)],
        ),
        SpellCastBlockReason.innateUseSpent,
      );
    });

    test('usage disponible : lançable sans aucun emplacement ; sort mineur '
        'inné et sort ordinaire inchangés', () async {
      final repo = await repository(
        rows: rowsWith([
          spellLine(30, 'inné'),
          spellLine(31, 'inné'),
          spellLine(32, 'préparé'),
        ]),
      );

      final detail = await repo.fetchCharacterDetail(characterId);

      expect(spellOf(detail, 30).innateUsesSpent, 0);
      expect(
        SpellCastBlockReason.of(
          spell: spellOf(detail, 30),
          spellSlots: const [],
        ),
        isNull,
      );
      expect(InnateSpellUsage.isLimited(spellOf(detail, 31)), isFalse);
      expect(InnateSpellUsage.isLimited(spellOf(detail, 32)), isFalse);
      expect(
        SpellCastBlockReason.of(
          spell: spellOf(detail, 32),
          spellSlots: const [],
        ),
        SpellCastBlockReason.noSlotAvailable,
      );
    });

    test('hors ligne : le cache restitue le compteur', () async {
      await (await repository(
        rows: rowsWith([spellLine(30, 'inné', innateUsesSpent: 1)]),
      )).fetchCharacterDetail(characterId);

      final detail = await (await repository(failOn: (method, table) => true))
          .fetchCharacterDetail(characterId);

      expect(spellOf(detail, 30).innateUsesSpent, 1);
    });

    test('ancien cache sans innate_uses_spent : 0 (usage disponible), sans '
        'erreur', () async {
      await (await repository(
        rows: rowsWith([spellLine(30, 'inné', innateUsesSpent: 1)]),
      )).fetchCharacterDetail(characterId);
      final payload = Map<String, dynamic>.from(
        await cache.get(cacheKey) as Map<String, dynamic>,
      );
      final row = Map<String, dynamic>.from(payload['row'] as Map);
      row['character_spells'] = [
        for (final spellRow in row['character_spells'] as List)
          Map<String, dynamic>.from(spellRow as Map)
            ..remove('innate_uses_spent'),
      ];
      payload['row'] = row;
      await cache.put(cacheKey, payload);

      final detail = await (await repository(failOn: (method, table) => true))
          .fetchCharacterDetail(characterId);

      final spell = spellOf(detail, 30);
      expect(spell.status, 'inné');
      expect(spell.innateUsesSpent, 0);
      expect(
        SpellCastBlockReason.of(spell: spell, spellSlots: const []),
        isNull,
      );
    });

    test('réponse sans la colonne (clé absente) : 0, sans erreur', () async {
      final repo = await repository(
        rows: rowsWith([spellLine(30, 'inné', innateUsesSpent: null)]),
      );

      final spell = spellOf(await repo.fetchCharacterDetail(characterId), 30);

      expect(spell.innateUsesSpent, 0);
    });

    test('lignes en double "inné" divergentes (0 et 1) : la plus haute est '
        'retenue, quel que soit l\'ordre — le sort est épuisé', () async {
      for (final reversed in [false, true]) {
        final lines = [
          spellLine(30, 'inné'),
          spellLine(30, 'inné', innateUsesSpent: 1),
        ];
        final repo = await repository(
          rows: rowsWith(reversed ? lines.reversed.toList() : lines),
        );

        final spell = spellOf(await repo.fetchCharacterDetail(characterId), 30);

        expect(spell.innateUsesSpent, 1, reason: 'reversed=$reversed');
        expect(
          SpellCastBlockReason.of(spell: spell, spellSlots: const []),
          SpellCastBlockReason.innateUseSpent,
          reason: 'reversed=$reversed',
        );
      }
    });

    test('lignes en double "inné" dépensée + ordinaire à 0 : le compteur de '
        'la ligne innée est retenu quel que soit l\'ordre (la ligne '
        'ordinaire ne le masque pas)', () async {
      for (final reversed in [false, true]) {
        final lines = [
          spellLine(30, 'inné', innateUsesSpent: 1),
          spellLine(30, 'connu'),
        ];
        final repo = await repository(
          rows: rowsWith(reversed ? lines.reversed.toList() : lines),
        );

        final spell = spellOf(await repo.fetchCharacterDetail(characterId), 30);

        expect(spell.innateUsesSpent, 1, reason: 'reversed=$reversed');
      }
    });

    // Retour QA : le statut ne dépend plus de l'ordre de lecture (le
    // `select` n'a pas d'`ORDER BY`). Une ligne ordinaire l'emporte toujours
    // sur une ligne 'inné' : le sort suit le circuit ordinaire (emplacement),
    // comme avant D08. Ce test remplace une « CARACTÉRISATION » où le statut
    // suivait la dernière ligne lue.
    for (final ordinary in ['connu', 'préparé']) {
      test('lignes en double "inné" + "$ordinary" : la ligne ordinaire '
          'l\'emporte quel que soit l\'ordre — sort non présenté comme inné, '
          'emplacement exigé', () async {
        for (final reversed in [false, true]) {
          final lines = [
            spellLine(30, 'inné', innateUsesSpent: 1),
            spellLine(30, ordinary),
          ];
          final repo = await repository(
            rows: rowsWith(reversed ? lines.reversed.toList() : lines),
          );

          final spell = spellOf(
            await repo.fetchCharacterDetail(characterId),
            30,
          );

          final reason = 'reversed=$reversed';
          expect(spell.status, ordinary, reason: reason);
          expect(InnateSpellUsage.isLimited(spell), isFalse, reason: reason);
          // Circuit ordinaire : jamais la raison « déjà utilisé », et un
          // emplacement est exigé.
          expect(
            SpellCastBlockReason.of(spell: spell, spellSlots: const []),
            ordinary == 'connu'
                ? SpellCastBlockReason.unprepared
                : SpellCastBlockReason.noSlotAvailable,
            reason: reason,
          );
          expect(
            SpellCastBlockReason.of(
              spell: spell,
              spellSlots: const [
                CharacterSpellSlot(level: 2, total: 1, used: 0),
              ],
            ),
            ordinary == 'connu' ? SpellCastBlockReason.unprepared : isNull,
            reason: reason,
          );
        }
      });
    }

    test('trois lignes "inné" + "connu" + "inné" : la ligne ordinaire '
        'l\'emporte encore', () async {
      final repo = await repository(
        rows: rowsWith([
          spellLine(30, 'inné'),
          spellLine(30, 'connu'),
          spellLine(30, 'inné', innateUsesSpent: 1),
        ]),
      );

      expect(
        spellOf(await repo.fetchCharacterDetail(characterId), 30).status,
        'connu',
      );
    });

    test(
      'lignes ordinaires de statuts différents ("connu" + "préparé") : '
      '"préparé" l\'emporte toujours, quel que soit l\'ordre des lignes — '
      "corrigé (D10) : avant ce correctif, la dernière ligne lue l'emportait",
      () async {
        final preparedLast = await repository(
          rows: rowsWith([spellLine(30, 'connu'), spellLine(30, 'préparé')]),
        );
        expect(
          spellOf(
            await preparedLast.fetchCharacterDetail(characterId),
            30,
          ).status,
          'préparé',
        );

        final knownLast = await repository(
          rows: rowsWith([spellLine(30, 'préparé'), spellLine(30, 'connu')]),
        );
        expect(
          spellOf(await knownLast.fetchCharacterDetail(characterId), 30).status,
          'préparé',
        );
      },
    );
  });

  group('setInnateSpellUsesSpent', () {
    const ownedCharacter = {
      'characters': [
        {'id': characterId},
      ],
    };

    test('en ligne : écrit la valeur absolue sur les seules lignes "inné" du '
        'sort, retourne synced', () async {
      final recorded = <_Recorded>[];
      final repo = await repository(rows: ownedCharacter, recorded: recorded);

      final outcome = await repo.setInnateSpellUsesSpent(
        characterId: characterId,
        spellId: 30,
        usesSpent: 1,
      );

      expect(outcome, WriteOutcome.synced);
      final writes = recorded.where((r) => r.method != 'GET').toList();
      expect(writes, hasLength(1));
      expect(writes.single.method, 'PATCH');
      expect(writes.single.table, 'character_spells');
      expect(writes.single.body, {'innate_uses_spent': 1});
      expect(writes.single.query['character_id'], 'eq.$characterId');
      expect(writes.single.query['spell_id'], 'eq.30');
      expect(writes.single.query['status'], 'eq.inné');
      // Appartenance vérifiée avant l'écriture.
      final ownerCheck = recorded.first;
      expect(ownerCheck.table, 'characters');
      expect(ownerCheck.query['owner_id'], 'eq.$ownerId');
    });

    // D11 du registre de dette technique (09/10/2026) : contrairement au
    // comportement antérieur (jamais mis en file, intention perdue), une
    // absence de connectivité met désormais réellement l'écriture en file.
    test('hors ligne : queued, aucune requête, mise en file réelle '
        '(targetId = spellId)', () async {
      final recorded = <_Recorded>[];
      final repo = await repository(
        rows: ownedCharacter,
        recorded: recorded,
        connected: false,
      );

      final outcome = await repo.setInnateSpellUsesSpent(
        characterId: characterId,
        spellId: 30,
        usesSpent: 1,
      );

      expect(outcome, WriteOutcome.queued);
      expect(recorded, isEmpty);
      final pending = await pendingWrites.allForOwner(ownerId);
      expect(pending, hasLength(1));
      expect(pending.single.kind, PendingCharacterWriteKind.innateSpell);
      expect(pending.single.targetId, '30');
      expect(pending.single.payload, {'spellId': 30, 'usesSpent': 1});
    });

    test('échec de l\'écriture : CharacterFailure', () async {
      final repo = await repository(
        rows: ownedCharacter,
        failOn: (method, table) => method == 'PATCH',
      );

      await expectLater(
        repo.setInnateSpellUsesSpent(
          characterId: characterId,
          spellId: 30,
          usesSpent: 1,
        ),
        throwsA(isA<CharacterFailure>()),
      );
    });

    test('personnage introuvable pour cet utilisateur : CharacterFailure, '
        'aucune écriture', () async {
      final recorded = <_Recorded>[];
      final repo = await repository(recorded: recorded);

      await expectLater(
        repo.setInnateSpellUsesSpent(
          characterId: characterId,
          spellId: 30,
          usesSpent: 1,
        ),
        throwsA(
          isA<CharacterFailure>().having(
            (failure) => failure.message,
            'message',
            'Personnage introuvable.',
          ),
        ),
      );
      expect(recorded.where((r) => r.method != 'GET'), isEmpty);
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

/// Même double que `character_repository_rest_test.dart` : routage par nom
/// de table, session factice sans réseau, journal [recorded] des requêtes.
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
