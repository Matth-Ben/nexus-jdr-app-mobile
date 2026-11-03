// Test de la résolution de langue "Langue du téléphone" de
// `main.dart::NexusJdrApp` (`MaterialApp.router.localeResolutionCallback`) —
// chantier "traduction de l'app" Phase A.
//
// Les tests de `profile_language_screen_test.dart` couvrent FR et EN
// individuellement (préférence forcée ou appareil en FR/EN), mais ne pompent
// pas le vrai `localeResolutionCallback` de `NexusJdrApp` : ce fichier pompe
// `NexusJdrApp` directement (même patron que `widget_test.dart`) pour vérifier
// le seul cas qui distingue ce callback du comportement par défaut de Flutter
// (`basicLocaleListResolution`, qui replierait sur `supportedLocales.first` —
// l'anglais, puisque `AppLocalizations.supportedLocales` généré est trié
// alphabétiquement `[en, fr]`) : un appareil dans une langue ni FR ni EN doit
// résoudre vers le FRANÇAIS, pas l'anglais.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/notifications/push_token_registrar.dart';
import 'package:personnages/core/router/app_router.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_catalog_preloader.dart';
import 'package:personnages/features/characters/presentation/providers/character_write_sync_coordinator.dart';
import 'package:personnages/features/profile/presentation/profile_language_screen.dart';
import 'package:personnages/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpAppOnLanguageScreen(
  WidgetTester tester, {
  required Locale deviceLocale,
}) async {
  // Préférence "Langue" jamais forcée (`SharedPreferences` vide) : la
  // résolution ne doit dépendre que de la langue de l'appareil simulée
  // ci-dessous, pas d'une préférence persistée qui court-circuiterait
  // `localeResolutionCallback` (voir `main.dart::NexusJdrApp.locale`).
  SharedPreferences.setMockInitialValues({});

  tester.platformDispatcher.localeTestValue = deviceLocale;
  tester.platformDispatcher.localesTestValue = [deviceLocale];
  addTearDown(tester.platformDispatcher.clearLocaleTestValue);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  final testRouter = GoRouter(
    initialLocation: '/profile/language',
    routes: [
      GoRoute(
        path: '/profile/language',
        builder: (context, state) => const ProfileLanguageScreen(),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appRouterProvider.overrideWithValue(testRouter),
        characterWriteSyncCoordinatorProvider.overrideWith(
          (ref) => CharacterWriteSyncCoordinator(ref),
        ),
        characterCreationCatalogPreloaderProvider.overrideWith(
          (ref) => CharacterCreationCatalogPreloader(ref),
        ),
        pushTokenRegistrarProvider.overrideWith(
          (ref) => PushTokenRegistrar(ref),
        ),
      ],
      child: const NexusJdrApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('appareil en allemand (ni FR ni EN), aucune préférence forcée -> '
      'résout en FRANÇAIS (pas en anglais, malgré `supportedLocales` généré '
      'trié [en, fr])', (tester) async {
    await _pumpAppOnLanguageScreen(tester, deviceLocale: const Locale('de'));

    expect(find.text('LANGUE'), findsOneWidget);
    expect(find.text('LANGUAGE'), findsNothing);
  });

  testWidgets('appareil en espagnol (ni FR ni EN), aucune préférence forcée -> '
      'résout en FRANÇAIS', (tester) async {
    await _pumpAppOnLanguageScreen(tester, deviceLocale: const Locale('es'));

    expect(find.text('LANGUE'), findsOneWidget);
    expect(find.text('LANGUAGE'), findsNothing);
  });

  testWidgets('appareil en anglais, aucune préférence forcée -> résout bien en '
      'anglais (non-régression : le fallback français ci-dessus ne doit pas '
      'absorber un appareil réellement anglais)', (tester) async {
    await _pumpAppOnLanguageScreen(tester, deviceLocale: const Locale('en'));

    expect(find.text('LANGUAGE'), findsOneWidget);
    expect(find.text('LANGUE'), findsNothing);
  });
}
