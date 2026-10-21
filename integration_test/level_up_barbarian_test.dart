// Jamais teste en live avant cette campagne QA (21/10/2026) : creation et
// montee de niveau standard du Barbare (classe martiale, pas de sorts) --
// sous-classe (Voie) au niveau 3, ASI au niveau 4, attaque supplementaire
// au niveau 5 (voir 04-fonctionnalites-app-mobile.md section 6, point 3 pour
// le deroule generique de la montee de niveau, et la consigne de campagne
// pour les niveaux a atteindre par classe).
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

  testWidgets('Barbare : creation, choix de voie (niveau 3), ASI (niveau 4), '
      'attaque supplementaire (niveau 5), jamais de blocage', (tester) async {
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

    const name = 'QA-Test-Barbare';
    await createCharacter(
      tester,
      characterName: name,
      raceName: 'Orc',
      className: 'Barbare',
      backgroundName: 'Acolyte',
    );

    await openCharacterByName(tester, name);

    await openLevelUpFromCharacterDetail(tester);
    final level2 = await runOneLevelUp(tester);
    expect(
      level2.blocked,
      isFalse,
      reason: 'niveau 2 ne doit jamais bloquer : ${level2.screenText}',
    );

    await openLevelUpFromCharacterDetail(tester);
    final level3 = await runOneLevelUp(tester);
    if (level3.blocked) {
      fail(
        'BUG a transmettre a dev-flutter : le choix de Voie du Barbare '
        '(niveau 3) bloque. Texte observe : ${level3.screenText}',
      );
    }

    await openLevelUpFromCharacterDetail(tester);
    final level4 = await runOneLevelUp(tester);
    if (level4.blocked) {
      fail(
        "BUG a transmettre a dev-flutter : l'ASI du Barbare (niveau 4) "
        'bloque. Texte observe : ${level4.screenText}',
      );
    }

    await openLevelUpFromCharacterDetail(tester);
    final level5 = await runOneLevelUp(tester);
    if (level5.blocked) {
      fail(
        "BUG a transmettre a dev-flutter : l'attaque supplementaire du "
        'Barbare (niveau 5) bloque. Texte observe : ${level5.screenText}',
      );
    }

    // ignore: avoid_print
    print(
      'OBSERVATION Barbare niveau 5 -- texte visible sur la fiche : '
      '${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().toList()}',
    );

    if (find.text('APT.').evaluate().isNotEmpty) {
      await tapText(tester, 'APT.');
      await pumpUntilSettled(tester, attempts: 4);
      // ignore: avoid_print
      print(
        'OBSERVATION onglet APT. (Barbare niveau 5) : '
        '${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().toList()}',
      );
    }
  });
}
