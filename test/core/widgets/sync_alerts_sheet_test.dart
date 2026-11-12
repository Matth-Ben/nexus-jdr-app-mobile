// Tests du panneau des alertes de synchronisation (`showSyncAlertsSheet`,
// fiche A du 12/11/2026) : vide / 1 / N alertes (FR et EN), tri, orphelines,
// « Écarter » et « Tout écarter » annulables (id et date d'origine restaurés),
// sémantique, cibles >= 44 dp, x2,0 / x3,0 sur 320x568, hors ligne.
//
// Polices réelles : la police de test (un em par glyphe) fausserait la
// vérification « aucun mot coupé lettre par lettre ».

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/cache_providers.dart';
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/sync_alert_store.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/core/sync/sync_clock_provider.dart';
import 'package:personnages/core/sync/sync_status_providers.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/widgets/sync_alerts_sheet.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_connectivity_checker.dart';

const _owner = 'owner-1';
final _now = DateTime(2026, 11, 12, 12);

Future<void> _loadFont(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
  await loader.load();
}

CharacterSummary _character(String id) => CharacterSummary(
  id: id,
  name: 'Perso $id',
  raceName: 'Elfe',
  className: 'Magicienne',
  level: 3,
  xp: 1200,
);

void main() {
  late AppDatabase db;
  late FakeConnectivityChecker connectivity;
  late DateTime clock;
  late SyncAlertStore store;

  setUpAll(() async {
    await _loadFont('WorkSans', 'assets/fonts/WorkSans-VariableFont_wght.ttf');
    await _loadFont('PressStart2P', 'assets/fonts/PressStart2P-Regular.ttf');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    connectivity = FakeConnectivityChecker();
    clock = _now.subtract(const Duration(minutes: 5));
    store = SyncAlertStore(db, now: () => clock);
  });

  tearDown(() async {
    await connectivity.close();
    await db.close();
  });

  void surface(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget app({
    Locale locale = const Locale('fr'),
    double scale = 1,
    List<Override> extra = const [],
    bool watchCharacters = false,
  }) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        syncOwnerIdProvider.overrideWithValue(_owner),
        connectivityCheckerProvider.overrideWithValue(connectivity),
        syncClockProvider.overrideWithValue(() => _now),
        ...extra,
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              // Simule l'écran liste, vivant sous la feuille.
              if (watchCharacters) ref.watch(charactersProvider);
              return Center(
                child: ElevatedButton(
                  onPressed: () => unawaited(showSyncAlertsSheet(context)),
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> flushDb(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }

  Future<void> add(
    WidgetTester tester, {
    String name = 'Aria',
    String characterId = 'c1',
    SyncAlertKind kind = SyncAlertKind.abandon,
    String dataKind = 'hp',
    Map<String, dynamic>? value = const {'currentHp': 7, 'maxHp': 12},
    DateTime? createdAt,
    String owner = _owner,
  }) async {
    clock = createdAt ?? clock;
    await tester.runAsync(
      () => store.add(
        ownerId: owner,
        kind: kind,
        characterId: characterId,
        characterName: name,
        dataKind: dataKind,
        serverValue: value,
      ),
    );
  }

  Future<List<SyncAlert>> inDb(WidgetTester tester) async =>
      (await tester.runAsync(() => store.allForOwner(_owner)))!;

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await flushDb(tester);
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> pumpApp(
    WidgetTester tester, {
    Locale locale = const Locale('fr'),
    double scale = 1,
    List<Override> extra = const [],
    bool watchCharacters = false,
    Size size = const Size(360, 800),
  }) async {
    surface(tester, size);
    await tester.pumpWidget(
      app(
        locale: locale,
        scale: scale,
        extra: extra,
        watchCharacters: watchCharacters,
      ),
    );
    await flushDb(tester);
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(seconds: 10));
  }

  Finder dismissButtons() => find.byWidgetPredicate(
    (w) =>
        w is Semantics &&
        w.properties.button == true &&
        (w.properties.label ?? '').startsWith('Écarter l'),
  );

  Finder liveRegions() => find.byWidgetPredicate(
    (w) => w is Semantics && w.properties.liveRegion == true,
  );

  double top(WidgetTester tester, String text) =>
      tester.getTopLeft(find.textContaining(text)).dy;

  group('contenu', () {
    testWidgets('vide : message, icône décorative teal, région live, ni '
        '« Tout écarter » ni carte', (tester) async {
      await pumpApp(tester);
      await open(tester);

      expect(find.text('ALERTES DE SYNCHRO'), findsOneWidget);
      expect(find.text('Aucune alerte de synchronisation.'), findsOneWidget);
      expect(
        find.text(
          'Les conflits et les modifications non envoyées apparaîtront ici.',
        ),
        findsOneWidget,
      );
      final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle_outline));
      expect(icon.size, 32);
      expect(icon.color, AppColors.accentTeal);
      expect(
        find.ancestor(
          of: find.byIcon(Icons.check_circle_outline),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
      expect(liveRegions(), findsOneWidget);
      expect(find.text('TOUT ÉCARTER'), findsNothing);
      expect(dismissButtons(), findsNothing);
      await finish(tester);
    });

    testWidgets('vide, anglais', (tester) async {
      await pumpApp(tester, locale: const Locale('en'));
      await open(tester);
      expect(find.text('SYNC ALERTS'), findsOneWidget);
      expect(find.text('No sync alerts.'), findsOneWidget);
      expect(
        find.text('Conflicts and unsent changes will appear here.'),
        findsOneWidget,
      );
      await finish(tester);
    });

    testWidgets('1 alerte (abandon) : introduction, type, date relative, '
        'message complet, « Écarter », pas de « Tout écarter »', (
      tester,
    ) async {
      await add(tester);
      await pumpApp(tester);
      await open(tester);

      expect(
        find.text(
          'Ces messages signalent des modifications faites hors ligne qui ont '
          'été écrasées ou abandonnées.',
        ),
        findsOneWidget,
      );
      expect(find.text('Modification non envoyée'), findsOneWidget);
      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
      expect(find.text('il y a 5 min'), findsOneWidget);
      expect(
        find.text(
          'Modification non enregistrée : la dernière valeur connue des PV de '
          'Aria est 7/12.',
        ),
        findsOneWidget,
      );
      expect(find.text('Écarter'), findsOneWidget);
      expect(find.text('TOUT ÉCARTER'), findsNothing);
      await finish(tester);
    });

    testWidgets('conflit : type, icône et date « depuis … »', (tester) async {
      await add(
        tester,
        kind: SyncAlertKind.conflict,
        createdAt: _now.subtract(const Duration(hours: 2)),
      );
      await pumpApp(tester);
      await open(tester);

      expect(find.text('Modification concurrente'), findsOneWidget);
      expect(find.byIcon(Icons.sync_problem), findsOneWidget);
      expect(find.text('depuis il y a 2 h'), findsOneWidget);
      expect(
        find.textContaining('Aria a été modifié sur un autre appareil'),
        findsOneWidget,
      );
      await finish(tester);
    });

    testWidgets('date absolue au-delà de 24 h, et « depuis » pour un conflit '
        'ancien', (tester) async {
      await add(
        tester,
        kind: SyncAlertKind.conflict,
        createdAt: DateTime(2026, 11, 2, 14, 32),
      );
      await pumpApp(tester);
      await open(tester);
      expect(find.textContaining('depuis 2 nov. 2026 à 14:32'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('N alertes en anglais : types, dates, « Dismiss all »', (
      tester,
    ) async {
      await add(tester, name: 'Aria');
      await add(
        tester,
        name: 'Borin',
        kind: SyncAlertKind.conflict,
        createdAt: _now.subtract(const Duration(hours: 3)),
      );
      await pumpApp(tester, locale: const Locale('en'));
      await open(tester);

      expect(find.text('SYNC ALERTS'), findsOneWidget);
      expect(find.text('DISMISS ALL'), findsOneWidget);
      expect(find.text('Dismiss'), findsNWidgets(2));
      expect(find.text('Change not sent'), findsOneWidget);
      expect(find.text('Concurrent change'), findsOneWidget);
      expect(find.text('5 min ago'), findsOneWidget);
      expect(find.text('since 3 h ago'), findsOneWidget);
      expect(
        find.textContaining('Change not saved: the last known HP of Aria'),
        findsOneWidget,
      );
      await finish(tester);
    });

    testWidgets('tri : plus récent d\'abord, puis id décroissant à date '
        'égale', (tester) async {
      await add(tester, name: 'Aria', createdAt: DateTime(2026, 11, 12, 10));
      await add(tester, name: 'Borin', createdAt: DateTime(2026, 11, 12, 11));
      await add(tester, name: 'Cyrus', createdAt: DateTime(2026, 11, 12, 9));
      await add(tester, name: 'Dora', createdAt: DateTime(2026, 11, 12, 11));
      await pumpApp(tester);
      await open(tester);

      final order = [
        top(tester, 'PV de Dora'),
        top(tester, 'PV de Borin'),
        top(tester, 'PV de Aria'),
        top(tester, 'PV de Cyrus'),
      ];
      expect(order, orderedEquals([...order]..sort()));
      expect(order.toSet().length, 4);
      await finish(tester);
    });

    testWidgets('message complet : le nom de 32 caractères n\'est pas tronqué '
        'dans le panneau', (tester) async {
      const longName = 'Ambrelune de Vaucluse-Halltesse!';
      await add(tester, name: longName);
      await pumpApp(tester);
      await open(tester);
      expect(find.textContaining(longName), findsOneWidget);
      expect(find.textContaining('…'), findsNothing);
      await finish(tester);
    });

    testWidgets('nom vide : « ce personnage »', (tester) async {
      await add(tester, name: '');
      await pumpApp(tester);
      await open(tester);
      expect(find.textContaining('PV de ce personnage'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('alertes d\'un autre compte : jamais affichées', (
      tester,
    ) async {
      await add(tester, name: 'Intrus', owner: 'owner-2');
      await pumpApp(tester);
      await open(tester);
      expect(find.textContaining('Intrus'), findsNothing);
      expect(find.text('Aucune alerte de synchronisation.'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('alerte mise à jour sur place : le panneau affiche le '
        'nouveau texte', (tester) async {
      await add(
        tester,
        kind: SyncAlertKind.conflict,
        value: const {
          'currentHp': 12,
          'temporaryHp': 0,
          'maxHp': 30,
          'queued': {'currentHp': 5, 'temporaryHp': 0},
        },
      );
      await pumpApp(tester);
      await open(tester);
      expect(find.textContaining('hors ligne (5/30)'), findsOneWidget);

      final id = (await inDb(tester)).single.id;
      await tester.runAsync(
        () => store.updateValue(
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
      expect(find.textContaining('hors ligne (8/30)'), findsOneWidget);
      await finish(tester);
    });
  });

  group('alertes orphelines', () {
    List<Override> chars(List<CharacterSummary> list) => [
      charactersProvider.overrideWith((ref) async => list),
    ];

    testWidgets('liste chargée sans ce personnage : ligne d\'orpheline ; '
        'avec lui : aucune', (tester) async {
      await add(tester, name: 'Aria', characterId: 'gone');
      await add(tester, name: 'Borin', characterId: 'here');
      await pumpApp(
        tester,
        watchCharacters: true,
        extra: chars([_character('here')]),
      );
      await open(tester);

      const orphan =
          "Ce personnage n'est plus dans ta liste (supprimé ou devenu "
          "inaccessible). Cette alerte n'a plus d'objet.";
      expect(find.text(orphan), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      // La ligne d'orpheline est dans la carte d'Aria, pas dans celle de Borin.
      final orphanTop = tester.getTopLeft(find.text(orphan)).dy;
      expect(orphanTop, greaterThan(top(tester, 'PV de Aria')));
      expect(
        orphanTop,
        lessThan(tester.getTopLeft(find.text('Écarter').at(1)).dy),
      );
      await finish(tester);
    });

    testWidgets('anglais', (tester) async {
      await add(tester, characterId: 'gone');
      await pumpApp(
        tester,
        locale: const Locale('en'),
        watchCharacters: true,
        extra: chars(const []),
      );
      await open(tester);
      expect(
        find.text(
          'This character is no longer in your list (deleted or no longer '
          'accessible). This alert no longer applies.',
        ),
        findsOneWidget,
      );
      await finish(tester);
    });

    testWidgets('liste EN CHARGEMENT : jamais de faux positif', (tester) async {
      final completer = Completer<List<CharacterSummary>>();
      await add(tester, characterId: 'gone');
      await pumpApp(
        tester,
        watchCharacters: true,
        extra: [charactersProvider.overrideWith((ref) => completer.future)],
      );
      await open(tester);

      expect(find.textContaining('PV de Aria'), findsOneWidget);
      expect(find.textContaining("n'est plus dans ta liste"), findsNothing);
      expect(find.byIcon(Icons.info_outline), findsNothing);

      // Une fois la liste chargée, l'orpheline apparaît.
      completer.complete([_character('here')]);
      await flushDb(tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining("n'est plus dans ta liste"), findsOneWidget);
      await finish(tester);
    });

    testWidgets('liste en erreur ou jamais chargée : jamais de faux '
        'positif', (tester) async {
      await add(tester, characterId: 'gone');
      await pumpApp(
        tester,
        watchCharacters: true,
        extra: [
          charactersProvider.overrideWith((ref) async => throw StateError('x')),
        ],
      );
      await open(tester);
      expect(find.textContaining("n'est plus dans ta liste"), findsNothing);
      await finish(tester);

      // Liste non vivante sous la feuille (jamais lue) : pas de chargement
      // déclenché par le panneau, donc « inconnu ».
      await pumpApp(tester, extra: chars(const []));
      await open(tester);
      expect(find.textContaining('PV de Aria'), findsOneWidget);
      expect(find.textContaining("n'est plus dans ta liste"), findsNothing);
      await finish(tester);
    });
  });

  group('écarter', () {
    testWidgets('« Écarter » : suppression immédiate de CETTE alerte, '
        'SnackBar « Alerte écartée », puis « Annuler » restaure id et date '
        'd\'origine', (tester) async {
      await add(tester, name: 'Aria', createdAt: DateTime(2026, 11, 12, 10));
      await add(tester, name: 'Borin', createdAt: DateTime(2026, 11, 12, 11));
      final before = await inDb(tester);
      final borin = before.firstWhere((a) => a.characterName == 'Borin');
      await pumpApp(tester);
      await open(tester);

      // Borin est la plus récente : première carte, premier « Écarter ».
      await tester.tap(find.text('Écarter').first);
      await flushDb(tester);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('PV de Borin'), findsNothing);
      expect(find.textContaining('PV de Aria'), findsOneWidget);
      expect(find.text('Alerte écartée'), findsOneWidget);
      final left = await inDb(tester);
      expect(left.map((a) => a.characterName), ['Aria']);

      // Le SnackBar est visible AU-DESSUS du panneau (dans la feuille).
      final snack = tester.getRect(find.text('Alerte écartée'));
      final sheetBottom = tester.view.physicalSize.height;
      expect(snack.bottom, lessThanOrEqualTo(sheetBottom));
      expect(tester.hitTestOnBinding(snack.center).path, isNotEmpty);

      await tester.tap(find.text('ANNULER'));
      await flushDb(tester);
      await tester.pump(const Duration(milliseconds: 300));

      final restored = (await inDb(tester))
          .firstWhere((a) => a.characterName == 'Borin');
      expect(restored.id, borin.id, reason: 'même id');
      expect(restored.createdAt, borin.createdAt, reason: 'même date');
      expect(restored.kind, borin.kind);
      expect(restored.dataKind, borin.dataKind);
      expect(restored.serverValue, borin.serverValue);
      expect(find.textContaining('PV de Borin'), findsOneWidget);
      // Remise à sa place (plus récente en premier).
      expect(top(tester, 'PV de Borin'), lessThan(top(tester, 'PV de Aria')));
      await finish(tester);
    });

    testWidgets('« Écarter » ne touche pas aux écritures en attente', (
      tester,
    ) async {
      final queue = PendingCharacterWriteQueue(db);
      await tester.runAsync(
        () => queue.enqueue(
          characterId: 'c1',
          ownerId: _owner,
          kind: PendingCharacterWriteKind.hp,
          targetId: '',
          payload: {'currentHp': 1, 'temporaryHp': 0},
        ),
      );
      await add(tester);
      await add(tester, name: 'Borin');
      await add(tester, name: 'Cyrus');
      await pumpApp(tester);
      await open(tester);

      await tester.tap(find.text('Écarter').first);
      await flushDb(tester);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('TOUT ÉCARTER'));
      await flushDb(tester);
      expect(await inDb(tester), isEmpty);

      final pending = await tester.runAsync(
        () => queue.watchPendingCount(_owner).first,
      );
      expect(pending, 1, reason: 'l\'écriture en attente est intacte');
      await finish(tester);
    });

    testWidgets('« Tout écarter » : visible dès 2 alertes, vide tout, la '
        'feuille reste ouverte (état vide), « N alertes écartées » + '
        '« Annuler » restaure tout avec ids et dates', (tester) async {
      await add(tester, name: 'Aria', createdAt: DateTime(2026, 11, 12, 9));
      await add(tester, name: 'Borin', createdAt: DateTime(2026, 11, 12, 10));
      await add(tester, name: 'Cyrus', createdAt: DateTime(2026, 11, 12, 11));
      final before = await inDb(tester);
      await pumpApp(tester);
      await open(tester);

      expect(find.text('TOUT ÉCARTER'), findsOneWidget);
      await tester.tap(find.text('TOUT ÉCARTER'));
      await flushDb(tester);
      await tester.pump(const Duration(milliseconds: 300));

      expect(await inDb(tester), isEmpty);
      expect(find.text('ALERTES DE SYNCHRO'), findsOneWidget);
      expect(find.text('Aucune alerte de synchronisation.'), findsOneWidget);
      expect(find.text('3 alertes écartées'), findsOneWidget);

      await tester.tap(find.text('ANNULER'));
      await flushDb(tester);
      await tester.pump(const Duration(milliseconds: 300));

      final after = await inDb(tester);
      expect(after.length, 3);
      for (final original in before) {
        final back = after.firstWhere((a) => a.id == original.id);
        expect(back.createdAt, original.createdAt);
        expect(back.characterName, original.characterName);
        expect(back.serverValue, original.serverValue);
      }
      expect(find.textContaining('PV de Cyrus'), findsOneWidget);
      expect(find.text('TOUT ÉCARTER'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('« Tout écarter » en anglais : pluriel ICU', (tester) async {
      await add(tester, name: 'Aria');
      await add(tester, name: 'Borin');
      await pumpApp(tester, locale: const Locale('en'));
      await open(tester);
      await tester.tap(find.text('DISMISS ALL'));
      await flushDb(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('2 alerts dismissed'), findsOneWidget);
      expect(find.text('UNDO'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('hors ligne : le panneau s\'ouvre et écarte/annule sans '
        'réseau', (tester) async {
      await add(tester, name: 'Aria');
      await pumpApp(tester);
      connectivity.goOffline();
      await tester.pump();
      await open(tester);

      expect(find.textContaining('PV de Aria'), findsOneWidget);
      await tester.tap(find.text('Écarter'));
      await flushDb(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(await inDb(tester), isEmpty);
      await tester.tap(find.text('ANNULER'));
      await flushDb(tester);
      expect((await inDb(tester)).length, 1);
      await finish(tester);
    });
  });

  group('sémantique et cibles', () {
    testWidgets('bouton « Écarter l\'alerte : {nom} » (nom complet), nœud de '
        'carte avec type + message, annonce de l\'écartement', (tester) async {
      final semantics = tester.ensureSemantics();
      const longName = 'Ambrelune de Vaucluse-Halltesse!';
      await add(tester, name: longName);
      await pumpApp(tester);
      await open(tester);

      expect(
        find.bySemanticsLabel("Écarter l'alerte : $longName"),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(
          find.bySemanticsLabel("Écarter l'alerte : $longName"),
        ),
        isSemantics(isButton: true, hasTapAction: true),
      );
      // Le nœud de la carte rassemble type, date et message complet.
      final card = find.bySemanticsLabel(
        RegExp('Modification non envoyée.*$longName', dotAll: true),
      );
      expect(card, findsOneWidget);

      await tester.tap(find.text('Écarter'));
      await flushDb(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.bySemanticsLabel(RegExp('Alerte écartée. Annuler disponible.')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Aucune alerte de synchronisation.'),
        findsNothing,
        reason: 'le titre vide est annoncé par sa région live, pas par label',
      );
      await finish(tester);
      semantics.dispose();
    });

    testWidgets('nom vide : « Écarter l\'alerte : ce personnage »', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await add(tester, name: '');
      await pumpApp(tester);
      await open(tester);
      expect(
        find.bySemanticsLabel("Écarter l'alerte : ce personnage"),
        findsOneWidget,
      );
      await finish(tester);
      semantics.dispose();
    });

    testWidgets('cibles >= 44 dp : « Écarter » et « Tout écarter »', (
      tester,
    ) async {
      await add(tester, name: 'Aria');
      await add(tester, name: 'Borin');
      await pumpApp(tester);
      await open(tester);

      for (final label in ['Écarter', 'TOUT ÉCARTER']) {
        final targets = find.ancestor(
          of: find.text(label),
          matching: find.byType(InkWell),
        );
        expect(targets, findsWidgets);
        for (final e in targets.evaluate()) {
          final size = tester.getSize(find.byWidget(e.widget));
          expect(size.height, greaterThanOrEqualTo(44), reason: label);
          expect(size.width, greaterThanOrEqualTo(44), reason: label);
        }
      }
      await finish(tester);
    });

    test('contraste AA : text.muted sur parchment.card et blanc sur '
        'accent.brick', () {
      double lum(Color c) {
        double ch(double v) => v <= 0.03928
            ? v / 12.92
            : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
        return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
      }

      double ratio(Color a, Color b) {
        final l1 = lum(a);
        final l2 = lum(b);
        return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
      }

      expect(
        ratio(AppColors.textMuted, AppColors.parchmentCard),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        ratio(Colors.white, AppColors.accentBrick),
        greaterThanOrEqualTo(4.5),
      );
    });

    testWidgets('hauteur : plafonnée à 85 % de l\'écran, contenu '
        'défilant, fermeture par la croix', (tester) async {
      for (var i = 0; i < 12; i++) {
        await add(tester, name: 'Perso$i', characterId: 'c$i');
      }
      await pumpApp(tester, size: const Size(360, 640));
      await open(tester);

      final panel = tester.getRect(
        find
            .ancestor(
              of: find.text('ALERTES DE SYNCHRO'),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(panel.height, lessThanOrEqualTo(640 * 0.85 + 0.5));
      expect(panel.bottom, closeTo(640, 0.5));
      // Tout reste atteignable en défilant.
      await tester.dragUntilVisible(
        find.textContaining('PV de Perso0'),
        find.byType(ListView),
        const Offset(0, -100),
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('ALERTES DE SYNCHRO'), findsNothing);
      await finish(tester);
    });
  });

  group('grandes polices sur 320x568', () {
    for (final locale in const [Locale('fr'), Locale('en')]) {
      for (final scale in <double>[2.0, 3.0]) {
        testWidgets('${locale.languageCode} x$scale : rien ne déborde, aucun '
            'mot coupé lettre par lettre, tout atteignable', (tester) async {
          await add(
            tester,
            name: 'Halltesse Ambrelune de Vaucluse',
            characterId: 'gone',
            kind: SyncAlertKind.conflict,
            createdAt: DateTime(2026, 11, 2, 14, 32),
          );
          await add(tester, name: 'Borin', characterId: 'b');
          await add(
            tester,
            name: 'Cyrus',
            characterId: 'c',
            dataKind: 'spell_slot',
            value: const {'level': 3, 'remaining': 1, 'max': 3},
          );
          await pumpApp(
            tester,
            locale: locale,
            scale: scale,
            size: const Size(320, 568),
            watchCharacters: true,
            extra: [
              charactersProvider.overrideWith(
                (ref) async => [_character('b'), _character('c')],
              ),
            ],
          );
          await open(tester);
          expect(tester.takeException(), isNull);

          final panel = tester.getRect(
            find
                .ancestor(
                  of: find.text(
                    locale.languageCode == 'fr'
                        ? 'ALERTES DE SYNCHRO'
                        : 'SYNC ALERTS',
                  ),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          );
          expect(panel.height, lessThanOrEqualTo(568 * 0.85 + 0.5));

          // On parcourt toute la liste (les cartes hors écran ne sont pas
          // construites) : à chaque pas, aucun mot coupé (chaque paragraphe
          // est au moins aussi large que son plus long mot) et chaque
          // « Écarter » visible a une cible >= 44 dans l'écran.
          final dismiss = locale.languageCode == 'fr' ? 'Écarter' : 'Dismiss';
          final list = find.byType(ListView);
          final cards = find.byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith('syncAlertCard-'),
          );
          final seen = <Key>{};
          final reachable = <Key>{};
          for (var step = 0; step < 40; step++) {
            for (final element
                in find
                    .descendant(of: list, matching: find.byType(Text))
                    .evaluate()) {
              final data = (element.widget as Text).data;
              if (data == null || data.isEmpty) continue;
              final paragraph = element.renderObject! as RenderParagraph;
              var longest = 0.0;
              for (final word in data.split(RegExp(r'\s+'))) {
                if (word.isEmpty) continue;
                final painter = TextPainter(
                  text: TextSpan(text: word, style: paragraph.text.style),
                  textDirection: TextDirection.ltr,
                  textScaler: paragraph.textScaler,
                )..layout();
                longest = math.max(longest, painter.width);
                painter.dispose();
              }
              expect(
                paragraph.size.width,
                greaterThanOrEqualTo(longest - 0.5),
                reason: 'mot coupé dans « $data »',
              );
              expect(paragraph.didExceedMaxLines, isFalse);
            }
            for (final card in cards.evaluate()) {
              final key = card.widget.key!;
              seen.add(key);
              final button = find.descendant(
                of: find.byKey(key),
                matching: find.text(dismiss),
              );
              final rect = tester.getRect(
                find.ancestor(of: button, matching: find.byType(InkWell)).first,
              );
              if (rect.top >= panel.top && rect.bottom <= 568.5) {
                expect(rect.height, greaterThanOrEqualTo(44));
                expect(rect.left, greaterThanOrEqualTo(-0.5));
                expect(rect.right, lessThanOrEqualTo(320.5));
                reachable.add(key);
              }
            }
            await tester.drag(list, const Offset(0, -100));
            await tester.pump();
          }
          expect(seen.length, 3);
          expect(reachable.length, 3, reason: 'chaque « Écarter » atteignable');
          // « Tout écarter » reste atteignable et sa cible est >= 44.
          final all = find.text(
            locale.languageCode == 'fr' ? 'TOUT ÉCARTER' : 'DISMISS ALL',
          );
          await tester.dragUntilVisible(all, list, const Offset(0, 100));
          await tester.pump();
          await tester.pump();
          expect(
            tester
                .getSize(
                  find.ancestor(of: all, matching: find.byType(InkWell)).first,
                )
                .height,
            greaterThanOrEqualTo(44),
          );
          expect(tester.takeException(), isNull);
          await finish(tester);
        });
      }
    }
  });
}
