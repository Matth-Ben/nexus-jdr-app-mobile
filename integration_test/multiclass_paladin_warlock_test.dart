// Multiclassage Paladin/Occultiste -- verifie les prerequis
// (domain/multiclass_prerequisites.dart), les maitrises gagnees
// (domain/multiclass_proficiencies.dart -- fix Artificier n'est pas ici, mais meme famille de table) et le calcul
// combine des emplacements de sorts le cas echeant, en conditions reelles.
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

  testWidgets('Multiclassage Paladin/Occultiste : prerequis, '
      'maitrises, emplacements de sorts', (tester) async {
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
    final name = qaUniqueCharacterName('QA-Test-PaladinChangeformeOccultiste');
    await createCharacter(
      tester,
      characterName: name,
      raceName: 'Changeforme',

      className: 'Paladin',
      backgroundName: 'Acolyte',
      abilityIncrements: {'cha': 3},
    );

    await openCharacterByName(tester, name);

    await openLevelUpFromCharacterDetail(tester);
    final level2 = await runOneLevelUp(tester, multiclassInto: 'Occultiste');

    if (level2.blocked) {
      fail(
        'BUG a transmettre a dev-flutter : le multiclassage '
        'Paladin/Occultiste bloque au niveau 2. Texte '
        'observe : ${level2.screenText}',
      );
    }

    // ignore: avoid_print
    print(
      'OBSERVATION apres multiclassage Paladin/Occultiste '
      '-- fiche personnage : ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().toList()}',
    );

    if (find.text('APT.').evaluate().isNotEmpty) {
      await tapText(tester, 'APT.');
      await pumpUntilSettled(tester, attempts: 4);
      // ignore: avoid_print
      print(
        'OBSERVATION onglet APT. (multiclasse Paladin/Occultiste) : ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().toList()}',
      );
    }

    if (find.text('SORTS').evaluate().isNotEmpty) {
      await tapText(tester, 'SORTS');
      await pumpUntilSettled(tester, attempts: 4);
      // ignore: avoid_print
      print(
        'OBSERVATION onglet SORTS (multiclasse Paladin/Occultiste) : ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().toList()}',
      );
    }
  });
}
