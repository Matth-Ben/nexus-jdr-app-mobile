// Tests de widget de l'écran dédié "Supprimer le compte"
// (`presentation/profile_delete_account_screen.dart`) — remplace
// `delete_account_sheet_test.dart` (l'ancienne bottom sheet à 2 étapes a été
// retirée, voir la doc de classe de `ProfileDeleteAccountScreen`) : affichage
// de tous les éléments de l'écran plein (bandeau bois, bandeau "ACTION
// IRRÉVERSIBLE", liste "CE QUI SERA SUPPRIMÉ", case à cocher, champ mot de
// passe, boutons empilés), activation du bouton "SUPPRIMER DÉFINITIVEMENT"
// conditionnée à la case cochée ET au mot de passe non vide, soumission
// réussie (vérifie -> supprime -> déconnecte, dans cet ordre), mot de passe
// incorrect (erreur inline, aucune suppression tentée), hors-ligne, échec de
// `deleteAccount`, verrouillage pendant l'appel réseau — mêmes scénarios que
// l'ancienne sheet, adaptés à un écran routé (`go_router`) plutôt qu'à une
// sheet modale.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/network/connectivity_checker.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/core/widgets/destructive_button.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/features/auth/data/auth_repository.dart';
import 'package:personnages/features/auth/domain/auth_failure.dart';
import 'package:personnages/features/auth/presentation/providers/auth_providers.dart';
import 'package:personnages/features/profile/presentation/profile_delete_account_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeAuthRepository implements AuthRepository {
  final Completer<void> deleteGate = Completer<void>();
  bool gateDeleteAccount = false;

  int signInCallCount = 0;
  String? lastEmail;
  String? lastPassword;
  Object? signInErrorToThrow;

  int deleteAccountCallCount = 0;
  Object? deleteAccountErrorToThrow;

  int signOutCallCount = 0;

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    signInCallCount++;
    lastEmail = email;
    lastPassword = password;
    final error = signInErrorToThrow;
    if (error != null) throw error;
  }

  @override
  Future<void> deleteAccount() async {
    deleteAccountCallCount++;
    if (gateDeleteAccount) await deleteGate.future;
    final error = deleteAccountErrorToThrow;
    if (error != null) throw error;
  }

  @override
  Future<void> signOut() async {
    signOutCallCount++;
  }

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

class _FakeConnectivityChecker implements ConnectivityChecker {
  _FakeConnectivityChecker({required this.connected});

  final bool connected;

  @override
  Future<bool> hasConnection() async => connected;

  @override
  Stream<bool> get onConnectivityRestored => const Stream.empty();
}

User _fakeUser({String email = 'joueur@exemple.com'}) {
  return User(
    id: 'fake-user-id',
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    email: email,
    createdAt: '2026-01-01T00:00:00Z',
  );
}

