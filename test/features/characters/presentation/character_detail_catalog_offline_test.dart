// T5b-2 (P15, F20) : ajout d'un objet du catalogue et butin avec objets hors
// ligne depuis la fiche. Écran réel + dépôt d'écriture réel (file drift, faux
// serveur PostgREST) ; seule la relecture de la fiche est un double qui rejoue
// la superposition de la file (celle du vrai dépôt, avec le cache du catalogue,
// est couverte dans `data/character_inventory_catalog_offline_test.dart`), et
// le catalogue est une liste fixe (son cache aussi).

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
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/data/character_inventory_row_mapper.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/data/pending_character_write_syncer.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/characters/domain/inventory_catalog_item.dart';
import 'package:personnages/features/characters/domain/offline_inventory_writes.dart';
import 'package:personnages/features/characters/domain/reward_item_draft.dart';
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

const _dagger = InventoryCatalogItem(
  id: 11,
  name: 'Dague',
  category: 'arme',
  costAmount: 2,
  weight: 0.5,
);

/// Ligne `items` du catalogue en cache pour la superposition du double.
const _daggerItemRow = {
  'category': 'arme',
  'weight': 0.5,
  'cost': {'amount': 2, 'currency': 'gp'},
};

/// Écritures déléguées au vrai dépôt ; relecture = fiche de base (inventaire du
/// faux serveur) + écritures `inventoryItem`/`currency` en file (même règle que
/// `_withPendingWrites`) ; catalogue fixe, indisponible tant que
/// [catalogAvailable] est faux.
class _ScreenRepository implements CharacterRepository {
  _ScreenRepository(this.real, this.queue, this.server);

  final SupabaseCharacterRepository real;
  final PendingCharacterWriteQueue queue;
  final FakeCharacterWriteServer server;
  bool catalogAvailable = true;
  int catalogFetches = 0;

  @override
  Future<List<InventoryCatalogItem>> fetchInventoryCatalog() async {
    catalogFetches++;
    if (!catalogAvailable) {
      throw const CharacterFailure(
        'Impossible de contacter le serveur.',
        code: CharacterErrorCode.network,
      );
    }
    return const [_dagger];
  }

