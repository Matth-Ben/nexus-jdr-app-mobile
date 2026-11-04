// Tests de la boîte de dialogue "Mot de passe oublié ?"
// (`lib/features/auth/presentation/widgets/forgot_password_dialog.dart`),
// ouverte depuis `login_screen.dart` en mode connexion.
//
// Même stratégie que `login_screen_test.dart` : un double de test
// (`_FakeAuthRepository`) injecté via `authRepositoryProvider
// .overrideWithValue`, jamais `Supabase.instance.client`.
//
// Point central de ces tests : que l'appel réussisse ou échoue, la boîte de
// dialogue se ferme et affiche toujours le même message neutre
// (`forgotPasswordNeutralMessage` ci-dessous, texte français résolu via
// `AppLocalizations` — chantier "traduction de l'app" Phase B) — jamais un
// message qui confirmerait ou infirmerait l'existence d'un compte pour
// l'e-mail saisi (voir la doc de classe de `showForgotPasswordDialog`).

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/features/auth/data/auth_repository.dart';
import 'package:personnages/features/auth/presentation/providers/auth_providers.dart';
import 'package:personnages/features/auth/presentation/widgets/forgot_password_dialog.dart';
import 'package:personnages/l10n/app_localizations.dart';

/// Texte français du message neutre (`app_fr.arb::authForgotPasswordNeutralMessage`),
/// dupliqué ici plutôt que résolu via `AppLocalizations` (voir
/// `profile_language_screen_test.dart` pour le même principe) : ces tests
/// forcent la locale `fr` ci-dessous, donc ce texte reste la valeur
/// attendue à l'écran.
const String forgotPasswordNeutralMessage =
    'Si un compte existe avec cet email, un lien de réinitialisation vient '
    "d'être envoyé.";

/// Même principe que [forgotPasswordNeutralMessage], texte anglais
/// (`app_en.arb::authForgotPasswordNeutralMessage`) — utilisé par le groupe
/// "locale anglaise" ci-dessous.
const String forgotPasswordNeutralMessageEn =
    'If an account exists with this email, a reset link has just been sent.';

class _FakeAuthRepository implements AuthRepository {
  int resetPasswordCallCount = 0;
  String? lastEmail;
  Object? resetPasswordError;
  Completer<void>? resetPasswordCompleter;

  @override
  Future<void> resetPasswordForEmail({required String email}) async {
    resetPasswordCallCount++;
    lastEmail = email;
    if (resetPasswordCompleter != null) {
      await resetPasswordCompleter!.future;
    }
    if (resetPasswordError != null) {
      throw resetPasswordError!;
    }
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
    String? displayName,
  }) async => false;

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signInWithApple() async {}

  @override
  Future<void> signOut() async {}

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

  @override
  Future<void> markOnboardingSeen() async {}
}

