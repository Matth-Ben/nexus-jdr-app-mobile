// Tests de widget de la carte "CHOIX DE RACE" de l'onglet "Compétences" —
// voir la documentation de classe de `CharacterRaceChoicesCard`.
//
// `CharacterRaceChoicesCard` est un `StatelessWidget` pur (pas de Riverpod,
// pas de réseau) : même approche que `character_appearance_card_test.dart`,
// un simple `MaterialApp(home: ...)` suffit à le monter.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/presentation/widgets/character_race_choices_card.dart';
import 'package:personnages/l10n/app_localizations.dart';

CharacterDetail _detail({
  List<String> raceSkillChoiceNames = const [],
  List<String> raceToolChoiceNames = const [],
}) {
  return CharacterDetail(
    id: '1',
    name: 'Test',
    classes: const [],
    xp: 0,
    currentHp: 10,
    maxHp: 10,
    temporaryHp: 0,
    abilityScores: const {},
    raceSkillChoiceNames: raceSkillChoiceNames,
    raceToolChoiceNames: raceToolChoiceNames,
  );
}

Future<void> _pump(
  WidgetTester tester,
  CharacterDetail detail, {
  Locale locale = const Locale('fr'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      // `CharacterRaceChoicesCard` lit `AppLocalizations.of(context)!`
      // (chantier "traduction de l'app" Phase B, lot "Characters —
      // classe/race/maîtrises") : sans ces delegates, l'appel renverrait
      // `null` et le `!` planterait. `fr` par défaut, `en` passé
      // explicitement par le groupe "locale anglaise" plus bas.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(body: CharacterRaceChoicesCard(detail: detail)),
    ),
  );
}

void main() {
  testWidgets(
    'affiche une paire "Compétence"/nom par entrée de raceSkillChoiceNames '
    '(choix interactif, ex. Changelin)',
    (tester) async {
      await _pump(
        tester,
        _detail(raceSkillChoiceNames: const ['Persuasion', 'Tromperie']),
      );

      expect(find.text('CHOIX DE RACE'), findsOneWidget);
      expect(find.text('Compétence'), findsNWidgets(2));
      expect(find.text('Persuasion'), findsOneWidget);
      expect(find.text('Tromperie'), findsOneWidget);
    },
  );

  testWidgets(
    'affiche une paire "Outil"/nom par entrée de raceToolChoiceNames (ex. '
    'Nain)',
    (tester) async {
      await _pump(
        tester,
        _detail(raceToolChoiceNames: const ['Outils de forgeron']),
      );

      expect(find.text('CHOIX DE RACE'), findsOneWidget);
      expect(find.text('Outil'), findsOneWidget);
      expect(find.text('Outils de forgeron'), findsOneWidget);
    },
  );

  testWidgets('affiche compétence(s) ET outil(s) ensemble quand les deux sont '
      'renseignés (générique, même si aucune des 10 races actuelles n\'a les '
      'deux en même temps — voir la consigne d\'origine)', (tester) async {
    await _pump(
      tester,
      _detail(
        raceSkillChoiceNames: const ['Persuasion', 'Représentation'],
        raceToolChoiceNames: const ['Luth'],
      ),
    );

    expect(find.text('Compétence'), findsNWidgets(2));
    expect(find.text('Outil'), findsOneWidget);
    expect(find.text('Persuasion'), findsOneWidget);
    expect(find.text('Représentation'), findsOneWidget);
    expect(find.text('Luth'), findsOneWidget);
  });

  testWidgets(
    'se réduit à SizedBox.shrink (filet de sécurité) quand ni compétence ni '
    'outil de race ne sont renseignés',
    (tester) async {
      await _pump(tester, _detail());

      expect(find.text('CHOIX DE RACE'), findsNothing);
      expect(find.byType(CharacterRaceChoicesCard), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CharacterRaceChoicesCard),
          matching: find.byType(SizedBox),
        ),
        findsOneWidget,
      );
    },
  );

  group('CharacterRaceChoicesCard.hasContent', () {
    test('true si au moins une compétence de race est présente', () {
      expect(
        CharacterRaceChoicesCard.hasContent(
          _detail(raceSkillChoiceNames: const ['Persuasion']),
        ),
        isTrue,
      );
    });

    test('true si au moins un outil de race est présent', () {
      expect(
        CharacterRaceChoicesCard.hasContent(
          _detail(raceToolChoiceNames: const ['Luth']),
        ),
        isTrue,
      );
    });

    test('false si ni compétence ni outil de race ne sont renseignés '
        '(la grande majorité des races)', () {
      expect(CharacterRaceChoicesCard.hasContent(_detail()), isFalse);
    });
  });

  group('locale anglaise', () {
    // Même rationale que les autres lots du chantier "traduction de l'app"
    // Phase B : vérifie qu'un texte anglais s'affiche réellement.
    testWidgets('titre et libellés "Skill"/"Tool" en anglais', (tester) async {
      await _pump(
        tester,
        _detail(
          raceSkillChoiceNames: const ['Persuasion'],
          raceToolChoiceNames: const ['Outils de forgeron'],
        ),
        locale: const Locale('en'),
      );

      expect(find.text('RACE CHOICES'), findsOneWidget);
      expect(find.text('Skill'), findsOneWidget);
      expect(find.text('Tool'), findsOneWidget);
    });
  });
}
