// Relance en arrière-plan de la vérification de version (décision du
// 11/11/2026) : tant que le dernier résultat est un repli (timeout/erreur),
// la requête est relancée après un backoff fini et à chaque retour du réseau ;
// une vraie réponse met l'état à jour (écran de mise à jour obligatoire, via
// `AppBootstrap`) et arrête toute relance.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/features/app_update/data/app_version_repository.dart';
import 'package:personnages/features/app_update/domain/app_version_status.dart';
import 'package:personnages/features/app_update/presentation/force_update_screen.dart';
import 'package:personnages/features/app_update/presentation/providers/app_version_providers.dart';
import 'package:personnages/main.dart';

import '../../../support/fake_connectivity_checker.dart';

const _required = AppVersionRow(
  minimumSupportedVersion: '0.3.0',
  latestVersion: '0.5.0',
);
const _upToDate = AppVersionRow(
  minimumSupportedVersion: '0.1.0',
  latestVersion: '0.1.0',
);

/// Réponses successives scriptées (la dernière est répétée) ; `null` = ne
/// répond jamais, une exception = échec immédiat.
class _ScriptedRepository implements AppVersionRepository {
  _ScriptedRepository(this._script);

  final List<Object?> _script;
  int calls = 0;

  @override
  Future<AppVersionRow> fetchCurrentPlatformVersion() {
    final step = _script[calls < _script.length ? calls : _script.length - 1];
    calls++;
    if (step == null) return Completer<AppVersionRow>().future;
    if (step is AppVersionRow) return Future.value(step);
    return Future.error(step);
  }
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

  Future<void> settle(
    WidgetTester tester, [
    Duration by = Duration.zero,
  ]) async {
    await tester.pump(by);
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
  }

  Future<FakeConnectivityChecker> pumpApp(
    WidgetTester tester,
    _ScriptedRepository repository, {
    List<Duration> backoff = const [Duration(seconds: 10)],
  }) async {
    final connectivity = FakeConnectivityChecker();
    addTearDown(connectivity.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appVersionRepositoryProvider.overrideWithValue(repository),
          appVersionRetryBackoffProvider.overrideWithValue(backoff),
          connectivityCheckerProvider.overrideWithValue(connectivity),
        ],
        child: AppBootstrap(
          initialize: () async => (
            supabaseReady: true,
            firebaseAnalyticsReady: false,
            postHogReady: false,
          ),
          child: const MaterialApp(
            home: Scaffold(body: Center(child: Text('App prête'))),
          ),
        ),
      ),
    );
    await settle(tester);
    return connectivity;
  }

  Future<void> dispose(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox.shrink());

  testWidgets('délai dépassé puis réponse tardive « mise à jour obligatoire » '
      '-> ForceUpdateScreen (le splash est déjà sorti)', (tester) async {
    final repository = _ScriptedRepository([null, _required]);
    await pumpApp(tester, repository);

    await settle(tester, appVersionCheckTimeout);
    expect(find.text('App prête'), findsOneWidget);
    expect(find.byType(ForceUpdateScreen), findsNothing);

    await settle(tester, const Duration(seconds: 11));

    expect(repository.calls, 2);
    expect(find.byType(ForceUpdateScreen), findsOneWidget);
    expect(find.text('App prête'), findsNothing);
    await dispose(tester);
  });

  testWidgets('retour du réseau -> relance ; réponse « obligatoire » -> '
      'ForceUpdateScreen', (tester) async {
    final repository = _ScriptedRepository([
      const SocketException('Failed host lookup'),
      _required,
    ]);
    final connectivity = await pumpApp(tester, repository, backoff: const []);
    expect(find.text('App prête'), findsOneWidget);
    expect(repository.calls, 1);

    connectivity.goOnline();
    await settle(tester);

    expect(repository.calls, 2);
    expect(find.byType(ForceUpdateScreen), findsOneWidget);
    await dispose(tester);
  });

  testWidgets('vraie réponse « à jour » : plus aucune relance (ni délai, ni '
      'retour du réseau)', (tester) async {
    final repository = _ScriptedRepository([_upToDate]);
    final connectivity = await pumpApp(tester, repository);

    connectivity.goOnline();
    await settle(tester, const Duration(minutes: 5));
    connectivity.goOnline();
    await settle(tester);

    expect(repository.calls, 1);
    expect(find.text('App prête'), findsOneWidget);
    await dispose(tester);
  });

  testWidgets('échec permanent : nombre de relances fini (1 + backoff), pas '
      'de boucle ; seul le retour du réseau relance ensuite', (tester) async {
    final repository = _ScriptedRepository([const SocketException('down')]);
    final connectivity = await pumpApp(
      tester,
      repository,
      backoff: const [Duration(seconds: 10), Duration(seconds: 30)],
    );

    await settle(tester, const Duration(minutes: 10));
    expect(repository.calls, 3);

    connectivity.goOnline();
    await settle(tester);
    expect(repository.calls, 4);

    await settle(tester, const Duration(minutes: 10));
    expect(repository.calls, 4);
    await dispose(tester);
  });

  testWidgets('libération du provider : plus aucune relance', (tester) async {
    final repository = _ScriptedRepository([const SocketException('down')]);
    await pumpApp(tester, repository);
    await dispose(tester);

    await tester.pump(const Duration(minutes: 5));

    expect(repository.calls, 1);
  });

  test(
    'résultat tardif « suggérée » exposé par le provider (bannière)',
    () async {
      final repository = _ScriptedRepository([
        const SocketException('down'),
        const AppVersionRow(
          minimumSupportedVersion: '0.1.0',
          latestVersion: '0.5.0',
        ),
      ]);
      final connectivity = FakeConnectivityChecker();
      addTearDown(connectivity.close);
      PackageInfo.setMockInitialValues(
        appName: 'Nexus JDR — Personnages',
        packageName: 'com.nexusjdr.personnages',
        version: '0.1.0',
        buildNumber: '1',
        buildSignature: '',
      );
      final container = ProviderContainer(
        overrides: [
          appVersionRepositoryProvider.overrideWithValue(repository),
          appVersionRetryBackoffProvider.overrideWithValue(const []),
          connectivityCheckerProvider.overrideWithValue(connectivity),
        ],
      );
      addTearDown(container.dispose);
      container.listen(appVersionCheckProvider, (_, _) {});
      expect(
        (await container.read(appVersionCheckProvider.future)).status,
        AppVersionStatus.upToDate,
      );

      connectivity.goOnline();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        container.read(appVersionCheckProvider).value?.status,
        AppVersionStatus.updateSuggested,
      );
    },
  );
}
