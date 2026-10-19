// Verifie en conditions reelles (vrai appareil, vrai Supabase distant) le
// point de vigilance signale en dette technique D84 : le choix des 3
// manoeuvres du Guerrier Maitre de guerre (niveau 3) est-il bien propose,
// ou silencieusement absent / bloquant (meme trou que le Moine Voie des
// quatre elements avant son correctif) ? Ce test n'affirme PAS un resultat
// attendu -- il observe et rapporte precisement l'etat reel (voir le
// rapport de campagne correspondant), conformement a la consigne : ne pas
// trancher seul, remonter precisement a dev-flutter si bloque ou absent.
//
// Couvre aussi la race Orc (point d'attention de l'audit).
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

  testWidgets('Guerrier Maitre de guerre (niveau 3) : observation du choix de '
      'manoeuvres (D84)', (tester) async {
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

    const name = 'QA-Test-GuerrierOrc';
    await createCharacter(
      tester,
      characterName: name,
      raceName: 'Orc',
      className: 'Guerrier',
      backgroundName: 'Acolyte',
    );

    await openCharacterByName(tester, name);

    await openLevelUpFromCharacterDetail(tester);
    final level2 = await runOneLevelUp(tester);
    expect(level2.blocked, isFalse, reason: 'niveau 2 ne doit jamais bloquer');

    await openLevelUpFromCharacterDetail(tester);
    final level3 = await runOneLevelUp(
      tester,
      choicePicker: (titles) => titles.firstWhere(
        (t) => t.toLowerCase().contains('guerre'),
        orElse: () => titles.first,
      ),
    );

    if (level3.blocked) {
      fail(
        'BUG a transmettre a dev-flutter (meme famille que le Moine Voie '
        'des quatre elements avant correctif, voir D84 du registre de '
        'dette technique) : le niveau 3 du Guerrier Maitre de guerre '
        'bloque sur un choice_type non resolu. Texte observe : '
        '${level3.screenText}',
      );
    }

    // Pas de blocage : on devrait etre revenu sur la fiche personnage.
    // ignore: avoid_print
    print(
      'OBSERVATION niveau 3 Guerrier Maitre de guerre -- texte visible '
      'apres le flux : ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().toList()}',
    );

    // Ouvre l'onglet "APT." pour capturer les aptitudes de classe
    // affichees a ce niveau (observation du contenu reel, pas une
    // assertion -- voir la consigne de la campagne).
    if (find.text('APT.').evaluate().isNotEmpty) {
      await tapText(tester, 'APT.');
      await pumpUntilSettled(tester, attempts: 4);
      // ignore: avoid_print
      print(
        'OBSERVATION onglet APT. (Guerrier Maitre de guerre, niveau 3) : ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().toList()}',
      );
    }
  });
}
