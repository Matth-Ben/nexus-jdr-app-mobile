// Tests de widget de l'ecran de recadrage d'avatar
// (`presentation/widgets/avatar_crop_screen.dart`) - verification de
// connectivite *avant* l'upload, verrouillage pendant l'envoi, erreurs
// (`AuthFailure`/generique), succes (upload + pop(true)).
//
// Lacune de couverture comblee par ce fichier : ni `AvatarCropScreen` ni son
// original `features/characters/presentation/widgets/portrait_crop_screen.dart`
// n'avaient de test de widget avant ce chantier QA. Raison technique
// probable de cette lacune historique, decouverte en ecrivant ce fichier :
// `_submit` capture l'image via `RenderRepaintBoundary.toImage()`, une
// operation asynchrone reelle (hors de l'horloge simulee du test) - toute
// interaction qui va jusqu'a cet appel doit passer par `tester.runAsync`,
// sans quoi `pumpAndSettle` ne se termine jamais (timeout). Voir le rapport
// de la tache "Modifier le profil (avatar/mot de passe/email)" pour le
// detail. Le dernier test de ce fichier verifie que le geste retour Android
// (systeme) est bien bloque pendant l'envoi via
// `PopScope(canPop: !_isUploading)`, meme pattern que les 3 sheets de la
// meme tache (`change_password_sheet.dart`/`change_email_sheet.dart`/
// `edit_display_name_sheet.dart`) - un bug reel a ete trouve et corrige ici
// (le geste retour systeme contournait auparavant le garde-fou
// `_isUploading`, qui ne couvrait que le bouton retour visible du
// `WoodBackHeader`).

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/network/connectivity_checker.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/features/auth/data/auth_repository.dart';
import 'package:personnages/features/auth/domain/auth_failure.dart';
import 'package:personnages/features/auth/presentation/providers/auth_providers.dart';
import 'package:personnages/features/profile/presentation/widgets/avatar_crop_screen.dart';

final Uint8List _fakePngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGNgAAAAAgABSK+kc'
  'QAAAABJRU5ErkJggg==',
);

class _FakeAuthRepository implements AuthRepository {
  final Completer<void> gate = Completer<void>();
  bool gateUpdateAvatar = false;

  int updateAvatarCallCount = 0;
  Uint8List? lastBytes;
  Object? errorToThrow;

