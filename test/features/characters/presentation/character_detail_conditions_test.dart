// Câblage des conditions (P6) côté `character_detail_screen.dart` : ouverture
// du sélecteur, écriture via `CharacterConditionsRepository`, affichage
// optimiste, retour arrière en cas d'erreur, hors-ligne (T5).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/native.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/cache_providers.dart';
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/core/sync/sync_status_providers.dart';
import 'package:personnages/features/characters/data/pending_character_write_syncer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../support/fake_character_write_server.dart';
import '../../../support/fake_connectivity_checker.dart';

import 'package:personnages/core/widgets/alert_banner.dart';
import 'package:personnages/core/widgets/selection_checkbox.dart';
import 'package:personnages/features/characters/data/character_conditions_repository.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/domain/condition_type.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/character_detail_screen.dart';
import 'package:personnages/features/characters/presentation/providers/character_conditions_providers.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/features/characters/presentation/widgets/condition_chips.dart';
import 'package:personnages/l10n/app_localizations.dart';

/// Seules `fetchCharacters`/`fetchCharacterDetail` sont utilisées ici.
class _FakeCharacterRepository implements CharacterRepository {
  _FakeCharacterRepository(this.current);

  CharacterDetail current;
  int fetchCount = 0;

  @override
  Future<List<CharacterSummary>> fetchCharacters() async => const [];

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) async {
    fetchCount++;
    return current;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeConditionsRepository implements CharacterConditionsRepository {
  _FakeConditionsRepository(this.characters);

  final _FakeCharacterRepository characters;
  final List<(String, List<ConditionType>)> calls = [];
  WriteOutcome outcome = WriteOutcome.synced;
  Object? error;
  Completer<void>? gate;
  List<String> lastUnknownKeys = const [];

  @override
  Future<WriteOutcome> setConditions({
    required String characterId,
    required List<ConditionType> conditions,
    List<String> unknownKeys = const [],
  }) async {
    calls.add((characterId, conditions));
    lastUnknownKeys = unknownKeys;
    await gate?.future;
    final failure = error;
    if (failure != null) throw failure;
    if (outcome == WriteOutcome.synced) {
      // Simule le serveur : la fiche relue porte désormais les conditions.
      characters.current = characters.current.copyWith(conditions: conditions);
    }
    return outcome;
  }
}

CharacterDetail _fighter({
  List<ConditionType> conditions = const [],
  List<String> unknownConditionKeys = const [],
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
  conditions: conditions,
  unknownConditionKeys: unknownConditionKeys,
);

Future<(_FakeCharacterRepository, _FakeConditionsRepository)> _pump(
  WidgetTester tester, {
  List<ConditionType> conditions = const [],
  List<String> unknownConditionKeys = const [],
  List<Override> extraOverrides = const [],
  CharacterConditionsRepository? conditionsRepositoryOverride,
}) async {
  final characters = _FakeCharacterRepository(
    _fighter(
      conditions: conditions,
      unknownConditionKeys: unknownConditionKeys,
    ),
  );
  final conditionsRepository = _FakeConditionsRepository(characters);
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        characterRepositoryProvider.overrideWithValue(characters),
        characterConditionsRepositoryProvider.overrideWithValue(
          conditionsRepositoryOverride ?? conditionsRepository,
        ),
        ...extraOverrides,
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
  return (characters, conditionsRepository);
}

Future<void> _openSelector(WidgetTester tester) async {
  await tester.tap(find.text('État'));
  await tester.pumpAndSettle();
}

Future<void> _check(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pump();
}

void main() {
  testWidgets('clé inconnue lue avec la fiche : transmise à écriture', (
    tester,
  ) async {
    final (_, repo) = await _pump(
      tester,
      conditions: const [ConditionType.blinded],
      unknownConditionKeys: const ['futur_etat'],
    );

    await tester.tap(find.byIcon(Icons.edit_outlined).last);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Aveuglé'),
      ),
    ); // désélection effective
    await tester.pump();
    await tester.tap(find.text('ENREGISTRER'));
    await tester.pumpAndSettle();

    expect(repo.calls.single.$2, isEmpty);
    expect(repo.lastUnknownKeys, ['futur_etat']);
  });

  testWidgets('accessDenied : message localisé au singulier', (tester) async {
    final (_, repo) = await _pump(tester);
    repo.error = const CharacterFailure(
      'x',
      code: CharacterErrorCode.accessDenied,
    );

    await _openSelector(tester);
    await _check(tester, 'Charmé');
    await tester.tap(find.text('ENREGISTRER'));
    await tester.pumpAndSettle();

    expect(find.text("Vous n'avez pas accès à ce personnage."), findsOneWidget);
  });

  testWidgets('sans condition : « + État », le sélecteur s\'ouvre', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byType(ConditionChip), findsNothing);

    await _openSelector(tester);

    expect(find.text('ÉTATS'), findsOneWidget);
  });

  testWidgets('enregistrer : écriture (remplacement complet), fiche relue, '
      'pastille affichée, feuille fermée', (tester) async {
    final (characters, repo) = await _pump(tester);
    final fetchesBefore = characters.fetchCount;

    await _openSelector(tester);
    await _check(tester, 'Charmé');
    await tester.tap(find.text('ENREGISTRER'));
    await tester.pumpAndSettle();

    expect(repo.calls, hasLength(1));
    expect(repo.calls.single.$1, '1');
    expect(repo.calls.single.$2, [ConditionType.charmed]);
    expect(characters.fetchCount, greaterThan(fetchesBefore));
    expect(find.text('ÉTATS'), findsNothing);
    expect(find.byType(ConditionChip), findsOneWidget);
    expect(find.text('Charmé'), findsOneWidget);
  });

  testWidgets('modifier des conditions existantes : le sélecteur est '
      'pré-coché, tout décocher écrit un tableau vide', (tester) async {
    final (_, repo) = await _pump(
      tester,
      conditions: const [ConditionType.blinded],
    );
    expect(find.text('Aveuglé'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit_outlined).last);
    await tester.pumpAndSettle();
    final checked = tester
        .widgetList<SelectionCheckbox>(find.byType(SelectionCheckbox))
        .where((c) => c.checked);
    expect(checked.length, 1);

    await tester.tap(find.text('Tout décocher'));
    await tester.pump();
    await tester.tap(find.text('ENREGISTRER'));
    await tester.pumpAndSettle();

    expect(repo.calls.single.$2, isEmpty);
    expect(find.byType(ConditionChip), findsNothing);
    expect(find.text('État'), findsOneWidget);
  });

  testWidgets('affichage optimiste : la pastille apparaît sur la fiche '
      'pendant l\'écriture', (tester) async {
    final (_, repo) = await _pump(tester);
    repo.gate = Completer<void>();

    await _openSelector(tester);
    await _check(tester, 'Charmé');
    await tester.tap(find.text('ENREGISTRER'));
    await tester.pump();

    // Écriture en vol : la fiche (derrière la feuille) montre déjà l'état.
    expect(find.byType(ConditionChip), findsOneWidget);
    expect(find.text('ÉTATS'), findsOneWidget);

    repo.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('ÉTATS'), findsNothing);
    expect(find.byType(ConditionChip), findsOneWidget);
  });

  testWidgets('erreur d\'écriture : retour arrière sur la fiche, message dans '
      'la feuille, sélection conservée', (tester) async {
    final (_, repo) = await _pump(tester);
    repo.error = const CharacterFailure('Boom serveur.');

    await _openSelector(tester);
    await _check(tester, 'Charmé');
    await tester.tap(find.text('ENREGISTRER'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertBanner), findsOneWidget);
    expect(find.text('Boom serveur.'), findsOneWidget);
    expect(find.text('ÉTATS'), findsOneWidget);
    // Retour arrière : aucune pastille sur la fiche.
    expect(find.byType(ConditionChip), findsNothing);
    // Sélection conservée dans la feuille.
    expect(
      tester
          .widgetList<SelectionCheckbox>(find.byType(SelectionCheckbox))
          .where((c) => c.checked)
          .length,
      1,
    );

    // Un nouvel essai réussi enregistre la sélection conservée.
    repo.error = null;
    await tester.tap(find.text('ENREGISTRER'));
    await tester.pumpAndSettle();
    expect(repo.calls.last.$2, [ConditionType.charmed]);
    expect(find.text('ÉTATS'), findsNothing);
    expect(find.byType(ConditionChip), findsOneWidget);
  });

  testWidgets('hors-ligne (mise en file) : feuille fermée comme un succès, '
      'pastille affichée, message « sera synchronisé », pas d\'erreur', (
    tester,
  ) async {
    final (characters, repo) = await _pump(tester);
    repo.outcome = WriteOutcome.queued;

    await _openSelector(tester);
    await _check(tester, 'Charmé');
    await tester.tap(find.text('ENREGISTRER'));
    await tester.pumpAndSettle();

    expect(
      find.text('Hors ligne : sera synchronisé dès que la connexion revient.'),
      findsOneWidget,
    );
    expect(find.textContaining("n'a pas pu être enregistrée"), findsNothing);
    expect(find.text('ÉTATS'), findsNothing, reason: 'feuille fermée');
    expect(find.byType(ConditionChip), findsOneWidget);
    expect(repo.calls.single.$2, [ConditionType.charmed]);
    expect(characters.current.conditions, isEmpty, reason: 'rien côté serveur');
  });

  testWidgets('hors-ligne, pile réelle (file drift + dépôt + synchroniseur) : '
      'pastilles à jour, bandeau « 1 modification en attente », puis retour '
      'réseau -> synchro', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final connectivity = FakeConnectivityChecker();
    final queue = PendingCharacterWriteQueue(db);
    final cache = ReferenceDataCache(db);
    final server = FakeCharacterWriteServer(
      characterRow: {
        'id': '1',
        'owner_id': 'owner-1',
        'conditions': <String>[],
      },
    );
    late SupabaseClient client;
    await tester.runAsync(() async {
      client = await buildSignedInClient(server, ownerId: 'owner-1');
    });
    final realRepository = SupabaseCharacterConditionsRepository(
      client,
      connectivity,
      queue,
      cache,
    );
    final syncer = PendingCharacterWriteSyncer(
      client,
      queue,
      cache,
      SupabaseCharacterRepository(client, cache, queue, connectivity),
    );
    addTearDown(() async {
      await connectivity.close();
      await db.close();
    });

    await _pump(
      tester,
      conditionsRepositoryOverride: realRepository,
      extraOverrides: [
        appDatabaseProvider.overrideWithValue(db),
        syncOwnerIdProvider.overrideWithValue('owner-1'),
        connectivityCheckerProvider.overrideWithValue(connectivity),
      ],
    );

    connectivity.goOffline();
    await tester.pump();
    await _openSelector(tester);
    await _check(tester, 'Charmé');
    await tester.tap(find.text('ENREGISTRER'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('ÉTATS'), findsNothing, reason: 'feuille fermée');
    expect(find.byType(ConditionChip), findsOneWidget);
    expect(find.textContaining("n'a pas pu être enregistrée"), findsNothing);
    expect(find.text('Hors ligne · 1 modification en attente'), findsOneWidget);
    expect(server.requests.where((r) => r.isWrite), isEmpty);

    connectivity.goOnline();
    await tester.runAsync(() async {
      expect(await syncer.sync(), {'1'});
    });
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));

    expect(server.characterRow['conditions'], ['charmed']);
    expect(find.textContaining('modification en attente'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(seconds: 10));
  });
}
