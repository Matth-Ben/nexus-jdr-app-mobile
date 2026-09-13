// Tests de widget du sous-écran "Modifier le profil"
// (`presentation/profile_edit_screen.dart`) — refonte du 13/09/2026
// (recettage direction-artistique) : édition directe/inline plutôt que 4
// lignes résumé + sheet, voir la documentation de classe de
// `ProfileEditScreen`.
//
// - Avatar centré + 2 liens "Prendre une photo"/"Choisir dans la galerie",
//   les deux ouvrent `showAvatarEditSheet`.
// - Champ "Pseudo" inline, prérempli, piloté par un bouton "Enregistrer" en
//   bas d'écran (désactivé si inchangé/vide) — logique de sauvegarde reprise
//   de `edit_display_name_sheet_test.dart` (même double `_FakeAuthRepository`
//   à `gate`/`errorToThrow`, mêmes scénarios réseau).
// - Champ "E-mail" visuellement désactivé, tap ouvre `showChangeEmailSheet`.
// - Ligne "Changer le mot de passe", tap ouvre `showChangePasswordSheet`.
//
// `currentUserProvider`/`authRepositoryProvider`/`connectivityCheckerProvider`
// injectés via `overrideWithValue`, jamais `Supabase.instance.client` — même
// stratégie que `profile_screen_test.dart`.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/network/connectivity_checker.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/profile_avatar.dart';
import 'package:personnages/features/auth/data/auth_repository.dart';
import 'package:personnages/features/auth/domain/auth_failure.dart';
import 'package:personnages/features/auth/presentation/providers/auth_providers.dart';
import 'package:personnages/features/profile/presentation/profile_edit_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeAuthRepository implements AuthRepository {
  final Completer<void> gate = Completer<void>();
  bool gateUpdateDisplayName = false;

  int updateDisplayNameCallCount = 0;
  String? lastDisplayName;
  Object? errorToThrow;

  @override
  Future<void> updateDisplayName({required String? displayName}) async {
    updateDisplayNameCallCount++;
    lastDisplayName = displayName;
    if (gateUpdateDisplayName) await gate.future;
    final error = errorToThrow;
    if (error != null) throw error;
  }

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
  Future<void> updatePassword({required String newPassword}) async {}

  @override
  Future<void> updateEmail({required String newEmail}) async {}

  @override
  Future<String> updateAvatar({required Uint8List bytes}) async => '';

  @override
  Future<void> removeAvatar() async {}
}

class _FakeConnectivityChecker implements ConnectivityChecker {
  _FakeConnectivityChecker({required this.connected});

  final bool connected;

