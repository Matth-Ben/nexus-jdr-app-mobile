// Tests de widget de l'écran de connexion/inscription.
//
// Le dépôt de test (`_FakeAuthRepository`) est injecté via
// `authRepositoryProvider.overrideWithValue`, pour ne jamais toucher à
// `Supabase.instance.client` (non initialisé dans un test de widget — voir
// `test/widget_test.dart`).

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/auth/data/auth_repository.dart';
import 'package:personnages/features/auth/domain/auth_failure.dart';
import 'package:personnages/features/auth/presentation/login_screen.dart';
import 'package:personnages/features/auth/presentation/providers/auth_providers.dart';

/// Double de test pour [AuthRepository].
///
/// - [signInError]/[signUpError] permettent de simuler un échec (typiquement
///   une [AuthFailure] déjà traduite, comme le ferait le vrai
///   `SupabaseAuthRepository`, mais aussi n'importe quelle autre [Exception]
///   pour vérifier le repli défensif de l'écran).
/// - [signInCompleter]/[signUpCompleter], quand fournis, permettent de
///   garder l'appel en attente pour observer l'état "en cours de soumission"
///   (bouton désactivé + indicateur de chargement) avant de le résoudre
///   manuellement dans le test.
class _FakeAuthRepository implements AuthRepository {
  int signInCallCount = 0;
  int signUpCallCount = 0;
  int signOutCallCount = 0;

  Object? signInError;
  Object? signUpError;

  Completer<void>? signInCompleter;
  Completer<void>? signUpCompleter;

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    signInCallCount++;
    if (signInCompleter != null) {
      await signInCompleter!.future;
    }
    if (signInError != null) {
      throw signInError!;
    }
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    signUpCallCount++;
    if (signUpCompleter != null) {
      await signUpCompleter!.future;
    }
    if (signUpError != null) {
      throw signUpError!;
    }
  }

  @override
  Future<void> signOut() async {
    signOutCallCount++;
  }

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

