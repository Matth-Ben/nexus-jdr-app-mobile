import 'package:flutter_test/flutter_test.dart';

import 'app_launch.dart';

/// Compte de test confirmé, fourni via `--dart-define` (jamais en dur ici,
/// jamais committé — voir `integration_test/README.md`) :
///
/// ```
/// flutter test integration_test/<fichier>.dart -d emulator-5554 \
///   --dart-define-from-file=config/dev.json \
///   --dart-define-from-file=config/qa_test_account.json
/// ```
///
/// Nécessaire car la confirmation par e-mail est activée sur le projet
/// Supabase distant partagé dev/staging/prod (voir la doc de classe
/// d'`AuthRepository.signUp`, `lib/features/auth/data/auth_repository.dart`) :
/// un compte créé par un `signUp` automatisé depuis ce dossier ne reçoit
/// jamais de session (personne pour cliquer le lien de confirmation), donc
/// aucun scénario authentifié (fiche personnage, assistant de création,
/// montée de niveau, multiclassage...) ne peut démarrer sans un compte
/// *déjà* confirmé au préalable — à créer une fois manuellement (inscription
/// réelle + clic sur le lien de confirmation reçu par e-mail), puis à
/// réutiliser ici.
const String qaTestEmail = String.fromEnvironment('QA_TEST_EMAIL');
const String qaTestPassword = String.fromEnvironment('QA_TEST_PASSWORD');

/// `true` si [qaTestEmail]/[qaTestPassword] ont été fournis — les tests qui
/// en dépendent doivent se `skip` explicitement sinon (jamais échouer avec
/// un message d'erreur réseau opaque), voir [requireQaTestAccount].
bool get hasQaTestAccount =>
    qaTestEmail.isNotEmpty && qaTestPassword.isNotEmpty;

/// Message de `skip` uniforme pour tout test authentifié de ce dossier tant
/// que [hasQaTestAccount] est faux.
const String qaTestAccountMissingReason =
    'QA_TEST_EMAIL/QA_TEST_PASSWORD non fournis — voir '
    'integration_test/support/qa_test_account.dart et '
    'integration_test/README.md pour créer/configurer le compte de test '
    'confirmé requis par les scénarios authentifiés.';

/// Connecte [tester] avec le compte de test confirmé ([qaTestEmail]/
/// [qaTestPassword]) depuis l'écran de connexion déjà affiché (voir
/// [launchApp]), puis attend la redirection post-login pilotée par le
/// routeur (`core/router/app_router.dart`, réagit à `onAuthStateChange`).
///
/// N'appelle jamais [hasQaTestAccount] elle-même : c'est à l'appelant de
/// `skip` le test entier si le compte n'est pas configuré (voir
/// [qaTestAccountMissingReason]), pour que l'absence de compte de test
/// produise un `skip` explicite dans le rapport `flutter test`, jamais un
/// échec silencieusement confondu avec une vraie régression.
Future<void> loginWithQaTestAccount(WidgetTester tester) async {
  await tester.enterText(emailFieldFinder, qaTestEmail);
  await tester.enterText(passwordFieldFinder, qaTestPassword);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();

  // `PrimaryButton` (`core/widgets/primary_button.dart`) met son libellé en
  // majuscules à l'affichage (`label.toUpperCase()`) — le texte réellement
  // rendu est donc "ENTRER", pas "Entrer". `tester.tap` sur ce `Text` suffit
  // à déclencher l'`InkWell` ancêtre (hit-test standard du moteur de rendu),
  // sans jamais cibler de coordonnées d'écran.
  await tester.tap(find.text('ENTRER'));

  await tester.pumpAndSettle(const Duration(seconds: 1));
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
  await tester.pumpAndSettle(const Duration(seconds: 2));
}