  @override
  Future<bool> hasConnection() async => connected;

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

Future<_FakeAuthRepository> _pumpScreen(
  WidgetTester tester, {
  required User? user,
  bool connected = true,
}) async {
  final repository = _FakeAuthRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(user),
        authRepositoryProvider.overrideWithValue(repository),
        connectivityCheckerProvider.overrideWithValue(
          _FakeConnectivityChecker(connected: connected),
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
  return repository;
}

void main() {
  testWidgets('affiche le bandeau bois "MODIFIER LE PROFIL"', (tester) async {
    await _pumpScreen(tester, user: _fakeUser());

    expect(find.text('MODIFIER LE PROFIL'), findsOneWidget);
  });

  group('Avatar', () {
    testWidgets(
      'affiche les 2 liens "Prendre une photo"/"Choisir dans la galerie"',
      (tester) async {
        await _pumpScreen(tester, user: _fakeUser());

        expect(find.text('Prendre une photo'), findsOneWidget);
        expect(find.text('Choisir dans la galerie'), findsOneWidget);
      },
    );

    testWidgets(
      'taper "Prendre une photo" ouvre le sheet de choix caméra/galerie',
      (tester) async {
        await _pumpScreen(tester, user: _fakeUser());

        await tester.tap(find.text('Prendre une photo'));
        await tester.pumpAndSettle();

        // `Icons.photo_camera_outlined` n'existe que dans les lignes du
        // sheet (`avatar_edit_sheet.dart`), jamais sur cet écran (badge
        // caméra en `Icons.photo_camera` plein) : preuve non ambiguë que le
        // sheet est bien ouvert, malgré le libellé partagé avec le lien de
        // l'écran resté affiché en arrière-plan.
        expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
        expect(find.text('Choisir dans la galerie'), findsNWidgets(2));
      },
    );

    testWidgets(
      'taper "Choisir dans la galerie" ouvre le même sheet de choix',
      (tester) async {
        await _pumpScreen(tester, user: _fakeUser());

        await tester.tap(find.text('Choisir dans la galerie'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
        expect(find.text('Retirer la photo'), findsNothing);
      },
    );

    testWidgets(
      'taper l\'avatar lui-même ouvre aussi le sheet, avec "Retirer la '
      'photo" si un avatar est déjà défini',
      (tester) async {
        await _pumpScreen(
          tester,
          user: _fakeUser(avatarUrl: 'https://exemple.com/avatar.png'),
        );

        await tester.tap(find.byType(ProfileAvatar));
        await tester.pumpAndSettle();

        expect(find.text('Retirer la photo'), findsOneWidget);
      },
    );
  });

  group('Pseudo', () {
    testWidgets('préremplit le champ depuis `full_name`, pas le repli '
        '"Aventurier"', (tester) async {
      await _pumpScreen(tester, user: _fakeUser(fullName: 'Aranea'));

      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(field.controller!.text, 'Aranea');
      expect(find.text('Aventurier'), findsNothing);
    });

    testWidgets('champ vide quand `full_name` est absent', (tester) async {
      await _pumpScreen(tester, user: _fakeUser());

      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(field.controller!.text, isEmpty);
    });

    testWidgets('"Enregistrer" désactivé tant que le pseudo est inchangé', (
      tester,
    ) async {
      await _pumpScreen(tester, user: _fakeUser(fullName: 'Aranea'));

      final button = tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'ENREGISTRER'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('"Enregistrer" désactivé tant que le pseudo saisi est vide', (
      tester,
    ) async {
      await _pumpScreen(tester, user: _fakeUser(fullName: 'Aranea'));

      await tester.enterText(find.byType(TextFormField), '   ');
      await tester.pump();

      final button = tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'ENREGISTRER'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets(
      '"Enregistrer" activé dès que le pseudo saisi diffère et n\'est pas '
      'vide',
      (tester) async {
        await _pumpScreen(tester, user: _fakeUser(fullName: 'Aranea'));

        await tester.enterText(find.byType(TextFormField), 'Nouveau nom');
        await tester.pump();

        final button = tester.widget<PrimaryButton>(
          find.widgetWithText(PrimaryButton, 'ENREGISTRER'),
        );
        expect(button.onPressed, isNotNull);
      },
    );

    testWidgets(
      '"Enregistrer" : envoie la valeur trimée, affiche le SnackBar de '
      'confirmation, se redésactive ensuite',
      (tester) async {
        final repository = await _pumpScreen(
          tester,
          user: _fakeUser(fullName: 'Aranea'),
        );

        await tester.enterText(find.byType(TextFormField), '  Nouveau nom  ');
        await tester.pump();
        await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
        await tester.pumpAndSettle();

        expect(repository.updateDisplayNameCallCount, 1);
        expect(repository.lastDisplayName, 'Nouveau nom');
        expect(find.text('Pseudo mis à jour.'), findsOneWidget);

        final button = tester.widget<PrimaryButton>(
          find.widgetWithText(PrimaryButton, 'ENREGISTRER'),
        );
        expect(
          button.onPressed,
          isNull,
          reason:
              'redevient désactivé, le pseudo enregistré est la '
              'nouvelle référence',
        );
      },
    );

    testWidgets(
      'pendant la sauvegarde : "Enregistrer" en isLoading, champ pseudo '
      'désactivé',
      (tester) async {
        final repository = await _pumpScreen(
          tester,
          user: _fakeUser(fullName: 'Aranea'),
        );
        repository.gateUpdateDisplayName = true;

        await tester.enterText(find.byType(TextFormField), 'Nouveau nom');
        await tester.pump();
        await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
        await tester.pump();

        // Plus de `Text('ENREGISTRER')` pendant `isLoading` (remplacé par le
        // spinner) : `find.widgetWithText` ne le trouverait plus, on
        // retrouve le bouton par type (seul `PrimaryButton` de cet écran).
        final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
        expect(button.isLoading, isTrue);

        final field = tester.widget<TextFormField>(find.byType(TextFormField));
        expect(field.enabled, isFalse);

        repository.gate.complete();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'aucune connexion réseau : bandeau hors-ligne honnête, aucun appel '
      'réseau tenté, texte saisi préservé',
      (tester) async {
        final repository = await _pumpScreen(
          tester,
          user: _fakeUser(fullName: 'Aranea'),
          connected: false,
        );

        await tester.enterText(
          find.byType(TextFormField),
          'Pas encore enregistré',
        );
        await tester.pump();
        await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining("n'a pas pu être enregistrée"),
          findsOneWidget,
        );
        expect(repository.updateDisplayNameCallCount, 0);
        expect(
          tester
              .widget<TextFormField>(find.byType(TextFormField))
              .controller!
              .text,
          'Pas encore enregistré',
        );
      },
    );

    testWidgets(
      'AuthFailure : bandeau d\'alerte inline affiche `failure.message`',
      (tester) async {
        final repository = await _pumpScreen(
          tester,
          user: _fakeUser(fullName: 'Aranea'),
        );
        repository.errorToThrow = const AuthFailure('Erreur serveur.');

        await tester.enterText(find.byType(TextFormField), 'Nouveau nom');
        await tester.pump();
        await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
        await tester.pumpAndSettle();

        expect(find.text('Erreur serveur.'), findsOneWidget);
      },
    );

    testWidgets('échec inattendu (pas une AuthFailure) : bandeau générique', (
      tester,
    ) async {
      final repository = await _pumpScreen(
        tester,
        user: _fakeUser(fullName: 'Aranea'),
      );
      repository.errorToThrow = Exception('boom');

      await tester.enterText(find.byType(TextFormField), 'Nouveau nom');
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(
        find.text("Impossible d'enregistrer les modifications. Réessayez."),
        findsOneWidget,
      );
    });
  });

  group('E-mail', () {
    testWidgets('affiche l\'adresse courante dans un champ non éditable', (
      tester,
    ) async {
      await _pumpScreen(tester, user: _fakeUser(email: 'aranea@exemple.com'));

      expect(find.text('E-mail'), findsOneWidget);
      expect(find.text('aranea@exemple.com'), findsOneWidget);
      // Aucun `TextFormField` pour ce champ : seul celui du pseudo existe.
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('affiche le texte d\'aide sur le lien de confirmation', (
      tester,
    ) async {
      await _pumpScreen(tester, user: _fakeUser());

      expect(
        find.text(
          "Modifier l'e-mail envoie un lien de confirmation à la nouvelle "
          'adresse.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('taper le champ ouvre la sheet "ADRESSE EMAIL"', (
      tester,
    ) async {
      await _pumpScreen(tester, user: _fakeUser(email: 'aranea@exemple.com'));

      await tester.tap(find.text('aranea@exemple.com'));
      await tester.pumpAndSettle();

      expect(find.text('ADRESSE EMAIL'), findsOneWidget);
    });
  });

  group('Mot de passe', () {
    testWidgets('affiche la ligne "Changer le mot de passe"', (tester) async {
      await _pumpScreen(tester, user: _fakeUser());

      expect(find.text('Changer le mot de passe'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('taper la ligne ouvre la sheet "MOT DE PASSE"', (tester) async {
      await _pumpScreen(tester, user: _fakeUser());

      await tester.tap(find.text('Changer le mot de passe'));
      await tester.pumpAndSettle();

      expect(find.text('MOT DE PASSE'), findsOneWidget);
    });
  });

  testWidgets('le bandeau bois propose un retour fonctionnel', (tester) async {
    await _pumpScreen(tester, user: _fakeUser());
    expect(find.text('Ouvrir'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    expect(find.text('Ouvrir'), findsOneWidget);
  });
}
