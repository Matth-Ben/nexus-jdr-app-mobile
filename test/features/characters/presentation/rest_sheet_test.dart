// Tests de widget de la feuille "Repos"
// (`presentation/widgets/rest_sheet.dart`) — même patron que
// `add_xp_sheet_test.dart` (feuille dans un `MaterialApp` minimal, aucun
// dépôt à injecter : `onApply` est un simple callback synchrone).
//
// Couvre aussi la règle RAW 5e "dépenser un dé de vie" (repos court, spec
// visuelle direction-artistique) : ligne d'état, stepper borné, jet
// auto-résolu (jamais de bouton "Lancer" séparé), bascule roll/moyenne,
// relance du lot complet, plafonnement du gain à `maxHp`, et masquage
// complet de la section quand `hitDie` est `null` (cas défensif).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/stepper_counter.dart';
import 'package:personnages/features/characters/domain/rest_type.dart';
import 'package:personnages/features/characters/presentation/widgets/rest_sheet.dart';

void main() {
  Future<void> pumpSheet(
    WidgetTester tester, {
    required int currentHp,
    required int maxHp,
    int? hitDie,
    int hitDiceTotal = 0,
    int hitDiceSpent = 0,
    int constitutionModifier = 0,
    required ValueChanged<RestSheetResult> onApply,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showRestSheet(
                  context,
                  currentHp: currentHp,
                  maxHp: maxHp,
                  hitDie: hitDie,
                  hitDiceTotal: hitDiceTotal,
                  hitDiceSpent: hitDiceSpent,
                  constitutionModifier: constitutionModifier,
                  onApply: onApply,
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

  Future<void> openShortRest(
    WidgetTester tester, {
    required int currentHp,
    required int maxHp,
    int? hitDie,
    int hitDiceTotal = 0,
    int hitDiceSpent = 0,
    int constitutionModifier = 0,
    required ValueChanged<RestSheetResult> onApply,
  }) async {
    await pumpSheet(
      tester,
      currentHp: currentHp,
      maxHp: maxHp,
      hitDie: hitDie,
      hitDiceTotal: hitDiceTotal,
      hitDiceSpent: hitDiceSpent,
      constitutionModifier: constitutionModifier,
      onApply: onApply,
    );
    await tester.tap(find.text('REPOS COURT'));
    await tester.pumpAndSettle();
  }

  Future<void> tapDiceIncrement(WidgetTester tester, [int times = 1]) async {
    for (var i = 0; i < times; i++) {
      await tester.tap(find.bySemanticsLabel('Augmenter'));
      await tester.pumpAndSettle();
    }
  }

  int diceStepperValue(WidgetTester tester) =>
      tester.widget<StepperCounter>(find.byType(StepperCounter)).value;

  testWidgets(
    'affiche le titre, les PV actuels, et "Repos long" sélectionné par '
    'défaut avec son bloc d\'aide (PV après repos inclus)',
    (tester) async {
      await pumpSheet(tester, currentHp: 12, maxHp: 30, onApply: (_) {});

      expect(find.text('Repos'), findsOneWidget);
      expect(find.text('PV actuels : 12 / 30'), findsOneWidget);
      expect(find.text('REPOS COURT'), findsOneWidget);
      expect(find.text('REPOS LONG'), findsOneWidget);

      expect(
        find.text(
          'Restaure les PV au maximum, réinitialise les emplacements de '
          'sorts et recharge toutes les aptitudes rechargeables (repos '
          'court comme repos long).',
        ),
        findsOneWidget,
      );
      expect(find.text('PV après repos : 30 / 30'), findsOneWidget);
      // Bloc d'aide "repos court" pas affiché tant que ce segment n'est pas
      // sélectionné.
      expect(find.textContaining('Dés de vie disponibles'), findsNothing);
    },
  );

  group('repos court — dés de vie disponibles (hitDie connu)', () {
    testWidgets(
      'affiche la ligne d\'état, le stepper "Dés à dépenser", et masque le '
      'bloc d\'aide du repos long',
      (tester) async {
        await openShortRest(
          tester,
          currentHp: 12,
          maxHp: 30,
          hitDie: 8,
          hitDiceTotal: 4,
          hitDiceSpent: 1,
          onApply: (_) {},
        );

        expect(find.text('Dés de vie disponibles : 3/4 (d8)'), findsOneWidget);
        expect(find.text('Dés à dépenser'), findsOneWidget);
        expect(find.byType(StepperCounter), findsOneWidget);
        expect(diceStepperValue(tester), 0);
        expect(find.textContaining('PV après repos'), findsNothing);
        expect(find.textContaining('emplacements de sorts'), findsNothing);
        // Aucun dé sélectionné : pas de bloc de jet (c).
        expect(find.text('PV restaurés'), findsNothing);
      },
    );

    testWidgets(
      'stepper désactivé et message dédié quand 0 dé de vie disponible '
      '(reste affiché, jamais masqué)',
      (tester) async {
        await openShortRest(
          tester,
          currentHp: 12,
          maxHp: 30,
          hitDie: 8,
          hitDiceTotal: 4,
          hitDiceSpent: 4,
          onApply: (_) {},
        );

        expect(find.text('Dés de vie disponibles : 0/4 (d8)'), findsOneWidget);
        expect(find.byType(StepperCounter), findsOneWidget);
        expect(
          find.text(
            'Aucun dé de vie disponible. Le repos court reste gratuit — '
            'aucune action supplémentaire requise.',
          ),
          findsOneWidget,
        );

        final incrementInkWell = tester.widget<InkWell>(
          find.ancestor(
            of: find.bySemanticsLabel('Augmenter'),
            matching: find.byType(InkWell),
          ),
        );
        expect(incrementInkWell.onTap, isNull);
        final decrementInkWell = tester.widget<InkWell>(
          find.ancestor(
            of: find.bySemanticsLabel('Diminuer'),
            matching: find.byType(InkWell),
          ),
        );
        expect(decrementInkWell.onTap, isNull);
      },
    );

    testWidgets('stepper borné à [0, remaining] : "+" se désactive une fois le '
        'maximum atteint', (tester) async {
      await openShortRest(
        tester,
        currentHp: 12,
        maxHp: 30,
        hitDie: 8,
        hitDiceTotal: 4,
        hitDiceSpent: 2, // 2 dés disponibles.
        onApply: (_) {},
      );

      expect(diceStepperValue(tester), 0);
      await tapDiceIncrement(tester, 2);
      expect(diceStepperValue(tester), 2);

      final incrementInkWell = tester.widget<InkWell>(
        find.ancestor(
          of: find.bySemanticsLabel('Augmenter'),
          matching: find.byType(InkWell),
        ),
      );
      expect(
        incrementInkWell.onTap,
        isNull,
        reason: 'Plafonné à `remaining` (2 ici), jamais au-delà.',
      );

      // "-" ramène bien à 0, jamais en dessous.
      await tester.tap(find.bySemanticsLabel('Diminuer'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Diminuer'));
      await tester.pumpAndSettle();
      expect(diceStepperValue(tester), 0);
      final decrementInkWell = tester.widget<InkWell>(
        find.ancestor(
          of: find.bySemanticsLabel('Diminuer'),
          matching: find.byType(InkWell),
        ),
      );
      expect(decrementInkWell.onTap, isNull);
    });

    testWidgets(
      'jet auto-résolu dès la sélection d\'un dé (mode "Valeur moyenne", '
      'déterministe), sans bouton "Lancer" séparé',
      (tester) async {
        await openShortRest(
          tester,
          currentHp: 10,
          maxHp: 30,
          hitDie: 8,
          hitDiceTotal: 4,
          hitDiceSpent: 0,
          constitutionModifier: 2,
          onApply: (_) {},
        );

        await tapDiceIncrement(tester);
        await tester.tap(find.text('VALEUR MOYENNE'));
        await tester.pumpAndSettle();

        // d8 -> moyenne 5, tuile affiche la valeur brute du dé (sans le
        // modificateur, appliqué seulement au total).
        expect(find.text('5'), findsOneWidget);
        expect(
          find.text('(moitié du dé arrondie au supérieur, +1, par dé)'),
          findsOneWidget,
        );
        expect(find.text('Relancer les dés'), findsNothing);

        // Gain : 5 (moyenne) + 2 (modificateur Con) = 7, sous le plafond
        // (10 -> 17).
        expect(find.text('PV restaurés'), findsOneWidget);
        expect(find.text('10 → 17 (+7)'), findsOneWidget);
      },
    );

    testWidgets(
      'bascule "Lancer les dés" <-> "Valeur moyenne" recalcule le gain '
      'affiché',
      (tester) async {
        await openShortRest(
          tester,
          currentHp: 10,
          maxHp: 30,
          hitDie: 8,
          hitDiceTotal: 4,
          hitDiceSpent: 0,
          constitutionModifier: 2,
          onApply: (_) {},
        );

        await tapDiceIncrement(tester);
        // Mode "Lancer les dés" par défaut : lien "Relancer les dés" visible.
        expect(find.text('Relancer les dés'), findsOneWidget);

        await tester.tap(find.text('VALEUR MOYENNE'));
        await tester.pumpAndSettle();
        expect(find.text('10 → 17 (+7)'), findsOneWidget);
        expect(find.text('Relancer les dés'), findsNothing);

        await tester.tap(find.text('LANCER LES DÉS'));
        await tester.pumpAndSettle();
        expect(find.text('Relancer les dés'), findsOneWidget);
      },
    );

    testWidgets(
      '"Relancer les dés" relance le lot complet en un seul lien (jamais un '
      'lien par dé)',
      (tester) async {
        // hitDie = 1 : `rollHitDie` renvoie toujours 1 (déterministe, aucune
        // dépendance à une graine aléatoire réelle) — permet de vérifier la
        // structure (un seul lien, le lot entier reste de la bonne taille
        // après relance) sans jamais dépendre d'une valeur aléatoire.
        await openShortRest(
          tester,
          currentHp: 10,
          maxHp: 30,
          hitDie: 1,
          hitDiceTotal: 4,
          hitDiceSpent: 0,
          onApply: (_) {},
        );

        await tapDiceIncrement(tester, 3);
        expect(find.text('Relancer les dés'), findsOneWidget);
        expect(find.text('1'), findsNWidgets(3));

        await tester.tap(find.text('Relancer les dés'));
        await tester.pumpAndSettle();

        expect(find.text('1'), findsNWidgets(3));
      },
    );

    testWidgets(
      'gain plafonné à maxHp : le GainRow reflète le delta réel, jamais la '
      'somme brute des dés',
      (tester) async {
        await openShortRest(
          tester,
          currentHp: 27,
          maxHp: 30,
          hitDie: 8,
          hitDiceTotal: 4,
          hitDiceSpent: 0,
          constitutionModifier: 5,
          onApply: (_) {},
        );

        await tapDiceIncrement(tester);
        await tester.tap(find.text('VALEUR MOYENNE'));
        await tester.pumpAndSettle();

        // Brut : 5 (moyenne d8) + 5 (modificateur) = 10, mais seulement 3
        // PV de marge avant `maxHp`.
        expect(find.text('27 → 30 (+3)'), findsOneWidget);
      },
    );

    testWidgets(
      'PV déjà au maximum : affiche le bandeau dédié au-dessus du GainRow, '
      'gain à 0, sans empêcher la dépense de dés',
      (tester) async {
        await openShortRest(
          tester,
          currentHp: 30,
          maxHp: 30,
          hitDie: 8,
          hitDiceTotal: 4,
          hitDiceSpent: 0,
          constitutionModifier: 2,
          onApply: (_) {},
        );

        await tapDiceIncrement(tester);
        await tester.tap(find.text('VALEUR MOYENNE'));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'PV déjà au maximum : ce repos ne restaurera aucun PV '
            'supplémentaire.',
          ),
          findsOneWidget,
        );
        expect(find.text('30 → 30 (+0)'), findsOneWidget);
      },
    );

    testWidgets(
      '"Appliquer" transmet RestSheetResult(short, diceSpent, appliedGain) '
      'avec le gain réellement plafonné',
      (tester) async {
        RestSheetResult? applied;
        await openShortRest(
          tester,
          currentHp: 27,
          maxHp: 30,
          hitDie: 8,
          hitDiceTotal: 4,
          hitDiceSpent: 0,
          constitutionModifier: 5,
          onApply: (result) => applied = result,
        );

        await tapDiceIncrement(tester);
        await tester.tap(find.text('VALEUR MOYENNE'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('APPLIQUER'));
        await tester.pumpAndSettle();

        expect(applied?.type, RestType.short);
        expect(applied?.diceSpent, 1);
        expect(applied?.appliedGain, 3);
      },
    );

    testWidgets('revenir sur "Repos long" avant "Appliquer" transmet toujours '
        'diceSpent=0/appliedGain=0, même avec des dés sélectionnés au '
        'préalable', (tester) async {
      RestSheetResult? applied;
      await openShortRest(
        tester,
        currentHp: 10,
        maxHp: 30,
        hitDie: 8,
        hitDiceTotal: 4,
        hitDiceSpent: 0,
        constitutionModifier: 2,
        onApply: (result) => applied = result,
      );

      await tapDiceIncrement(tester);
      await tester.tap(find.text('VALEUR MOYENNE'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('REPOS LONG'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('APPLIQUER'));
      await tester.pumpAndSettle();

      expect(applied?.type, RestType.long);
      expect(applied?.diceSpent, 0);
      expect(applied?.appliedGain, 0);
    });
  });

  testWidgets(
    'hitDie null : la section "dés de vie" est entièrement masquée (cas '
    'défensif, comportement identique à avant cette fonctionnalité)',
    (tester) async {
      await openShortRest(
        tester,
        currentHp: 12,
        maxHp: 30,
        // hitDie volontairement omis (null par défaut).
        onApply: (_) {},
      );

      expect(find.textContaining('Dés de vie disponibles'), findsNothing);
      expect(find.text('Dés à dépenser'), findsNothing);
      expect(find.byType(StepperCounter), findsNothing);
      expect(find.text('PV restaurés'), findsNothing);
    },
  );

  testWidgets(
    '"Appliquer" est toujours activé (aucune saisie à valider), ferme la '
    'feuille et transmet le type sélectionné',
    (tester) async {
      RestType? applied;
      await pumpSheet(
        tester,
        currentHp: 12,
        maxHp: 30,
        onApply: (result) => applied = result.type,
      );

      final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(button.onPressed, isNotNull);

      await tester.tap(find.text('REPOS COURT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('APPLIQUER'));
      await tester.pumpAndSettle();

      expect(applied, RestType.short);
      expect(find.text('Repos'), findsNothing);
    },
  );

  testWidgets(
    '"Appliquer" sans changer de segment transmet RestType.long (valeur '
    'par défaut)',
    (tester) async {
      RestType? applied;
      await pumpSheet(
        tester,
        currentHp: 12,
        maxHp: 30,
        onApply: (result) => applied = result.type,
      );

      await tester.tap(find.text('APPLIQUER'));
      await tester.pumpAndSettle();

      expect(applied, RestType.long);
    },
  );

  testWidgets('"Annuler" ferme la feuille sans appeler onApply', (
    tester,
  ) async {
    var applyCallCount = 0;
    await pumpSheet(
      tester,
      currentHp: 12,
      maxHp: 30,
      onApply: (_) => applyCallCount++,
    );

    await tester.tap(find.text('ANNULER'));
    await tester.pumpAndSettle();

    expect(applyCallCount, 0);
    expect(find.text('Repos'), findsNothing);
  });
}