  @override
  Future<List<CharacterSummary>> fetchCharacters() async => const [];

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) async {
    var items = CharacterInventoryRowMapper.toCharacterInventoryItems(
      server.tables[_table]!,
      names: const {'11': 'Dague'},
      descriptions: const {},
    );
    var gold = (server.characterRow['currency_gp'] as num).toInt();
    final pending = await queue.forCharacter(
      ownerId: _ownerId,
      characterId: characterId,
    );
    for (final write in pending) {
      if (write.kind == PendingCharacterWriteKind.currency) {
        gold = ((write.payload['totals'] as Map)['currency_gp'] as num).toInt();
      }
      if (write.kind != PendingCharacterWriteKind.inventoryItem) continue;
      final parsed = parseInventoryItemPayload(write.payload);
      if (parsed == null) continue;
      items = [
        for (final item in items)
          if (item.id != write.targetId) item,
        if (parsed.op == InventoryItemOp.add)
          ...CharacterInventoryRowMapper.toCharacterInventoryItems(
            [
              parsed.toRow(
                inventoryId: write.targetId,
                characterId: '1',
                itemRow: parsed.itemId == 11 ? _daggerItemRow : null,
              ),
            ],
            names: const {'11': 'Dague'},
            descriptions: const {},
          ),
      ];
    }
    return _fighter(items, gold);
  }

  @override
  Future<WriteOutcome> addInventoryItem({
    required String characterId,
    required int itemId,
    required int quantity,
  }) => real.addInventoryItem(
    characterId: characterId,
    itemId: itemId,
    quantity: quantity,
  );

  @override
  Future<WriteOutcome> addReward({
    required String characterId,
    required Map<CurrencyKind, int> newCurrencyTotals,
    required List<RewardItemDraft> items,
  }) => real.addReward(
    characterId: characterId,
    newCurrencyTotals: newCurrencyTotals,
    items: items,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

CharacterDetail _fighter(List<CharacterInventoryItem> items, int gold) =>
    CharacterDetail(
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
      currencyGp: gold,
      inventory: items,
    );

void main() {
  late AppDatabase db;
  late FakeConnectivityChecker connectivity;
  late PendingCharacterWriteQueue queue;
  late FakeCharacterWriteServer server;
  late PendingCharacterWriteSyncer syncer;
  late _ScreenRepository repository;
  late List<Map<String, dynamic>> inventoryRows;

  Future<void> pump(WidgetTester tester) async {
    db = AppDatabase(NativeDatabase.memory());
    connectivity = FakeConnectivityChecker();
    queue = PendingCharacterWriteQueue(db);
    final cache = ReferenceDataCache(db);
    inventoryRows = [
      {
        'id': _serverItemId,
        'character_id': '1',
        'item_id': null,
        'custom_name': 'Corde du serveur',
        'quantity': 1,
        'equipped': false,
        'weapon_slot': null,
        'is_attuned': false,
      },
    ];
    server = FakeCharacterWriteServer(
      characterRow: {
        'id': '1',
        'owner_id': _ownerId,
        'name': 'Sylas',
        'currency_gp': 10,
      },
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
    repository = _ScreenRepository(real, queue, server);
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
          characterRepositoryProvider.overrideWithValue(repository),
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

  /// Laisse le temps réel s'écouler (la file drift est une vraie E/S : chaque
  /// étape du dépôt demande un tour de boucle réelle) puis avance les
  /// animations, jusqu'à ce que [done] soit vrai (au plus 150 tours), puis
  /// quelques tours de plus pour finir la relecture de la fiche. Sans cela, une
  /// transaction d'enfilage encore en vol bloquerait la lecture ou la synchro
  /// lancée ensuite par le test.
  Future<void> settleAfterAction(
    WidgetTester tester, {
    bool Function()? done,
  }) async {
    for (var i = 0; i < 150; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 500));
      if (done != null && done()) break;
      if (done == null && i == 7) break;
    }
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  bool shown(String text) => find.text(text).evaluate().isNotEmpty;

  Future<void> syncBack(WidgetTester tester) async {
    connectivity.goOnline();
    // La synchro tourne dans la zone du test (pas dans runAsync) : les
    // requêtes de flux drift (bandeau) lancées dans cette zone ne se terminent
    // qu'à un pump ; la bloquer en runAsync les ferait s'attendre l'une l'autre.
    Set<String>? synced;
    final running = syncer.sync().then((value) => synced = value);
    for (var i = 0; i < 200 && synced == null; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 500));
    }
    await running;
    expect(synced, {'1'});
    await settleAfterAction(tester);
  }

  Future<void> drain(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(seconds: 10));
  }

  Future<void> openCatalog(WidgetTester tester, {required String tile}) async {
    await tester.tap(find.text(tile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Depuis le catalogue'));
    await tester.pumpAndSettle();
  }

  Future<void> pickDagger(WidgetTester tester) async {
    await tester.tap(find.text('Dague'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PrimaryButton, 'AJOUTER'));
  }

  testWidgets('ajout du catalogue hors ligne : feuille fermée, objet visible, '
      'bandeau « 1 modification en attente », puis retour réseau -> '
      'synchro', (tester) async {
    await pump(tester);
    connectivity.goOffline();
    await tester.pump();

    await openCatalog(tester, tile: 'Objet');
    await pickDagger(tester);
    await settleAfterAction(
      tester,
      done: () => shown('Hors ligne · 1 modification en attente'),
    );

    expect(find.text('Depuis le catalogue'), findsNothing, reason: 'fermée');
    expect(find.text('Dague'), findsOneWidget);
    expect(find.text('Hors ligne · 1 modification en attente'), findsOneWidget);
    expect(server.writes, isEmpty);

    await syncBack(tester);

    expect(inventoryRows.where((r) => r['item_id'] == 11), hasLength(1));
    expect(find.textContaining('modification en attente'), findsNothing);
    await drain(tester);
  });

  testWidgets('feuille d\'ajout hors ligne sans catalogue : message dédié '
      'proposant l\'objet personnalisé ; retour du réseau : catalogue '
      'rechargé', (tester) async {
    await pump(tester);
    repository.catalogAvailable = false;
    connectivity.goOffline();
    await tester.pump();

    await openCatalog(tester, tile: 'Objet');

    expect(
      find.textContaining(
        'Le catalogue d\'objets n\'est pas encore disponible',
      ),
      findsOneWidget,
    );
    expect(find.text('AJOUTER UN OBJET PERSONNALISÉ'), findsOneWidget);

    repository.catalogAvailable = true;
    connectivity.goOnline();
    await tester.pumpAndSettle();

    expect(repository.catalogFetches, 2);
    expect(find.text('Dague'), findsOneWidget);
    expect(
      find.textContaining(
        'Le catalogue d\'objets n\'est pas encore disponible',
      ),
      findsNothing,
    );
    await drain(tester);
  });

  testWidgets('butin avec objets hors ligne : feuille fermée, objet visible, '
      'bandeau « 2 modifications en attente » (monnaie + objet), puis '
      'synchro', (tester) async {
    await pump(tester);
    connectivity.goOffline();
    await tester.pump();

    await tester.tap(find.text('RÉCOMPENSE'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '5');
    await tester.pump();
    await openCatalog(tester, tile: 'Ajouter un objet');
    await pickDagger(tester);
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(PrimaryButton, 'AJOUTER LA RÉCOMPENSE'),
    );
    await settleAfterAction(
      tester,
      done: () => shown('Hors ligne · 2 modifications en attente'),
    );

    expect(find.text('AJOUTER UNE RÉCOMPENSE'), findsNothing, reason: 'fermée');
    expect(find.text('Dague'), findsOneWidget);
    expect(find.text('15'), findsOneWidget, reason: '10 + 5 po superposés');
    expect(
      find.text('Hors ligne · 2 modifications en attente'),
      findsOneWidget,
    );
    expect(server.writes, isEmpty);
    final kinds = await tester.runAsync(
      () async => [for (final l in await queue.allForOwner(_ownerId)) l.kind],
    );
    expect(
      kinds,
      unorderedEquals([
        PendingCharacterWriteKind.currency,
        PendingCharacterWriteKind.inventoryItem,
      ]),
    );

    await syncBack(tester);

    expect(server.characterRow['currency_gp'], 15);
    expect(inventoryRows.where((r) => r['item_id'] == 11), hasLength(1));
    expect(find.textContaining('modification en attente'), findsNothing);
    await drain(tester);
  });
}
