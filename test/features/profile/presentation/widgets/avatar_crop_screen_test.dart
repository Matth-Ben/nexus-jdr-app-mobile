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

  /// Invoque des que `AuthRepository.updateAvatar` est appele : les
  /// tests attendent cet evenement plutot qu'une duree fixe (voir
  /// `_tapValiderAndAwaitCall`, qui le branche).
  void Function()? onUpdateAvatar;

  int updateAvatarCallCount = 0;
  Uint8List? lastBytes;
  Object? errorToThrow;

  @override
  Future<String> updateAvatar({required Uint8List bytes}) async {
    updateAvatarCallCount++;
    onUpdateAvatar?.call();
    lastBytes = bytes;
    if (gateUpdateAvatar) await gate.future;
    final error = errorToThrow;
    if (error != null) throw error;
    return 'https://exemple.com/avatar.png';
  }

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<bool> signUp({
    required String email,
    required String password,
  }) async => false;

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

/// Borne haute de l'attente de l'appel au depot. Volontairement tres large :
/// ce n'est pas une estimation du temps de capture, seulement un garde-fou
/// pour qu'une regression (appel jamais emis) echoue avec un message clair
/// plutot que de bloquer jusqu'au timeout global du test.
const Duration _repositoryCallTimeout = Duration(seconds: 10);

/// Tape "Valider" puis attend que `_submit` ait reellement appele le depot.
///
/// Entre le tap et cet appel, l'ecran enchaine `RenderRepaintBoundary
/// .toImage()` (thread raster du moteur) puis `Image.toByteData(png)`
/// (encodage sur un thread d'E/S du moteur) : du travail asynchrone reel, de
/// duree non bornee, hors de l'horloge simulee. Une attente a duree fixe
/// (historiquement 50 ms d'horloge reelle) etait une course - perdue de temps
/// en temps quand la machine est chargee (suite complete), d'ou des
/// `updateAvatarCallCount` a 0 intermittents. On attend donc l'evenement
/// lui-meme, signale par `_FakeAuthRepository.onUpdateAvatar`.
///
/// Le `Completer` est cree *dans* `runAsync`, et non dans le faux depot :
/// un `Future` complete ses auditeurs via la zone ou il a ete cree. Cree
/// dans le corps du test (zone a horloge simulee), il ne previendrait
/// personne tant que `runAsync` garde cette zone a l'arret - l'attente
/// expirerait alors meme si l'appel a bien eu lieu.
Future<void> _tapValiderAndAwaitCall(
  WidgetTester tester,
  _FakeAuthRepository repository,
) async {
  await tester.runAsync(() async {
    final called = Completer<void>();
    repository.onUpdateAvatar = () {
      if (!called.isCompleted) called.complete();
    };

    await tester.tap(find.widgetWithText(PrimaryButton, 'VALIDER'));
    await tester.pump();
    await called.future.timeout(
      _repositoryCallTimeout,
      onTimeout: () => fail(
        "AuthRepository.updateAvatar n'a pas ete appele dans les "
        '${_repositoryCallTimeout.inSeconds} s suivant le tap sur Valider '
        "(capture/encodage de l'image jamais aboutis ?).",
      ),
    );
    // Un tour de boucle d'evenements : vide la file de microtaches, donc
    // toute la suite de `_submit` qui ne depend que de la reponse du faux
    // depot (succes -> pop, erreur -> setState). Ce n'est pas une attente
    // temporelle : cette suite est exclusivement faite de microtaches,
    // toutes executees avant le prochain evenement de minuterie.
    await Future<void>.delayed(Duration.zero);
    await tester.pump();
  });
}

Future<void> _tapValiderAndSettle(
  WidgetTester tester,
  _FakeAuthRepository repository,
) async {
  await _tapValiderAndAwaitCall(tester, repository);
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

  testWidgets("pendant l'envoi : Valider en isLoading, Annuler desactive", (
    tester,
  ) async {
    final repository = await _pumpScreen(tester);
    repository.gateUpdateAvatar = true;

    await _tapValiderAndAwaitCall(tester, repository);

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
  });

  testWidgets(
    "succes : envoie les octets captures a AuthRepository.updateAvatar, "
    "ferme l'ecran (pop(true))",
    (tester) async {
      final repository = await _pumpScreen(tester);

      await _tapValiderAndSettle(tester, repository);

      expect(repository.updateAvatarCallCount, 1);
      expect(repository.lastBytes, isNotNull);
      expect(repository.lastBytes!.isNotEmpty, isTrue);
      expect(find.text('RECADRAGE'), findsNothing);
    },
  );

  testWidgets("AuthFailure : bandeau d'alerte inline affiche failure.message, "
      "l'ecran reste ouvert", (tester) async {
    final repository = await _pumpScreen(tester);
    repository.errorToThrow = const AuthFailure('Erreur serveur.');

    await _tapValiderAndSettle(tester, repository);

    expect(find.text('Erreur serveur.'), findsOneWidget);
    expect(find.text('RECADRAGE'), findsOneWidget);
  });

  testWidgets(
    'echec inattendu (pas une AuthFailure) : bandeau generique fixe',
    (tester) async {
      final repository = await _pumpScreen(tester);
      repository.errorToThrow = Exception('boom');

      await _tapValiderAndSettle(tester, repository);

      expect(
        find.text("Impossible de mettre à jour l'avatar. Réessayez."),
        findsOneWidget,
      );
      expect(find.text('RECADRAGE'), findsOneWidget);
    },
  );

  testWidgets("le bouton retour visible (WoodBackHeader) reste garde par "
      "isUploading : aucun effet pendant l'envoi", (tester) async {
    final repository = await _pumpScreen(tester);
    repository.gateUpdateAvatar = true;

    await _tapValiderAndAwaitCall(tester, repository);

    expect(repository.updateAvatarCallCount, 1);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pump();
    // Horloge simulee : laisse a une eventuelle transition de fermeture le
    // temps de se terminer. Sans cette avance, l'ecran reste trouve pendant
    // l'animation de sortie et l'assertion passe meme si le retour a ferme
    // l'ecran (garde `_isUploading` retiree de `_cancel`).
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('RECADRAGE'), findsOneWidget);

    repository.gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets(
    'alignement avec les 3 sheets de la meme tache (mot de passe/email/'
    "pseudo) : le geste retour Android (systeme) est bloque pendant l'envoi "
    '- PopScope(canPop: !_isUploading) empeche la fermeture, comme '
    'PopScope(canPop: !_isSaving) pose sur les 3 sheets.',
    (tester) async {
      final repository = await _pumpScreen(tester);
      repository.gateUpdateAvatar = true;

      await _tapValiderAndAwaitCall(tester, repository);

      expect(repository.updateAvatarCallCount, 1);

      // `pump()` simple, jamais `pumpAndSettle()` ici : `PrimaryButton`
      // affiche un `CircularProgressIndicator` indéterminé tant que
      // `_isUploading` reste vrai, dont l'animation ne se termine jamais
      // (`pumpAndSettle` boucle indéfiniment dessus) - même raison que les
      // autres tests de ce fichier qui interagissent pendant l'envoi.
      await tester.binding.handlePopRoute();
      await tester.pump();
      // Horloge simulee : laisse a une eventuelle transition de fermeture
      // le temps de se terminer. Sans cette avance, l'ecran reste trouve
      // pendant l'animation de sortie et l'assertion passe meme avec
      // `canPop: true`.
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('RECADRAGE'), findsOneWidget);

      repository.gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('RECADRAGE'), findsNothing);
    },
  );
}
