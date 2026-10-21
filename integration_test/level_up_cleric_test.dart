// Jamais teste en live SEUL avant cette campagne QA (21/10/2026) : le Clerc
// n'a ete exerce jusqu'ici qu'en multiclassage (Magicien/Clerc). Choix du
// Domaine divin DES LA CREATION (sous-classe niveau 1, voir
// domain/subclass_choice_block.dart), sorts prepares, puis montee jusqu'a
// l'ASI (niveau 4).
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

  testWidgets('Clerc (seul, pas en multiclasse) : creation avec Domaine de '
      'la Vie, sorts prepares, ASI (niveau 4), jamais de blocage', (
    tester,
  ) async {
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

    const name = 'QA-Test-Clerc';
    await createCharacter(
      tester,
      characterName: name,
      raceName: 'Aasimar',
      className: 'Clerc',
      subclassName: 'Domaine de la Vie',
      backgroundName: 'Acolyte',
    );

    await openCharacterByName(tester, name);

    await openLevelUpFromCharacterDetail(tester);
    final level2 = await runOneLevelUp(tester);
    if (level2.blocked) {
      fail(
        'BUG a transmettre a dev-flutter : le niveau 2 du Clerc (Conduit '
        "divin) bloque. Texte observe : ${level2.screenText}",
      );
    }

    await openLevelUpFromCharacterDetail(tester);
    final level3 = await runOneLevelUp(tester);
    if (level3.blocked) {
      fail(
        'BUG a transmettre a dev-flutter : le niveau 3 du Clerc bloque. '
        'Texte observe : ${level3.screenText}',
      );
    }

    await openLevelUpFromCharacterDetail(tester);
    final level4 = await runOneLevelUp(tester);
    if (level4.blocked) {
      fail(
        "BUG a transmettre a dev-flutter : l'ASI du Clerc (niveau 4) "
        'bloque. Texte observe : ${level4.screenText}',
      );
    }

    // ignore: avoid_print
    print(
      'OBSERVATION Clerc niveau 4 -- texte visible sur la fiche : '
      '${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().toList()}',
    );

    if (find.text('SORTS').evaluate().isNotEmpty) {
      await tapText(tester, 'SORTS');
      await pumpUntilSettled(tester, attempts: 4);
      // ignore: avoid_print
      print(
        'OBSERVATION onglet SORTS (Clerc niveau 4) : '
        '${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().toList()}',
      );
    }
  });
}
