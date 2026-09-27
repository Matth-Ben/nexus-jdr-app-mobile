import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:personnages/features/app_update/data/in_app_update_gateway.dart';
import 'package:personnages/features/app_update/domain/app_version_check_result.dart';
import 'package:personnages/features/app_update/domain/app_version_status.dart';
import 'package:personnages/features/app_update/domain/changelog_parser.dart';
import 'package:personnages/features/app_update/presentation/app_updates_screen.dart';
import 'package:personnages/features/app_update/presentation/providers/app_updates_providers.dart';
import 'package:personnages/features/app_update/presentation/providers/app_version_providers.dart';
import 'package:personnages/features/profile/presentation/providers/package_info_provider.dart';

class _FakeGateway implements InAppUpdateGateway {
  _FakeGateway(this.outcome);

  final InAppUpdateOutcome outcome;
  int calls = 0;

  @override
  Future<InAppUpdateOutcome> tryImmediateUpdate() async {
    calls++;
    return outcome;
  }
}

const _releases = [
  ChangelogRelease(
    version: '1.0.4',
    date: '2026-09-26',
    notes: ['• Politique de confidentialité complétée'],
  ),
  ChangelogRelease(
    version: '1.0.3',
    date: '2026-09-25',
    notes: ['Première version de test.'],
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  required _FakeGateway gateway,
  AppVersionCheckResult? versionCheck,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        inAppUpdateGatewayProvider.overrideWithValue(gateway),
        changelogReleasesProvider.overrideWith((ref) async => _releases),
        packageInfoProvider.overrideWith(
          (ref) async => PackageInfo(
            appName: 'Nexus JDR',
            packageName: 'com.nexus_jdr',
            version: '1.0.4',
            buildNumber: '5',
          ),
        ),
        appVersionCheckProvider.overrideWith(
          (ref) async =>
              versionCheck ??
              const AppVersionCheckResult(
                status: AppVersionStatus.upToDate,
                installedVersion: '1.0.4',
                minimumVersion: '1.0.0',
                latestVersion: '1.0.4',
              ),
        ),
      ],
      child: const MaterialApp(home: AppUpdatesScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('affiche la version installée et les notes de chaque version, '
      'la version installée mise en avant', (tester) async {
    await _pump(tester, gateway: _FakeGateway(InAppUpdateOutcome.upToDate));

    expect(find.text('Version installée : 1.0.4'), findsOneWidget);
    expect(find.text('Version 1.0.4'), findsOneWidget);
    expect(find.text('26/09/2026'), findsOneWidget);
    expect(
      find.text('• Politique de confidentialité complétée'),
      findsOneWidget,
    );
    expect(find.text('Version 1.0.3'), findsOneWidget);
    expect(find.text('INSTALLÉE'), findsOneWidget);
  });

  testWidgets('Google Play : déjà à jour -> message', (tester) async {
    final gateway = _FakeGateway(InAppUpdateOutcome.upToDate);
    await _pump(tester, gateway: gateway);

    await tester.tap(find.text('RECHERCHER UNE MISE À JOUR'));
    await tester.pumpAndSettle();

    expect(gateway.calls, 1);
    expect(find.text('Tu as déjà la dernière version.'), findsOneWidget);
  });

  testWidgets('Google Play : mise à jour refusée -> message', (tester) async {
    await _pump(tester, gateway: _FakeGateway(InAppUpdateOutcome.declined));

    await tester.tap(find.text('RECHERCHER UNE MISE À JOUR'));
    await tester.pumpAndSettle();

    expect(find.text('Mise à jour annulée.'), findsOneWidget);
  });

  testWidgets('hors Google Play : repli sur app_versions, une version plus '
      'récente propose d’ouvrir le store', (tester) async {
    await _pump(
      tester,
      gateway: _FakeGateway(InAppUpdateOutcome.unavailable),
      versionCheck: const AppVersionCheckResult(
        status: AppVersionStatus.updateSuggested,
        installedVersion: '1.0.4',
        minimumVersion: '1.0.0',
        latestVersion: '1.0.5',
      ),
    );

    await tester.tap(find.text('RECHERCHER UNE MISE À JOUR'));
    await tester.pumpAndSettle();

    expect(find.text('Mise à jour disponible'), findsOneWidget);
    expect(
      find.text('La version 1.0.5 est disponible (tu as la 1.0.4).'),
      findsOneWidget,
    );

    await tester.tap(find.text('Plus tard'));
    await tester.pumpAndSettle();
    expect(find.text('Mise à jour disponible'), findsNothing);
  });

  testWidgets('hors Google Play et déjà à jour -> message', (tester) async {
    await _pump(tester, gateway: _FakeGateway(InAppUpdateOutcome.unavailable));

    await tester.tap(find.text('RECHERCHER UNE MISE À JOUR'));
    await tester.pumpAndSettle();

    expect(find.text('Tu as déjà la dernière version.'), findsOneWidget);
  });
}
