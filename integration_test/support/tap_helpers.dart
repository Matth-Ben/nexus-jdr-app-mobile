import 'package:flutter_test/flutter_test.dart';

/// Timeout court (au lieu des 10 minutes par defaut de
/// `WidgetTester.pumpAndSettle`) pour TOUS les `pumpAndSettle` de ce
/// dossier -- une vraie action/transition reseau de cette app se
/// stabilise en quelques secondes au pire ; au-dela, mieux vaut un echec
/// de test rapide et explicite (`FlutterError` de timeout, avec la pile
/// d'appel exacte) qu'un test qui semble "bloque" indefiniment (vecu
/// en conditions reelles pendant cette campagne QA : un defaut de 10 min
/// masquait un vrai probleme -- apply du niveau 2 jamais retombe -- sous
/// une attente si longue qu'elle semblait un plantage de l'outillage).
///
/// Correctif D111 (`docs/dette-technique.md`) : avant ce correctif, cette
/// constante etait passee en 1er argument positionnel de `pumpAndSettle`
/// (`pumpAndSettle(settleTimeout)`) -- qui correspond a `duration`
/// (l'intervalle entre deux pumps), pas a `timeout` (3e argument). Elle ne
/// raccourcissait donc rien : le vrai timeout de blocage restait le defaut
/// Flutter de 10 minutes.
///
/// `WidgetTester.pumpAndSettle` declare ses 3 parametres entre CROCHETS
/// (`[Duration duration = ..., EnginePhase phase = ...,
/// Duration timeout = ...]`, voir `flutter_test/lib/src/widget_tester.dart`)
/// -- donc POSITIONNELS optionnels, PAS nommes (accolades) malgre leurs noms
/// explicites dans la signature : `pumpAndSettle(timeout: settleTimeout)`
/// echoue a la compilation (`undefined_named_parameter`, verifie en tentant
/// ce correctif). Utiliser [settleQuickly] ci-dessous plutot que
/// `tester.pumpAndSettle(settleTimeout)` nu -- il positionne correctement
/// cette constante en 3e argument, apres les 2 premiers a leur valeur par
/// defaut.
const Duration settleTimeout = Duration(seconds: 10);

/// Equivalent de `tester.pumpAndSettle()` avec le timeout court
/// [settleTimeout] au lieu du defaut Flutter de 10 minutes -- a utiliser
/// PARTOUT dans ce dossier a la place de `tester.pumpAndSettle(settleTimeout)`
/// (voir la doc de [settleTimeout], correctif D111).
Future<void> settleQuickly(WidgetTester tester) => tester.pumpAndSettle(
  const Duration(milliseconds: 100),
  EnginePhase.sendSemanticsUpdate,
  settleTimeout,
);

/// Construit un nom de personnage de test unique, suffixe d'un horodatage en
/// microsecondes -- correctif D109 (`docs/dette-technique.md`) : plusieurs
/// fichiers `level_up_*`/`multiclass_*` codaient leur nom de personnage de
/// test en dur (ex. `'QA-Test-Ensorceleur'`), sans aucun moyen de le faire
/// varier -- relancer un meme fichier deux fois sur le projet Supabase
/// distant partage (jamais nettoye automatiquement, voir
/// `integration_test/README.md` "Donnees de test laissees en base") cree
/// alors un doublon supplementaire a chaque fois (3 deja trouves en base
/// pour `QA-Test-Ensorceleur` avant ce correctif, voir D107). Meme principe
/// que `login_screen_test.dart`, qui horodate deja ses e-mails jetables pour
/// la meme raison.
String qaUniqueCharacterName(String base) =>
    '$base-${DateTime.now().microsecondsSinceEpoch}';

