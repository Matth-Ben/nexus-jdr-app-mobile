// Tests de widget du signal "À 0 PV" de `CharacterVitalsCard` (décision du
// 09/11/2026, proposition P5) : présent à PV = 0 exactement, absent à 1,
// icône + libellé (jamais la couleur seule).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/presentation/widgets/character_vitals_card.dart';
import 'package:personnages/l10n/app_localizations.dart';

Future<void> _pump(
  WidgetTester tester,
  int currentHp, {
  Locale locale = const Locale('fr'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(
        body: SingleChildScrollView(
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
            ),
            onTapAdjustHp: () {},
            onTapAddXp: () {},
            onTapLevelUp: () {},
            onTapRest: () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('à 0 PV : libellé "À 0 PV" et icône visibles, valeur 0 / 8 '
      'conservée', (tester) async {
    await _pump(tester, 0);

    expect(find.text('À 0 PV'), findsOneWidget);
    expect(find.byIcon(Icons.heart_broken_outlined), findsOneWidget);
    expect(find.text('0 / 8'), findsOneWidget);
  });

  testWidgets('à 1 PV : aucun signal', (tester) async {
    await _pump(tester, 1);

    expect(find.text('À 0 PV'), findsNothing);
    expect(find.byIcon(Icons.heart_broken_outlined), findsNothing);
  });

  testWidgets('locale anglaise : "At 0 HP"', (tester) async {
    await _pump(tester, 0, locale: const Locale('en'));

    expect(find.text('At 0 HP'), findsOneWidget);
  });
}
