// Tests de widget de la sheet "Modifier le profil"
// (`presentation/widgets/edit_display_name_sheet.dart`) — pattern
// autoportant calqué sur `character_story_edit_sheet_test.dart` (voir ce
// fichier pour le modèle de référence) : préremplissage depuis
// `currentUserProvider`, sauvegarde (succès/échec réseau/hors-ligne), texte
// saisi préservé sur échec, `closeEnabled` désactivé pendant la sauvegarde.

import 'dart:async';

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
import 'package:personnages/features/profile/presentation/widgets/edit_display_name_sheet.dart';
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
}

class _FakeConnectivityChecker implements ConnectivityChecker {
  _FakeConnectivityChecker({required this.connected});

  final bool connected;

  @override
  Future<bool> hasConnection() async => connected;

  @override
  Stream<bool> get onConnectivityRestored => const Stream.empty();
}

User _fakeUser({String? fullName}) {
  return User(
    id: 'fake-user-id',
    appMetadata: const {},
    userMetadata: fullName == null ? const {} : {'full_name': fullName},
    aud: 'authenticated',
    email: 'joueur@exemple.com',
    createdAt: '2026-01-01T00:00:00Z',
  );
}

Future<_FakeAuthRepository> _pumpSheet(
  WidgetTester tester, {
  User? user,
  bool connected = true,
}) async {
  final repository = _FakeAuthRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        currentUserProvider.overrideWithValue(user ?? _fakeUser()),
        connectivityCheckerProvider.overrideWithValue(
          _FakeConnectivityChecker(connected: connected),
        ),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showEditDisplayNameSheet(context),
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
    'préremplit le champ depuis `user_metadata[\'full_name\']` quand '
    'présent',
    (tester) async {
      await _pumpSheet(tester, user: _fakeUser(fullName: 'Aranea'));

      expect(find.text('MODIFIER LE PROFIL'), findsOneWidget);
      expect(find.text("NOM D'AFFICHAGE"), findsOneWidget);
      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(field.controller!.text, 'Aranea');
    },
  );

  testWidgets(
    'champ vide (jamais prérempli avec le fallback d\'affichage '
    '"Aventurier") quand `full_name` est absent',
    (tester) async {
      await _pumpSheet(tester, user: _fakeUser());

      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(field.controller!.text, isEmpty);
    },
  );

  testWidgets(
    '"Enregistrer" : envoie la valeur trimée, ferme la sheet et laisse '
    'l\'appelant afficher le SnackBar de confirmation',
    (tester) async {
      final repository = await _pumpSheet(tester);

      await tester.enterText(
        find.byType(TextFormField),
        '  Nouveau nom  ',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(repository.updateDisplayNameCallCount, 1);
      expect(repository.lastDisplayName, 'Nouveau nom');
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Profil mis à jour.'), findsOneWidget);
    },
  );

  testWidgets(
    'champ vidé (texte blanc après trim) envoie `null`, équivalent à '
    '"non défini"',
    (tester) async {
      final repository = await _pumpSheet(
        tester,
        user: _fakeUser(fullName: 'Ancien nom'),
      );

      await tester.enterText(find.byType(TextFormField), '   ');
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(repository.lastDisplayName, isNull);
    },
  );

  testWidgets(
    'pendant la sauvegarde : "Enregistrer" en isLoading, "Annuler" et le X '
    'du SheetHeaderBar désactivés (closeEnabled: false)',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.gateUpdateDisplayName = true;

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
    'aucune connexion réseau : bandeau hors-ligne honnête, sheet reste '
    'ouverte, texte saisi préservé, aucun appel réseau tenté',
    (tester) async {
      final repository = await _pumpSheet(tester, connected: false);

      await tester.enterText(
        find.byType(TextFormField),
        'Nom pas encore enregistré.',
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
        'Nom pas encore enregistré.',
      );
      expect(
        repository.updateDisplayNameCallCount,
        0,
        reason:
            'sans connectivité, aucune tentative réseau ne doit être '
            'faite (`AuthRepository.updateDisplayName` n\'a pas de file '
            "d'attente hors-ligne)",
      );
    },
  );

  testWidgets(
    'AuthFailure : bandeau d\'alerte inline affiche `failure.message`, '
    'sheet reste ouverte, texte saisi préservé',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.errorToThrow = const AuthFailure('Erreur serveur.');

      await tester.enterText(find.byType(TextFormField), 'En cours de saisie.');
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(find.text('Erreur serveur.'), findsOneWidget);
      expect(
        tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
        'En cours de saisie.',
      );
    },
  );

  testWidgets(
    'échec inattendu (pas une AuthFailure) : bandeau générique '
    '"Impossible d\'enregistrer les modifications. Réessayez."',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.errorToThrow = Exception('boom');

      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(
        find.text("Impossible d'enregistrer les modifications. Réessayez."),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'pendant la sauvegarde : ni le geste retour Android, ni un tap sur le '
    'voile ne ferment la sheet',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.gateUpdateDisplayName = true;

      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.byType(TextFormField),
        findsOneWidget,
        reason:
            'le geste retour ne doit pas fermer la sheet pendant la '
            'sauvegarde',
      );

      await tester.tapAt(const Offset(400, 10));
      await tester.pump();
      expect(find.byType(TextFormField), findsOneWidget);

      expect(repository.updateDisplayNameCallCount, 1);

      repository.gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNothing);
    },
  );
}
