// Tests de widget de la carte « ARME DE PACTE » (onglet « Personnage »,
// voir `character_detail_pact_weapon_test.dart` pour son câblage complet
// dans `character_detail_screen.dart`, et `shared_character_view_screen_test.dart`
// pour son rendu `readOnly: true`).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/pact_weapon_option.dart';
import 'package:personnages/features/characters/presentation/widgets/character_pact_weapon_card.dart';

const _rapier = PactWeaponOption(
  id: 77,
  name: 'Rapière',
  damageDice: '1d8',
  damageType: 'perforant',
  properties: ['finesse'],
);

Future<void> _pumpCard(
  WidgetTester tester, {
  PactWeaponOption? weapon,
  bool cursed = false,
  VoidCallback? onChangeForm,
  bool readOnly = false,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: CharacterPactWeaponCard(
          weapon: weapon,
          hasCursedBlade: cursed,
          onChangeForm: onChangeForm,
          readOnly: readOnly,
        ),
      ),
    ),
  ),
);

void main() {
  group('CharacterPactWeaponCard', () {
    testWidgets('forme choisie : nom, dégâts, propriétés, puces, rappel', (
      tester,
    ) async {
      await _pumpCard(tester, weapon: _rapier, onChangeForm: () {});

      expect(find.text('ARME DE PACTE'), findsOneWidget);
      expect(find.text('Rapière'), findsOneWidget);
      expect(find.text('1d8 perforant'), findsOneWidget);
      expect(find.text('finesse'), findsOneWidget);
      expect(find.text('Arme magique'), findsOneWidget);
      expect(find.text('Maîtrisée'), findsOneWidget);
      expect(find.text(CharacterPactWeaponCard.reminderText), findsOneWidget);
      expect(find.text('Changer de forme'), findsOneWidget);
      expect(find.text('Aucune forme choisie'), findsNothing);
      expect(find.text(CharacterPactWeaponCard.cursedBladeText), findsNothing);
    });

    testWidgets('libellé sémantique « Arme de pacte : nom, dés type »', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpCard(tester, weapon: _rapier, onChangeForm: () {});

      expect(
        find.bySemanticsLabel('Arme de pacte : Rapière, 1d8 perforant'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('cas vide : message, bouton « Choisir une forme », pas de '
        'puces', (tester) async {
      await _pumpCard(tester, onChangeForm: () {});

      expect(find.text('Aucune forme choisie'), findsOneWidget);
      expect(
        find.text(
          "Choisissez la forme que prend votre arme lorsque vous l'invoquez.",
        ),
        findsOneWidget,
      );
      expect(find.text('Choisir une forme'), findsOneWidget);
      expect(find.text('Arme magique'), findsNothing);
      // Le rappel reste affiché.
      expect(find.text(CharacterPactWeaponCard.reminderText), findsOneWidget);
    });

    testWidgets('Lame maudite : la ligne est affichée, aussi à l\'état vide', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        weapon: _rapier,
        cursed: true,
        onChangeForm: () {},
      );
      expect(
        find.text(CharacterPactWeaponCard.cursedBladeText),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.info_outline), findsOneWidget);

      await _pumpCard(tester, cursed: true, onChangeForm: () {});
      expect(
        find.text(CharacterPactWeaponCard.cursedBladeText),
        findsOneWidget,
      );
    });

    testWidgets('le bouton appelle onChangeForm', (tester) async {
      var taps = 0;
      await _pumpCard(tester, weapon: _rapier, onChangeForm: () => taps++);

      await tester.tap(find.text('Changer de forme'));
      expect(taps, 1);
    });

    testWidgets('onChangeForm nul : bouton verrouillé (opacité 0.6)', (
      tester,
    ) async {
      await _pumpCard(tester, weapon: _rapier);

      final opacity = tester.widget<Opacity>(
        find.ancestor(
          of: find.text('Changer de forme'),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 0.6);
      final inkWell = tester.widget<InkWell>(
        find.ancestor(
          of: find.text('Changer de forme'),
          matching: find.byType(InkWell),
        ),
      );
      expect(inkWell.onTap, isNull);
    });

    testWidgets('readOnly : aucun bouton, reste affiché normalement', (
      tester,
    ) async {
      await _pumpCard(tester, weapon: _rapier, cursed: true, readOnly: true);

      expect(find.text('Choisir une forme'), findsNothing);
      expect(find.text('Changer de forme'), findsNothing);
      expect(find.byType(InkWell), findsNothing);
      // Le reste (nom, dégâts, propriétés, ligne Lame maudite, rappel) reste
      // affiché normalement.
      expect(find.text('Rapière'), findsOneWidget);
      expect(find.text('1d8 perforant'), findsOneWidget);
      expect(find.text('finesse'), findsOneWidget);
      expect(
        find.text(CharacterPactWeaponCard.cursedBladeText),
        findsOneWidget,
      );
      expect(find.text(CharacterPactWeaponCard.reminderText), findsOneWidget);
    });

    testWidgets('readOnly avec état vide : aucun bouton', (tester) async {
      await _pumpCard(tester, readOnly: true);

      expect(find.text('Aucune forme choisie'), findsOneWidget);
      expect(find.text('Choisir une forme'), findsNothing);
    });
  });
}
