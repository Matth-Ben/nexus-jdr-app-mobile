// D193 : remplacements locaux optimistes de la fiche (PV, XP, sort inné,
// aptitude de classe, emplacement de sort). Après l'abandon d'une écriture
// mise en file (refus serveur non rejouable répété, D34), la fiche relue porte
// la valeur serveur : l'écran doit l'afficher, pas la valeur abandonnée.
//
// Écran réel + dépôt d'écriture réel (file drift, faux serveur PostgREST) ;
// seule la relecture de la fiche est un double qui rejoue la superposition de
// la file (celle du vrai dépôt est couverte côté `data/`). L'invalidation de
// la fiche après un abandon ou une synchro (faite en production par
// `CharacterWriteSyncCoordinator`) est reproduite par le test.

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
import 'package:personnages/core/rules/spell_status.dart';
import 'package:personnages/core/sync/sync_status_providers.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/data/pending_character_write_syncer.dart';
import 'package:personnages/features/characters/domain/character_class_feature.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/character_spell_slot.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/character_detail_screen.dart';
import 'package:personnages/features/characters/presentation/providers/character_detail_provider.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../support/fake_character_write_server.dart';
import '../../../support/fake_connectivity_checker.dart';

const _ownerId = 'owner-1';
const _innateSpellId = 10;
const _featureId = 7;
const _slotsLabel1 = 'Niveau 1 : 3 sur 3 emplacements disponibles';
const _slotsLabel1Spent = 'Niveau 1 : 2 sur 3 emplacements disponibles';

/// Écritures déléguées au vrai dépôt ; relecture = état du faux serveur +
/// écritures en file (même règle que `_withPendingWrites`).
class _ScreenRepository implements CharacterRepository {
  _ScreenRepository(this.real, this.queue, this.server);

  final SupabaseCharacterRepository real;
  final PendingCharacterWriteQueue queue;
  final FakeCharacterWriteServer server;

