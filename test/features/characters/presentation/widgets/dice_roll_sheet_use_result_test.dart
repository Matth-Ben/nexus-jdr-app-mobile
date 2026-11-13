// `showDiceRollSheet` : bouton optionnel « Utiliser {total} » (saisie
// d'initiative du combat de groupe) et comportement inchangé sans lui.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/presentation/widgets/dice_roll_sheet.dart';
import 'package:personnages/l10n/app_localizations.dart';

class _Outcome {
  bool completed = false;
  int? value;
}

Future<_Outcome> _open(
  WidgetTester tester, {
  required int modifier,
  String Function(int total)? useResultLabel,
  Random? random,
}) async {
  final outcome = _Outcome();
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              final value = await showDiceRollSheet(
                context,
                label: 'Initiative',
                modifier: modifier,
                useResultLabel: useResultLabel,
                random: random,
              );
              outcome
                ..completed = true
                ..value = value;
            },
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
  return outcome;
}

int _dieValue(WidgetTester tester) {
  final texts = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data)
      .whereType<String>();
  for (final text in texts) {
    final value = int.tryParse(text);
    if (value != null && value >= 1 && value <= 20) return value;
  }
  fail('Aucune valeur de dé trouvée.');
}

void main() {
  group('sans useResultLabel (appelants existants)', () {
    testWidgets('aucun bouton « Utiliser » ni bouton primaire', (tester) async {
      await _open(tester, modifier: 3, random: Random(1));
      expect(find.byKey(const Key('diceRollUseResult')), findsNothing);
      expect(find.byType(PrimaryButton), findsNothing);
      expect(find.text('RELANCER'), findsOneWidget);
    });

    testWidgets('fermée sans choix : le futur se termine à null', (
      tester,
    ) async {
      final outcome = await _open(tester, modifier: 3, random: Random(1));
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(outcome.completed, isTrue);
      expect(outcome.value, isNull);
    });
  });

  group('avec useResultLabel', () {
    testWidgets('« Utiliser {total} » = d20 + modificateur, ferme et renvoie '
        'le total', (tester) async {
      final outcome = await _open(
        tester,
        modifier: 3,
        random: Random(1),
        useResultLabel: (total) => 'Utiliser $total',
      );
      final total = _dieValue(tester) + 3;
      expect(find.text('UTILISER $total'), findsOneWidget);
      await tester.tap(find.byKey(const Key('diceRollUseResult')));
      await tester.pumpAndSettle();
      expect(outcome.completed, isTrue);
      expect(outcome.value, total);
      expect(find.text('RELANCER'), findsNothing);
    });

    testWidgets('modificateur négatif : le total est celui du détail', (
      tester,
    ) async {
      final outcome = await _open(
        tester,
        modifier: -2,
        random: Random(7),
        useResultLabel: (total) => 'Utiliser $total',
      );
      final total = _dieValue(tester) - 2;
      await tester.tap(find.byKey(const Key('diceRollUseResult')));
      await tester.pumpAndSettle();
      expect(outcome.value, total);
    });

    testWidgets('« Relancer » reste possible : le bouton suit le nouveau '
        'total', (tester) async {
      final outcome = await _open(
        tester,
        modifier: 0,
        random: Random(3),
        useResultLabel: (total) => 'Utiliser $total',
      );
      final first = _dieValue(tester);
      expect(find.text('UTILISER $first'), findsOneWidget);
      await tester.tap(find.text('RELANCER'));
      await tester.pumpAndSettle();
      final second = _dieValue(tester);
      expect(find.text('UTILISER $second'), findsOneWidget);
      await tester.tap(find.byKey(const Key('diceRollUseResult')));
      await tester.pumpAndSettle();
      expect(outcome.value, second);
    });

    testWidgets('fermée sans « Utiliser » : null (rien n\'est repris)', (
      tester,
    ) async {
      final outcome = await _open(
        tester,
        modifier: 3,
        random: Random(1),
        useResultLabel: (total) => 'Utiliser $total',
      );
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(outcome.completed, isTrue);
      expect(outcome.value, isNull);
    });
  });
}
