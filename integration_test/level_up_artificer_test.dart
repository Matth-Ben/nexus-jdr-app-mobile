// Jamais teste en live avant cette campagne QA (21/10/2026) : Artificier,
// classe recente dont la mecanique d'infusions (PR #159) n'est PAS encore
// utilisable -- le SQL de contenu des infusions n'est pas encore applique
// en base (voir la consigne de campagne). Ce test couvre UNIQUEMENT la
// creation et la montee de niveau standard (sorts prepares, specialisation
// au niveau 3, ASI au niveau 4) -- si le niveau 2 (qui declenche
// normalement le choix d'infusion en RAW) bloque ou affiche un etat vide
// en rapport avec les infusions, ce n'est PAS rapporte comme un bug neuf
// (deja connu, attendu tant que PR #159 n'est pas mergee) : le test
// l'observe et s'arrete proprement plutot que d'echouer dessus. Tout
// blocage SANS rapport avec les infusions reste rapporte normalement.
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

  testWidgets('Artificier : creation et montee de niveau standard '
      '(infusions non testees, PR #159 pas mergee)', (tester) async {
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

    const name = 'QA-Test-Artificier';
    await createCharacter(
      tester,
      characterName: name,
      raceName: 'Humain',
      className: 'Artificier',
      backgroundName: 'Acolyte',
    );

    await openCharacterByName(tester, name);

    await openLevelUpFromCharacterDetail(tester);
    final level2 = await runOneLevelUp(tester);
    if (level2.blocked) {
      final text = level2.screenText.join(' | ').toLowerCase();
      if (text.contains('infusion')) {
        // ignore: avoid_print
        print(
          'LIMITE CONNUE (PR #159 pas mergee) : le niveau 2 de '
          "l'Artificier bloque sur les infusions, comme attendu. Texte "
          'observe : ${level2.screenText}',
        );
        return;
      }
      fail(
        'BUG a transmettre a dev-flutter : le niveau 2 de l\'Artificier '
        'bloque pour une raison SANS rapport avec les infusions. Texte '
        'observe : ${level2.screenText}',
      );
    }

    await openLevelUpFromCharacterDetail(tester);
    final level3 = await runOneLevelUp(tester);
    if (level3.blocked) {
      fail(
        'BUG a transmettre a dev-flutter : le niveau 3 de l\'Artificier '
        '(specialisation) bloque. Texte observe : ${level3.screenText}',
      );
    }

    await openLevelUpFromCharacterDetail(tester);
    final level4 = await runOneLevelUp(tester);
    if (level4.blocked) {
      fail(
        'BUG a transmettre a dev-flutter : l\'ASI de l\'Artificier '
        '(niveau 4) bloque. Texte observe : ${level4.screenText}',
      );
    }

    // ignore: avoid_print
    print(
      'OBSERVATION Artificier niveau 4 -- texte visible sur la fiche : '
      '${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().toList()}',
    );
  });
}
