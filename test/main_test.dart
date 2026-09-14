// Tests de `AppBootstrap` (`lib/main.dart`) : affichage de [SplashScreen]
// pendant l'initialisation (Supabase/Firebase en production, substituée ici
// par un [Future] contrôlé) puis bascule automatique vers l'écran suivant
// une fois celle-ci résolue — voir la doc de classe d'`AppBootstrap`.
//
// `initialize`/`child` sont substitués ici pour ne jamais appeler
// `Supabase.initialize`/`Firebase.initializeApp` pour de vrai ni dépendre
// d'un `Supabase.instance.client` réel (voir `test/widget_test.dart`, qui
// pompe directement `NexusJdrApp` pour la même raison).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:personnages/features/app_update/data/app_version_repository.dart';
import 'package:personnages/features/app_update/presentation/force_update_screen.dart';
import 'package:personnages/features/app_update/presentation/providers/app_version_providers.dart';
import 'package:personnages/features/splash/presentation/splash_screen.dart';
import 'package:personnages/main.dart';

class _FakeAppVersionRepository implements AppVersionRepository {
  _FakeAppVersionRepository(this._row);

  final AppVersionRow _row;

  @override
  Future<AppVersionRow> fetchCurrentPlatformVersion() async => _row;
}

void main() {
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'Nexus JDR — Personnages',
      packageName: 'com.nexusjdr.personnages',
      version: '0.1.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets(
    'affiche SplashScreen pendant l\'initialisation, puis bascule sur '
    '`child` une fois celle-ci résolue',
    (tester) async {
      final completer = Completer<bool>();

      await tester.pumpWidget(
        ProviderScope(
          child: AppBootstrap(
            initialize: () => completer.future,
            // `MaterialApp` propre (pas un simple `Scaffold` nu) : en
            // production `child` est `NexusJdrApp`, qui pose lui-même son
            // `MaterialApp.router` — `AppBootstrap` ne fournit de
            // `MaterialApp` que pour la phase [SplashScreen] (voir sa doc de
            // classe), pas pour `child`.
            child: const MaterialApp(
              home: Scaffold(body: Center(child: Text('App prête'))),
            ),
          ),
        ),
      );
      // Un seul `pump` (pas `pumpAndSettle`, qui ne terminerait jamais tant
      // que l'animation continue des 3 points de SplashScreen tourne) :
      // suffisant pour laisser le `FutureBuilder` construire son premier
      // état ("en attente").
      await tester.pump();

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('App prête'), findsNothing);

      completer.complete(true);
      // Plusieurs `pump` supplémentaires (toujours pas `pumpAndSettle`, même
      // rationale) : depuis l'introduction de la vérification de version
      // (`appVersionCheckProvider`, voir la doc de classe d'`AppBootstrap`),
      // `child` n'apparaît plus dès la résolution d'`initialize` mais
      // seulement une fois cette vérification elle-même résolue (chaîne de
      // `Future`s supplémentaire : `packageInfoProvider.future` puis le
      // dépôt de version, ici non surchargé — retombe sur
      // `AppVersionStatus.upToDate` via le `catch` de
      // `appVersionCheckProvider`, voir sa doc).
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }

      expect(find.byType(SplashScreen), findsNothing);
      expect(find.text('App prête'), findsOneWidget);
    },
  );

  testWidgets(
    '`initialize` résolu à `false` (Supabase indisponible) -> écran de '
    'repli, jamais `child` (qui dépend de Supabase.instance.client) ; '
    '"Réessayer" relance `initialize`',
    (tester) async {
      var attempt = 0;
      await tester.pumpWidget(
        ProviderScope(
          child: AppBootstrap(
            initialize: () async => (++attempt) > 1,
            child: const MaterialApp(
              home: Scaffold(body: Center(child: Text('App prête'))),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('App prête'), findsNothing);
      expect(
        find.text(
          'Impossible de démarrer l\'application. Vérifie ta connexion et '
          'réessaie.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Réessayer'));
      // Plusieurs `pump` (même rationale que `pumpBootstrap` plus bas dans
      // ce fichier) : `initialize` réussit cette fois, mais la chaîne
      // `appVersionCheckProvider` (packageInfoProvider.future puis le
      // dépôt) doit encore se résoudre avant d'atteindre `child`.
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }

      expect(find.text('App prête'), findsOneWidget);
    },
  );

  testWidgets(
    '`initialize` qui lève malgré tout (défense en profondeur, ne devrait '
    'plus arriver en pratique) -> écran de repli, jamais `child`',
    (tester) async {
      final completer = Completer<bool>();

      await tester.pumpWidget(
        ProviderScope(
          child: AppBootstrap(
            initialize: () => completer.future,
            child: const MaterialApp(
              home: Scaffold(body: Center(child: Text('App prête'))),
            ),
          ),
        ),
      );
      await tester.pump();

      completer.completeError(Exception('échec inattendu simulé'));
      await tester.pump();
      await tester.pump();

      expect(find.text('App prête'), findsNothing);
      expect(
        find.text(
          'Impossible de démarrer l\'application. Vérifie ta connexion et '
          'réessaie.',
        ),
        findsOneWidget,
      );
    },
  );

  group('vérification de version une fois `initialize` résolu '
      '(`appVersionCheckProvider`, recettage direction-artistique du '
      '13/09/2026)', () {
    Future<void> pumpBootstrap(
      WidgetTester tester, {
      required AppVersionRepository repository,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appVersionRepositoryProvider.overrideWithValue(repository),
          ],
          child: AppBootstrap(
            initialize: () async => true,
            child: const MaterialApp(
              home: Scaffold(body: Center(child: Text('App prête'))),
            ),
          ),
        ),
      );
      // Ni `pumpAndSettle` (la `SplashScreen` transitoire de
      // `_splashApp()`, affichée pendant `initialize`/`appVersionCheckProvider`,
      // a un `AnimationController.repeat()` qui ne se stabilise jamais —
      // même piège documenté sur les 2 tests précédents de ce fichier) ni
      // un unique `pump` (`initialize`/`packageInfoProvider.future`/le
      // dépôt factice sont chacun résolus via un `Future` qui ne se
      // complète pas synchroniquement, même sans `await` explicite dans
      // leur corps — piège classique de `async {}`) : plusieurs `pump`
      // successifs laissent le temps à toute la chaîne de `Future`s de se
      // résoudre avant d'atteindre l'état stabilisé attendu.
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }
    }

    testWidgets(
      'AppVersionStatus.updateRequired -> affiche ForceUpdateScreen à la '
      'place de `child`, jamais `child` lui-même',
      (tester) async {
        await pumpBootstrap(
          tester,
          repository: _FakeAppVersionRepository(
            const AppVersionRow(
              minimumSupportedVersion: '0.3.0',
              latestVersion: '0.5.0',
            ),
          ),
        );

        expect(find.byType(ForceUpdateScreen), findsOneWidget);
        expect(find.text('App prête'), findsNothing);
        expect(
          find.text('Version installée : 0.1.0 · minimum requis : 0.3.0'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'AppVersionStatus.updateSuggested (< latest mais >= minimum) -> '
      'laisse passer vers `child` normalement (c\'est la bannière de la '
      'liste de personnages qui prend le relais, pas cet écran)',
      (tester) async {
        await pumpBootstrap(
          tester,
          repository: _FakeAppVersionRepository(
            const AppVersionRow(
              minimumSupportedVersion: '0.1.0',
              latestVersion: '0.5.0',
            ),
          ),
        );

        expect(find.byType(ForceUpdateScreen), findsNothing);
        expect(find.text('App prête'), findsOneWidget);
      },
    );

    testWidgets('AppVersionStatus.upToDate -> laisse passer vers `child` '
        'normalement', (tester) async {
      await pumpBootstrap(
        tester,
        repository: _FakeAppVersionRepository(
          const AppVersionRow(
            minimumSupportedVersion: '0.1.0',
            latestVersion: '0.1.0',
          ),
        ),
      );

      expect(find.byType(ForceUpdateScreen), findsNothing);
      expect(find.text('App prête'), findsOneWidget);
    });
  });
}
