// Jamais teste en live avant cette campagne QA (21/10/2026) : creation de
// l'Ensorceleur avec choix d'Origine magique DES LA CREATION (sous-classe
// niveau 1), sorts connus, points de sorcellerie (niveau 2), Metamagie
// (niveau 3), puis ASI (niveau 4).
//
// BUG trouve et reproduit 2 fois sur l'app reelle le 21/10/2026 (CORRIGE
// depuis -- voir D113, docs/dette-technique.md) : la montee de niveau 3
// (Metamagie) ne menait jamais a un ecran affichant un bouton "CONTINUER"
// exploitable -- `tapText(tester, 'CONTINUER')` echouait avec un
// `RangeError` juste apres l'annonce du niveau, faute de cablage cote app
// (Metamagie absente de `LevelUpChoiceKind`/`LevelUpBlockRules` et de
// `level_up_screen.dart`, voir l'audit `choice_type` du 21/10, D94). Cable
// depuis par le correctif Metamagie/Expertise/Ancetre draconique (PR #161,
// commit 9c386b0) : `support/level_up_flow.dart::runOneLevelUp` gere
// maintenant l'etape "NOUVELLES OPTIONS DE METAMAGIE" comme les autres
// choix a quota (disciplines elementaires, manoeuvres). Ce fichier n'attend
// donc plus de blocage au niveau 3 (voir l'`expect`/`fail` ci-dessous).
//
// Nom exact de l'Origine magique seme en base non confirme a l'ecriture de
// ce test (seul "Domaine de la Vie" du Clerc et "Le Grand Ancien" de
// l'Occultiste ont ete confirmes par lecture du code existant) -- utilise
// `autoPickSubclassIfOffered` (support/character_creation_flow.dart) qui
// tape la PREMIERE option proposee, quelle qu'elle soit, plutot que de
// deviner un nom au risque de faire echouer le test sur un mauvais
// selecteur.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_launch.dart';
import 'support/character_creation_flow.dart';
import 'support/level_up_flow.dart';
import 'support/qa_test_account.dart';
import 'support/tap_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Ensorceleur : creation avec Origine magique (premiere '
      'proposee), sorts connus, Metamagie (niveau 3), ASI (niveau 4), '
      'jamais de blocage', (tester) async {
    if (!hasQaTestAccount) {
      // ignore: avoid_print
      print('SKIP: $qaTestAccountMissingReason');
      return;
    }
    await launchApp(tester);
    if (find.text('ENTRER DANS LA TAVERNE').evaluate().isNotEmpty) {
      await loginWithQaTestAccount(tester);
    }
    await tapTextIfPresent(tester, 'Passer');
    await pumpUntilSettled(tester, attempts: 6);

    // Horodate (D109, docs/dette-technique.md) : relancer ce fichier sans
    // suffixe variable creait un doublon supplementaire a chaque fois (3
    // deja trouves en base avant ce correctif, voir D107).
    final name = qaUniqueCharacterName('QA-Test-Ensorceleur');
    await createCharacter(
      tester,
      characterName: name,
      raceName: 'Génasi',
      subraceName: 'Génasi du feu',
      className: 'Ensorceleur',
      autoPickSubclassIfOffered: true,
      backgroundName: 'Acolyte',
    );

    await openCharacterByName(tester, name);

    await openLevelUpFromCharacterDetail(tester);
    final level2 = await runOneLevelUp(tester);
    if (level2.blocked) {
      fail(
        "BUG a transmettre a dev-flutter : le niveau 2 de l'Ensorceleur "
        '(points de sorcellerie) bloque. Texte observe : ${level2.screenText}',
      );
    }

    await openLevelUpFromCharacterDetail(tester);
    final level3 = await runOneLevelUp(tester);
    if (level3.blocked) {
      fail(
        "BUG a transmettre a dev-flutter : le niveau 3 de l'Ensorceleur "
        '(Metamagie) bloque. Texte observe : ${level3.screenText}',
      );
    }

    await openLevelUpFromCharacterDetail(tester);
    final level4 = await runOneLevelUp(tester);
    if (level4.blocked) {
      fail(
        "BUG a transmettre a dev-flutter : l'ASI de l'Ensorceleur "
        '(niveau 4) bloque. Texte observe : ${level4.screenText}',
      );
    }

    // ignore: avoid_print
    print(
      'OBSERVATION Ensorceleur niveau 4 -- texte visible sur la fiche : '
      '${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().toList()}',
    );

    if (find.text('SORTS').evaluate().isNotEmpty) {
      await tapText(tester, 'SORTS');
      await pumpUntilSettled(tester, attempts: 4);
      // ignore: avoid_print
      print(
        'OBSERVATION onglet SORTS (Ensorceleur niveau 4) : '
        '${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().toList()}',
      );
    }

    if (find.text('APT.').evaluate().isNotEmpty) {
      await tapText(tester, 'APT.');
      await pumpUntilSettled(tester, attempts: 4);
      // ignore: avoid_print
      print(
        'OBSERVATION onglet APT. (Ensorceleur niveau 4, Metamagie '
        "attendue) : ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().toList()}",
      );
    }
  });
}
