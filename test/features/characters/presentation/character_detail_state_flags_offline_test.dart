// T5a (P15) : réglages d'état (inspiration, bonus de CA) hors ligne depuis la
// fiche. Écran réel + dépôt d'écriture réel (file drift, faux serveur
// PostgREST) ; seule la relecture de la fiche est un double qui rejoue la
// superposition de la file (celle du vrai dépôt est couverte dans
// `character_state_flags_offline_test.dart`).

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/cache_providers.dart';
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/core/sync/sync_status_providers.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/data/pending_character_write_syncer.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/domain/offline_state_writes.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/character_detail_screen.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../support/fake_character_write_server.dart';
import '../../../support/fake_connectivity_checker.dart';

const _ownerId = 'owner-1';

/// Écritures déléguées au vrai dépôt ; relecture = fiche de base + réglages
/// en file (même règle que `_withPendingWrites`).
class _QueueBackedRepository implements CharacterRepository {
  _QueueBackedRepository(this.real, this.queue, this.server);

  final SupabaseCharacterRepository real;
  final PendingCharacterWriteQueue queue;
  final FakeCharacterWriteServer server;

  @override
  Future<List<CharacterSummary>> fetchCharacters() async => const [];

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) async {
    var detail = _fighter(
      inspiration: server.characterRow['inspiration'] == true,
      armorClassBonus: (server.characterRow['armor_class_bonus'] as num)
          .toInt(),
    );
    final pending = await queue.forCharacter(
      ownerId: _ownerId,
      characterId: characterId,
    );
    for (final write in pending) {
      if (write.kind != PendingCharacterWriteKind.characterFlags) continue;
      final patch = parseCharacterFlagsPayload(write.payload);
      if (patch == null) continue;
      detail = detail.copyWith(
        inspiration: patch.inspiration ?? detail.inspiration,
        armorClassBonus: patch.armorClassBonus ?? detail.armorClassBonus,
      );
    }
    return detail;
  }

  @override
  Future<WriteOutcome> setInspiration({
    required String characterId,
    required bool inspiration,
  }) => real.setInspiration(characterId: characterId, inspiration: inspiration);

  @override
  Future<WriteOutcome> setArmorClassBonus({
    required String characterId,
    required int bonus,
  }) => real.setArmorClassBonus(characterId: characterId, bonus: bonus);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

CharacterDetail _fighter({
  required bool inspiration,
  required int armorClassBonus,
}) => CharacterDetail(
  id: '1',
  name: 'Sylas',
  classes: const [
    CharacterDetailClassRow(
      classId: 1,
      className: 'Guerrier',
      level: 3,
      isPrimary: true,
      savingThrowProficiencies: [],
      hitDie: 10,
    ),
  ],
  xp: 0,
  currentHp: 10,
  maxHp: 10,
  temporaryHp: 0,
  abilityScores: const {},
  inspiration: inspiration,
  armorClassBonus: armorClassBonus,
);

void main() {
  late AppDatabase db;
  late FakeConnectivityChecker connectivity;
  late PendingCharacterWriteQueue queue;
  late FakeCharacterWriteServer server;
  late PendingCharacterWriteSyncer syncer;

  Future<void> pump(WidgetTester tester) async {
    db = AppDatabase(NativeDatabase.memory());
    connectivity = FakeConnectivityChecker();
    queue = PendingCharacterWriteQueue(db);
    final cache = ReferenceDataCache(db);
    server = FakeCharacterWriteServer(
      characterRow: {
        'id': '1',
        'owner_id': _ownerId,
        'name': 'Sylas',
        'inspiration': false,
        'armor_class_bonus': 0,
      },
    );
    late SupabaseClient client;
    await tester.runAsync(() async {
      client = await buildSignedInClient(server, ownerId: _ownerId);
    });
    final real = SupabaseCharacterRepository(
      client,
      cache,
      queue,
      connectivity,
    );
    syncer = PendingCharacterWriteSyncer(client, queue, cache, real);
    addTearDown(() async {
      await connectivity.close();
      await db.close();
    });
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          characterRepositoryProvider.overrideWithValue(
            _QueueBackedRepository(real, queue, server),
          ),
          appDatabaseProvider.overrideWithValue(db),
          syncOwnerIdProvider.overrideWithValue(_ownerId),
          connectivityCheckerProvider.overrideWithValue(connectivity),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          routerConfig: GoRouter(
            initialLocation: '/characters/1',
            routes: [
              GoRoute(
                path: '/characters/:id',
                builder: (context, state) => CharacterDetailScreen(
                  characterId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> settleAndSync(WidgetTester tester) async {
    connectivity.goOnline();
    await tester.runAsync(() async {
      expect(await syncer.sync(), {'1'});
    });
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> drain(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(seconds: 10));
  }

  testWidgets('inspiration hors ligne : pas de message d\'échec, état affiché, '
      'bandeau « 1 modification en attente », puis retour réseau -> '
      'synchro', (tester) async {
    await pump(tester);
    connectivity.goOffline();
    await tester.pump();
    expect(find.text('✓'), findsNothing);

    await tester.tap(find.text('INSP.'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining("n'a pas pu être enregistrée"), findsNothing);
    expect(
      find.text('Hors ligne : sera synchronisé dès que la connexion revient.'),
      findsOneWidget,
    );
    expect(find.text('✓'), findsOneWidget, reason: 'inspiration effective');
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Hors ligne · 1 modification en attente'), findsOneWidget);
    expect(server.writes, isEmpty);

    await settleAndSync(tester);

    expect(server.characterRow['inspiration'], true);
    expect(find.textContaining('modification en attente'), findsNothing);
    await drain(tester);
  });

  testWidgets('bonus de CA hors ligne : feuille fermée, pas de message '
      'd\'échec, bandeau « 1 modification en attente », puis synchro', (
    tester,
  ) async {
    await pump(tester);
    connectivity.goOffline();
    await tester.pump();

    await tester.tap(find.text('CA'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Augmenter'));
    await tester.tap(find.bySemanticsLabel('Augmenter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('VALIDER'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Ajustement de CA'), findsNothing, reason: 'sheet fermée');
    expect(find.textContaining("n'a pas pu être enregistrée"), findsNothing);
    expect(find.text('Hors ligne · 1 modification en attente'), findsOneWidget);
    expect(server.writes, isEmpty);

    await settleAndSync(tester);

    expect(server.characterRow['armor_class_bonus'], 2);
    expect(find.textContaining('modification en attente'), findsNothing);
    await drain(tester);
  });
}
