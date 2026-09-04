// Tests de widget du sous-écran "Modifier le profil"
// (`presentation/profile_edit_screen.dart`) — les 4 lignes affichent la
// bonne valeur/le bon fallback depuis `currentUserProvider`, chaque ligne
// ouvre la bonne sheet au tap, bandeau bois avec retour fonctionnel.
//
// `currentUserProvider`/`authRepositoryProvider` injectés via
// `overrideWithValue`, jamais `Supabase.instance.client` — même stratégie
// que `profile_screen_test.dart`.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/network/connectivity_checker.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/features/auth/data/auth_repository.dart';
import 'package:personnages/features/auth/presentation/providers/auth_providers.dart';
import 'package:personnages/features/profile/presentation/profile_edit_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signUp({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}

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

class _AlwaysOnlineConnectivityChecker implements ConnectivityChecker {
  @override
  Future<bool> hasConnection() async => true;

  @override
  Stream<bool> get onConnectivityRestored => const Stream.empty();
}

User _fakeUser({
  String? fullName,
  String? avatarUrl,
  String email = 'joueur@exemple.com',
}) {
  return User(
    id: 'fake-user-id',
    appMetadata: const {},
    userMetadata: {'full_name': ?fullName, 'avatar_url': ?avatarUrl},
    aud: 'authenticated',
    email: email,
    createdAt: '2026-01-01T00:00:00Z',
  );
}

Future<void> _pumpScreen(WidgetTester tester, {required User? user}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(user),
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
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
                    onPressed: () => context.push('/profile/edit'),
                    child: const Text('Ouvrir'),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/profile/edit',
              builder: (context, state) => const ProfileEditScreen(),
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
  testWidgets('affiche le bandeau bois "MODIFIER LE PROFIL"', (tester) async {
    await _pumpScreen(tester, user: _fakeUser());

    expect(find.text('MODIFIER LE PROFIL'), findsOneWidget);
  });

  testWidgets(
    'ligne "Pseudo" : affiche le pseudo courant, ou "Aventurier" si vide '
    '(même fallback que `profile_screen.dart`)',
    (tester) async {
      await _pumpScreen(tester, user: _fakeUser(fullName: 'Aranea'));
      expect(find.text('Pseudo'), findsOneWidget);
      expect(find.text('Aranea'), findsOneWidget);
    },
  );

  testWidgets('ligne "Pseudo" : "Aventurier" quand `full_name` est absent', (
    tester,
  ) async {
    await _pumpScreen(tester, user: _fakeUser());
    expect(find.text('Aventurier'), findsOneWidget);
  });

  testWidgets(
    'ligne "Avatar" : "Aucune photo" sans `avatar_url`, "Photo définie" '
    'sinon',
    (tester) async {
      await _pumpScreen(tester, user: _fakeUser());
      expect(find.text('Avatar'), findsOneWidget);
      expect(find.text('Aucune photo'), findsOneWidget);

      await _pumpScreen(
        tester,
        user: _fakeUser(avatarUrl: 'https://exemple.com/avatar.png'),
      );
      expect(find.text('Photo définie'), findsOneWidget);
    },
  );

  testWidgets(
    'ligne "Mot de passe" : valeur fixe masquée, jamais le vrai mot de '
    'passe',
    (tester) async {
      await _pumpScreen(tester, user: _fakeUser());
      expect(find.text('Mot de passe'), findsOneWidget);
      expect(find.text('••••••••'), findsOneWidget);
    },
  );

  testWidgets('ligne "Email" : affiche l\'adresse courante', (tester) async {
    await _pumpScreen(tester, user: _fakeUser(email: 'aranea@exemple.com'));
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('aranea@exemple.com'), findsOneWidget);
  });

  testWidgets('taper "Pseudo" ouvre la sheet "PSEUDO"', (tester) async {
    await _pumpScreen(tester, user: _fakeUser());

    await tester.tap(find.text('Pseudo'));
    await tester.pumpAndSettle();

    expect(find.text('PSEUDO'), findsOneWidget);
  });

  testWidgets('taper "Avatar" ouvre le sheet de choix de source', (
    tester,
  ) async {
    await _pumpScreen(tester, user: _fakeUser());

    await tester.tap(find.text('Avatar'));
    await tester.pumpAndSettle();

    expect(find.text('Prendre une photo'), findsOneWidget);
    expect(find.text('Choisir dans la galerie'), findsOneWidget);
    expect(
      find.text('Retirer la photo'),
      findsNothing,
      reason: 'sans avatar déjà défini, pas d\'option de suppression',
    );
  });

  testWidgets(
    'taper "Avatar" avec un avatar déjà défini propose "Retirer la photo"',
    (tester) async {
      await _pumpScreen(
        tester,
        user: _fakeUser(avatarUrl: 'https://exemple.com/avatar.png'),
      );

      await tester.tap(find.text('Avatar'));
      await tester.pumpAndSettle();

      expect(find.text('Retirer la photo'), findsOneWidget);
    },
  );

  testWidgets('taper "Mot de passe" ouvre la sheet "MOT DE PASSE"', (
    tester,
  ) async {
    await _pumpScreen(tester, user: _fakeUser());

    await tester.tap(find.text('Mot de passe'));
    await tester.pumpAndSettle();

    expect(find.text('MOT DE PASSE'), findsOneWidget);
  });

  testWidgets('taper "Email" ouvre la sheet "ADRESSE EMAIL"', (tester) async {
    await _pumpScreen(tester, user: _fakeUser());

    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();

    expect(find.text('ADRESSE EMAIL'), findsOneWidget);
  });

  testWidgets('le bandeau bois propose un retour fonctionnel', (tester) async {
    await _pumpScreen(tester, user: _fakeUser());
    expect(find.text('Ouvrir'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    expect(find.text('Ouvrir'), findsOneWidget);
  });
}