  @override
  Future<String> updateAvatar({required Uint8List bytes}) async {
    updateAvatarCallCount++;
    lastBytes = bytes;
    if (gateUpdateAvatar) await gate.future;
    final error = errorToThrow;
    if (error != null) throw error;
    return 'https://exemple.com/avatar.png';
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

  @override
  Future<void> updateDisplayName({required String? displayName}) async {}

  @override
  Future<void> updatePassword({required String newPassword}) async {}

  @override
  Future<void> updateEmail({required String newEmail}) async {}

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

Future<_FakeAuthRepository> _pumpScreen(
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
                onPressed: () => Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => AvatarCropScreen(imageBytes: _fakePngBytes),
                  ),
                ),
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

Future<void> _tapValiderAndSettle(WidgetTester tester) async {
  await tester.runAsync(() async {
    await tester.tap(find.widgetWithText(PrimaryButton, 'VALIDER'));
    await tester.pump();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await tester.pump();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await tester.pump();
  });
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('affiche le cadre de recadrage et les boutons Annuler/Valider', (
    tester,
  ) async {
    await _pumpScreen(tester);

    expect(find.text('RECADRAGE'), findsOneWidget);
    expect(find.widgetWithText(SecondaryButton, 'ANNULER'), findsOneWidget);
    expect(find.widgetWithText(PrimaryButton, 'VALIDER'), findsOneWidget);
  });

  testWidgets(
    'aucune connexion reseau : bandeau hors-ligne, ecran reste ouvert, '
    'aucun appel reseau tente (jamais atteint la capture RepaintBoundary : '
    'la connectivite est verifiee avant)',
    (tester) async {
      final repository = await _pumpScreen(tester, connected: false);

      await tester.tap(find.widgetWithText(PrimaryButton, 'VALIDER'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Hors ligne'), findsOneWidget);
      expect(repository.updateAvatarCallCount, 0);
      expect(find.text('RECADRAGE'), findsOneWidget);
    },
  );

  testWidgets(
    "pendant l'envoi : Valider en isLoading, Annuler desactive",
    (tester) async {
      final repository = await _pumpScreen(tester);
      repository.gateUpdateAvatar = true;

      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(PrimaryButton, 'VALIDER'));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      });

      expect(repository.updateAvatarCallCount, 1);

      final primaryButton = tester.widget<PrimaryButton>(
        find.byType(PrimaryButton),
      );
      expect(primaryButton.isLoading, isTrue);

      final secondaryButton = tester.widget<SecondaryButton>(
        find.widgetWithText(SecondaryButton, 'ANNULER'),
      );
      expect(secondaryButton.onPressed, isNull);

      repository.gate.complete();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    "succes : envoie les octets captures a AuthRepository.updateAvatar, "
    "ferme l'ecran (pop(true))",
    (tester) async {
      final repository = await _pumpScreen(tester);

      await _tapValiderAndSettle(tester);

      expect(repository.updateAvatarCallCount, 1);
      expect(repository.lastBytes, isNotNull);
      expect(repository.lastBytes!.isNotEmpty, isTrue);
      expect(find.text('RECADRAGE'), findsNothing);
    },
  );

  testWidgets(
    "AuthFailure : bandeau d'alerte inline affiche failure.message, "
    "l'ecran reste ouvert",
    (tester) async {
      final repository = await _pumpScreen(tester);
      repository.errorToThrow = const AuthFailure('Erreur serveur.');

      await _tapValiderAndSettle(tester);

      expect(find.text('Erreur serveur.'), findsOneWidget);
      expect(find.text('RECADRAGE'), findsOneWidget);
    },
  );

  testWidgets(
    'echec inattendu (pas une AuthFailure) : bandeau generique fixe',
    (tester) async {
      final repository = await _pumpScreen(tester);
      repository.errorToThrow = Exception('boom');

      await _tapValiderAndSettle(tester);

      expect(
        find.text("Impossible de mettre à jour l'avatar. Réessayez."),
        findsOneWidget,
      );
      expect(find.text('RECADRAGE'), findsOneWidget);
    },
  );

  testWidgets(
    "le bouton retour visible (WoodBackHeader) reste garde par "
    "isUploading : aucun effet pendant l'envoi",
    (tester) async {
      final repository = await _pumpScreen(tester);
      repository.gateUpdateAvatar = true;

      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(PrimaryButton, 'VALIDER'));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      });

      expect(repository.updateAvatarCallCount, 1);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pump();

      expect(find.text('RECADRAGE'), findsOneWidget);

      repository.gate.complete();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'alignement avec les 3 sheets de la meme tache (mot de passe/email/'
    "pseudo) : le geste retour Android (systeme) est bloque pendant l'envoi "
    '- PopScope(canPop: !_isUploading) empeche la fermeture, comme '
    'PopScope(canPop: !_isSaving) pose sur les 3 sheets.',
    (tester) async {
      final repository = await _pumpScreen(tester);
      repository.gateUpdateAvatar = true;

      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(PrimaryButton, 'VALIDER'));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      });

      expect(repository.updateAvatarCallCount, 1);

      // `pump()` simple, jamais `pumpAndSettle()` ici : `PrimaryButton`
      // affiche un `CircularProgressIndicator` indéterminé tant que
      // `_isUploading` reste vrai, dont l'animation ne se termine jamais
      // (`pumpAndSettle` boucle indéfiniment dessus) - même raison que les
      // autres tests de ce fichier qui interagissent pendant l'envoi.
      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(find.text('RECADRAGE'), findsOneWidget);

      repository.gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('RECADRAGE'), findsNothing);
    },
  );
}
