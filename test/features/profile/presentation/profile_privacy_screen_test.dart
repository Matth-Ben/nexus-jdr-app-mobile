// Tests de widget de l'écran "Confidentialité et données"
// (`presentation/profile_privacy_screen.dart`) — bandeau bois + retour, les
// 3 tuiles (icônes dédiées, ouverture de la bonne sheet/SnackBar), le bouton
// destructif isolé "Supprimer mon compte" (ouvre sa sheet, jamais une simple
// tuile).
//
// Aucune donnée à charger (écran 100% synchrone) : `currentUserProvider`
// tout de même overridé (`authRepositoryProvider`/`connectivityCheckerProvider`
// aussi) car `showDeleteAccountSheet` en dépend dès l'ouverture de l'écran —
// même stratégie que `profile_screen_test.dart`.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/network/connectivity_checker.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/core/widgets/destructive_button.dart';
import 'package:personnages/features/auth/data/auth_repository.dart';
import 'package:personnages/features/auth/presentation/providers/auth_providers.dart';
import 'package:personnages/features/profile/data/data_export_repository.dart';
import 'package:personnages/features/profile/presentation/profile_privacy_screen.dart';
import 'package:personnages/features/profile/presentation/providers/data_export_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  Future<void> signUp({
    required String email,
    required String password,
  }) async {}

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

Future<void> _pumpScreen(WidgetTester tester) async {
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
          ],
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('affiche le bandeau bois et les 3 tuiles avec leurs icônes '
      'dédiées', (tester) async {
    await _pumpScreen(tester);

    expect(find.text('CONFIDENTIALITÉ ET DONNÉES'), findsOneWidget);
    for (final label in const [
      'Export de mes données',
      'Politique de confidentialité',
      'Gestion des autorisations appareil',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byIcon(Icons.download_outlined), findsOneWidget);
    expect(find.byIcon(Icons.description_outlined), findsOneWidget);
    expect(find.byIcon(Icons.admin_panel_settings_outlined), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(3));
  });

  testWidgets(
    '"Supprimer mon compte" est un `DestructiveButton` isolé, pas une '
    'tuile',
    (tester) async {
      await _pumpScreen(tester);

      expect(
        find.widgetWithText(DestructiveButton, 'Supprimer mon compte'),
        findsOneWidget,
      );
    },
  );

  testWidgets('taper "Export de mes données" ouvre la sheet éponyme', (
    tester,
  ) async {
    await _pumpScreen(tester);

    await tester.tap(find.text('Export de mes données'));
    await tester.pumpAndSettle();

    expect(find.text('EXPORT DE MES DONNÉES'), findsOneWidget);
  });

  testWidgets(
    'taper "Politique de confidentialité" affiche le SnackBar "Bientôt '
    'disponible"',
    (tester) async {
      await _pumpScreen(tester);

      await tester.tap(find.text('Politique de confidentialité'));
      await tester.pumpAndSettle();

      expect(find.text('Bientôt disponible'), findsOneWidget);
    },
  );

  testWidgets(
    'taper "Gestion des autorisations appareil" ouvre la sheet éponyme',
    (tester) async {
      await _pumpScreen(tester);

      await tester.tap(find.text('Gestion des autorisations appareil'));
      await tester.pumpAndSettle();

      expect(find.text('GESTION DES AUTORISATIONS APPAREIL'), findsOneWidget);
    },
  );

  testWidgets('taper "Supprimer mon compte" ouvre la sheet de suppression', (
    tester,
  ) async {
    await _pumpScreen(tester);

    await tester.tap(find.text('Supprimer mon compte'));
    await tester.pumpAndSettle();

    expect(find.text('SUPPRIMER MON COMPTE'), findsOneWidget);
  });

  testWidgets('le bandeau bois propose un retour fonctionnel', (tester) async {
    await _pumpScreen(tester);
    expect(find.text('Ouvrir'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    expect(find.text('Ouvrir'), findsOneWidget);
  });
}
