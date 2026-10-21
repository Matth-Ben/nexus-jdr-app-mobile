// Jamais teste en live avant cette campagne QA (21/10/2026) : creation de
// l'Ensorceleur avec choix d'Origine magique DES LA CREATION (sous-classe
// niveau 1), sorts connus, points de sorcellerie (niveau 2), Metamagie
// (niveau 3), puis ASI (niveau 4).
//
// BUG trouve et reproduit 2 fois sur l'app reelle (21/10/2026, jamais
// corrige ici -- a transmettre a dev-flutter) : la montee de niveau 3
// (Metamagie) ne mene jamais a un ecran affichant un bouton "CONTINUER"
// exploitable -- `tapText(tester, 'CONTINUER')` echoue avec un `RangeError`
// (aucune occurrence du texte trouvee), juste apres l'annonce du niveau.
// Aucune exception n'est levee cote app (pas d'"EXCEPTION CAUGHT BY WIDGETS
// LIBRARY" dans les logs), donc pas un plantage franc -- plutot un ecran
// inattendu que ce test ne sait pas interpreter. Cause probable (lecture de
// code, pas confirmee par acces direct a la base) :
// `domain/level_up_choice_kind.dart::LevelUpChoiceKind` et
// `domain/level_up_block_reason.dart::LevelUpBlockRules.resolvedChoiceTypes`
// ne contiennent AUCUNE valeur pour la Metamagie (contrairement a
// 'sous_classe'/'style_combat'/'ennemi_jure'/'pacte'/'invocation'/
// 'discipline_elementaire'), et aucune etape dediee de
// `presentation/level_up_screen.dart` ne la mentionne (recherche
// "metamagie"/"metamagic" infructueuse dans tout `lib/features/characters`).
// La Metamagie du Sorcier (PHB, niveau 3, 2 options parmi la liste complete)
// semble donc ne jamais avoir ete implementee cote app, a la difference des
// manoeuvres du Guerrier Maitre de guerre (implementees mais non couvertes
// par ce dossier de tests avant cette campagne, voir
// level_up_fighter_battle_master_test.dart).
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

    const name = 'QA-Test-Ensorceleur';
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