/// Fait défiler [finder] (premier résultat si plusieurs correspondances,
/// voir [skip]) dans le `Scrollable` ancêtre le plus proche puis tape
/// dessus — jamais par coordonnées d'écran (voir `integration_test/README.md`,
/// section "Sélecteurs"), même patron que `login_screen_test.dart::_tapText`.
///
/// Réutilisé par tous les parcours de ce dossier (assistant de création,
/// montée de niveau) pour taper un bouton/une tuile identifiée par son texte
/// visible : tous les boutons `PrimaryButton`/`SecondaryButton` affichent
/// leur libellé en MAJUSCULES (`label.toUpperCase()`), donc [text] doit être
/// déjà en majuscules pour un bouton — voir
/// `core/widgets/primary_button.dart`/`secondary_button.dart`. Les titres de
/// tuile (`SelectableOptionTile`/`CheckableOptionTile`) gardent eux leur
/// casse d'origine (pas de transformation, voir leurs sources).
Future<void> tapText(WidgetTester tester, String text, {int skip = 0}) async {
  final finder = find.text(text);
  final target = finder.at(skip);
  await tester.ensureVisible(target);
  await settleQuickly(tester);
  await tester.tap(target);
  await settleQuickly(tester);
}

/// Variante de [tapText] qui n'échoue pas si [text] n'existe pas sur l'écran
/// actuel — renvoie `true` si le tap a eu lieu. Utilisée pour les étapes
/// optionnelles de l'assistant de création/montée de niveau (ex. sous-race,
/// bonus racial au choix, étape "Choix à faire") dont la présence dépend des
/// données choisies plus haut dans le parcours.
Future<bool> tapTextIfPresent(WidgetTester tester, String text) async {
  if (find.text(text).evaluate().isEmpty) return false;
  await tapText(tester, text);
  return true;
}

/// `true` si [text] est présent à l'écran, sans tenter de défiler ni taper —
/// utilisé pour les assertions de présence/absence d'une étape (ex.
/// régression "Disciplines élémentaires" absente pour un Moine d'une autre
/// sous-classe).
bool isTextPresent(String text) => find.text(text).evaluate().isNotEmpty;

/// Pompe plusieurs fois avec une petite pause, pour les transitions réseau
/// qu'un seul `pumpAndSettle` ne couvre pas toujours de façon fiable (même
/// rationale que `app_launch.dart::launchApp`) — utilisé après une action qui
/// déclenche un appel Supabase (ex. "Créer le personnage", "Continuer" sur le
/// récapitulatif de montée de niveau).
Future<void> pumpUntilSettled(
  WidgetTester tester, {
  int attempts = 20,
  Duration step = const Duration(milliseconds: 500),
}) async {
  for (var i = 0; i < attempts; i++) {
    await tester.pump(step);
  }
  await settleQuickly(tester);
}

/// Fait défiler [listFinder] (typiquement `find.byType(ListView).first`) par
/// petits pas jusqu'à ce que [text] soit monté dans l'arbre de widgets, puis
/// tape dessus — nécessaire pour les tuiles hors du `cacheExtent` initial
/// d'une liste longue (ex. l'étape 1/9 "Race" : ~38 races, les dernières de
/// la liste "RACES D'EXTENSION" ne sont pas montées tant qu'on n'a pas
/// défilé jusqu'à elles, même avec `ListView(children: [...])` — la
/// construction reste paresseuse par sliver sous le capot). Préférer
/// [tapText] seul quand [text] est déjà visible sans défilement (ex. tout
/// le reste de l'assistant de création, dont les listes sont courtes).
Future<void> scrollUntilVisibleThenTap(
  WidgetTester tester,
  Finder listFinder,
  String text, {
  int maxDrags = 25,
}) async {
  for (var i = 0; i < maxDrags; i++) {
    if (find.text(text).evaluate().isNotEmpty) {
      await tapText(tester, text);
      return;
    }
    await tester.drag(listFinder, const Offset(0, -250));
    await settleQuickly(tester);
  }
  // Dernière tentative (déclenche l'erreur standard de `tapText` si toujours
  // absent, plutôt qu'un échec silencieux).
  await tapText(tester, text);
}
