// Jamais teste en live avant cette campagne QA (21/10/2026) : creation
// (sorts connus des le niveau 1, voir 04-fonctionnalites-app-mobile.md
// section 6) et montee de niveau du Barde jusqu'au College (sous-classe,
// niveau 3) et a l'ASI (niveau 4). Pas d'attaque supplementaire pour cette
// classe -- non teste au-dela du niveau 4 (voir la consigne de campagne).
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

  testWidgets('Barde : creation avec sorts connus, choix de College '
      '(niveau 3), ASI (niveau 4), jamais de blocage', (tester) async {
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

    // Horodate (D109, docs/dette-technique.md) : evite un doublon en base a
    // chaque relance de ce fichier.
    final name = qaUniqueCharacterName('QA-Test-Barde');
    await createCharacter(
      tester,
      characterName: name,
      raceName: 'Humain',
      className: 'Barde',
      backgroundName: 'Acolyte',
    );

    await openCharacterByName(tester, name);

    await openLevelUpFromCharacterDetail(tester);
    final level2 = await runOneLevelUp(tester);
    if (level2.blocked) {
      fail(
        'BUG a transmettre a dev-flutter : le niveau 2 du Barde (nouveaux '
        'sorts connus) bloque. Texte observe : ${level2.screenText}',
      );
    }

    await openLevelUpFromCharacterDetail(tester);
    final level3 = await runOneLevelUp(tester);
    if (level3.blocked) {
      fail(
        'BUG a transmettre a dev-flutter : le choix de College du Barde '
        '(niveau 3) bloque. Texte observe : ${level3.screenText}',
      );
    }

    await openLevelUpFromCharacterDetail(tester);
    final level4 = await runOneLevelUp(tester);
    if (level4.blocked) {
      fail(
        "BUG a transmettre a dev-flutter : l'ASI du Barde (niveau 4) "
        'bloque. Texte observe : ${level4.screenText}',
      );
    }

    // ignore: avoid_print
    print(
      'OBSERVATION Barde niveau 4 -- texte visible sur la fiche : '
      '${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().toList()}',
    );

    if (find.text('SORTS').evaluate().isNotEmpty) {
      await tapText(tester, 'SORTS');
      await pumpUntilSettled(tester, attempts: 4);
      // ignore: avoid_print
      print(
        'OBSERVATION onglet SORTS (Barde niveau 4) : '
        '${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().toList()}',
      );
    }
  });
}