void main() {
  late _FakeAuthRepository fakeRepository;

  setUp(() {
    fakeRepository = _FakeAuthRepository();
  });

  Widget buildTestWidget({
    String initialEmail = '',
    Locale locale = const Locale('fr'),
  }) {
    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
      child: MaterialApp(
        // Locale forcée (déterministe, indépendante de l'hôte qui exécute
        // `flutter test`) : les assertions de ces tests comparent du texte
        // en dur dans [locale], même principe que
        // `profile_language_screen_test.dart`. `fr` par défaut, `en` passé
        // explicitement par le groupe "locale anglaise" ci-dessous.
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: Scaffold(
          body: Builder(
            builder: (context) => Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () => showForgotPasswordDialog(
                  context,
                  ref: ref,
                  initialEmail: initialEmail,
                ),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openDialog(
    WidgetTester tester, {
    String initialEmail = '',
    Locale locale = const Locale('fr'),
  }) async {
    await tester.pumpWidget(
      buildTestWidget(initialEmail: initialEmail, locale: locale),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'préremplit le champ avec l\'e-mail déjà saisi sur le formulaire de connexion',
    (WidgetTester tester) async {
      await openDialog(tester, initialEmail: 'nom@exemple.com');

      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(field.controller?.text, 'nom@exemple.com');
    },
  );

  testWidgets('affiche le champ vide si aucun e-mail n\'était saisi', (
    WidgetTester tester,
  ) async {
    await openDialog(tester);

    final field = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(field.controller?.text, isEmpty);
  });

  testWidgets(
    'affiche une erreur de validation et n\'appelle pas le dépôt pour un e-mail invalide',
    (WidgetTester tester) async {
      await openDialog(tester, initialEmail: 'pas-un-email');

      // `find.text('Envoyer le lien')` ne correspond à rien : `PrimaryButton`
      // affiche son libellé en majuscules (`label.toUpperCase()`), même
      // convention que dans `login_screen_test.dart` (qui cible le bouton
      // par type plutôt que par texte, pour la même raison).
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(find.text('Adresse e-mail invalide.'), findsOneWidget);
      expect(fakeRepository.resetPasswordCallCount, 0);
    },
  );

  testWidgets(
    'annuler ferme la boîte de dialogue sans appeler le dépôt ni afficher de message',
    (WidgetTester tester) async {
      await openDialog(tester, initialEmail: 'nom@exemple.com');

      // Même remarque que ci-dessus pour `PrimaryButton` : `SecondaryButton`
      // affiche aussi son libellé en majuscules.
      await tester.tap(find.byType(SecondaryButton));
      await tester.pumpAndSettle();

      expect(find.text('Mot de passe oublié ?'), findsNothing);
      expect(fakeRepository.resetPasswordCallCount, 0);
      expect(find.text(forgotPasswordNeutralMessage), findsNothing);
    },
  );

  testWidgets(
    'affiche un indicateur de chargement pendant l\'appel, boutons désactivés',
    (WidgetTester tester) async {
      final completer = Completer<void>();
      fakeRepository.resetPasswordCompleter = completer;

      await openDialog(tester, initialEmail: 'nom@exemple.com');
      // `find.text('Envoyer le lien')` ne correspond à rien : `PrimaryButton`
      // affiche son libellé en majuscules (`label.toUpperCase()`), même
      // convention que dans `login_screen_test.dart` (qui cible le bouton
      // par type plutôt que par texte, pour la même raison).
      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'au succès : ferme la boîte de dialogue et affiche le message neutre',
    (WidgetTester tester) async {
      await openDialog(tester, initialEmail: 'nom@exemple.com');

      // `find.text('Envoyer le lien')` ne correspond à rien : `PrimaryButton`
      // affiche son libellé en majuscules (`label.toUpperCase()`), même
      // convention que dans `login_screen_test.dart` (qui cible le bouton
      // par type plutôt que par texte, pour la même raison).
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(fakeRepository.resetPasswordCallCount, 1);
      expect(fakeRepository.lastEmail, 'nom@exemple.com');
      expect(find.text('Mot de passe oublié ?'), findsNothing);
      expect(find.text(forgotPasswordNeutralMessage), findsOneWidget);
    },
  );

  testWidgets(
    "à l'échec (ex. absence de réseau) : ferme aussi la boîte de dialogue et "
    'affiche exactement le même message neutre, jamais un message révélant '
    "l'existence d'un compte",
    (WidgetTester tester) async {
      fakeRepository.resetPasswordError = Exception('boom');

      await openDialog(tester, initialEmail: 'nom@exemple.com');

      // `find.text('Envoyer le lien')` ne correspond à rien : `PrimaryButton`
      // affiche son libellé en majuscules (`label.toUpperCase()`), même
      // convention que dans `login_screen_test.dart` (qui cible le bouton
      // par type plutôt que par texte, pour la même raison).
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(fakeRepository.resetPasswordCallCount, 1);
      expect(find.text('Mot de passe oublié ?'), findsNothing);
      expect(find.text(forgotPasswordNeutralMessage), findsOneWidget);
    },
  );

  group('locale anglaise', () {
    // Trou de couverture signalé par `qa-testeur` (chantier "traduction de
    // l'app" Phase B, lot "Auth") : jusqu'ici ce fichier ne pompait jamais
    // la boîte de dialogue qu'en français (voir `buildTestWidget`) — aucun
    // test ne garantissait qu'un texte anglais s'affiche réellement quand
    // la locale de l'app est `en`.
    testWidgets('affiche le titre, le bouton et le message neutre en anglais', (
      WidgetTester tester,
    ) async {
      await openDialog(
        tester,
        initialEmail: 'nom@exemple.com',
        locale: const Locale('en'),
      );

      expect(find.text('Forgot your password?'), findsOneWidget);
      // `SecondaryButton`/`PrimaryButton` affichent leur libellé en
      // majuscules (`label.toUpperCase()`), même remarque que les tests
      // français ci-dessus.
      expect(find.text('CANCEL'), findsOneWidget);
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(find.text('Forgot your password?'), findsNothing);
      expect(find.text(forgotPasswordNeutralMessageEn), findsOneWidget);
    });
  });
}
