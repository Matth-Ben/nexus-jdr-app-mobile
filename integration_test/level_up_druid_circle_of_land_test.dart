// Verifie en conditions reelles le point de vigilance Druide Cercle de la
// Terre (niveau 2) -- D82 du registre de dette technique : soit le choix
// de terrain (8 options) n'apparait pas du tout (contenu pas encore
// peuple cote base), soit les 8 terrains apparaissent melanges sans
// distinction (bug D82 deja connu). Ce test n'affirme PAS un resultat
// attendu -- il observe et rapporte precisement l'etat reel.
//
// Couvre aussi la race Aasimar (bonus racial au choix, point d'attention
// de l'audit).
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

  testWidgets('Druide Cercle de la Terre (niveau 2) : observation du choix de '
      'terrain (D82)', (tester) async {
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

    const name = 'QA-Test-DruideAasimar';
    await createCharacter(
      tester,
      characterName: name,
      raceName: 'Aasimar',
      className: 'Druide',
      backgroundName: 'Acolyte',
    );

    await openCharacterByName(tester, name);

    await openLevelUpFromCharacterDetail(tester);
    final level2 = await runOneLevelUp(
      tester,
      choicePicker: (titles) => titles.firstWhere(
        (t) => t.toLowerCase().contains('terre'),
        orElse: () => titles.first,
      ),
    );

    if (level2.blocked) {
      fail(
        'BUG a transmettre a dev-flutter : le niveau 2 du Druide Cercle '
        'de la Terre bloque sur un choice_type non resolu. Texte '
        'observe : ${level2.screenText}',
      );
    }

    // ignore: avoid_print
    print(
      'OBSERVATION niveau 2 Druide Cercle de la Terre -- texte visible '
      'apres le flux : ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().toList()}',
    );

    if (find.text('APT.').evaluate().isNotEmpty) {
      await tapText(tester, 'APT.');
      await pumpUntilSettled(tester, attempts: 4);
      // ignore: avoid_print
      print(
        'OBSERVATION onglet APT. (Druide Cercle de la Terre, niveau 2) : ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().toList()}',
      );
    }
  });
}
