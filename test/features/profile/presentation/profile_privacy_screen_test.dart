// Tests de widget de l'écran "Confidentialité"
// (`presentation/profile_privacy_screen.dart`) — bandeau bois "CONFIDENTIALITÉ"
// + retour, section "MES DONNÉES" (3 tuiles regroupées dans un
// `SettingsListCard`, icônes dédiées, ouverture de la bonne sheet/route,
// icône de fin `north_east` uniquement sur "Autorisations de l'appareil"
// [qui ouvre une sheet système] — "Politique de confidentialité" garde le
// chevron par défaut depuis qu'elle pousse l'écran interne
// `ProfilePrivacyPolicyScreen`), bascule "Partager mes données d'usage"
// (`core/analytics/`, voir plus bas), section "ZONE DANGEREUSE"
// (`DestructiveMenuTile` isolée "Supprimer mon compte", jamais une simple
// tuile) — recettage direction-artistique du 13/09/2026.
//
// Aucune donnée à charger (écran 100% synchrone) : `currentUserProvider`
// tout de même overridé (`authRepositoryProvider`/`connectivityCheckerProvider`
// aussi) car `showDeleteAccountSheet` en dépend dès l'ouverture de l'écran —
// même stratégie que `profile_screen_test.dart`. `SharedPreferences.setMockInitialValues`
// (vide à chaque test) pour `AnalyticsPreferencesController`
// (`core/analytics/analytics_preferences_provider.dart`, lu par la bascule
// "Partager mes données d'usage"), et `analyticsServiceProvider` overridé par
// un `_FakeAnalyticsService` pour observer `setEnabled` sans jamais toucher
// à un vrai SDK.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/analytics/analytics_preferences_provider.dart';
import 'package:personnages/core/analytics/analytics_service.dart';
import 'package:personnages/core/network/connectivity_checker.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/core/widgets/destructive_menu_tile.dart';
import 'package:personnages/core/widgets/settings_list_card.dart';
import 'package:personnages/features/auth/data/auth_repository.dart';
import 'package:personnages/features/auth/presentation/providers/auth_providers.dart';
import 'package:personnages/features/profile/data/data_export_repository.dart';
import 'package:personnages/features/profile/presentation/profile_delete_account_screen.dart';
import 'package:personnages/features/profile/presentation/profile_privacy_policy_screen.dart';
import 'package:personnages/features/profile/presentation/profile_privacy_screen.dart';
import 'package:personnages/features/profile/presentation/providers/data_export_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Enregistre les appels `setEnabled` reçus pour assertions — voir la doc de
/// classe d'`AnalyticsService` : "FakeAnalyticsService dans les tests si
/// besoin".
class _FakeAnalyticsService implements AnalyticsService {
  final List<bool> setEnabledCalls = [];

  @override
  bool get isInitialized => true;

  @override
  Future<void> trackEvent(
    String name, {
    Map<String, Object?> parameters = const {},
  }) async {}

  @override
  Future<void> trackScreen(String screenName) async {}

  @override
  Future<void> setEnabled(bool enabled) async {
    setEnabledCalls.add(enabled);
  }
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> signUp({
    required String email,
    required String password,
  }) async => false;

  @override
  Future<void> resetPasswordForEmail({required String email}) async {}

  @override
  Future<void> updateDisplayName({required String? displayName}) async {}

  @override
  Future<void> updatePassword({required String newPassword}) async {}

  @override
  Future<void> updateEmail({required String newEmail}) async {}

  @override
  Future<String> updateAvatar({required Uint8List bytes}) async => '';

  @override
  Future<void> removeAvatar() async {}
}

class _FakeDataExportRepository implements DataExportRepository {
  @override
  Future<String> exportMyData() async => '/tmp/export.json';
}

class _AlwaysOnlineConnectivityChecker implements ConnectivityChecker {
  @override
  Future<bool> hasConnection() async => true;

  @override
  Stream<bool> get onConnectivityRestored => const Stream.empty();
}