void main() {
  late _FakeAuthRepository fakeRepository;

  setUp(() {
    fakeRepository = _FakeAuthRepository();
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  Future<void> fillLoginForm(
    WidgetTester tester, {
    String email = 'nom@exemple.com',
    String password = 'motdepasse123',
  }) async {
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), password);
  }

  testWidgets('affiche les champs et l\'action attendus en mode connexion', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());

    expect(find.text('Adresse e-mail'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
    expect(find.text('Confirmer le mot de passe'), findsNothing);
    expect(find.text('ENTRER'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);
  });

  testWidgets('affiche la mention de compte unique avec l\'app Histoires', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());

    expect(find.text("Même compte que l'app Histoires"), findsOneWidget);
  });

  testWidgets(
    'affiche le lien "Mot de passe oublié ?" en mode connexion, absent en '
    'mode inscription',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Mot de passe oublié ?'), findsOneWidget);

      await tester.tap(find.text('Créer un compte'));
      await tester.pumpAndSettle();

      expect(find.text('Mot de passe oublié ?'), findsNothing);
    },
  );

  testWidgets(
    'bascule vers le mode inscription et affiche le champ de confirmation',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.text('Créer un compte'));
      await tester.pumpAndSettle();

      expect(find.text('Confirmer le mot de passe'), findsOneWidget);
      expect(find.text('CRÉER LE COMPTE'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);
    },
  );

  testWidgets(
    'basculer de mode vide le champ mot de passe précédemment saisi',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.enterText(find.byType(TextFormField).at(1), 'motdepasse123');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Créer un compte'));
      await tester.pumpAndSettle();

      final passwordField = tester.widget<TextFormField>(
        find.byType(TextFormField).at(1),
      );
      expect(passwordField.controller?.text, isEmpty);
    },
  );

  testWidgets('après une tentative de soumission invalide, basculer de mode ne '
      'réaffiche pas l\'erreur de validation sur le champ vidé '
      'programmatiquement', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget());

    // Déclenche une erreur de validation en mode connexion.
    await tester.tap(find.text('ENTRER'));
    await tester.pumpAndSettle();
    expect(find.text('Saisissez votre mot de passe.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), 'motdepasse123');
    await tester.pumpAndSettle();
    expect(find.text('Saisissez votre mot de passe.'), findsNothing);

    await tester.tap(find.text('Créer un compte'));
    await tester.pumpAndSettle();

    // Attendu : plus d'erreur affichée juste après le changement de mode
    // (le champ vient d'être vidé programmatiquement, pas par l'utilisateur).
    expect(find.text('Saisissez votre mot de passe.'), findsNothing);
  });

  testWidgets(
    'affiche une erreur de validation et n\'appelle pas Supabase si les '
    'champs sont vides',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.text('ENTRER'));
      await tester.pumpAndSettle();

      expect(find.text('Saisissez votre adresse e-mail.'), findsOneWidget);
      expect(find.text('Saisissez votre mot de passe.'), findsOneWidget);
      expect(fakeRepository.signInCallCount, 0);
    },
  );

  testWidgets('affiche une erreur de validation pour un e-mail mal formé sans '
      'appeler Supabase', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget());

    await fillLoginForm(tester, email: 'pas-un-email');
    await tester.tap(find.text('ENTRER'));
    await tester.pumpAndSettle();

    expect(find.text('Adresse e-mail invalide.'), findsOneWidget);
    expect(fakeRepository.signInCallCount, 0);
  });

  testWidgets('en inscription, affiche une erreur si les mots de passe ne '
      'correspondent pas et n\'appelle pas Supabase', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());

    await tester.tap(find.text('Créer un compte'));
    await tester.pumpAndSettle();

    await fillLoginForm(tester);
    await tester.enterText(find.byType(TextFormField).at(2), 'autremotdepasse');
    await tester.tap(find.text('CRÉER LE COMPTE'));
    await tester.pumpAndSettle();

    expect(
      find.text('Les mots de passe ne correspondent pas.'),
      findsOneWidget,
    );
    expect(fakeRepository.signUpCallCount, 0);
  });

  testWidgets(
    'appelle signInWithPassword quand le formulaire de connexion est valide',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      await fillLoginForm(tester);
      await tester.tap(find.text('ENTRER'));
      await tester.pumpAndSettle();

      expect(fakeRepository.signInCallCount, 1);
    },
  );

  testWidgets('appelle signUp quand le formulaire d\'inscription est valide', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());

    await tester.tap(find.text('Créer un compte'));
    await tester.pumpAndSettle();

    await fillLoginForm(tester);
    await tester.enterText(find.byType(TextFormField).at(2), 'motdepasse123');
    await tester.tap(find.text('CRÉER LE COMPTE'));
    await tester.pumpAndSettle();

    expect(fakeRepository.signUpCallCount, 1);
    expect(fakeRepository.signInCallCount, 0);
  });

  testWidgets(
    'affiche le message d\'une AuthFailure renvoyée par le dépôt (ex. '
    'identifiants incorrects)',
    (WidgetTester tester) async {
      fakeRepository.signInError = const AuthFailure(
        'Adresse e-mail ou mot de passe incorrect.',
      );

      await tester.pumpWidget(buildTestWidget());
      await fillLoginForm(tester);
      await tester.tap(find.text('ENTRER'));
      await tester.pumpAndSettle();

      expect(
        find.text('Adresse e-mail ou mot de passe incorrect.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'affiche un message générique si le dépôt lève une exception inattendue '
    '(repli défensif, ex. absence de réseau non déjà traduite)',
    (WidgetTester tester) async {
      fakeRepository.signInError = Exception('boom');

      await tester.pumpWidget(buildTestWidget());
      await fillLoginForm(tester);
      await tester.tap(find.text('ENTRER'));
      await tester.pumpAndSettle();

      expect(
        find.text('Une erreur inattendue est survenue. Réessayez.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'désactive le bouton et affiche un indicateur de chargement pendant la '
    'soumission, puis les restaure une fois terminé',
    (WidgetTester tester) async {
      final completer = Completer<void>();
      fakeRepository.signInCompleter = completer;

      await tester.pumpWidget(buildTestWidget());
      await fillLoginForm(tester);
      await tester.tap(find.text('ENTRER'));
      await tester.pump();

      // Pendant l'appel en cours : indicateur visible, bouton texte masqué.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('ENTRER'), findsNothing);

      // Le bouton est désactivé (onPressed == null) le temps de l'appel :
      // retaper dessus ne doit pas déclencher un second appel concurrent.
      await tester.tap(find.byType(PrimaryButton), warnIfMissed: false);
      await tester.pump();
      expect(fakeRepository.signInCallCount, 1);

      completer.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('ENTRER'), findsOneWidget);
    },
  );
}