  @override
  Future<List<CharacterSummary>> fetchCharacters() async => const [];

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) async {
    final spellRow = server.tables['character_spells']!.single;
    final slotRow = server.tables['character_spell_slots']!.single;
    final featureRows = server.tables['character_feature_uses']!;
    var detail = CharacterDetail(
      id: '1',
      name: 'Sylas',
      classes: const [
        CharacterDetailClassRow(
          classId: 1,
          className: 'Magicien',
          level: 3,
          isPrimary: true,
          savingThrowProficiencies: [],
          hitDie: 6,
        ),
      ],
      xp: (server.characterRow['xp'] as num).toInt(),
      currentHp: (server.characterRow['current_hp'] as num).toInt(),
      maxHp: 30,
      temporaryHp: 0,
      abilityScores: const {},
      spells: [
        CharacterSpellEntry(
          id: _innateSpellId,
          name: 'Ténèbres',
          level: 2,
          school: 'Évocation',
          status: SpellStatus.innate,
          innateUsesSpent: (spellRow['innate_uses_spent'] as num).toInt(),
        ),
        const CharacterSpellEntry(
          id: 1,
          name: 'Bouclier',
          level: 1,
          school: 'Abjuration',
          status: SpellStatus.prepared,
        ),
      ],
      spellSlots: [
        CharacterSpellSlot(
          level: 1,
          total: 3,
          used: (slotRow['slots_used'] as num).toInt(),
        ),
      ],
      classFeatures: [
        CharacterClassFeature(
          id: _featureId,
          name: 'Rage',
          level: 1,
          usesMax: 2,
          usesRemaining: featureRows.isEmpty
              ? 2
              : (featureRows.last['uses_remaining'] as num).toInt(),
          restType: 'repos_court',
        ),
      ],
    );
    final pending = await queue.forCharacter(
      ownerId: _ownerId,
      characterId: characterId,
    );
    for (final write in pending) {
      switch (write.kind) {
        case PendingCharacterWriteKind.hp:
          detail = detail.copyWith(
            currentHp: (write.payload['currentHp'] as num).toInt(),
          );
        case PendingCharacterWriteKind.xp:
          detail = detail.copyWith(xp: (write.payload['newXp'] as num).toInt());
        case PendingCharacterWriteKind.innateSpell:
          detail = detail.copyWith(
            spells: [
              for (final spell in detail.spells)
                if (spell.id == _innateSpellId)
                  spell.copyWithInnateUsesSpent(
                    (write.payload['usesSpent'] as num).toInt(),
                  )
                else
                  spell,
            ],
          );
        case PendingCharacterWriteKind.classFeature:
          final feature = detail.classFeatures.single;
          detail = detail.copyWith(
            classFeatures: [
              CharacterClassFeature(
                id: feature.id,
                name: feature.name,
                level: feature.level,
                usesMax: feature.usesMax,
                usesRemaining: (write.payload['usesRemaining'] as num).toInt(),
                restType: feature.restType,
              ),
            ],
          );
        case PendingCharacterWriteKind.spellSlot:
          detail = detail.copyWith(
            spellSlots: [
              CharacterSpellSlot(
                level: 1,
                total: 3,
                used: (write.payload['slotsUsed'] as num).toInt(),
              ),
            ],
          );
        default:
          break;
      }
    }
    return detail;
  }

  @override
  Future<WriteOutcome> updateHp({
    required String characterId,
    required int currentHp,
    required int temporaryHp,
  }) => real.updateHp(
    characterId: characterId,
    currentHp: currentHp,
    temporaryHp: temporaryHp,
  );

  @override
  Future<WriteOutcome> addXp({
    required String characterId,
    required int newXp,
  }) => real.addXp(characterId: characterId, newXp: newXp);

  @override
  Future<WriteOutcome> setInnateSpellUsesSpent({
    required String characterId,
    required int spellId,
    required int usesSpent,
  }) => real.setInnateSpellUsesSpent(
    characterId: characterId,
    spellId: spellId,
    usesSpent: usesSpent,
  );

  @override
  Future<WriteOutcome> useClassFeature({
    required String characterId,
    required int classFeatureId,
    required int usesRemaining,
  }) => real.useClassFeature(
    characterId: characterId,
    classFeatureId: classFeatureId,
    usesRemaining: usesRemaining,
  );

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
    db = AppDatabase(NativeDatabase.memory());
    connectivity = FakeConnectivityChecker();
    queue = PendingCharacterWriteQueue(db);
    final cache = ReferenceDataCache(db);
    server = FakeCharacterWriteServer(
      characterRow: {
        'id': '1',
        'owner_id': _ownerId,
        'name': 'Sylas',
        'xp': 100,
        'current_hp': 18,
        'max_hp': 30,
        'temporary_hp': 0,
      },
    );
    server.tables['character_spells'] = [
      {
        'id': 'cs-1',
        'character_id': '1',
        'spell_id': _innateSpellId,
        'status': 'inné',
        'innate_uses_spent': 0,
      },
    ];
    server.tables['character_spell_slots'] = [
      {'id': 'ss-1', 'character_id': '1', 'slot_level': 1, 'slots_used': 0},
    ];
    server.tables['character_feature_uses'] = [];
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
            _ScreenRepository(real, queue, server),
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

  /// Comme `CharacterWriteSyncCoordinator` : relit la fiche affichée.
  Future<void> invalidateDetail(WidgetTester tester) async {
    ProviderScope.containerOf(
      tester.element(find.byType(CharacterDetailScreen)),
    ).invalidate(characterDetailProvider('1'));
    await tester.pump();
    await tester.pumpAndSettle();
  }

  /// Exécute [action] dans la zone du test en pompant jusqu'à sa fin (au plus
  /// 200 tours) : les requêtes de flux drift du bandeau, lancées dans cette
  /// zone, ne se terminent qu'à un pump ; bloquer en `runAsync` les ferait
  /// s'attendre l'une l'autre (voir `character_detail_catalog_offline_test`).
  Future<T> inZone<T>(WidgetTester tester, Future<T> Function() action) async {
    T? result;
    var finished = false;
    final running = action().then((value) {
      result = value;
      finished = true;
    });
    for (var i = 0; i < 200 && !finished; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 500));
    }
    await running;
    return result as T;
  }

  Future<void> abandonUntilDropped(WidgetTester tester) => inZone(
    tester,
    () async {
      for (
        var i = 0;
        i < PendingCharacterWriteQueue.abandonAfterConsecutiveFailures;
        i++
      ) {
        await syncer.syncWithReport();
      }
      expect(await queue.allForOwner(_ownerId), isEmpty, reason: 'abandonnée');
    },
  );

  /// Retour du réseau, refus 42501 répété jusqu'à l'abandon, puis relecture
  /// de la fiche (invalidation faite par le coordinateur en production).
  Future<void> abandonAll(WidgetTester tester) async {
    connectivity.goOnline();
    server.rejectWith('42501');
    await abandonUntilDropped(tester);
    server.clearRejection();
    await invalidateDetail(tester);
  }

  /// Retour du réseau puis synchro réussie de toute la file.
  Future<void> syncAll(WidgetTester tester) async {
    connectivity.goOnline();
    await inZone(tester, () async {
      expect(await syncer.sync(), {'1'});
      expect(await queue.allForOwner(_ownerId), isEmpty);
    });
    await invalidateDetail(tester);
  }

  Future<void> drain(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(seconds: 10));
  }

  Future<void> healOneHp(WidgetTester tester) async {
    await tester.tap(find.text('POINTS DE VIE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SOINS'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Augmenter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SOIGNER'));
    await tester.pumpAndSettle();
  }

  Future<void> addXp(WidgetTester tester, String amount) async {
    await tester.tap(find.widgetWithText(PrimaryButton, '+ XP'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), amount);
    await tester.pumpAndSettle();
    await tester.tap(find.text('AJOUTER'));
    await tester.pumpAndSettle();
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  Future<void> castInnate(WidgetTester tester) async {
    await tester.tap(find.text('Ténèbres'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PrimaryButton, 'LANCER'));
    await tester.pumpAndSettle();
    final confirm = find.widgetWithText(PrimaryButton, 'LANCER');
    if (tester.any(confirm)) {
      await tester.tap(confirm);
      await tester.pumpAndSettle();
    }
  }

  Future<void> castShield(WidgetTester tester) async {
    await tester.tap(find.text('Bouclier'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PrimaryButton, 'LANCER'));
    await tester.pumpAndSettle();
  }

  Future<void> useRage(WidgetTester tester) async {
    await tester.tap(find.text('Rage'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('UTILISER'));
    await tester.pumpAndSettle();
  }

  /// Libellé d'usage de « Rage » dans la carte d'aptitudes (texte voisin du
  /// nom, dans la même ligne).
  String featureLabel(WidgetTester tester) {
    final row = find
        .ancestor(of: find.text('Rage'), matching: find.byType(Row))
        .first;
    return tester
        .widgetList<Text>(find.descendant(of: row, matching: find.byType(Text)))
        .map((t) => t.data)
        .whereType<String>()
        .join('|');
  }

  group('PV', () {
    testWidgets('hors ligne : la valeur en file reste affichée', (
      tester,
    ) async {
      await pump(tester);
      connectivity.goOffline();
      await healOneHp(tester);
      expect(find.text('19 / 30'), findsOneWidget);

      await invalidateDetail(tester);

      expect(find.text('19 / 30'), findsOneWidget);
      expect(find.text('18 / 30'), findsNothing);
      await drain(tester);
    });

    testWidgets('abandon (42501 x5) : la fiche affiche la valeur serveur', (
      tester,
    ) async {
      await pump(tester);
      connectivity.goOffline();
      await healOneHp(tester);
      expect(find.text('19 / 30'), findsOneWidget);

      await abandonAll(tester);

      expect(find.text('18 / 30'), findsOneWidget);
      expect(find.text('19 / 30'), findsNothing);
      await drain(tester);
    });

    testWidgets('retour réseau + synchro réussie : valeur confirmée, sans '
        'retour en arrière', (tester) async {
      await pump(tester);
      connectivity.goOffline();
      await healOneHp(tester);

      await syncAll(tester);

      expect(server.characterRow['current_hp'], 19);
      expect(find.text('19 / 30'), findsOneWidget);
      expect(find.text('18 / 30'), findsNothing);
      await drain(tester);
    });

    testWidgets('relecture après synchro : pas de retour bref à la précédente '
        'valeur pendant le chargement', (tester) async {
      await pump(tester);
      connectivity.goOffline();
      await healOneHp(tester);
      connectivity.goOnline();
      await inZone(tester, () async {
        expect(await syncer.sync(), {'1'});
      });

      // La fiche affichée date d'avant l'écriture (18) ; la relecture la
      // rejoue pendant le chargement : la valeur confirmée ne doit pas
      // être remplacée par elle.
      ProviderScope.containerOf(
        tester.element(find.byType(CharacterDetailScreen)),
      ).invalidate(characterDetailProvider('1'));
      await tester.pump();
      expect(find.text('19 / 30'), findsOneWidget);
      expect(find.text('18 / 30'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('19 / 30'), findsOneWidget);
      await drain(tester);
    });

    testWidgets('deux ajustements hors ligne cumulés, puis abandon : valeur '
        'serveur', (tester) async {
      await pump(tester);
      connectivity.goOffline();
      await healOneHp(tester);
      await healOneHp(tester);
      expect(find.text('20 / 30'), findsOneWidget);

      await abandonAll(tester);

      expect(find.text('18 / 30'), findsOneWidget);
      await drain(tester);
    });
  });

  group('XP', () {
    testWidgets('hors ligne : la valeur en file reste affichée', (
      tester,
    ) async {
      await pump(tester);
      connectivity.goOffline();
      await addXp(tester, '50');
      expect(find.textContaining('150 /'), findsOneWidget);

      await invalidateDetail(tester);

      expect(find.textContaining('150 /'), findsOneWidget);
      await drain(tester);
    });

    testWidgets('abandon (42501 x5) : la fiche affiche la valeur serveur', (
      tester,
    ) async {
      await pump(tester);
      connectivity.goOffline();
      await addXp(tester, '50');
      expect(find.textContaining('150 /'), findsOneWidget);

      await abandonAll(tester);

      expect(find.textContaining('100 /'), findsOneWidget);
      expect(find.textContaining('150 /'), findsNothing);
      await drain(tester);
    });

    testWidgets('synchro réussie : valeur confirmée conservée', (tester) async {
      await pump(tester);
      connectivity.goOffline();
      await addXp(tester, '50');

      await syncAll(tester);

      expect(server.characterRow['xp'], 150);
      expect(find.textContaining('150 /'), findsOneWidget);
      await drain(tester);
    });
  });

  group('sort inné', () {
    testWidgets('hors ligne : « Épuisé » reste affiché', (tester) async {
      await pump(tester);
      connectivity.goOffline();
      await openTab(tester, 'SORTS');
      await castInnate(tester);
      expect(find.text('Épuisé'), findsOneWidget);

      await invalidateDetail(tester);

      expect(find.text('Épuisé'), findsOneWidget);
      await drain(tester);
    });

    testWidgets('abandon (zéro ligne, x5) : le sort redevient disponible', (
      tester,
    ) async {
      await pump(tester);
      connectivity.goOffline();
      await openTab(tester, 'SORTS');
      await castInnate(tester);
      expect(find.text('Épuisé'), findsOneWidget);

      // Zéro ligne affectée : le filtre `status` ne correspond plus.
      server.tables['character_spells']!.single['status'] = 'autre';
      connectivity.goOnline();
      await abandonUntilDropped(tester);
      server.tables['character_spells']!.single['status'] = 'inné';
      await invalidateDetail(tester);

      expect(find.text('Épuisé'), findsNothing);
      await drain(tester);
    });

    testWidgets('abandon (42501 x5) : le sort redevient disponible', (
      tester,
    ) async {
      await pump(tester);
      connectivity.goOffline();
      await openTab(tester, 'SORTS');
      await castInnate(tester);
      expect(find.text('Épuisé'), findsOneWidget);

      await abandonAll(tester);

      expect(find.text('Épuisé'), findsNothing);
      await drain(tester);
    });

    testWidgets('synchro réussie : « Épuisé » conservé', (tester) async {
      await pump(tester);
      connectivity.goOffline();
      await openTab(tester, 'SORTS');
      await castInnate(tester);

      await syncAll(tester);

      expect(server.tables['character_spells']!.single['innate_uses_spent'], 1);
      expect(find.text('Épuisé'), findsOneWidget);
      await drain(tester);
    });
  });

  group('aptitude de classe', () {
    testWidgets('hors ligne : l\'usage en file reste affiché', (tester) async {
      await pump(tester);
      connectivity.goOffline();
      await openTab(tester, 'APT.');
      final initial = featureLabel(tester);
      await useRage(tester);
      final after = featureLabel(tester);
      expect(after, isNot(initial));

      await invalidateDetail(tester);

      expect(featureLabel(tester), after);
      await drain(tester);
    });

    testWidgets('abandon (42501 x5) : la fiche affiche la valeur serveur', (
      tester,
    ) async {
      await pump(tester);
      connectivity.goOffline();
      await openTab(tester, 'APT.');
      final initial = featureLabel(tester);
      await useRage(tester);
      expect(featureLabel(tester), isNot(initial));

      await abandonAll(tester);

      expect(featureLabel(tester), initial);
      await drain(tester);
    });

    testWidgets('synchro réussie : valeur confirmée conservée', (tester) async {
      await pump(tester);
      connectivity.goOffline();
      await openTab(tester, 'APT.');
      await useRage(tester);
      final after = featureLabel(tester);

      await syncAll(tester);

      expect(server.tables['character_feature_uses'], hasLength(1));
      expect(featureLabel(tester), after);
      await drain(tester);
    });
  });

  group('emplacements de sorts (déjà corrigés, non-régression)', () {
    testWidgets('hors ligne : emplacement consommé reste affiché', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pump(tester);
      connectivity.goOffline();
      await openTab(tester, 'SORTS');
      expect(find.bySemanticsLabel(_slotsLabel1), findsNWidgets(2));
      await castShield(tester);
      expect(find.bySemanticsLabel(_slotsLabel1Spent), findsNWidgets(2));

      await invalidateDetail(tester);

      expect(find.bySemanticsLabel(_slotsLabel1Spent), findsNWidgets(2));
      semantics.dispose();
      await drain(tester);
    });

    testWidgets('abandon : la fiche affiche la valeur serveur', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester);
      connectivity.goOffline();
      await openTab(tester, 'SORTS');
      await castShield(tester);
      expect(find.bySemanticsLabel(_slotsLabel1Spent), findsNWidgets(2));

      await abandonAll(tester);

      expect(find.bySemanticsLabel(_slotsLabel1), findsNWidgets(2));
      semantics.dispose();
      await drain(tester);
    });
  });
}
