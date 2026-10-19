// Confirme en conditions reelles (vrai appareil, vrai Supabase distant) le
// correctif "Moine, Voie des quatre elements" (commit d781354,
// 19/10/2026) : avant lui, `class_features.choice_type ==
// 'discipline_elementaire'` n'etait gere par aucun code Dart et bloquait
// indefiniment la montee de niveau 3 de tout Moine de cette sous-classe.
//
// Deux personnages distincts (voir domain/level_up_choice_kind.dart) :
// - "Voie des quatre elements" : l'etape "Disciplines elementaires" doit
//   apparaitre aux niveaux 3 (2 choix) et 6 (1 choix), sans jamais bloquer.
// - un Moine d'une AUTRE sous-classe (regression deja corrigee en revue
//   avant merge, a reconfirmer en conditions reelles) : cette etape ne doit
//   JAMAIS apparaitre, aux memes niveaux.
//
// Couvre aussi la race Genasi (4 sous-races, point d'attention de l'audit)
// via le personnage "Voie des quatre elements" (Genasi du feu).
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_launch.dart';
import 'support/character_creation_flow.dart';
import 'support/level_up_flow.dart';
import 'support/qa_test_account.dart';
import 'support/tap_helpers.dart';

Future<void> _bootToCharacterList(WidgetTester tester) async {
  await launchApp(tester);
  if (find.text('ENTRER DANS LA TAVERNE').evaluate().isNotEmpty) {
    await loginWithQaTestAccount(tester);
  }
  await tapTextIfPresent(tester, 'Passer');
  await pumpUntilSettled(tester, attempts: 6);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Moine Voie des quatre elements : disciplines elementaires aux '
      'niveaux 3 (2 choix) et 6 (1 choix), jamais de blocage', (tester) async {
    if (!hasQaTestAccount) {
      // ignore: avoid_print
      print('SKIP: $qaTestAccountMissingReason');
      return;
    }
    await _bootToCharacterList(tester);

    const name = 'QA-Test-Moine4Elements';
    await createCharacter(
      tester,
      characterName: name,
      raceName: 'G\u00e9nasi',
      subraceName: 'G\u00e9nasi du feu',
      className: 'Moine',
      backgroundName: 'Acolyte',
    );

    await openCharacterByName(tester, name);

    // Niveau 2 : rien de special pour le Moine a ce niveau.
    await openLevelUpFromCharacterDetail(tester);
    final level2 = await runOneLevelUp(tester);
    expect(level2.blocked, isFalse, reason: 'niveau 2 ne doit jamais bloquer');

    // Niveau 3 : choix de sous-classe, puis (meme niveau) 2 disciplines
    // elementaires si "Voie des quatre elements" est choisie.
    await openLevelUpFromCharacterDetail(tester);
    final level3 = await runOneLevelUp(
      tester,
      choicePicker: (titles) => titles.firstWhere(
        (t) => t.toLowerCase().contains('quatre '),
        orElse: () => titles.first,
      ),
    );
    expect(
      level3.blocked,
      isFalse,
      reason:
          'BUG attendu corrige (commit d781354) : le niveau 3 ne doit '
          'plus jamais bloquer sur discipline_elementaire. Texte observe '
          'si echec : ${level3.screenText}',
    );

    // Niveau 4 : ASI, rien de specifique aux disciplines.
    await openLevelUpFromCharacterDetail(tester);
    final level4 = await runOneLevelUp(tester);
    expect(level4.blocked, isFalse);

    // Niveau 5 : rien de specifique aux disciplines (seuil suivant : 6).
    await openLevelUpFromCharacterDetail(tester);
    final level5 = await runOneLevelUp(tester);
    expect(level5.blocked, isFalse);

    // Niveau 6 : 1 discipline elementaire supplementaire attendue.
    await openLevelUpFromCharacterDetail(tester);
    final level6 = await runOneLevelUp(tester);
    expect(
      level6.blocked,
      isFalse,
      reason:
          'le niveau 6 (2e palier de discipline_elementaire) ne doit pas '
          'non plus bloquer : ${level6.screenText}',
    );
  });

  testWidgets("Moine d'une AUTRE sous-classe : jamais d'etape Disciplines "
      'elementaires aux niveaux 3 et 6 (regression deja corrigee en revue '
      'avant merge, reconfirmee ici en conditions reelles)', (tester) async {
    if (!hasQaTestAccount) {
      // ignore: avoid_print
      print('SKIP: $qaTestAccountMissingReason');
      return;
    }
    await _bootToCharacterList(tester);

    const name = 'QA-Test-MoineControle';
    await createCharacter(
      tester,
      characterName: name,
      raceName: 'Humain',
      className: 'Moine',
      backgroundName: 'Acolyte',
    );

    await openCharacterByName(tester, name);

    await openLevelUpFromCharacterDetail(tester);
    await runOneLevelUp(tester); // niveau 2

    await openLevelUpFromCharacterDetail(tester);
    final level3 = await runOneLevelUp(
      tester,
      choicePicker: (titles) => titles.firstWhere(
        (t) => !t.toLowerCase().contains('quatre '),
        orElse: () => titles.first,
      ),
    );
    expect(level3.blocked, isFalse);
    expect(
      level3.hadElementalDisciplinesStep,
      isFalse,
      reason:
          'une sous-classe differente de "Voie des quatre elements" ne '
          'doit jamais declencher cette etape',
    );

    await openLevelUpFromCharacterDetail(tester);
    await runOneLevelUp(tester); // niveau 4 (ASI)
    await openLevelUpFromCharacterDetail(tester);
    await runOneLevelUp(tester); // niveau 5

    await openLevelUpFromCharacterDetail(tester);
    final level6 = await runOneLevelUp(tester);
    expect(level6.blocked, isFalse);
    expect(level6.hadElementalDisciplinesStep, isFalse);
  });
}
