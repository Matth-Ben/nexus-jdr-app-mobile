// Tests de widget de la carte "CHOIX DE CLASSE" de l'onglet "Compétences" —
// voir la documentation de classe de `CharacterClassChoicesCard`.
//
// `CharacterClassChoicesCard` est un `StatelessWidget` pur (pas de Riverpod,
// pas de réseau) : même approche que `character_race_choices_card_test.dart`,
// un simple `MaterialApp(home: ...)` suffit à le monter.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_class_choice.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/presentation/widgets/character_class_choices_card.dart';
import 'package:personnages/l10n/app_localizations.dart';

CharacterDetailClassRow _classRow(
  String name, {
  String? subclassName,
  bool isPrimary = true,
}) => CharacterDetailClassRow(
  classId: name.hashCode,
  className: name,
  level: 3,
  isPrimary: isPrimary,
  savingThrowProficiencies: const [],
  hitDie: 8,
  subclassName: subclassName,
);

CharacterDetail _detail({
  List<CharacterDetailClassRow> classes = const [],
  List<CharacterClassChoice> classChoices = const [],
}) {
  return CharacterDetail(
    id: '1',
    name: 'Test',
    classes: classes,
    classChoices: classChoices,
    xp: 0,
    currentHp: 10,
    maxHp: 10,
    temporaryHp: 0,
    abilityScores: const {},
  );
}

Future<void> _pump(
  WidgetTester tester,
  CharacterDetail detail, {
  Locale locale = const Locale('fr'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      // `CharacterClassChoicesCard` lit `AppLocalizations.of(context)!`
      // (chantier "traduction de l'app" Phase B, lot "Characters —
      // classe/race/maîtrises") : sans ces delegates, l'appel renverrait
      // `null` et le `!` planterait. `fr` par défaut, `en` passé
      // explicitement par le groupe "locale anglaise" plus bas.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(body: CharacterClassChoicesCard(detail: detail)),
    ),
  );
}

void main() {
  testWidgets(
    'affiche une paire "Sous-classe"/nom quand une seule classe a une '
    'sous-classe choisie (cas le plus courant)',
    (tester) async {
      await _pump(
        tester,
        _detail(
          classes: [_classRow('Clerc', subclassName: 'Domaine de la vie')],
        ),
      );

      expect(find.text('CHOIX DE CLASSE'), findsOneWidget);
      expect(find.text('Sous-classe'), findsOneWidget);
      expect(find.text('Domaine de la vie'), findsOneWidget);
    },
  );

  testWidgets('désambiguïse par nom de classe quand plus d\'une classe a une '
      'sous-classe choisie (multiclassage)', (tester) async {
    await _pump(
      tester,
      _detail(
        classes: [
          _classRow('Clerc', subclassName: 'Domaine de la vie'),
          _classRow('Guerrier', subclassName: 'Champion', isPrimary: false),
        ],
      ),
    );

    expect(find.text('Sous-classe (Clerc)'), findsOneWidget);
    expect(find.text('Sous-classe (Guerrier)'), findsOneWidget);
    expect(find.text('Sous-classe'), findsNothing);
  });

  testWidgets('affiche une paire libellé/valeur par choix de classe résolu', (
    tester,
  ) async {
    await _pump(
      tester,
      _detail(
        classChoices: const [
          CharacterClassChoice(
            featureName: 'Style de combat',
            chosenValue: 'Défense',
          ),
        ],
      ),
    );

    expect(find.text('Style de combat'), findsOneWidget);
    expect(find.text('Défense'), findsOneWidget);
  });

  testWidgets(
    'se réduit à SizedBox.shrink (filet de sécurité) quand ni sous-classe '
    'ni choix de classe ne sont renseignés',
    (tester) async {
      await _pump(tester, _detail(classes: [_classRow('Clerc')]));

      expect(find.text('CHOIX DE CLASSE'), findsNothing);
      expect(find.byType(CharacterClassChoicesCard), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CharacterClassChoicesCard),
          matching: find.byType(SizedBox),
        ),
        findsOneWidget,
      );
    },
  );

  group('CharacterClassChoicesCard.hasContent', () {
    test('true si au moins une classe a une sous-classe choisie', () {
      expect(
        CharacterClassChoicesCard.hasContent(
          _detail(
            classes: [_classRow('Clerc', subclassName: 'Domaine de la vie')],
          ),
        ),
        isTrue,
      );
    });

    test('true si au moins un choix de classe est résolu', () {
      expect(
        CharacterClassChoicesCard.hasContent(
          _detail(
            classChoices: const [
              CharacterClassChoice(
                featureName: 'Style de combat',
                chosenValue: 'Défense',
              ),
            ],
          ),
        ),
        isTrue,
      );
    });

    test('false si ni sous-classe ni choix de classe ne sont renseignés', () {
      expect(
        CharacterClassChoicesCard.hasContent(
          _detail(classes: [_classRow('Clerc')]),
        ),
        isFalse,
      );
    });
  });

  group('locale anglaise', () {
    // Même rationale que les autres lots du chantier "traduction de l'app"
    // Phase B : vérifie qu'un texte anglais s'affiche réellement.
    testWidgets('titre et libellé "Subclass" en anglais', (tester) async {
      await _pump(
        tester,
        _detail(
          classes: [_classRow('Clerc', subclassName: 'Domaine de la vie')],
        ),
        locale: const Locale('en'),
      );

      expect(find.text('CLASS CHOICES'), findsOneWidget);
      expect(find.text('Subclass'), findsOneWidget);
    });

    testWidgets('libellé désambiguïsé "Subclass (className)" en anglais', (
      tester,
    ) async {
      await _pump(
        tester,
        _detail(
          classes: [
            _classRow('Clerc', subclassName: 'Domaine de la vie'),
            _classRow('Guerrier', subclassName: 'Champion', isPrimary: false),
          ],
        ),
        locale: const Locale('en'),
      );

      expect(find.text('Subclass (Clerc)'), findsOneWidget);
      expect(find.text('Subclass (Guerrier)'), findsOneWidget);
    });
  });
}
