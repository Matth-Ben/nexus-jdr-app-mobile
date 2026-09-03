// Tests de widget de l'écran "Profil" (`presentation/profile_screen.dart`) —
// avatar/nom/e-mail (fallback "Aventurier" quand `user_metadata['full_name']`
// est absent/vide), bandeau "Compte lié à l'app Histoires", les 4 lignes de
// menu (navigation vers la sheet "Modifier le profil", `SnackBar` "Bientôt
// disponible" pour les 3 autres), bouton "Se déconnecter", pied de page
// version.
//
// `currentUserProvider`/`authRepositoryProvider` injectés via
// `overrideWithValue`, jamais `Supabase.instance.client` — même stratégie que
// `character_list_screen_test.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:personnages/core/network/connectivity_checker.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/features/auth/data/auth_repository.dart';
import 'package:personnages/features/auth/presentation/providers/auth_providers.dart';
import 'package:personnages/features/profile/presentation/profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeAuthRepository implements AuthRepository {
  int signOutCallCount = 0;

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signUp({required String email, required String password}) async {}

  @override
  Future<void> signOut() async {
    signOutCallCount++;
  }

  @override
  Future<void> resetPasswordForEmail({required String email}) async {}

  @override
  Future<void> updateDisplayName({required String? displayName}) async {}
}

class _AlwaysOnlineConnectivityChecker implements ConnectivityChecker {
  @override
  Future<bool> hasConnection() async => true;

  @override
  Stream<bool> get onConnectivityRestored => const Stream.empty();
}

User _fakeUser({String? fullName, String email = 'joueur@exemple.com'}) {
  return User(
    id: 'fake-user-id',
    appMetadata: const {},
    userMetadata: fullName == null ? const {} : {'full_name': fullName},
    aud: 'authenticated',
    email: email,
    createdAt: '2026-01-01T00:00:00Z',
  );
}

void main() {
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'Nexus JDR — Personnages',
      packageName: 'app.nexusjdr.personnages',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  late _FakeAuthRepository fakeAuthRepository;

  setUp(() {
    fakeAuthRepository = _FakeAuthRepository();
  });

  Widget buildTestWidget({required User? user}) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(user),
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
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
                    onPressed: () => context.push('/profile'),
                    child: const Text('Ouvrir le profil'),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> pumpProfile(WidgetTester tester, {required User? user}) async {
    await tester.pumpWidget(buildTestWidget(user: user));
    await tester.tap(find.text('Ouvrir le profil'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'affiche le nom (`user_metadata[\'full_name\']`) et l\'e-mail de '
    '`currentUserProvider`',
    (tester) async {
      await pumpProfile(
        tester,
        user: _fakeUser(
          fullName: 'Aranea Nightsong',
          email: 'aranea@exemple.com',
        ),
      );

      expect(find.text('PROFIL'), findsOneWidget);
      expect(find.text('Aranea Nightsong'), findsOneWidget);
      expect(find.text('aranea@exemple.com'), findsOneWidget);
    },
  );

  testWidgets(
    'affiche "Aventurier" quand `full_name` est absent — fallback '
    "d'affichage uniquement, jamais une valeur stockée",
    (tester) async {
      await pumpProfile(tester, user: _fakeUser());

      expect(find.text('Aventurier'), findsOneWidget);
    },
  );

  testWidgets(
    'affiche "Aventurier" quand `full_name` est une chaîne blanche',
    (tester) async {
      await pumpProfile(tester, user: _fakeUser(fullName: '   '));

      expect(find.text('Aventurier'), findsOneWidget);
    },
  );

  testWidgets('affiche le bandeau "Compte lié à l\'app Histoires"', (
    tester,
  ) async {
    await pumpProfile(tester, user: _fakeUser());

    expect(find.text("Compte lié à l'app Histoires"), findsOneWidget);
  });

  testWidgets(
    'affiche les 4 lignes de menu avec leurs icônes dédiées',
    (tester) async {
      await pumpProfile(tester, user: _fakeUser());

      for (final label in const [
        'Modifier le profil',
        'Notifications',
        'Confidentialité et données',
        'Aide et support',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none), findsOneWidget);
      expect(find.byIcon(Icons.privacy_tip_outlined), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(4));
    },
  );

  testWidgets(
    'taper "Modifier le profil" ouvre la sheet "MODIFIER LE PROFIL"',
    (tester) async {
      await pumpProfile(tester, user: _fakeUser(fullName: 'Aranea'));

      await tester.tap(find.text('Modifier le profil'));
      await tester.pumpAndSettle();

      expect(find.text('MODIFIER LE PROFIL'), findsOneWidget);
    },
  );

  for (final label in const [
    'Notifications',
    'Confidentialité et données',
    'Aide et support',
  ]) {
    testWidgets(
      'taper "$label" affiche le SnackBar "Bientôt disponible"',
      (tester) async {
        await pumpProfile(tester, user: _fakeUser());

        await tester.tap(find.text(label));
        await tester.pumpAndSettle();

        expect(find.text('Bientôt disponible'), findsOneWidget);
      },
    );
  }

  testWidgets(
    'le bouton "Se déconnecter" appelle `AuthRepository.signOut`',
    (tester) async {
      await pumpProfile(tester, user: _fakeUser());

      // Le contenu scrollable dépasse la hauteur du viewport de test :
      // s'assure que le bouton (en bas de la liste) est bien visible avant
      // de taper dessus.
      await tester.ensureVisible(find.text('Se déconnecter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Se déconnecter'));
      await tester.pumpAndSettle();

      expect(fakeAuthRepository.signOutCallCount, 1);
    },
  );

  testWidgets('le bandeau bois "PROFIL" propose un retour fonctionnel', (
    tester,
  ) async {
    await pumpProfile(tester, user: _fakeUser());
    expect(find.text('Ouvrir le profil'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    expect(find.text('Ouvrir le profil'), findsOneWidget);
  });

  testWidgets(
    'le pied de page affiche la version lue dynamiquement '
    '(`package_info_plus`, mockée ici via `setMockInitialValues`)',
    (tester) async {
      await pumpProfile(tester, user: _fakeUser());

      await tester.ensureVisible(
        find.text('Nexus JDR — Personnages · v1.0.0'),
      );
      expect(
        find.text('Nexus JDR — Personnages · v1.0.0'),
        findsOneWidget,
      );
    },
  );
}
