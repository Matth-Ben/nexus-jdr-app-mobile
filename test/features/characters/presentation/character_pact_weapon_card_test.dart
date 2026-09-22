// Tests de widget de la carte « ARME DE PACTE » et de son intégration à
// l'onglet « Inventaire » (`CharacterInventoryTabBody`).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_class_choice.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/pact_weapon_option.dart';
import 'package:personnages/features/characters/presentation/widgets/character_inventory_tab_body.dart';
import 'package:personnages/features/characters/presentation/widgets/character_pact_weapon_card.dart';

const _rapier = PactWeaponOption(
  id: 77,
  name: 'Rapière',
  damageDice: '1d8',
  damageType: 'perforant',
  properties: ['finesse'],
);

CharacterDetail _detail({
  String className = 'Occultiste',
  String pact = 'lame',
  String? subclassName,
  PactWeaponOption? pactWeapon,
}) => CharacterDetail(
  id: '1',
  name: 'Test',
  classes: [
    CharacterDetailClassRow(
      classId: 1,
      className: className,
      level: 3,
      isPrimary: true,
      savingThrowProficiencies: const [],
      hitDie: 8,
      subclassName: subclassName,
    ),
  ],
  xp: 0,
  currentHp: 1,
  maxHp: 1,
  temporaryHp: 0,
  abilityScores: const {},
  classChoices: [
    CharacterClassChoice(featureName: 'Faveur de pacte', chosenValue: pact),
  ],
  pactWeapon: pactWeapon,
);

Future<void> _pumpCard(
  WidgetTester tester, {
  PactWeaponOption? weapon,
  bool cursed = false,
  VoidCallback? onChangeForm,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: CharacterPactWeaponCard(
          weapon: weapon,
          hasCursedBlade: cursed,
          onChangeForm: onChangeForm,
        ),
      ),
    ),
  ),
);

Future<void> _pumpTab(
  WidgetTester tester,
  CharacterDetail detail, {
  VoidCallback? onChangePactWeapon,
  bool actionsDisabled = false,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: CharacterInventoryTabBody(
        detail: detail,
        actionsDisabled: actionsDisabled,
        onChangePactWeapon: onChangePactWeapon,
        onUseItem: (_) {},
        onToggleItemEquipped: (_) {},
        onToggleItemAttuned: (_) {},
        onRemoveItem: (_) {},
        onAdjustCurrency: (_, _) {},
        onAddInventoryItem: (_, _) {},
        onAddCustomInventoryItem: (_, _) {},
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
  });

  group('CharacterInventoryTabBody : carte Arme de pacte', () {
    testWidgets('Occultiste Pacte de la lame : carte visible, inventaire '
        'vide compris', (tester) async {
      await _pumpTab(
        tester,
        _detail(pactWeapon: _rapier),
        onChangePactWeapon: () {},
      );

      expect(find.byType(CharacterPactWeaponCard), findsOneWidget);
      expect(find.text('INVENTAIRE VIDE'), findsOneWidget);
      expect(find.text('Rapière'), findsOneWidget);
    });

    testWidgets('Lame maudite transmise à la carte', (tester) async {
      await _pumpTab(
        tester,
        _detail(subclassName: 'Lame maudite'),
        onChangePactWeapon: () {},
      );

      expect(
        find.text(CharacterPactWeaponCard.cursedBladeText),
        findsOneWidget,
      );
    });

    testWidgets('autre pacte ou autre classe : aucune carte', (tester) async {
      await _pumpTab(
        tester,
        _detail(pact: 'chaine'),
        onChangePactWeapon: () {},
      );
      expect(find.byType(CharacterPactWeaponCard), findsNothing);

      await _pumpTab(
        tester,
        _detail(className: 'Guerrier'),
        onChangePactWeapon: () {},
      );
      expect(find.byType(CharacterPactWeaponCard), findsNothing);
    });

    testWidgets('vue partagée (sans callback) : aucune carte', (tester) async {
      await _pumpTab(tester, _detail(pactWeapon: _rapier));

      expect(find.byType(CharacterPactWeaponCard), findsNothing);
    });

    testWidgets('tap sur le bouton : relaie onChangePactWeapon', (
      tester,
    ) async {
      var taps = 0;
      await _pumpTab(tester, _detail(), onChangePactWeapon: () => taps++);

      await tester.tap(find.text('Choisir une forme'));
      expect(taps, 1);
    });

    testWidgets('écriture d\'inventaire en cours : bouton verrouillé', (
      tester,
    ) async {
      var taps = 0;
      await _pumpTab(
        tester,
        _detail(),
        onChangePactWeapon: () => taps++,
        actionsDisabled: true,
      );

      await tester.tap(find.text('Choisir une forme'), warnIfMissed: false);
      expect(taps, 0);
      final opacity = tester.widget<Opacity>(
        find.ancestor(
          of: find.text('Choisir une forme'),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 0.6);
    });
  });
}
