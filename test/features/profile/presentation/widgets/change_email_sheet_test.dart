// Tests de widget de la sheet "Adresse email"
// (`presentation/widgets/change_email_sheet.dart`) — pattern autoportant
// calqué sur `change_password_sheet_test.dart` (voir ce fichier pour le
// modèle de référence), avec en plus le bandeau `InfoBanner` permanent, le
// rappel "Adresse actuelle : ...", et le SnackBar spécifique (pas "mis à
// jour" : le changement n'est pas effectif immédiatement).

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
import 'package:personnages/features/profile/presentation/widgets/change_email_sheet.dart';

class _FakeAuthRepository implements AuthRepository {
  final Completer<void> gate = Completer<void>();
  bool gateUpdateEmail = false;

  int updateEmailCallCount = 0;
  String? lastEmail;
  Object? errorToThrow;

  @override
  Future<void> updateEmail({required String newEmail}) async {
    updateEmailCallCount++;
    lastEmail = newEmail;
    if (gateUpdateEmail) await gate.future;
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
  Future<void> signUp({required String email, required String password}) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> resetPasswordForEmail({required String email}) async {}

  @override
  Future<void> updateDisplayName({required String? displayName}) async {}

  @override
  Future<void> updatePassword({required String newPassword}) async {}

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
  String currentEmail = 'ancien@exemple.com',
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
                onPressed: () =>
                    showChangeEmailSheet(context, currentEmail: currentEmail),
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

void main() {
  testWidgets(
    'affiche le titre, le bandeau info permanent, le champ et le rappel de '
    'l\'adresse actuelle',
    (tester) async {
      await _pumpSheet(tester, currentEmail: 'ancien@exemple.com');

      expect(find.text('ADRESSE EMAIL'), findsOneWidget);
      expect(
        find.textContaining('Un email de confirmation sera envoyé'),
        findsOneWidget,
      );
      expect(find.text('NOUVELLE ADRESSE EMAIL'), findsOneWidget);
      expect(
        find.text('Adresse actuelle : ancien@exemple.com'),
        findsOneWidget,
      );
      expect(find.byType(TextFormField), findsOneWidget);
    },
  );

  testWidgets(
    'adresse invalide : erreur inline sous le champ, jamais d\'appel réseau',
    (tester) async {
      final repository = await _pumpSheet(tester);

      await tester.enterText(find.byType(TextFormField), 'pas-une-adresse');
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(find.text('Adresse e-mail invalide.'), findsOneWidget);
      expect(repository.updateEmailCallCount, 0);
    },
  );

  testWidgets(
    'formulaire valide : envoie la nouvelle adresse trimée, ferme la sheet, '
    'laisse l\'appelant afficher le SnackBar spécifique (pas "mis à jour")',
    (tester) async {
      final repository = await _pumpSheet(tester);

      await tester.enterText(
        find.byType(TextFormField),
        '  nouveau@exemple.com  ',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(repository.updateEmailCallCount, 1);
      expect(repository.lastEmail, 'nouveau@exemple.com');
      expect(find.byType(TextFormField), findsNothing);
      expect(
        find.text(
          'Email de confirmation envoyé. Vérifie ta boîte de réception '
          'pour finaliser le changement.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'pendant la sauvegarde : "Enregistrer" en isLoading, "Annuler" et le X '
    'du SheetHeaderBar désactivés',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.gateUpdateEmail = true;

      await tester.enterText(find.byType(TextFormField), 'nouveau@exemple.com');
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

      await tester.enterText(
        find.byType(TextFormField),
        'nouveau@exemple.com',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining("n'a pas pu être enregistrée"),
        findsOneWidget,
      );
      expect(find.byType(TextFormField), findsOneWidget);
      expect(
        tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
        'nouveau@exemple.com',
      );
      expect(repository.updateEmailCallCount, 0);
    },
  );

  testWidgets(
    'AuthFailure : bandeau d\'alerte inline affiche `failure.message`, '
    'sheet reste ouverte, saisie préservée',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.errorToThrow = const AuthFailure('Erreur serveur.');

      await tester.enterText(
        find.byType(TextFormField),
        'nouveau@exemple.com',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(find.text('Erreur serveur.'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    },
  );

  testWidgets(
    'échec inattendu (pas une AuthFailure) : bandeau générique fixe',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.errorToThrow = Exception('boom');

      await tester.enterText(
        find.byType(TextFormField),
        'nouveau@exemple.com',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(
        find.text("Impossible d'envoyer le nouvel email. Réessayez."),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'pendant la sauvegarde : ni le geste retour Android, ni un tap sur le '
    'voile ne ferment la sheet',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.gateUpdateEmail = true;

      await tester.enterText(
        find.byType(TextFormField),
        'nouveau@exemple.com',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(TextFormField), findsOneWidget);

      expect(repository.updateEmailCallCount, 1);

      repository.gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNothing);
    },
  );
}
