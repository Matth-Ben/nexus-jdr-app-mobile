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
  // Le champ mot de passe déclenche déjà la connexion sur l'action IME
  // "done" (`onFieldSubmitted: (_) => onSubmit()`, voir
  // `lib/features/auth/presentation/login_screen.dart`) : cette seule
  // action suffit à soumettre le formulaire, exactement comme un joueur qui
  // valide son clavier plutôt que de taper le bouton. `pumpAndSettle` laisse
  // la soumission démarrer (le bouton passe en `isLoading`, qui REMPLACE son
  // libellé "ENTRER" par un `CircularProgressIndicator` — voir
  // `core/widgets/primary_button.dart` — jamais les deux en même temps).
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();

  // Bug trouvé en exécutant ce helper pour la première fois en conditions
  // réelles (campagne QA du 19/10/2026, compte de test enfin débloqué) :
  // un second `tap(find.text('ENTRER'))` inconditionnel après l'action
  // "done" ci-dessus plantait avec "Found 0 widgets with text ENTRER" dès
  // que la soumission déclenchée par "done" avait déjà fait disparaître ce
  // libellé (bouton en `isLoading`, ou déjà redirigé après connexion
  // réussie) — `tester.tap` n'accepte aucun `Finder` vide. Le second tap
  // n'a donc plus de raison d'être inconditionnel : il ne sert plus qu'en
  // repli défensif, si jamais l'action "done" simulée n'avait, pour une
  // raison quelconque (ex. future variante de cet écran), pas déjà
  // déclenché la soumission — jamais par coordonnées d'écran, toujours par
  // ce même sélecteur texte (voir `core/widgets/primary_button.dart` pour
  // la mise en majuscules du libellé).
  final entrerButton = find.text('ENTRER');
  if (entrerButton.evaluate().isNotEmpty) {
    await tester.tap(entrerButton);
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  for (var attempt = 0; attempt < 20; attempt++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
  await tester.pumpAndSettle(const Duration(seconds: 2));
}
