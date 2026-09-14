// Tests de widget de `UpdateSuggestedBanner` (bannière "Mise à jour
// suggérée") — `appVersionRepositoryProvider` surchargé par un double (jamais
// `Supabase.instance.client`), `PackageInfo.setMockInitialValues` pour la
// version installée (même convention que `profile_screen_test.dart`),
// `SharedPreferences.setMockInitialValues` pour la persistance de fermeture
// (store en mémoire remis à zéro à chaque test).
//
// Le lien "Mettre à jour" n'est volontairement jamais tapé ici : voir
// `force_update_screen_test.dart` pour le rationale complet
// (`canLaunchUrl`/`launchUrl` non mockés sous `flutter test`).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:personnages/features/app_update/data/app_version_repository.dart';
import 'package:personnages/features/app_update/presentation/providers/app_version_providers.dart';
import 'package:personnages/features/app_update/presentation/widgets/update_suggested_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpBanner(
    WidgetTester tester, {
    required AppVersionRepository repository,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appVersionRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: UpdateSuggestedBanner())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('statut upToDate (version installée == latest) : rien affiché', (
    tester,
  ) async {
    await pumpBanner(
      tester,
      repository: _FakeAppVersionRepository(
        const AppVersionRow(
          minimumSupportedVersion: '0.1.0',
          latestVersion: '0.1.0',
        ),
      ),
    );

    expect(find.text('Nouvelle version disponible'), findsNothing);
  });

  testWidgets(
    'statut updateRequired (version installée < minimum) : la bannière ne '
    's\'affiche pas (c\'est l\'écran bloquant qui prend le relais, pas '
    'elle)',
    (tester) async {
      await pumpBanner(
        tester,
        repository: _FakeAppVersionRepository(
          const AppVersionRow(
            minimumSupportedVersion: '0.5.0',
            latestVersion: '0.6.0',
          ),
        ),
      );

      expect(find.text('Nouvelle version disponible'), findsNothing);
    },
  );

  group('statut updateSuggested (installée >= minimum, < latest)', () {
    AppVersionRepository suggestedRepository() => _FakeAppVersionRepository(
      const AppVersionRow(
        minimumSupportedVersion: '0.1.0',
        latestVersion: '0.5.0',
      ),
    );

    testWidgets(
      'affiche l\'icône de téléchargement, le texte et le lien "Mettre à '
      'jour"',
      (tester) async {
        await pumpBanner(tester, repository: suggestedRepository());

        expect(find.text('Nouvelle version disponible'), findsOneWidget);
        expect(find.text('Mettre à jour'), findsOneWidget);
        expect(find.byIcon(Icons.file_download_outlined), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
      },
    );

    testWidgets('taper "×" referme la bannière immédiatement', (tester) async {
      await pumpBanner(tester, repository: suggestedRepository());
      expect(find.text('Nouvelle version disponible'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Nouvelle version disponible'), findsNothing);
    });

    testWidgets('la fermeture est persistée : un nouvel affichage (nouveau '
        'ProviderScope, mêmes SharedPreferences) ne réaffiche pas la bannière '
        'pour la même version', (tester) async {
      await pumpBanner(tester, repository: suggestedRepository());
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Nouveau `ProviderScope`/`pumpWidget` : simule une nouvelle
      // ouverture de l'app (ou de l'écran) — `SharedPreferences` reste le
      // même store en mémoire (pas de `setMockInitialValues` entre les
      // deux), donc la fermeture persistée doit être relue.
      await pumpBanner(tester, repository: suggestedRepository());

      expect(find.text('Nouvelle version disponible'), findsNothing);
    });

    testWidgets(
      'une NOUVELLE version suggérée (latest_version différent de celle '
      'refermée) réaffiche la bannière malgré la fermeture précédente',
      (tester) async {
        await pumpBanner(tester, repository: suggestedRepository());
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        final newerRepository = _FakeAppVersionRepository(
          const AppVersionRow(
            minimumSupportedVersion: '0.1.0',
            // Nouvelle version publiée depuis la fermeture précédente
            // (0.5.0 refermée, 0.7.0 maintenant proposée).
            latestVersion: '0.7.0',
          ),
        );
        await pumpBanner(tester, repository: newerRepository);

        expect(find.text('Nouvelle version disponible'), findsOneWidget);
      },
    );
  });
}
