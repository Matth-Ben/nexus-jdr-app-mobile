// Tests de widget de la sheet d'aide contextuelle
// (`presentation/widgets/step_help_sheet.dart`) — même patron que
// `spell_info_panel_test.dart` : la sheet est ouverte depuis un `Builder`
// minimal, aucun réseau/état à simuler (contenu statique).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/creation_step_help.dart';
import 'package:personnages/features/character_creation/presentation/widgets/step_help_sheet.dart';

Future<void> _pumpSheet(WidgetTester tester, StepHelpContent content) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showStepHelpSheet(context, content),
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

void main() {
  testWidgets('affiche le titre (en majuscules) et le corps du contenu '
      'fourni', (tester) async {
    await _pumpSheet(tester, CreationStepHelp.race);

    expect(find.text('1. RACE'), findsOneWidget);
    expect(find.text(CreationStepHelp.race.body), findsOneWidget);
  });

  testWidgets('la croix du SheetHeaderBar referme la sheet', (tester) async {
    await _pumpSheet(tester, CreationStepHelp.race);
    expect(find.text('1. RACE'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('1. RACE'), findsNothing);
  });
}