Future<_FakeAuthRepository> _pumpScreen(
  WidgetTester tester, {
  bool connected = true,
  String email = 'joueur@exemple.com',
}) async {
  final repository = _FakeAuthRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        currentUserProvider.overrideWithValue(_fakeUser(email: email)),
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
                    onPressed: () =>
                        context.push('/profile/privacy/delete-account'),
                    child: const Text('Ouvrir'),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/profile/privacy/delete-account',
              builder: (context, state) => const ProfileDeleteAccountScreen(),
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

Finder get _submitButton =>
    find.widgetWithText(DestructiveButton, 'SUPPRIMER DÉFINITIVEMENT');

Future<void> _checkConfirmationBox(WidgetTester tester) async {
  final finder = find.textContaining(
    'Je comprends que cette action est définitive',
  );
  // La case de confirmation peut être hors du viewport initial du corps
  // scrollable (contenu > hauteur d'écran de test) : la ramène en vue avant
  // de taper dessus, sinon le point tapé pourrait tomber sur un tout autre
  // widget (ex. le bouton fixe en bas d'écran).
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  testWidgets('affiche tous les éléments de l\'écran', (tester) async {
    await _pumpScreen(tester);

    expect(find.text('SUPPRIMER LE COMPTE'), findsOneWidget);
    expect(find.text('ACTION IRRÉVERSIBLE'), findsOneWidget);
    expect(
      find.textContaining('Cette action est irréversible'),
      findsOneWidget,
    );
    expect(find.text('CE QUI SERA SUPPRIMÉ'), findsOneWidget);
    expect(find.text('Tous tes personnages et leurs fiches'), findsOneWidget);
    expect(find.text('Ton accès aux histoires partagées'), findsOneWidget);
    expect(find.text('Ton profil et tes préférences'), findsOneWidget);
    expect(
      find.textContaining('Je comprends que cette action est définitive'),
      findsOneWidget,
    );
    expect(find.byType(TextFormField), findsOneWidget);
    expect(_submitButton, findsOneWidget);
    expect(find.widgetWithText(SecondaryButton, 'ANNULER'), findsOneWidget);
  });

  testWidgets(
    '"SUPPRIMER DÉFINITIVEMENT" reste désactivé tant que la case n\'est '
    'pas cochée ou que le mot de passe est vide, activé une fois les deux '
    'réunis',
    (tester) async {
      await _pumpScreen(tester);

      // Ni la case ni le mot de passe ne sont fournis.
      expect(tester.widget<DestructiveButton>(_submitButton).onPressed, isNull);

      // Mot de passe seul : toujours désactivé.
      await tester.enterText(find.byType(TextFormField), 'bon-mdp-1234');
      await tester.pump();
      expect(tester.widget<DestructiveButton>(_submitButton).onPressed, isNull);

      // Case seule (mot de passe effacé) : toujours désactivé.
      await tester.enterText(find.byType(TextFormField), '');
      await tester.pump();
      await _checkConfirmationBox(tester);
      expect(tester.widget<DestructiveButton>(_submitButton).onPressed, isNull);

      // Les deux réunis : activé.
      await tester.enterText(find.byType(TextFormField), 'bon-mdp-1234');
      await tester.pump();
      expect(
        tester.widget<DestructiveButton>(_submitButton).onPressed,
        isNotNull,
      );
    },
  );

  testWidgets('mot de passe incorrect -> erreur inline sous le champ, aucune '
      'suppression tentée', (tester) async {
    final repository = await _pumpScreen(tester);
    repository.signInErrorToThrow = const AuthFailure(
      'Adresse e-mail ou mot de passe incorrect.',
    );
    await _checkConfirmationBox(tester);
    await tester.enterText(find.byType(TextFormField), 'mauvais-mdp');
    await tester.pump();

    await tester.tap(_submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Mot de passe incorrect.'), findsOneWidget);
    expect(repository.signInCallCount, 1);
    expect(repository.lastEmail, 'joueur@exemple.com');
    expect(repository.lastPassword, 'mauvais-mdp');
    expect(
      repository.deleteAccountCallCount,
      0,
      reason:
          'un mot de passe incorrect ne doit jamais déclencher la '
          'suppression',
    );
    expect(repository.signOutCallCount, 0);
    // L'écran reste affiché.
    expect(find.text('SUPPRIMER LE COMPTE'), findsOneWidget);
  });

  testWidgets('mot de passe correct -> vérifie puis supprime le compte puis '
      'déconnecte, dans cet ordre', (tester) async {
    final repository = await _pumpScreen(tester);
    await _checkConfirmationBox(tester);
    await tester.enterText(find.byType(TextFormField), 'bon-mdp-1234');
    await tester.pump();

    await tester.tap(_submitButton);
    await tester.pumpAndSettle();

    expect(repository.signInCallCount, 1);
    expect(repository.lastPassword, 'bon-mdp-1234');
    expect(repository.deleteAccountCallCount, 1);
    expect(repository.signOutCallCount, 1);
    // L'écran s'est fermé après le succès complet (retour à l'accueil de
    // test).
    expect(find.text('SUPPRIMER LE COMPTE'), findsNothing);
    expect(find.text('Ouvrir'), findsOneWidget);
  });

  testWidgets(
    'échec de `deleteAccount` (mot de passe pourtant correct) : bandeau '
    'générique, jamais de déconnexion',
    (tester) async {
      final repository = await _pumpScreen(tester);
      repository.deleteAccountErrorToThrow = const AuthFailure(
        'Détail serveur jamais affiché.',
      );
      await _checkConfirmationBox(tester);
      await tester.enterText(find.byType(TextFormField), 'bon-mdp-1234');
      await tester.pump();

      await tester.tap(_submitButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Impossible de supprimer le compte. Réessayez.'),
        findsOneWidget,
      );
      expect(find.text('Détail serveur jamais affiché.'), findsNothing);
      expect(repository.signOutCallCount, 0);
      expect(find.byType(TextFormField), findsOneWidget);
    },
  );

  testWidgets('hors-ligne -> bandeau générique hors-ligne, aucune tentative de '
      'vérification du mot de passe', (tester) async {
    final repository = await _pumpScreen(tester, connected: false);
    await _checkConfirmationBox(tester);
    await tester.enterText(find.byType(TextFormField), 'bon-mdp-1234');
    await tester.pump();

    await tester.tap(_submitButton);
    await tester.pumpAndSettle();

    expect(find.textContaining("n'a pas pu être enregistrée"), findsOneWidget);
    expect(repository.signInCallCount, 0);
    expect(repository.deleteAccountCallCount, 0);
  });

  testWidgets(
    'pendant l\'appel réseau, le libellé du bouton change, "Annuler" est '
    'désactivé, la saisie reste préservée',
    (tester) async {
      final repository = await _pumpScreen(tester);
      repository.gateDeleteAccount = true;
      await _checkConfirmationBox(tester);
      await tester.enterText(find.byType(TextFormField), 'bon-mdp-1234');
      await tester.pump();

      await tester.tap(_submitButton);
      await tester.pump();

      expect(
        find.widgetWithText(DestructiveButton, 'SUPPRESSION EN COURS…'),
        findsOneWidget,
      );
      final deleteButton = tester.widget<DestructiveButton>(
        find.widgetWithText(DestructiveButton, 'SUPPRESSION EN COURS…'),
      );
      expect(deleteButton.onPressed, isNull);

      final secondaryButton = tester.widget<SecondaryButton>(
        find.widgetWithText(SecondaryButton, 'ANNULER'),
      );
      expect(secondaryButton.onPressed, isNull);

      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        'bon-mdp-1234',
      );

      repository.deleteGate.complete();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'le geste retour Android ne ferme pas l\'écran pendant l\'appel réseau',
    (tester) async {
      final repository = await _pumpScreen(tester);
      repository.gateDeleteAccount = true;
      await _checkConfirmationBox(tester);
      await tester.enterText(find.byType(TextFormField), 'bon-mdp-1234');
      await tester.pump();

      await tester.tap(_submitButton);
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('SUPPRIMER LE COMPTE'),
        findsOneWidget,
        reason: 'le geste retour ne doit pas fermer l\'écran pendant l\'envoi',
      );

      expect(repository.deleteAccountCallCount, 1);

      repository.deleteGate.complete();
      await tester.pumpAndSettle();

      expect(find.text('SUPPRIMER LE COMPTE'), findsNothing);
    },
  );

  testWidgets('"ANNULER" revient à l\'écran précédent', (tester) async {
    await _pumpScreen(tester);

    await tester.tap(find.widgetWithText(SecondaryButton, 'ANNULER'));
    await tester.pumpAndSettle();

    expect(find.text('SUPPRIMER LE COMPTE'), findsNothing);
    expect(find.text('Ouvrir'), findsOneWidget);
  });

  testWidgets('la flèche retour du bandeau bois revient à l\'écran précédent', (
    tester,
  ) async {
    await _pumpScreen(tester);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    expect(find.text('SUPPRIMER LE COMPTE'), findsNothing);
    expect(find.text('Ouvrir'), findsOneWidget);
  });
}