User _fakeUser() {
  return User(
    id: 'fake-user-id',
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    email: 'joueur@exemple.com',
    createdAt: '2026-01-01T00:00:00Z',
  );
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  AnalyticsService? analyticsService,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(_fakeUser()),
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        dataExportRepositoryProvider.overrideWithValue(
          _FakeDataExportRepository(),
        ),
        connectivityCheckerProvider.overrideWithValue(
          _AlwaysOnlineConnectivityChecker(),
        ),
        analyticsServiceProvider.overrideWithValue(
          analyticsService ?? const NoopAnalyticsService(),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => context.push('/profile/privacy'),
                    child: const Text('Ouvrir'),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/profile/privacy',
              builder: (context, state) => const ProfilePrivacyScreen(),
            ),
            GoRoute(
              path: '/profile/privacy/delete-account',
              builder: (context, state) => const ProfileDeleteAccountScreen(),
            ),
            GoRoute(
              path: '/profile/privacy/policy',
              builder: (context, state) => const ProfilePrivacyPolicyScreen(),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'affiche le bandeau bois "CONFIDENTIALITÉ", la section "MES DONNÉES" '
    '(3 tuiles avec leurs icônes dédiées, regroupées dans un '
    'SettingsListCard) et son texte d\'aide',
    (tester) async {
      await _pumpScreen(tester);

      expect(find.text('CONFIDENTIALITÉ'), findsOneWidget);
      expect(find.text('CONFIDENTIALITÉ ET DONNÉES'), findsNothing);
      expect(find.text('MES DONNÉES'), findsOneWidget);
      for (final label in const [
        'Exporter mes données',
        'Politique de confidentialité',
        "Autorisations de l'appareil",
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byIcon(Icons.download_outlined), findsOneWidget);
      expect(find.byIcon(Icons.description_outlined), findsOneWidget);
      expect(find.byIcon(Icons.admin_panel_settings_outlined), findsOneWidget);
      expect(find.byType(SettingsListCard), findsOneWidget);
      expect(
        find.text(
          "L'export contient tes personnages, leur inventaire, leurs "
          'sorts et leur historique (JSON, envoyé par e-mail).',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    '"Exporter mes données" et "Politique de confidentialité" gardent le '
    'chevron par défaut (actions internes), seule "Autorisations de '
    'l\'appareil" a l\'icône de lien externe (ouvre une sheet système)',
    (tester) async {
      await _pumpScreen(tester);

      // Scope au `SettingsListCard` : `DestructiveMenuTile` ("Supprimer mon
      // compte", plus bas) dessine lui aussi un `Icons.chevron_right`, mais
      // dans sa propre palette `accent.brick` — hors de la portée de ce test.
      final settingsCard = find.byType(SettingsListCard);
      expect(
        find.descendant(
          of: settingsCard,
          matching: find.byIcon(Icons.chevron_right),
        ),
        findsNWidgets(2),
      );
      expect(
        find.descendant(
          of: settingsCard,
          matching: find.byIcon(Icons.north_east),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('affiche "ZONE DANGEREUSE" et "Supprimer mon compte" est un '
      '`DestructiveMenuTile` isolé, pas une tuile de `SettingsListCard`', (
    tester,
  ) async {
    await _pumpScreen(tester);

    expect(find.text('ZONE DANGEREUSE'), findsOneWidget);
    expect(
      find.widgetWithText(DestructiveMenuTile, 'Supprimer mon compte'),
      findsOneWidget,
    );
    // Une seule carte `SettingsListCard` (celle de "MES DONNÉES") :
    // "Supprimer mon compte" n'en fait pas partie.
    expect(find.byType(SettingsListCard), findsOneWidget);
  });

  testWidgets('taper "Exporter mes données" ouvre la sheet éponyme', (
    tester,
  ) async {
    await _pumpScreen(tester);

    await tester.tap(find.text('Exporter mes données'));
    await tester.pumpAndSettle();

    expect(find.text('EXPORT DE MES DONNÉES'), findsOneWidget);
  });

  testWidgets('taper "Politique de confidentialité" pousse l\'écran dédié '
      '(/profile/privacy/policy)', (tester) async {
    await _pumpScreen(tester);

    await tester.tap(find.text('Politique de confidentialité'));
    await tester.pumpAndSettle();

    expect(find.text('POLITIQUE DE CONFIDENTIALITÉ'), findsOneWidget);
    expect(find.byType(ProfilePrivacyPolicyScreen), findsOneWidget);
  });

  testWidgets('taper "Autorisations de l\'appareil" ouvre la sheet éponyme', (
    tester,
  ) async {
    await _pumpScreen(tester);

    await tester.tap(find.text("Autorisations de l'appareil"));
    await tester.pumpAndSettle();

    expect(find.text('GESTION DES AUTORISATIONS APPAREIL'), findsOneWidget);
  });

  testWidgets('taper "Supprimer mon compte" pousse l\'écran dédié '
      '(/profile/privacy/delete-account), pas une sheet', (tester) async {
    await _pumpScreen(tester);

    await tester.tap(find.text('Supprimer mon compte'));
    await tester.pumpAndSettle();

    expect(find.text('SUPPRIMER LE COMPTE'), findsOneWidget);
    expect(find.byType(ProfileDeleteAccountScreen), findsOneWidget);
  });

  testWidgets('le bandeau bois propose un retour fonctionnel', (tester) async {
    await _pumpScreen(tester);
    expect(find.text('Ouvrir'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    expect(find.text('Ouvrir'), findsOneWidget);
  });

  group('bascule "Partager mes données d\'usage" (core/analytics/)', () {
    testWidgets(
      'affiche la rangée bascule, activée par défaut (rien de persisté)',
      (tester) async {
        await _pumpScreen(tester);

        expect(find.text("Partager mes données d'usage"), findsOneWidget);
        expect(
          find.text(
            "Statistiques d'utilisation anonymes, pour améliorer l'app. "
            'Désactivable à tout moment.',
          ),
          findsOneWidget,
        );
        final switchWidget = tester.widget<Switch>(find.byType(Switch));
        expect(switchWidget.value, isTrue);
      },
    );

    testWidgets('taper la bascule la désactive immédiatement et appelle '
        'AnalyticsService.setEnabled(false)', (tester) async {
      final fakeAnalyticsService = _FakeAnalyticsService();
      await _pumpScreen(tester, analyticsService: fakeAnalyticsService);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isFalse);
      expect(fakeAnalyticsService.setEnabledCalls, [false]);
    });

    testWidgets(
      'une préférence déjà désactivée en SharedPreferences est reflétée à '
      "l'ouverture de l'écran",
      (tester) async {
        SharedPreferences.setMockInitialValues({
          analyticsEnabledPrefsKey: false,
        });

        await _pumpScreen(tester);

        final switchWidget = tester.widget<Switch>(find.byType(Switch));
        expect(switchWidget.value, isFalse);
      },
    );
  });
}
