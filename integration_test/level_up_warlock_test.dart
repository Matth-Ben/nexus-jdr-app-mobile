// Jamais teste en live SEUL avant cette campagne QA (21/10/2026) : l'Occultiste
// n'a ete exerce jusqu'ici qu'en multiclassage (Paladin/Occultiste). Choix
// du patron DES LA CREATION (sous-classe niveau 1), invocations occultes
// (niveau 2, choice_type 'invocation' -- etape dediee, voir
// domain/level_up_choice_kind.dart), Faveur de pacte (niveau 3,
// choice_type 'pacte'), puis ASI (niveau 4).
//
// Nom exact du patron seme en base non confirme avec certitude (voir le
// commentaire de level_up_sorcerer_test.dart) -- utilise
// `autoPickSubclassIfOffered` plutot que de deviner.
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

  testWidgets('Occultiste (seul, pas en multiclasse) : creation avec patron '
      '(premier propose), invocations (niveau 2), Faveur de pacte '
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
    final name = qaUniqueCharacterName('QA-Test-Occultiste');
    await createCharacter(
      tester,
      characterName: name,
      raceName: 'Conil',
      className: 'Occultiste',
      autoPickSubclassIfOffered: true,
      backgroundName: 'Acolyte',
    );

    await openCharacterByName(tester, name);

    await openLevelUpFromCharacterDetail(tester);
    final level2 = await runOneLevelUp(tester);
    if (level2.blocked) {
      fail(
        "BUG a transmettre a dev-flutter : le niveau 2 de l'Occultiste "
        '(invocations occultes) bloque. Texte observe : ${level2.screenText}',
      );
    }

    await openLevelUpFromCharacterDetail(tester);
    final level3 = await runOneLevelUp(tester);
    if (level3.blocked) {
      fail(
        "BUG a transmettre a dev-flutter : le niveau 3 de l'Occultiste "
        '(Faveur de pacte) bloque. Texte observe : ${level3.screenText}',
      );
    }

    await openLevelUpFromCharacterDetail(tester);
    final level4 = await runOneLevelUp(tester);
    if (level4.blocked) {
      fail(
        "BUG a transmettre a dev-flutter : l'ASI de l'Occultiste "
        '(niveau 4) bloque. Texte observe : ${level4.screenText}',
      );
    }

    // ignore: avoid_print
    print(
      'OBSERVATION Occultiste niveau 4 -- texte visible sur la fiche : '
      '${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().toList()}',
    );

    if (find.text('SORTS').evaluate().isNotEmpty) {
      await tapText(tester, 'SORTS');
      await pumpUntilSettled(tester, attempts: 4);
      // ignore: avoid_print
      print(
        'OBSERVATION onglet SORTS (Occultiste niveau 4) : '
        '${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().toList()}',
      );
    }

    if (find.text('APT.').evaluate().isNotEmpty) {
      await tapText(tester, 'APT.');
      await pumpUntilSettled(tester, attempts: 4);
      // ignore: avoid_print
      print(
        'OBSERVATION onglet APT. (Occultiste niveau 4, Faveur de pacte '
        "attendue) : ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().toList()}",
      );
    }
  });
}
