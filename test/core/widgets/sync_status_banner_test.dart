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

  /// Ferme l'alerte affichée (laisse d'abord finir le fondu d'apparition).
  Future<void> dismissTop(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byIcon(Icons.close));
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

  group('alertes persistées (règles 2, 10, 11, 13)', () {
    testWidgets('abandon de PV : texte FR avec valeur serveur, bouton de '
        'fermeture >= 44 dp, région live, jamais de police display', (
      tester,
    ) async {
      await tester.pumpWidget(app(characterId: 'c1'));
      await addAlert(tester);

      expect(
        find.text(
          'Modification non enregistrée : la dernière valeur connue des PV de '
          'Aria est 7/12.',
        ),
        findsOneWidget,
      );
      expect(find.byType(AlertBanner), findsOneWidget);
      expect(liveRegions(), findsOneWidget);

      final close = find.byTooltip('Fermer');
      expect(close, findsOneWidget);
      final size = tester.getSize(close);
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));

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

    testWidgets('anglais : texte EN', (tester) async {
      await tester.pumpWidget(app(locale: const Locale('en')));
      await addAlert(tester);
      expect(
        find.text('Change not saved: the last known HP of Aria are 7/12.'),
        findsOneWidget,
      );
      expect(find.byTooltip('Dismiss'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('déclinaisons : emplacements, XP, repli, conflit', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await addAlert(
        tester,
        dataKind: 'spell_slot',
        value: const {'level': 3, 'remaining': 1, 'max': 3},
      );
      expect(
        find.text(
          'Modification non enregistrée : la dernière valeur connue des '
          'emplacements de niveau 3 de Aria est 1/3.',
        ),
        findsOneWidget,
      );
      await dismissTop(tester);
      await flushDb(tester);

      await addAlert(tester, dataKind: 'xp', value: const {'xp': 900});
      expect(
        find.text(
          "Modification non enregistrée : la dernière valeur connue de l'XP "
          'de Aria est 900.',
        ),
        findsOneWidget,
      );
      await dismissTop(tester);
      await flushDb(tester);

      await addAlert(tester, dataKind: 'class_feature', value: null);
      expect(
        find.text(
          "Une modification de Aria n'a pas pu être enregistrée. La fiche "
          'affiche la valeur du serveur.',
        ),
        findsOneWidget,
      );
      await dismissTop(tester);
      await flushDb(tester);

      await addAlert(tester, kind: SyncAlertKind.conflict);
      expect(
        find.text(
          'Aria a été modifié sur un autre appareil. Ta modification hors ligne '
          'a été appliquée par-dessus.',
        ),
        findsOneWidget,
      );
      await finish(tester);
    });

    testWidgets('une alerte à la fois : la plus ancienne, suffixe « (+N '
        'autres) », fermer affiche la suivante puis plus rien', (tester) async {
      await tester.pumpWidget(app());
      await addAlert(tester, name: 'Aria');
      await addAlert(tester, name: 'Borin');
      await addAlert(tester, name: 'Cyrus');

      expect(find.textContaining('Aria'), findsOneWidget);
      expect(find.textContaining('Borin'), findsNothing);
      expect(find.textContaining('(+2 autres)'), findsOneWidget);

      await dismissTop(tester);
      await flushDb(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Borin'), findsOneWidget);
      expect(find.textContaining('(+1 autre)'), findsOneWidget);

      await dismissTop(tester);
      await flushDb(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Cyrus'), findsOneWidget);
      expect(find.textContaining('(+'), findsNothing);

      await dismissTop(tester);
      await flushDb(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(AlertBanner), findsNothing);
      expect(await tester.runAsync(() => alerts.allForOwner(_owner)), isEmpty);
      await finish(tester);
    });

    testWidgets('la fermeture supprime la ligne en base (et rien d\'autre)', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await addAlert(tester, name: 'Aria');
      await addAlert(tester, name: 'Borin');
      await dismissTop(tester);
      await flushDb(tester);

      final left = await tester.runAsync(() => alerts.allForOwner(_owner));
      expect(left!.map((a) => a.characterName), ['Borin']);
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

    testWidgets('long texte à 360 dp et police x2,0 : aucun débordement', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await tester.pumpWidget(app());
      await addAlert(tester, name: 'Halltesse Ambrelune de Vaucluse');
      await addAlert(tester, name: 'Autre', kind: SyncAlertKind.conflict);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AlertBanner), findsOneWidget);
      expect(tester.takeException(), isNull);
      await finish(tester);
    });

    testWidgets('conflit T8 (objet) à 360 dp, police x2,0, EN : texte complet '
        'sans troncature, une seule région live, bouton >= 44 dp', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await tester.pumpWidget(app(locale: const Locale('en')));
      await addAlert(
        tester,
        kind: SyncAlertKind.conflict,
        dataKind: 'inventory_item',
        value: const {
          'items': [
            {'id': 'l1', 'name': 'Potion of healing', 'server': 5, 'queued': 4},
          ],
        },
      );
      await tester.pump(const Duration(milliseconds: 300));

      final message = find.text(
        'Aria: the quantity of “Potion of healing” was changed on another '
        'device (server: 5). Your offline change (4) replaced it.',
      );
      expect(message, findsOneWidget);
      expect(tester.widget<Text>(message).maxLines, isNull);
      expect(
        tester.widget<Text>(message).overflow,
        isNot(TextOverflow.ellipsis),
      );
      expect(liveRegions(), findsOneWidget);
      final size = tester.getSize(find.byTooltip('Dismiss'));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
      expect(tester.takeException(), isNull);
      await finish(tester);
    });

    testWidgets('mise à jour de l\'alerte (même id) : le texte change sans '
        'ré-annonce, fermer la supprime', (tester) async {
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
      expect(find.textContaining('(serveur : 12/30)'), findsOneWidget);
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
      expect(find.textContaining('hors ligne (8/30)'), findsOneWidget);
      expect(find.byType(AlertBanner), findsOneWidget);
      expect(liveRegions(), findsOneWidget);
      await dismissTop(tester);
      expect(find.byType(AlertBanner), findsNothing);
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
