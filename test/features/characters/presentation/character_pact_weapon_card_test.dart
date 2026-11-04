// Tests de widget de la carte « ARME DE PACTE » (onglet « Personnage »,
// voir `character_detail_pact_weapon_test.dart` pour son câblage complet
// dans `character_detail_screen.dart`, et `shared_character_view_screen_test.dart`
// pour son rendu `readOnly: true`).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/pact_weapon_option.dart';
import 'package:personnages/features/characters/presentation/widgets/character_pact_weapon_card.dart';
import 'package:personnages/l10n/app_localizations.dart';

const _rapier = PactWeaponOption(
  id: 77,
  name: 'Rapière',
  damageDice: '1d8',
  damageType: 'perforant',
  properties: ['finesse'],
);

// Dupliqués ici tels quels (même rationale que les autres lots du chantier
// "traduction de l'app" Phase B) : `CharacterPactWeaponCard` n'expose plus
// ces textes comme constantes statiques, désormais résolues via
// `AppLocalizations` (non accessible hors `BuildContext`).
const _reminderText =
    "Invoquée par une action. Disparaît si elle reste à plus de 1,50 m de "
    "vous pendant 1 minute, ou si vous l'invoquez à nouveau.";
const _cursedBladeText =
    'Lame maudite : vous pouvez utiliser le Charisme à la place de la '
    "Force ou de la Dextérité pour l'attaque et les dégâts.";

Future<void> _pumpCard(
  WidgetTester tester, {
  PactWeaponOption? weapon,
  bool cursed = false,
  VoidCallback? onChangeForm,
  bool readOnly = false,
  Locale locale = const Locale('fr'),
}) => tester.pumpWidget(
  MaterialApp(
    // `CharacterPactWeaponCard` lit `AppLocalizations.of(context)!`
    // (chantier "traduction de l'app" Phase B, lot "Characters —
    // classe/race/maîtrises") : sans ces delegates, l'appel renverrait
    // `null` et le `!` planterait. `fr` par défaut, `en` passé
    // explicitement par le groupe "locale anglaise" plus bas.
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
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
      expect(find.text(_reminderText), findsOneWidget);
      expect(find.text('Changer de forme'), findsOneWidget);
      expect(find.text('Aucune forme choisie'), findsNothing);
      expect(find.text(_cursedBladeText), findsNothing);
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
      expect(find.text(_reminderText), findsOneWidget);
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
      expect(find.text(_cursedBladeText), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);

      await _pumpCard(tester, cursed: true, onChangeForm: () {});
      expect(find.text(_cursedBladeText), findsOneWidget);
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
      expect(find.text(_cursedBladeText), findsOneWidget);
      expect(find.text(_reminderText), findsOneWidget);
    });

    testWidgets('readOnly avec état vide : aucun bouton', (tester) async {
      await _pumpCard(tester, readOnly: true);

      expect(find.text('Aucune forme choisie'), findsOneWidget);
      expect(find.text('Choisir une forme'), findsNothing);
    });
  });

  group('locale anglaise', () {
    // Même rationale que les autres lots du chantier "traduction de l'app"
    // Phase B : vérifie qu'un texte anglais s'affiche réellement.
    testWidgets('titre, puces, rappel, lame maudite et bouton en anglais', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        weapon: _rapier,
        cursed: true,
        onChangeForm: () {},
        locale: const Locale('en'),
      );

      expect(find.text('PACT WEAPON'), findsOneWidget);
      expect(find.text('Magic weapon'), findsOneWidget);
      expect(find.text('Proficient'), findsOneWidget);
      expect(find.text('Change form'), findsOneWidget);
      expect(
        find.text(
          'Summoned as an action. Disappears if it is more than 5 feet '
          'away from you for 1 minute, or if you summon it again.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Hexblade: you can use your Charisma instead of Strength or '
          'Dexterity for the attack and damage rolls.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('cas vide en anglais', (tester) async {
      await _pumpCard(tester, onChangeForm: () {}, locale: const Locale('en'));

      expect(find.text('No form chosen'), findsOneWidget);
      expect(
        find.text('Choose the form your weapon takes when you summon it.'),
        findsOneWidget,
      );
      expect(find.text('Choose a form'), findsOneWidget);
    });
  });
}
