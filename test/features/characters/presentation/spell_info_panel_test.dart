// Tests de widget du panneau "Infos" d'un sort
// (`presentation/widgets/spell_info_panel.dart`) et de la sheet de choix de
// niveau d'emplacement que son bouton "Lancer" peut ouvrir
// (`presentation/widgets/spell_action_sheet.dart::castSpellFlow`) — même
// patron que `rest_sheet_test.dart` : le panneau est ouvert depuis un
// `Builder` minimal, `onCastSpell` est un simple callback synchrone
// enregistrant ses appels (toute la logique d'écriture réseau vit dans
// `character_detail_screen.dart`, hors périmètre de ce fichier).
//
// Remplace l'ancien `spell_action_sheet_test.dart` : le tap sur une ligne de
// sort de l'onglet "Sorts" ouvrait jusque-là une sheet intermédiaire
// "Infos"/"Lancer" (`showSpellActionSheet`) avant d'atteindre ce panneau —
// retirée (retour utilisateur : "Lancer" étant déjà accessible depuis
// "Infos", l'étape intermédiaire n'ajoutait qu'un aller-retour), le tap
// ouvre désormais directement ce panneau ([showSpellInfoPanel]).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/character_spell_slot.dart';
import 'package:personnages/features/characters/presentation/widgets/spell_info_panel.dart';

const _cantrip = CharacterSpellEntry(
  id: 1,
  name: 'Lumière',
  level: 0,
  school: 'Évocation',
  status: 'connu',
);

const _fireball = CharacterSpellEntry(
  id: 2,
  name: 'Boule de feu',
  level: 3,
  school: 'Évocation',
  status: 'connu',
  castingTime: '1 action',
  range: '45 mètres',
  components: {
    'verbal': true,
    'somatic': true,
    'material': true,
    'material_desc': 'du guano',
  },
  duration: 'Instantanée',
  concentration: false,
  description: 'Une sphère de feu explose.',
);

void main() {
  List<CharacterSpellEntry> castCalls = [];
  List<int?> castLevels = [];

  Future<void> pumpPanel(
    WidgetTester tester, {
    required CharacterSpellEntry spell,
    required List<CharacterSpellSlot> spellSlots,
  }) async {
    castCalls = [];
    castLevels = [];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showSpellInfoPanel(
                  context,
                  spell: spell,
                  spellSlots: spellSlots,
                  onCastSpell: (castSpell, level) {
                    castCalls.add(castSpell);
                    castLevels.add(level);
                  },
                ),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'tap direct : affiche immédiatement le détail technique complet et la '
    'description, sans sheet "Infos"/"Lancer" intermédiaire',
    (tester) async {
      await pumpPanel(
        tester,
        spell: _fireball,
        spellSlots: const [CharacterSpellSlot(level: 3, total: 2, used: 0)],
      );

      expect(find.text('BOULE DE FEU'), findsOneWidget);
      expect(find.text('Évocation · Niveau 3'), findsOneWidget);
      expect(find.text("Temps d'incantation"), findsOneWidget);
      expect(find.text('1 action'), findsOneWidget);
      expect(find.text('Portée'), findsOneWidget);
      expect(find.text('45 mètres'), findsOneWidget);
      expect(find.text('Composantes'), findsOneWidget);
      expect(find.text('V, S, M — du guano'), findsOneWidget);
      expect(find.text('Durée'), findsOneWidget);
      expect(find.text('Instantanée'), findsOneWidget);
      expect(find.text('Concentration'), findsOneWidget);
      expect(find.text('Non'), findsOneWidget);
      expect(find.text('DESCRIPTION'), findsOneWidget);
      expect(find.text('Une sphère de feu explose.'), findsOneWidget);
      // Ni "Infos" ni sheet intermédiaire : un seul bouton d'action, "Lancer".
      expect(find.text('Infos'), findsNothing);
      expect(find.widgetWithText(PrimaryButton, 'LANCER'), findsOneWidget);
    },
  );

  testWidgets('un cantrip : "Lancer" exécute directement sans sheet de choix, '
      'slotLevel null', (tester) async {
    await pumpPanel(tester, spell: _cantrip, spellSlots: const []);

    expect(find.text('LUMIÈRE'), findsOneWidget);
    await tester.tap(find.widgetWithText(PrimaryButton, 'LANCER'));
    await tester.pumpAndSettle();

    expect(castCalls, [_cantrip]);
    expect(castLevels, [null]);
    // Le panneau est refermé.
    expect(find.text('LUMIÈRE'), findsNothing);
  });

  testWidgets(
    'un seul niveau éligible : "Lancer" exécute directement ce niveau, sans '
    'sheet de choix',
    (tester) async {
      await pumpPanel(
        tester,
        spell: _fireball,
        spellSlots: const [CharacterSpellSlot(level: 3, total: 2, used: 0)],
      );

      await tester.tap(find.widgetWithText(PrimaryButton, 'LANCER'));
      await tester.pumpAndSettle();

      expect(castCalls, [_fireball]);
      expect(castLevels, [3]);
      expect(
        find.textContaining("Choisissez le niveau d'emplacement"),
        findsNothing,
      );
    },
  );

  testWidgets(
    'plusieurs niveaux éligibles : "Lancer" ouvre une sheet de choix, un '
    'niveau épuisé reste listé mais non sélectionnable',
    (tester) async {
      await pumpPanel(
        tester,
        spell: _fireball,
        spellSlots: const [
          CharacterSpellSlot(level: 3, total: 2, used: 2), // épuisé
          CharacterSpellSlot(level: 4, total: 1, used: 0),
        ],
      );

      await tester.tap(find.widgetWithText(PrimaryButton, 'LANCER'));
      await tester.pumpAndSettle();

      expect(find.text('Lancer Boule de feu'), findsOneWidget);
      expect(find.text('Niveau 3'), findsOneWidget);
      expect(find.text('Niveau 4'), findsOneWidget);
      expect(find.text('Épuisé'), findsOneWidget);

      // Le niveau épuisé (3) ne doit rien déclencher au tap.
      await tester.tap(find.text('Niveau 3'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Confirme avec la présélection par défaut (niveau 4, seul disponible).
      final confirmButton = tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'LANCER'),
      );
      expect(confirmButton.onPressed, isNotNull);
      await tester.tap(find.widgetWithText(PrimaryButton, 'LANCER'));
      await tester.pumpAndSettle();

      expect(castCalls, [_fireball]);
      expect(castLevels, [4]);
    },
  );

  testWidgets('aucun niveau éligible disponible : "Lancer" est désactivé', (
    tester,
  ) async {
    await pumpPanel(
      tester,
      spell: _fireball,
      spellSlots: const [CharacterSpellSlot(level: 3, total: 2, used: 2)],
    );

    final button = tester.widget<PrimaryButton>(
      find.widgetWithText(PrimaryButton, 'LANCER'),
    );
    expect(button.onPressed, isNull);

    expect(castCalls, isEmpty);
    // Le panneau reste ouvert.
    expect(find.text('BOULE DE FEU'), findsOneWidget);
  });
}
