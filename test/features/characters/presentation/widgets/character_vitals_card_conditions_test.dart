// Zone d'état de `CharacterVitalsCard` (P6) : T3 (aucune collision avec le
// bandeau PV), actif même quand `hpActionsDisabled` (mort), conditions
// conservées à 0 PV / mort.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/condition_type.dart';
import 'package:personnages/features/characters/presentation/widgets/character_vitals_card.dart';
import 'package:personnages/features/characters/presentation/widgets/condition_chips.dart';
import 'package:personnages/l10n/app_localizations.dart';

class _Taps {
  int hp = 0;
  int conditions = 0;
}

Future<_Taps> _pump(
  WidgetTester tester, {
  List<ConditionType> conditions = const [],
  int currentHp = 8,
  bool hpActionsDisabled = false,
  bool withConditionsCallback = true,
}) async {
  final taps = _Taps();
  tester.view.physicalSize = const Size(360, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: CharacterVitalsCard(
            detail: CharacterDetail(
              id: '1',
              name: 'Test',
              classes: const [],
              xp: 0,
              currentHp: currentHp,
              maxHp: 8,
              temporaryHp: 0,
              abilityScores: const {},
              conditions: conditions,
              isDead: hpActionsDisabled,
            ),
            hpActionsDisabled: hpActionsDisabled,
            onTapAdjustHp: () => taps.hp++,
            onTapAddXp: () {},
            onTapLevelUp: () {},
            onTapRest: () {},
            onTapConditions: withConditionsCallback
                ? () => taps.conditions++
                : null,
          ),
        ),
      ),
    ),
  );
  return taps;
}

const _three = [
  ConditionType.blinded,
  ConditionType.poisoned,
  ConditionType.prone,
];

void main() {
  group('T3 : pas de collision avec le bandeau PV', () {
    testWidgets('la zone d\'état n\'est dans aucun InkWell du bandeau PV', (
      tester,
    ) async {
      await _pump(tester, conditions: _three);
      expect(
        find.ancestor(
          of: find.byType(ConditionsZone),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
      final hpInk = find.ancestor(
        of: find.text('POINTS DE VIE'),
        matching: find.byType(InkWell),
      );
      expect(hpInk, findsOneWidget);
      final hpRect = tester.getRect(hpInk);
      final zoneRect = tester.getRect(find.byType(ConditionsZone));
      expect(hpRect.overlaps(zoneRect), isFalse);
      // Juste sous le bandeau PV, avant le bouton « Repos ».
      expect(zoneRect.top, greaterThanOrEqualTo(hpRect.bottom));
      expect(
        zoneRect.bottom,
        lessThanOrEqualTo(tester.getTopLeft(find.text('REPOS')).dy),
      );
    });

    testWidgets(
      'tap sur une pastille : sélecteur seulement, pas la feuille PV',
      (tester) async {
        final taps = await _pump(tester, conditions: _three);
        await tester.tap(find.text('Aveuglé'));
        expect(taps.conditions, 1);
        expect(taps.hp, 0);
      },
    );

    testWidgets('tap sur le bandeau PV : feuille PV seulement', (tester) async {
      final taps = await _pump(tester, conditions: _three);
      await tester.tap(find.text('POINTS DE VIE'));
      expect(taps.hp, 1);
      expect(taps.conditions, 0);
    });

    testWidgets('tap sur le bouton d\'édition : sélecteur seulement', (
      tester,
    ) async {
      final taps = await _pump(tester, conditions: _three);
      await tester.tap(find.byIcon(Icons.edit_outlined).last);
      expect(taps.conditions, 1);
      expect(taps.hp, 0);
    });

    testWidgets('sans condition : « + État » ouvre le sélecteur, pas la '
        'feuille PV', (tester) async {
      final taps = await _pump(tester);
      expect(find.byType(ConditionChip), findsNothing);
      await tester.tap(find.text('État'));
      expect(taps.conditions, 1);
      expect(taps.hp, 0);
    });
  });

  group('états hors PV', () {
    testWidgets('actif même quand hpActionsDisabled, alors que le bandeau PV '
        'est inerte', (tester) async {
      final taps = await _pump(
        tester,
        conditions: _three,
        hpActionsDisabled: true,
      );
      await tester.tap(find.text('Aveuglé'));
      await tester.tap(find.byIcon(Icons.edit_outlined).last);
      expect(taps.conditions, 2);
      await tester.tap(find.text('POINTS DE VIE'));
      expect(taps.hp, 0);
    });

    testWidgets(
      'conditions conservées à 0 PV (avec l\'indicateur « À 0 PV »)',
      (tester) async {
        await _pump(tester, conditions: _three, currentHp: 0);
        expect(find.text('À 0 PV'), findsOneWidget);
        expect(find.byType(ConditionChip), findsNWidgets(3));
      },
    );

    testWidgets('lecture seule (pas de callback) : pastilles sans bouton', (
      tester,
    ) async {
      await _pump(tester, conditions: _three, withConditionsCallback: false);
      expect(find.byType(ConditionChip), findsNWidgets(3));
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget); // bandeau PV
    });

    testWidgets('sans callback ni condition : aucune zone', (tester) async {
      await _pump(tester, withConditionsCallback: false);
      expect(find.byType(ConditionsZone), findsNothing);
    });
  });
}
