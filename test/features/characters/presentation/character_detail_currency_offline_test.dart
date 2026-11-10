// T3 (P15) : ajustement et conversion de monnaies hors ligne depuis la fiche.
// Écran réel + dépôt d'écriture réel (file drift, faux serveur PostgREST) ;
// seule la relecture de la fiche est un double qui rejoue la superposition
// de la file (celle du vrai dépôt est couverte dans
// `character_repository_pending_writes_test.dart`).

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
import 'package:personnages/features/characters/data/character_detail_cache.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/data/pending_character_write_syncer.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/characters/domain/reward_item_draft.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/character_detail_screen.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../support/fake_character_write_server.dart';
import '../../../support/fake_connectivity_checker.dart';

const _ownerId = 'owner-1';

/// Écritures déléguées au vrai dépôt ; relecture = fiche de base + monnaies
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
      gold: (server.characterRow['currency_gp'] as num).toInt(),
    );
    final pending = await queue.forCharacter(
      ownerId: _ownerId,
      characterId: characterId,
    );
    for (final write in pending) {
      if (write.kind != PendingCharacterWriteKind.currency) continue;
      final totals = validCurrencyTotals(write.payload['totals']);
      if (totals == null) continue;
      detail = detail.copyWith(
        currencyGp: totals['currency_gp'] ?? detail.currencyGp,
        currencySp: totals['currency_sp'] ?? detail.currencySp,
      );
    }
    return detail;
  }

  @override
  Future<WriteOutcome> adjustCurrency({
    required String characterId,
    required CurrencyKind currency,
    required int newAmount,
  }) => real.adjustCurrency(
    characterId: characterId,
    currency: currency,
    newAmount: newAmount,
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

CharacterDetail _fighter({required int gold}) => CharacterDetail(
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
        'currency_gp': 10,
        'currency_sp': 0,
      },
    );
    late SupabaseClient client;
    await tester.runAsync(() async {
      client = await buildSignedInClient(server, ownerId: _ownerId);
      await cache.put(
        CharacterDetailCache.keyFor(ownerId: _ownerId, characterId: '1'),
        {
          CharacterDetailCache.rowKey: {
            'name': 'Sylas',
            'currency_gp': 10,
            'currency_sp': 0,
          },
        },
      );
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

  testWidgets('ajustement hors ligne : feuille fermée, valeur à jour, '
      'bandeau « 1 modification en attente », puis retour réseau -> '
      'synchro', (tester) async {
    await pump(tester);
    connectivity.goOffline();
    await tester.pump();

    await tester.tap(find.text('PO'));
    await tester.pumpAndSettle();
    final increment = find.bySemanticsLabel('Augmenter');
    await tester.tap(increment);
    await tester.tap(increment);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PrimaryButton, 'APPLIQUER'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.widgetWithText(PrimaryButton, 'APPLIQUER'), findsNothing);
    expect(find.text('12'), findsWidgets, reason: 'valeur effective locale');
    expect(find.text('Hors ligne · 1 modification en attente'), findsOneWidget);
    expect(server.writes, isEmpty);

    await settleAndSync(tester);

    expect(server.characterRow['currency_gp'], 12);
    expect(find.textContaining('modification en attente'), findsNothing);
    await drain(tester);
  });

  testWidgets('conversion hors ligne : feuille fermée, soldes à jour, '
      'bandeau « 1 modification en attente », puis synchro', (tester) async {
    await pump(tester);
    connectivity.goOffline();
    await tester.pump();

    await tester.tap(find.text('PO'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CHANGER'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '4');
    await tester.pump();
    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TextField), findsNothing, reason: 'feuille fermée');
    expect(find.text('6'), findsWidgets);
    expect(find.text('40'), findsWidgets);
    expect(find.text('Hors ligne · 1 modification en attente'), findsOneWidget);
    expect(server.writes, isEmpty);

    await settleAndSync(tester);

    expect(server.characterRow['currency_gp'], 6);
    expect(server.characterRow['currency_sp'], 40);
    expect(find.textContaining('modification en attente'), findsNothing);
    await drain(tester);
  });
}
