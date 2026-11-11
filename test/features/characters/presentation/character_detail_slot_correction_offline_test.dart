// P9, hors ligne : lancer puis ANNULER avec la vraie file drift
// (`PendingCharacterWriteQueue`, kind `spellSlot`, valeur absolue par niveau)
// et le faux serveur PostgREST. Écran réel + dépôt d'écriture réel ; seule la
// relecture de la fiche est un double qui rejoue la superposition de la file
// (celle du vrai dépôt est couverte dans `data/`).

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
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/data/pending_character_write_syncer.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_spell_slot.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/character_detail_screen.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../support/fake_character_write_server.dart';
import '../../../support/fake_connectivity_checker.dart';
import '../../../support/fake_slot_repository.dart';

const _ownerId = 'owner-1';

/// Écritures déléguées au vrai dépôt ; relecture = fiche de base + écritures
/// `spellSlot` en file (même règle que `_withPendingWrites`).
class _ScreenRepository implements CharacterRepository {
  _ScreenRepository(this.real, this.queue);

  final SupabaseCharacterRepository real;
  final PendingCharacterWriteQueue queue;

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) async {
    var detail = wizardDetail(level3Used: 1);
    final pending = await queue.forCharacter(
      ownerId: _ownerId,
      characterId: characterId,
    );
    for (final write in pending) {
      if (write.kind != PendingCharacterWriteKind.spellSlot) continue;
      final level = (write.payload['slotLevel'] as num).toInt();
      final used = (write.payload['slotsUsed'] as num).toInt();
      detail = detail.copyWith(
        spellSlots: [
          for (final slot in detail.spellSlots)
            if (slot.level == level)
              CharacterSpellSlot(level: level, total: slot.total, used: used)
            else
              slot,
        ],
      );
    }
    return detail;
  }

  @override
  Future<WriteOutcome> castSpell({
    required String characterId,
    required int slotLevel,
    required int slotsUsed,
    bool isPactSlot = false,
  }) => real.castSpell(
    characterId: characterId,
    slotLevel: slotLevel,
    slotsUsed: slotsUsed,
    isPactSlot: isPactSlot,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  late AppDatabase db;
  late FakeConnectivityChecker connectivity;
  late PendingCharacterWriteQueue queue;
  late FakeCharacterWriteServer server;
  late PendingCharacterWriteSyncer syncer;

  Future<void> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    connectivity = FakeConnectivityChecker();
    queue = PendingCharacterWriteQueue(db);
    final cache = ReferenceDataCache(db);
    server = FakeCharacterWriteServer(
      characterRow: {'id': '1', 'owner_id': _ownerId, 'name': 'Test'},
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
            _ScreenRepository(real, queue),
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
    await tester.tap(find.text('SORTS'));
    await tester.pumpAndSettle();
  }

  /// Laisse le temps réel s'écouler (la file drift est une vraie E/S) puis
  /// avance les animations — voir `character_detail_catalog_offline_test.dart`.
  Future<void> settle(WidgetTester tester, {bool Function()? done}) async {
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

  Future<void> drain(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(seconds: 10));
  }

  testWidgets('hors ligne : lancer puis ANNULER -> une seule entrée de file '
      'avec la valeur absolue finale, bandeau de synchro, rejeu unique au '
      'retour du réseau', (tester) async {
    await pump(tester);
    connectivity.goOffline();
    await tester.pump();

    await tester.tap(find.text('Boule de feu'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PrimaryButton, 'LANCER'));
    await settle(
      tester,
      done: () => shown('Hors ligne · 1 modification en attente'),
    );

    // Un seul SnackBar : lancer + « sera synchronisé » fusionnés.
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Emplacement de niveau 3 utilisé'), findsOneWidget);
    expect(
      find.text('Hors ligne : sera synchronisé dès que la connexion revient.'),
      findsOneWidget,
    );
    expect(find.text('Hors ligne · 1 modification en attente'), findsOneWidget);
    expect(server.writes, isEmpty);

    // used 1 -> 2 (lancer) -> 1 (annulation, +1 relatif).
    await tester.tap(find.text('ANNULER'));
    await settle(tester);

    final entries = await tester.runAsync(
      () async =>
          (await queue.allForOwner(_ownerId))
              .where((w) => w.kind == PendingCharacterWriteKind.spellSlot)
              .toList(),
    );
    expect(entries, hasLength(1));
    expect(entries!.single.payload['slotLevel'], 3);
    expect(entries.single.payload['slotsUsed'], 1);
    expect(entries.single.payload['isPactSlot'], false);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Hors ligne · 1 modification en attente'), findsOneWidget);
    expect(server.writes, isEmpty);

    connectivity.goOnline();
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
    await settle(tester);

    expect(server.appliedWrites, hasLength(1));
    expect(server.appliedWrites.single.table, 'character_spell_slots');
    expect(server.appliedWrites.single.body, {'slots_used': 1});
    expect(find.textContaining('modification en attente'), findsNothing);
    await drain(tester);
  });

  testWidgets('hors ligne : la correction manuelle écrit une valeur absolue '
      'par niveau dans la file (dernière valeur gagnante)', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    connectivity.goOffline();
    await tester.pump();

    await tester.tap(find.text('Corriger'));
    await tester.pumpAndSettle();
    Finder remove() => find.bySemanticsLabel(
      RegExp(r'Niveau 3 : \d restants sur 2\. Retirer un emplacement'),
    );
    // used 1 -> 2 -> (0 restant : « − » sans effet).
    await tester.tap(remove());
    await settle(tester);
    await tester.tap(remove());
    await settle(tester);

    final entries = await tester.runAsync(
      () async =>
          (await queue.allForOwner(_ownerId))
              .where((w) => w.kind == PendingCharacterWriteKind.spellSlot)
              .toList(),
    );
    expect(entries, hasLength(1));
    expect(entries!.single.payload['slotLevel'], 3);
    expect(entries.single.payload['slotsUsed'], 2);
    expect(server.writes, isEmpty);
    expect(find.text('Hors ligne · 1 modification en attente'), findsOneWidget);
    handle.dispose();
    await drain(tester);
  });
}
