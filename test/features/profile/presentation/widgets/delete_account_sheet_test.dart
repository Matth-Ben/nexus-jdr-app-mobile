// Tests de widget de la sheet "Supprimer mon compte"
// (`presentation/widgets/delete_account_sheet.dart`) — pattern autoportant
// calqué sur `report_bug_sheet_test.dart`/`change_password_sheet_test.dart` :
// étape "Avertissement" (Annuler/Continuer), étape "Confirmation" (mot de
// passe incorrect -> pas de suppression tentée, mot de passe correct ->
// suppression puis déconnexion, verrouillage pendant l'appel réseau à chaque
// étape, hors-ligne vérifié 2 fois, préservation de l'état, fermeture non
// bloquée pendant l'envoi, jamais d'effet de bord sans `mounted`).

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/network/connectivity_checker.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/core/widgets/destructive_button.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/core/widgets/sheet_header_bar.dart';
import 'package:personnages/features/auth/data/auth_repository.dart';
import 'package:personnages/features/auth/domain/auth_failure.dart';
import 'package:personnages/features/auth/presentation/providers/auth_providers.dart';
import 'package:personnages/features/profile/presentation/widgets/delete_account_sheet.dart';
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

Future<_FakeAuthRepository> _pumpSheet(
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
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showDeleteAccountSheet(context),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
  return repository;
}

Future<void> _goToConfirmStep(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(DestructiveButton, 'Continuer'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('étape 1/2 : affiche le titre et le message d\'avertissement', (
    tester,
  ) async {
    await _pumpSheet(tester);

    expect(find.text('SUPPRIMER MON COMPTE'), findsOneWidget);
    expect(
      find.textContaining('Cette action est irréversible'),
      findsOneWidget,
    );
    expect(find.widgetWithText(SecondaryButton, 'ANNULER'), findsOneWidget);
    expect(find.widgetWithText(DestructiveButton, 'Continuer'), findsOneWidget);
  });

  testWidgets('étape 1/2 : "Annuler" ferme la sheet', (tester) async {
    await _pumpSheet(tester);

    await tester.tap(find.widgetWithText(SecondaryButton, 'ANNULER'));
    await tester.pumpAndSettle();

    expect(find.text('SUPPRIMER MON COMPTE'), findsNothing);
  });

  testWidgets(
    'étape 1/2 : "Continuer" passe à l\'étape de confirmation par mot de '
    'passe',
    (tester) async {
      await _pumpSheet(tester);

      await _goToConfirmStep(tester);

      expect(
        find.text('SAISIS TON MOT DE PASSE POUR CONFIRMER'),
        findsOneWidget,
      );
      expect(find.byType(TextFormField), findsOneWidget);
      expect(
        find.widgetWithText(
          DestructiveButton,
          'Supprimer définitivement mon compte',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'étape 2/2 : mot de passe incorrect -> erreur inline sous le champ, '
    'aucune suppression tentée',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.signInErrorToThrow = const AuthFailure(
        'Adresse e-mail ou mot de passe incorrect.',
      );
      await _goToConfirmStep(tester);

      await tester.enterText(find.byType(TextFormField), 'mauvais-mdp');
      await tester.tap(
        find.widgetWithText(
          DestructiveButton,
          'Supprimer définitivement mon compte',
        ),
      );
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
      // La sheet reste ouverte, toujours à l'étape de confirmation.
      expect(find.byType(TextFormField), findsOneWidget);
    },
  );

  testWidgets(
    'étape 2/2 : mot de passe correct -> vérifie puis supprime le compte '
    'puis déconnecte, dans cet ordre',
    (tester) async {
      final repository = await _pumpSheet(tester);
      await _goToConfirmStep(tester);

      await tester.enterText(find.byType(TextFormField), 'bon-mdp-1234');
      await tester.tap(
        find.widgetWithText(
          DestructiveButton,
          'Supprimer définitivement mon compte',
        ),
      );
      await tester.pumpAndSettle();

      expect(repository.signInCallCount, 1);
      expect(repository.lastPassword, 'bon-mdp-1234');
      expect(repository.deleteAccountCallCount, 1);
      expect(repository.signOutCallCount, 1);
      // La sheet s'est fermée après le succès complet.
      expect(find.text('SUPPRIMER MON COMPTE'), findsNothing);
    },
  );

  testWidgets(
    'étape 2/2 : échec de `deleteAccount` (mot de passe pourtant correct) : '
    'bandeau générique, jamais de déconnexion',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.deleteAccountErrorToThrow = const AuthFailure(
        'Détail serveur jamais affiché.',
      );
      await _goToConfirmStep(tester);

      await tester.enterText(find.byType(TextFormField), 'bon-mdp-1234');
      await tester.tap(
        find.widgetWithText(
          DestructiveButton,
          'Supprimer définitivement mon compte',
        ),
      );
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

  testWidgets('étape 2/2 : hors-ligne -> bandeau générique hors-ligne, aucune '
      'tentative de vérification du mot de passe', (tester) async {
    final repository = await _pumpSheet(tester, connected: false);
    await _goToConfirmStep(tester);

    await tester.enterText(find.byType(TextFormField), 'bon-mdp-1234');
    await tester.tap(
      find.widgetWithText(
        DestructiveButton,
        'Supprimer définitivement mon compte',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining("n'a pas pu être enregistrée"), findsOneWidget);
    expect(repository.signInCallCount, 0);
    expect(repository.deleteAccountCallCount, 0);
  });

  testWidgets(
    'étape 2/2 : pendant l\'appel réseau, le libellé du bouton change, '
    '"Annuler" et le X du header sont désactivés, la saisie reste '
    'préservée',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.gateDeleteAccount = true;
      await _goToConfirmStep(tester);

      await tester.enterText(find.byType(TextFormField), 'bon-mdp-1234');
      await tester.tap(
        find.widgetWithText(
          DestructiveButton,
          'Supprimer définitivement mon compte',
        ),
      );
      await tester.pump();

      expect(
        find.widgetWithText(DestructiveButton, 'Suppression en cours…'),
        findsOneWidget,
      );
      final deleteButton = tester.widget<DestructiveButton>(
        find.widgetWithText(DestructiveButton, 'Suppression en cours…'),
      );
      expect(deleteButton.onPressed, isNull);

      final secondaryButton = tester.widget<SecondaryButton>(
        find.widgetWithText(SecondaryButton, 'ANNULER'),
      );
      expect(secondaryButton.onPressed, isNull);

      final header = tester.widget<SheetHeaderBar>(find.byType(SheetHeaderBar));
      expect(header.closeEnabled, isFalse);

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
    'étape 2/2 : ni le geste retour Android ni un tap sur le voile ne '
    'ferment la sheet pendant l\'appel réseau',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.gateDeleteAccount = true;
      await _goToConfirmStep(tester);

      await tester.enterText(find.byType(TextFormField), 'bon-mdp-1234');
      await tester.tap(
        find.widgetWithText(
          DestructiveButton,
          'Supprimer définitivement mon compte',
        ),
      );
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.byType(TextFormField),
        findsOneWidget,
        reason: 'le geste retour ne doit pas fermer la sheet pendant l\'envoi',
      );

      await tester.tapAt(const Offset(400, 10));
      await tester.pump();
      expect(find.byType(TextFormField), findsOneWidget);

      expect(repository.deleteAccountCallCount, 1);

      repository.deleteGate.complete();
      await tester.pumpAndSettle();

      expect(find.text('SUPPRIMER MON COMPTE'), findsNothing);
    },
  );
}
