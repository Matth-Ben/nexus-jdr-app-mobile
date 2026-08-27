// Tests de widget de la carte "Apparence physique" de l'onglet "Personnage"
// — voir `docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` ligne 45.
//
// `CharacterAppearanceCard` est un `StatelessWidget` pur (pas de Riverpod,
// pas de réseau) : même approche que `character_story_tab_body_test.dart`,
// un simple `MaterialApp(home: ...)` suffit à le monter.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/presentation/widgets/character_appearance_card.dart';

CharacterDetail _detail({
  String sexe = '',
  String age = '',
  String height = '',
  String weight = '',
  String eyes = '',
  String skin = '',
  String hair = '',
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
    sexe: sexe,
    age: age,
    height: height,
    weight: weight,
    eyes: eyes,
    skin: skin,
    hair: hair,
  );
}

Future<void> _pump(WidgetTester tester, CharacterDetail detail) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: CharacterAppearanceCard(detail: detail)),
    ),
  );
}

void main() {
  testWidgets('affiche les 7 champs avec leur libellé et leur valeur quand '
      'tous renseignés', (tester) async {
    await _pump(
      tester,
      _detail(
        sexe: 'Femme',
        age: '124 ans',
        height: '1m70',
        weight: '58 kg',
        eyes: 'Argentés',
        skin: 'Pâle',
        hair: 'Argentés, tressés',
      ),
    );

    expect(find.text('APPARENCE PHYSIQUE'), findsOneWidget);
    for (final label in const [
      'Sexe',
      'Âge',
      'Taille',
      'Poids',
      'Yeux',
      'Peau',
      'Cheveux',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Femme'), findsOneWidget);
    expect(find.text('124 ans'), findsOneWidget);
    expect(find.text('1m70'), findsOneWidget);
    expect(find.text('58 kg'), findsOneWidget);
    expect(find.text('Argentés'), findsOneWidget);
    expect(find.text('Pâle'), findsOneWidget);
    expect(find.text('Argentés, tressés'), findsOneWidget);
  });

  testWidgets('omet un champ individuellement vide ou blanc du Wrap', (
    tester,
  ) async {
    await _pump(tester, _detail(sexe: 'Femme', age: '124 ans', eyes: '   '));

    expect(find.text('APPARENCE PHYSIQUE'), findsOneWidget);
    expect(find.text('Sexe'), findsOneWidget);
    expect(find.text('Âge'), findsOneWidget);
    expect(find.text('Yeux'), findsNothing);
    expect(find.text('Taille'), findsNothing);
    expect(find.text('Poids'), findsNothing);
    expect(find.text('Peau'), findsNothing);
    expect(find.text('Cheveux'), findsNothing);
  });

  testWidgets(
    'se réduit à SizedBox.shrink (filet de sécurité) quand les 7 champs '
    'sont vides',
    (tester) async {
      await _pump(tester, _detail());

      expect(find.text('APPARENCE PHYSIQUE'), findsNothing);
      expect(find.byType(CharacterAppearanceCard), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CharacterAppearanceCard),
          matching: find.byType(SizedBox),
        ),
        findsOneWidget,
      );
    },
  );

  group('CharacterAppearanceCard.hasContent', () {
    test('true si au moins un des 7 champs est renseigné', () {
      expect(CharacterAppearanceCard.hasContent(_detail(hair: 'Roux')), isTrue);
    });

    test('false si les 7 champs sont vides ou blancs', () {
      expect(
        CharacterAppearanceCard.hasContent(_detail(sexe: '   ', age: '')),
        isFalse,
      );
    });
  });
}
