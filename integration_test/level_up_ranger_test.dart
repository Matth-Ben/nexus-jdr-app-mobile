// Jamais teste en live SEUL avant cette campagne QA (21/10/2026) : le
// Rodeur n'a ete exerce jusqu'ici qu'en multiclassage (Rodeur/Druide).
// Creation sans sorts (lanceur demi-sorts qui commence au niveau 2 pour
// cette classe), Archetype (sous-classe, niveau 3), ASI (niveau 4),
// attaque supplementaire (niveau 5, classe martiale -- voir la consigne de
// campagne).
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

  testWidgets('Rodeur (seul, pas en multiclasse) : creation, premiers '
      'sorts (niveau 2), Archetype (niveau 3), ASI (niveau 4), attaque '
      'supplementaire (niveau 5), jamais de blocage', (tester) async {
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

    const name = 'QA-Test-Rodeur';
    await createCharacter(
      tester,
      characterName: name,
      raceName: 'Changeforme',
      className: 'Rôdeur',
      backgroundName: 'Acolyte',
    );

    await openCharacterByName(tester, name);

    await openLevelUpFromCharacterDetail(tester);
    final level2 = await runOneLevelUp(tester);
    if (level2.blocked) {
      fail(
        'BUG a transmettre a dev-flutter : le niveau 2 du Rodeur (premiers '
        'sorts) bloque. Texte observe : ${level2.screenText}',
      );
    }

    await openLevelUpFromCharacterDetail(tester);
    final level3 = await runOneLevelUp(tester);
    if (level3.blocked) {
      fail(
        "BUG a transmettre a dev-flutter : le choix d'Archetype du Rodeur "
        '(niveau 3) bloque. Texte observe : ${level3.screenText}',
      );
    }

    await openLevelUpFromCharacterDetail(tester);
    final level4 = await runOneLevelUp(tester);
    if (level4.blocked) {
      fail(
        "BUG a transmettre a dev-flutter : l'ASI du Rodeur (niveau 4) "
        'bloque. Texte observe : ${level4.screenText}',
      );
    }

    await openLevelUpFromCharacterDetail(tester);
    final level5 = await runOneLevelUp(tester);
    if (level5.blocked) {
      fail(
        "BUG a transmettre a dev-flutter : l'attaque supplementaire du "
        'Rodeur (niveau 5) bloque. Texte observe : ${level5.screenText}',
      );
    }

    // ignore: avoid_print
    print(
      'OBSERVATION Rodeur niveau 5 -- texte visible sur la fiche : '
      '${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().toList()}',
    );

    if (find.text('SORTS').evaluate().isNotEmpty) {
      await tapText(tester, 'SORTS');
      await pumpUntilSettled(tester, attempts: 4);
      // ignore: avoid_print
      print(
        'OBSERVATION onglet SORTS (Rodeur niveau 5) : '
        '${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().toList()}',
      );
    }
  });
}
