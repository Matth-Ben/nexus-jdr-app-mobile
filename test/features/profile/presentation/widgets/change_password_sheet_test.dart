// Tests de widget de la sheet "Mot de passe"
// (`presentation/widgets/change_password_sheet.dart`) — pattern autoportant
// calqué sur `edit_display_name_sheet_test.dart`/`report_bug_sheet_test.dart`
// (voir ces fichiers pour le modèle de référence), avec en plus la
// validation de `Form` (`AutovalidateMode.onUserInteraction`, comme
// `login_screen_test.dart`) : mot de passe trop court, confirmation
// différente, jamais d'appel réseau tant que le formulaire est invalide.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/network/connectivity_checker.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/core/widgets/sheet_header_bar.dart';
import 'package:personnages/features/auth/data/auth_repository.dart';
import 'package:personnages/features/auth/domain/auth_failure.dart';
import 'package:personnages/features/auth/presentation/providers/auth_providers.dart';
import 'package:personnages/features/profile/presentation/widgets/change_password_sheet.dart';

class _FakeAuthRepository implements AuthRepository {
  final Completer<void> gate = Completer<void>();
  bool gateUpdatePassword = false;

  int updatePasswordCallCount = 0;
  String? lastPassword;
  Object? errorToThrow;

  @override
  Future<void> updatePassword({required String newPassword}) async {
    updatePasswordCallCount++;
    lastPassword = newPassword;
    if (gateUpdatePassword) await gate.future;
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
  Future<void> updateDisplayName({required String? displayName}) async {}

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

Future<_FakeAuthRepository> _pumpSheet(
  WidgetTester tester, {
  bool connected = true,
}) async {
  final repository = _FakeAuthRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        connectivityCheckerProvider.overrideWithValue(
          _FakeConnectivityChecker(connected: connected),
        ),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showChangePasswordSheet(context),
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

Finder _passwordField() => find.byType(TextFormField).first;
Finder _confirmField() => find.byType(TextFormField).last;

void main() {
  testWidgets('affiche le titre et les 2 champs', (tester) async {
    await _pumpSheet(tester);

    expect(find.text('MOT DE PASSE'), findsOneWidget);
    expect(find.text('NOUVEAU MOT DE PASSE'), findsOneWidget);
    expect(find.text('CONFIRMER LE MOT DE PASSE'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets(
    'mot de passe trop court : erreur inline sous le champ, jamais d\'appel '
    'réseau',
    (tester) async {
      final repository = await _pumpSheet(tester);

      await tester.enterText(_passwordField(), '123');
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(
        find.text('Le mot de passe doit contenir au moins 6 caractères.'),
        findsOneWidget,
      );
      expect(repository.updatePasswordCallCount, 0);
    },
  );

  testWidgets(
    'confirmation différente : erreur inline sous le champ, jamais d\'appel '
    'réseau',
    (tester) async {
      final repository = await _pumpSheet(tester);

      await tester.enterText(_passwordField(), 'motdepasse123');
      await tester.enterText(_confirmField(), 'different123');
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(
        find.text('Les mots de passe ne correspondent pas.'),
        findsOneWidget,
      );
      expect(repository.updatePasswordCallCount, 0);
    },
  );

  testWidgets(
    'formulaire valide : envoie le mot de passe, ferme la sheet, laisse '
    'l\'appelant afficher le SnackBar de confirmation',
    (tester) async {
      final repository = await _pumpSheet(tester);

      await tester.enterText(_passwordField(), 'motdepasse123');
      await tester.enterText(_confirmField(), 'motdepasse123');
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(repository.updatePasswordCallCount, 1);
      expect(repository.lastPassword, 'motdepasse123');
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Mot de passe mis à jour.'), findsOneWidget);
    },
  );

  testWidgets(
    'pendant la sauvegarde : "Enregistrer" en isLoading, "Annuler" et le X '
    'du SheetHeaderBar désactivés',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.gateUpdatePassword = true;

      await tester.enterText(_passwordField(), 'motdepasse123');
      await tester.enterText(_confirmField(), 'motdepasse123');
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pump();

      final primaryButton = tester.widget<PrimaryButton>(
        find.byType(PrimaryButton),
      );
      expect(primaryButton.isLoading, isTrue);

      final secondaryButton = tester.widget<SecondaryButton>(
        find.widgetWithText(SecondaryButton, 'ANNULER'),
      );
      expect(secondaryButton.onPressed, isNull);

      final header = tester.widget<SheetHeaderBar>(find.byType(SheetHeaderBar));
      expect(header.closeEnabled, isFalse);

      repository.gate.complete();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'aucune connexion réseau : bandeau hors-ligne, sheet reste ouverte, '
    'saisie préservée, aucun appel réseau tenté',
    (tester) async {
      final repository = await _pumpSheet(tester, connected: false);

      await tester.enterText(_passwordField(), 'motdepasse123');
      await tester.enterText(_confirmField(), 'motdepasse123');
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining("n'a pas pu être enregistrée"),
        findsOneWidget,
      );
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(
        tester.widget<TextFormField>(_passwordField()).controller!.text,
        'motdepasse123',
      );
      expect(repository.updatePasswordCallCount, 0);
    },
  );

  testWidgets(
    'AuthFailure : bandeau d\'alerte inline affiche `failure.message`, '
    'sheet reste ouverte, saisie préservée',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.errorToThrow = const AuthFailure('Erreur serveur.');

      await tester.enterText(_passwordField(), 'motdepasse123');
      await tester.enterText(_confirmField(), 'motdepasse123');
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(find.text('Erreur serveur.'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    },
  );

  testWidgets(
    'échec inattendu (pas une AuthFailure) : bandeau générique fixe',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.errorToThrow = Exception('boom');

      await tester.enterText(_passwordField(), 'motdepasse123');
      await tester.enterText(_confirmField(), 'motdepasse123');
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(
        find.text('Impossible de mettre à jour le mot de passe. Réessayez.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'pendant la sauvegarde : ni le geste retour Android, ni un tap sur le '
    'voile ne ferment la sheet',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.gateUpdatePassword = true;

      await tester.enterText(_passwordField(), 'motdepasse123');
      await tester.enterText(_confirmField(), 'motdepasse123');
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(TextFormField), findsNWidgets(2));

      expect(repository.updatePasswordCallCount, 1);

      repository.gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNothing);
    },
  );
}
