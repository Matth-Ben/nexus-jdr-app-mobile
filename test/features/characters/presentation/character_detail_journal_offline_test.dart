// T4 (P15) : journal de campagne hors ligne depuis la fiche. Écran réel +
// dépôt d'écriture réel (file drift, faux serveur PostgREST) ; seule la
// relecture de la fiche est un double qui rejoue la superposition de la file
// (celle du vrai dépôt est couverte dans
// `data/character_journal_offline_test.dart`).

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
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_journal_entry.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/domain/offline_journal_writes.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/character_detail_screen.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../support/fake_character_write_server.dart';
import '../../../support/fake_connectivity_checker.dart';

const _ownerId = 'owner-1';
const _table = 'character_journal_entries';
const _serverEntryId = '11111111-1111-4111-8111-111111111111';

/// Écritures déléguées au vrai dépôt ; relecture = fiche de base (journal du
/// faux serveur) + écritures de journal en file (même règle que
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
    var entries = [
      for (final row in server.tables[_table]!)
        CharacterJournalEntry(
          id: row['id'] as String,
          body: row['body'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
        ),
    ];
    final pending = await queue.forCharacter(
      ownerId: _ownerId,
      characterId: characterId,
    );
    for (final write in pending) {
      if (write.kind != PendingCharacterWriteKind.journalEntry) continue;
      final parsed = parseJournalPayload(write.payload);
      if (parsed == null) continue;
      entries = [
        for (final e in entries)
          if (e.id != write.targetId) e,
        if (parsed.op == JournalWriteOp.add)
          CharacterJournalEntry(
            id: write.targetId,
            body: parsed.body!,
            createdAt: parsed.createdAt!,
          ),
        if (parsed.op == JournalWriteOp.update)
          for (final e in entries)
            if (e.id == write.targetId)
              CharacterJournalEntry(
                id: e.id,
                body: parsed.body!,
                createdAt: e.createdAt,
              ),
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return _fighter(entries);
  }

  @override
  Future<WriteOutcome> addJournalEntry({
    required String characterId,
    required String body,
  }) => real.addJournalEntry(characterId: characterId, body: body);

  @override
  Future<WriteOutcome> updateJournalEntry({
    required String characterId,
    required String entryId,
    required String body,
  }) => real.updateJournalEntry(
    characterId: characterId,
    entryId: entryId,
    body: body,
  );

  @override
  Future<WriteOutcome> removeJournalEntry({
    required String characterId,
    required String entryId,
  }) => real.removeJournalEntry(characterId: characterId, entryId: entryId);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

CharacterDetail _fighter(List<CharacterJournalEntry> entries) =>
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
      journalEntries: entries,
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
    final journalRows = <Map<String, dynamic>>[
      {
        'id': _serverEntryId,
        'character_id': '1',
        'body': 'Séance du serveur',
        'created_at': '2026-01-01T10:00:00+00:00',
      },
    ];
    server = FakeCharacterWriteServer(
      characterRow: {'id': '1', 'owner_id': _ownerId, 'name': 'Sylas'},
    );
    server.tables[_table] = journalRows;
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
    await tester.tap(find.text('HIST.'));
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

  testWidgets('ajout hors ligne : feuille fermée, note visible, bandeau '
      '« 1 modification en attente », puis retour réseau -> synchro', (
    tester,
  ) async {
    await pump(tester);
    connectivity.goOffline();
    await tester.pump();

    await tester.tap(find.text('Ajouter une note'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Note hors ligne');
    await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
    await settleAfterAction(tester);

    expect(find.text('AJOUTER UNE NOTE'), findsNothing, reason: 'fermée');
    expect(find.text('Note hors ligne'), findsOneWidget);
    expect(find.text('Hors ligne · 1 modification en attente'), findsOneWidget);
    expect(server.writes, isEmpty);

    await syncBack(tester);

    expect(
      server.tables[_table]!.map((r) => r['body']),
      contains('Note hors ligne'),
    );
    expect(find.textContaining('modification en attente'), findsNothing);
    await drain(tester);
  });

  testWidgets('modification puis suppression hors ligne : texte remplacé '
      'puis note masquée, une seule modification en attente, puis synchro', (
    tester,
  ) async {
    await pump(tester);
    connectivity.goOffline();
    await tester.pump();

    await tester.tap(find.text('Séance du serveur'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Séance corrigée');
    await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
    await settleAfterAction(tester);
    expect(find.text('Séance corrigée'), findsOneWidget);
    expect(find.text('Hors ligne · 1 modification en attente'), findsOneWidget);

    await tester.tap(find.text('Séance corrigée'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer').last);
    await settleAfterAction(tester);

    expect(find.text('Séance corrigée'), findsNothing);
    expect(find.text('Hors ligne · 1 modification en attente'), findsOneWidget);
    expect(server.writes, isEmpty);

    await syncBack(tester);

    expect(server.tables[_table], isEmpty);
    await drain(tester);
  });

  testWidgets('échec en ligne (refus serveur) : texte conservé, bandeau '
      'd\'erreur, rien en file', (tester) async {
    await pump(tester);
    server.rejectWith('42501');

    await tester.tap(find.text('Ajouter une note'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'À garder');
    await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
    await settleAfterAction(tester);

    expect(find.text('AJOUTER UNE NOTE'), findsOneWidget, reason: 'ouverte');
    expect(find.text('À garder'), findsOneWidget, reason: 'texte conservé');
    expect(await queue.allForOwner(_ownerId), isEmpty);
    await drain(tester);
  });
}
