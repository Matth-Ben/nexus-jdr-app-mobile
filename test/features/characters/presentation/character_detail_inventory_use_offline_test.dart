// T5b-3 (P15) : usage d'un objet consommable hors ligne depuis la fiche. Écran
// réel + dépôt d'écriture réel (file drift, faux serveur PostgREST) ; seule la
// relecture de la fiche est un double qui rejoue la superposition de la file
// (celle du vrai dépôt est couverte dans
// `data/character_inventory_use_offline_test.dart`).

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
import 'package:personnages/features/characters/data/character_inventory_row_mapper.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/data/pending_character_write_syncer.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/domain/offline_inventory_writes.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/character_detail_screen.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../support/fake_character_write_server.dart';
import '../../../support/fake_connectivity_checker.dart';

const _ownerId = 'owner-1';
const _table = 'character_inventory';
const _serverItemId = '11111111-1111-4111-8111-111111111111';

/// Écritures déléguées au vrai dépôt ; relecture = fiche de base (inventaire du
/// faux serveur) + écritures `inventoryItem` en file (même règle que
/// `_withPendingWrites`).
class _QueueBackedRepository implements CharacterRepository {
  _QueueBackedRepository(this.real, this.queue, this.server);

  final SupabaseCharacterRepository real;
  final PendingCharacterWriteQueue queue;
  final FakeCharacterWriteServer server;

  @override
  Future<List<CharacterSummary>> fetchCharacters() async => const [];

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) async {
    var items = CharacterInventoryRowMapper.toCharacterInventoryItems(
      server.tables[_table]!,
      names: const {'5': 'Potion de soin'},
      descriptions: const {},
    );
    final pending = await queue.forCharacter(
      ownerId: _ownerId,
      characterId: characterId,
    );
    for (final write in pending) {
      if (write.kind != PendingCharacterWriteKind.inventoryItem) continue;
      final parsed = parseInventoryItemPayload(write.payload);
      if (parsed == null) continue;
      switch (parsed.op) {
        case InventoryItemOp.quantity:
          items = [
            for (final item in items)
              if (item.id != write.targetId)
                item
              else if (parsed.quantity! > 0)
                item.copyWithQuantity(parsed.quantity!),
          ];
        case InventoryItemOp.delete:
          items = [
            for (final item in items)
              if (item.id != write.targetId) item,
          ];
        case InventoryItemOp.add:
          break;
      }
    }
    return _fighter(items);
  }

  @override
  Future<WriteOutcome> useInventoryItem({
    required String characterId,
    required String inventoryId,
    required int newQuantity,
  }) => real.useInventoryItem(
    characterId: characterId,
    inventoryId: inventoryId,
    newQuantity: newQuantity,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

CharacterDetail _fighter(List<CharacterInventoryItem> items) => CharacterDetail(
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
  inventory: items,
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
    final inventoryRows = <Map<String, dynamic>>[
      {
        'id': _serverItemId,
        'character_id': '1',
        'item_id': 5,
        'custom_name': null,
        'quantity': 2,
        'items': {'category': 'equipement_general', 'consumable': true},
        'equipped': false,
        'weapon_slot': null,
        'is_attuned': false,
      },
    ];
    server = FakeCharacterWriteServer(
      characterRow: {'id': '1', 'owner_id': _ownerId, 'name': 'Sylas'},
    );
    server.tables[_table] = inventoryRows;
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
    await tester.tap(find.text('SAC'));
    await tester.pumpAndSettle();
  }

  Future<void> settleAfterAction(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> syncBack(WidgetTester tester) async {
    connectivity.goOnline();
    await tester.runAsync(() async {
      expect(await syncer.sync(), {'1'});
    });
    await settleAfterAction(tester);
  }

  Future<void> drain(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(seconds: 10));
  }

  Future<void> useItem(WidgetTester tester) async {
    await tester.tap(find.text('Potion de soin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Utiliser'));
    await settleAfterAction(tester);
  }

  testWidgets('usage hors ligne : quantité mise à jour, message « sera '
      'synchronisé » (pas « utilisé »), bandeau « 1 modification en attente », '
      'puis retour réseau -> synchro', (tester) async {
    await pump(tester);
    expect(find.textContaining('x2'), findsOneWidget);
    connectivity.goOffline();
    await tester.pump();

    await useItem(tester);

    expect(find.textContaining('x1'), findsOneWidget);
    expect(find.textContaining('x2'), findsNothing);
    expect(
      find.text('Hors ligne : sera synchronisé dès que la connexion revient.'),
      findsOneWidget,
    );
    expect(find.text('Potion de soin utilisé.'), findsNothing);
    expect(find.text('Hors ligne · 1 modification en attente'), findsOneWidget);
    expect(server.writes, isEmpty);

    await syncBack(tester);

    expect(server.tables[_table]!.single['quantity'], 1);
    expect(find.textContaining('modification en attente'), findsNothing);
    await drain(tester);
  });

  testWidgets('deux usages hors ligne jusqu à 0 : ligne masquée, une seule '
      'modification en attente (tombstone), synchro = DELETE', (tester) async {
    await pump(tester);
    connectivity.goOffline();
    await tester.pump();

    await useItem(tester);
    await useItem(tester);

    expect(find.text('Potion de soin'), findsNothing);
    expect(find.text('Hors ligne · 1 modification en attente'), findsOneWidget);

    await syncBack(tester);

    expect(server.tables[_table], isEmpty);
    expect(server.writes.map((w) => w.method), ['DELETE']);
    await drain(tester);
  });

  testWidgets('usage en ligne : message de confirmation, UPDATE immédiat', (
    tester,
  ) async {
    await pump(tester);

    await useItem(tester);

    expect(find.text('Potion de soin utilisé.'), findsOneWidget);
    expect(server.tables[_table]!.single['quantity'], 1);
    expect(await queue.allForOwner(_ownerId), isEmpty);
    await drain(tester);
  });
}
