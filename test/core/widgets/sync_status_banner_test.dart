// Tests de widget de `SyncStatusBanner` (T2 du chantier hors-ligne) : états,
// précédence côté rendu, alertes persistées, placement des compteurs
// (fiche = ce personnage, liste = total du compte), accessibilité et absence
// de débordement à 360 dp / police x2,0.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/sync_alert_store.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/core/sync/sync_activity_provider.dart';
import 'package:personnages/core/sync/sync_status_providers.dart';
import 'package:personnages/core/theme/app_typography.dart';
import 'package:personnages/core/widgets/alert_banner.dart';
import 'package:personnages/core/widgets/info_banner.dart';
import 'package:personnages/core/widgets/sync_status_banner.dart';
import 'package:personnages/core/cache/cache_providers.dart';
import 'package:personnages/l10n/app_localizations.dart';

import '../../support/fake_connectivity_checker.dart';

const _owner = 'owner-1';

void main() {
  late AppDatabase db;
  late FakeConnectivityChecker connectivity;
  late SyncAlertStore alerts;
  late PendingCharacterWriteQueue queue;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    connectivity = FakeConnectivityChecker();
    alerts = SyncAlertStore(db);
    queue = PendingCharacterWriteQueue(db);
  });

  tearDown(() async {
    await connectivity.close();
    await db.close();
  });

  List<Override> overrides() => [
    appDatabaseProvider.overrideWithValue(db),
    syncOwnerIdProvider.overrideWithValue(_owner),
    connectivityCheckerProvider.overrideWithValue(connectivity),
  ];

  Widget app({
    String? characterId,
    Locale locale = const Locale('fr'),
    List<Widget> below = const [],
  }) {
    return ProviderScope(
      overrides: overrides(),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                SyncStatusBanner(
                  characterId: characterId,
                  visiblePadding: EdgeInsets.zero,
                ),
                ...below,
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Laisse les opérations drift (vrai asynchrone) aboutir, puis rend la main
  /// au banc de test.
  Future<void> flushDb(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }

  Future<void> addAlert(
    WidgetTester tester, {
    String name = 'Aria',
    SyncAlertKind kind = SyncAlertKind.abandon,
    String dataKind = 'hp',
    Map<String, dynamic>? value = const {'currentHp': 7, 'maxHp': 12},
  }) async {
    await tester.runAsync(
      () => alerts.add(
        ownerId: _owner,
        kind: kind,
        characterId: 'c-$name',
        characterName: name,
        dataKind: dataKind,
        serverValue: value,
      ),
    );
    await flushDb(tester);
  }

  Future<void> enqueueHp(WidgetTester tester, String characterId) async {
    await tester.runAsync(
      () => queue.enqueue(
        characterId: characterId,
        ownerId: _owner,
        kind: PendingCharacterWriteKind.hp,
        targetId: '',
        payload: {'currentHp': 1, 'temporaryHp': 0},
      ),
    );
    await flushDb(tester);
  }

  /// Démonte l'arbre et laisse expirer les temporisateurs drift/engine.
  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(seconds: 10));
  }

  /// Écarte la plus ancienne alerte, comme le fait le panneau (suppression de
  /// la ligne d'alerte, rien d'autre) ; le bandeau, lui, n'a plus de ✕.
  Future<void> dismissOldest(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 300));
    final all = await tester.runAsync(() => alerts.allForOwner(_owner));
    await tester.runAsync(
      () => alerts.dismiss(ownerId: _owner, id: all!.first.id),
    );
    await flushDb(tester);
    await tester.pump(const Duration(milliseconds: 300));
  }

  Finder liveRegions() => find.byWidgetPredicate(
    (w) => w is Semantics && w.properties.liveRegion == true,
  );

  Future<void> goOffline(WidgetTester tester) async {
    connectivity.goOffline();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
  }

  group('règle 1 : silencieux en usage normal', () {
    testWidgets('fiche et liste : aucun bandeau si N = 0, en ligne, sans '
        'alerte', (tester) async {
      await tester.pumpWidget(app(characterId: 'c1'));
      await tester.pump(const Duration(seconds: 10));
      expect(find.byType(InfoBanner), findsNothing);
      expect(find.byType(AlertBanner), findsNothing);

      await tester.pumpWidget(app());
      await tester.pump(const Duration(seconds: 10));
      expect(find.byType(InfoBanner), findsNothing);
      expect(find.byType(AlertBanner), findsNothing);
      await finish(tester);
    });
  });

  group('alertes persistées (règles 2, 10, 11, 13) : bandeau de comptage', () {
    testWidgets('1 alerte : « 1 alerte de synchronisation » + « Voir les '
        'alertes », cible >= 44 dp, pas de ✕, pas de texte d\'alerte, jamais '
        'de police display', (tester) async {
      await tester.pumpWidget(app(characterId: 'c1'));
      await addAlert(tester);

      expect(find.byType(AlertBanner), findsOneWidget);
      expect(find.text('1 alerte de synchronisation'), findsOneWidget);
      expect(find.text('Voir les alertes'), findsOneWidget);
      // Plus de ✕ : seul le tap vers le panneau.
      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.byType(IconButton), findsNothing);
      expect(find.byTooltip('Fermer'), findsNothing);
      // Ni le message de l'alerte ni « (+N autres) » dans le bandeau.
      expect(find.textContaining('Aria'), findsNothing);
      expect(find.textContaining('(+'), findsNothing);

      final size = tester.getSize(find.byType(AlertBanner));
      expect(size.height, greaterThanOrEqualTo(44));
      expect(
        tester.getSize(find.byType(InkWell)).height,
        greaterThanOrEqualTo(44),
        reason: 'tout le bandeau est la zone de tap',
      );

      for (final text in tester.widgetList<Text>(
        find.descendant(
          of: find.byType(SyncStatusBanner),
          matching: find.byType(Text),
        ),
      )) {
        expect(
          text.style?.fontFamily,
          isNot(AppTypography.display(fontSize: 12).fontFamily),
          reason: 'jamais font.display dans le bandeau',
        );
      }
      await finish(tester);
    });

    testWidgets('N alertes : le libellé porte le TOTAL (pluriel) et suit '
        'les ajouts', (tester) async {
      await tester.pumpWidget(app());
      await addAlert(tester, name: 'Aria');
      await addAlert(tester, name: 'Borin');
      await addAlert(tester, name: 'Cyrus');
      expect(find.text('3 alertes de synchronisation'), findsOneWidget);
      expect(find.textContaining('Borin'), findsNothing);

      await addAlert(tester, name: 'Dora');
      expect(find.text('4 alertes de synchronisation'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('anglais : « 1 sync alert » / « 2 sync alerts » + « View '
        'alerts »', (tester) async {
      await tester.pumpWidget(app(locale: const Locale('en')));
      await addAlert(tester);
      expect(find.text('1 sync alert'), findsOneWidget);
      expect(find.text('View alerts'), findsOneWidget);
      expect(find.byTooltip('Dismiss'), findsNothing);
      await addAlert(tester, name: 'Borin');
      expect(find.text('2 sync alerts'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('un tap sur le bandeau ouvre le panneau des alertes', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await addAlert(tester);
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byType(AlertBanner));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await flushDb(tester);

      expect(find.text('ALERTES DE SYNCHRO'), findsOneWidget);
      expect(find.textContaining('PV de Aria'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('sémantique : un nœud bouton « {N} alertes de '
        'synchronisation. Ouvrir la liste. », texte visible exclu', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(app());
      await addAlert(tester);
      await addAlert(tester, name: 'Borin');
      await tester.pump(const Duration(milliseconds: 300));

      final node = find.bySemanticsLabel(
        '2 alertes de synchronisation. Ouvrir la liste.',
      );
      expect(node, findsOneWidget);
      expect(
        tester.getSemantics(node),
        isSemantics(
          label: '2 alertes de synchronisation. Ouvrir la liste.',
          isButton: true,
          hasTapAction: true,
        ),
      );
      // Le texte visible n'est pas lu en plus.
      expect(find.bySemanticsLabel('Voir les alertes'), findsNothing);
      await finish(tester);
      semantics.dispose();
    });

    testWidgets('région live : active à l\'APPARITION seulement, pas à chaque '
        'changement de N', (tester) async {
      await tester.pumpWidget(app());
      await addAlert(tester);
      expect(liveRegions(), findsOneWidget, reason: 'apparition');

      await tester.pump(const Duration(milliseconds: 300));
      expect(liveRegions(), findsNothing, reason: 'retirée après l\'annonce');

      await addAlert(tester, name: 'Borin');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('2 alertes de synchronisation'), findsOneWidget);
      expect(liveRegions(), findsNothing, reason: 'N change : pas d\'annonce');
      await finish(tester);
    });

    testWidgets('région live : de nouveau active quand le bandeau réapparaît '
        'après avoir disparu', (tester) async {
      await tester.pumpWidget(app());
      await addAlert(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(liveRegions(), findsNothing);

      await dismissOldest(tester);
      expect(find.byType(AlertBanner), findsNothing);

      await addAlert(tester, name: 'Borin');
      expect(liveRegions(), findsOneWidget);
      await finish(tester);
    });

    testWidgets('écarter les alertes (depuis le panneau, ici directement en '
        'base) fait suivre le total puis disparaître le bandeau', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await addAlert(tester, name: 'Aria');
      await addAlert(tester, name: 'Borin');
      await addAlert(tester, name: 'Cyrus');
      expect(find.text('3 alertes de synchronisation'), findsOneWidget);

      await dismissOldest(tester);
      expect(find.text('2 alertes de synchronisation'), findsOneWidget);
      await dismissOldest(tester);
      expect(find.text('1 alerte de synchronisation'), findsOneWidget);
      await dismissOldest(tester);
      expect(find.byType(AlertBanner), findsNothing);
      expect(await tester.runAsync(() => alerts.allForOwner(_owner)), isEmpty);
      await finish(tester);
    });

    testWidgets('persiste à travers un changement d\'écran (arbre reconstruit '
        'sur la même base) et reste visible fiche ET liste', (tester) async {
      await tester.pumpWidget(app(characterId: 'c1'));
      await addAlert(tester);
      expect(find.byType(AlertBanner), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app());
      await flushDb(tester);
      expect(find.byType(AlertBanner), findsOneWidget, reason: 'liste');

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app(characterId: 'autre'));
      await flushDb(tester);
      expect(find.byType(AlertBanner), findsOneWidget, reason: 'autre fiche');
      await finish(tester);
    });

    testWidgets(
      'filtre ownerId : l\'alerte d\'un autre compte n\'apparaît pas',
      (tester) async {
        await tester.runAsync(
          () => alerts.add(
            ownerId: 'owner-2',
            kind: SyncAlertKind.abandon,
            characterId: 'x',
            characterName: 'Intrus',
            dataKind: 'hp',
          ),
        );
        await tester.pumpWidget(app());
        await flushDb(tester);
        expect(find.byType(AlertBanner), findsNothing);
        await finish(tester);
      },
    );

    testWidgets('360 dp et police x2,0, FR puis EN : aucun débordement, tout '
        'le texte visible, cible >= 44 dp', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await tester.pumpWidget(app());
      await addAlert(tester, name: 'Halltesse Ambrelune de Vaucluse');
      await addAlert(tester, name: 'Autre', kind: SyncAlertKind.conflict);
      await addAlert(tester, name: 'Troisième');
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AlertBanner), findsOneWidget);
      expect(find.text('3 alertes de synchronisation'), findsOneWidget);
      expect(find.text('Voir les alertes'), findsOneWidget);
      expect(
        tester.getSize(find.byType(AlertBanner)).height,
        greaterThanOrEqualTo(44),
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app(locale: const Locale('en')));
      await flushDb(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('3 sync alerts'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await finish(tester);
    });

    testWidgets('alerte mise à jour sur place (même id) : le bandeau ne '
        'change pas et n\'est pas ré-annoncé', (tester) async {
      await tester.pumpWidget(app());
      await addAlert(
        tester,
        kind: SyncAlertKind.conflict,
        value: const {
          'currentHp': 12,
          'temporaryHp': 0,
          'maxHp': 30,
          'queued': {'currentHp': 5, 'temporaryHp': 0},
        },
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('1 alerte de synchronisation'), findsOneWidget);
      final id = (await tester.runAsync(() => alerts.allForOwner(_owner)))!
          .single
          .id;
      await tester.runAsync(
        () => alerts.updateValue(
          ownerId: _owner,
          id: id,
          characterName: 'Aria',
          serverValue: const {
            'currentHp': 12,
            'temporaryHp': 0,
            'maxHp': 30,
            'queued': {'currentHp': 8, 'temporaryHp': 0},
          },
        ),
      );
      await flushDb(tester);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('1 alerte de synchronisation'), findsOneWidget);
      expect(find.byType(AlertBanner), findsOneWidget);
      expect(liveRegions(), findsNothing);
      await finish(tester);
    });
  });

  group('états de connectivité et de file (règles 3, 5, 6, 7, 13)', () {
    testWidgets('fiche : hors ligne sans modification -> texte dédié après '
        '2 s, région live fixe ; la liste ne l\'affiche pas (décision a)', (
      tester,
    ) async {
      await tester.pumpWidget(app(characterId: 'c1'));
      await flushDb(tester);
      connectivity.goOffline();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.byType(InfoBanner), findsNothing);
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        find.text(
          'Hors ligne. Tes modifications seront envoyées au retour du '
          'réseau.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
      expect(liveRegions(), findsOneWidget);

      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(InfoBanner), findsNothing, reason: 'liste, N = 0');
      await finish(tester);
    });

    testWidgets('règle 7 : compteur par personnage sur la fiche, total du '
        'compte sur la liste ; pluriel ; pas de région live propre à N', (
      tester,
    ) async {
      await enqueueHp(tester, 'c1');
      await enqueueHp(tester, 'c2');

      await tester.pumpWidget(app(characterId: 'c1'));
      await flushDb(tester);
      await goOffline(tester);
      expect(
        find.text('Hors ligne · 1 modification en attente'),
        findsOneWidget,
      );

      await tester.pumpWidget(app());
      await flushDb(tester);
      await goOffline(tester);
      expect(
        find.text('Hors ligne · 2 modifications en attente'),
        findsOneWidget,
      );
      expect(liveRegions(), findsOneWidget, reason: 'libellé fixe, hors-ligne');

      await enqueueHp(tester, 'c3');
      expect(
        find.text('Hors ligne · 3 modifications en attente'),
        findsOneWidget,
        reason: 'N en direct',
      );
      await finish(tester);
    });

    testWidgets('anglais : pluriel ICU du hors-ligne', (tester) async {
      await enqueueHp(tester, 'c1');
      await tester.pumpWidget(app(locale: const Locale('en')));
      await flushDb(tester);
      await goOffline(tester);
      expect(find.text('Offline · 1 change pending'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('en ligne : « en attente d\'envoi » après 3 s, sans région '
        'live', (tester) async {
      await tester.pumpWidget(app());
      await enqueueHp(tester, 'c1');
      await tester.pump(const Duration(milliseconds: 2500));
      expect(find.byType(InfoBanner), findsNothing);
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('1 modification en attente d\'envoi'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
      expect(liveRegions(), findsNothing);
      await finish(tester);
    });

    testWidgets('« en cours » : pas avant 1 s, icône fixe, sans région live', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SyncStatusBanner)),
      );
      container.read(syncActivityProvider.notifier).begin();
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.byType(InfoBanner), findsNothing);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Synchronisation…'), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);
      expect(liveRegions(), findsNothing);

      container.read(syncActivityProvider.notifier).end();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(InfoBanner), findsNothing);
      await finish(tester);
    });

    testWidgets('retour du réseau après un hors-ligne : « Synchronisé » '
        '(Icons.check, région live) 2 s puis plus rien', (tester) async {
      await tester.pumpWidget(app(characterId: 'c1'));
      await flushDb(tester);
      await goOffline(tester);
      connectivity.goOnline();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Synchronisé'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(liveRegions(), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(InfoBanner), findsNothing);
      await finish(tester);
    });

    testWidgets('règle 3 : l\'alerte prime sur le hors-ligne', (tester) async {
      await tester.pumpWidget(app(characterId: 'c1'));
      await flushDb(tester);
      await goOffline(tester);
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);

      await addAlert(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(AlertBanner), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
      await finish(tester);
    });
  });
}
