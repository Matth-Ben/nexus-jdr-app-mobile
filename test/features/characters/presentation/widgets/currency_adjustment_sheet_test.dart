// Tests de widget de la feuille d'ajustement de monnaie (saisie numérique)
// et de la feuille de conversion de pièces (bouton "Changer", aperçu).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/characters/presentation/widgets/currency_adjustment_sheet.dart';
import 'package:personnages/l10n/app_localizations.dart';

const _balances = {
  CurrencyKind.platinum: 0,
  CurrencyKind.gold: 25,
  CurrencyKind.electrum: 0,
  CurrencyKind.silver: 15,
  CurrencyKind.copper: 7,
};

class _Result {
  final List<int> adjusted = [];
  final List<Map<CurrencyKind, int>> converted = [];
}

Future<_Result> _open(
  WidgetTester tester, {
  CurrencyKind currency = CurrencyKind.gold,
  Map<CurrencyKind, int> balances = _balances,
  bool withConversion = true,
  Size? size,
  double textScale = 1,
}) async {
  final result = _Result();
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showCurrencyAdjustmentSheet(
              context,
              currency: currency,
              currentAmount: balances[currency] ?? 0,
              onApply: result.adjusted.add,
              balances: withConversion ? balances : null,
              onConvert: withConversion ? result.converted.add : null,
            ),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  group('feuille d\'ajustement', () {
    testWidgets('saisir 40 en mode Ajouter : nouveau solde absolu 65', (
      tester,
    ) async {
      final result = await _open(tester);

      await tester.enterText(find.byType(TextField), '40');
      await tester.pump();
      await tester.tap(find.text('APPLIQUER'));
      await tester.pumpAndSettle();

      expect(result.adjusted, [65]);
    });

    testWidgets('mode Retirer : saisie bornée au solde, jamais négatif', (
      tester,
    ) async {
      final result = await _open(tester);

      await tester.tap(find.text('RETIRER'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '900');
      await tester.pump();
      await tester.tap(find.text('APPLIQUER'));
      await tester.pumpAndSettle();

      expect(result.adjusted, [0]);
    });

    testWidgets('bascule vers Retirer : montant déjà saisi ramené au solde', (
      tester,
    ) async {
      final result = await _open(tester);

      await tester.enterText(find.byType(TextField), '100');
      await tester.pump();
      await tester.tap(find.text('RETIRER'));
      await tester.pump();
      await tester.tap(find.text('APPLIQUER'));
      await tester.pumpAndSettle();

      expect(result.adjusted, [0]);
    });

    testWidgets('sans conversion fournie, pas de bouton "Changer"', (
      tester,
    ) async {
      await _open(tester, withConversion: false);
      expect(find.text('CHANGER'), findsNothing);
    });

    testWidgets('tient à 320 px avec texte agrandi', (tester) async {
      await _open(tester, size: const Size(320, 640), textScale: 1.6);
      expect(tester.takeException(), isNull);
    });
  });

  group('conversion', () {
    Future<void> openConversion(WidgetTester tester) async {
      await tester.tap(find.text('CHANGER'));
      await tester.pumpAndSettle();
    }

    testWidgets('"Changer" ouvre la feuille de conversion', (tester) async {
      await _open(tester);
      await openConversion(tester);
      expect(find.text('Changer des pièces'), findsOneWidget);
    });

    testWidgets('PE masqué tant que le solde est à 0', (tester) async {
      await _open(tester);
      await openConversion(tester);
      expect(find.textContaining('PE'), findsNothing);
    });

    testWidgets('PE proposé quand le solde est > 0', (tester) async {
      await _open(tester, balances: {..._balances, CurrencyKind.electrum: 3});
      await openConversion(tester);
      expect(find.textContaining('PE'), findsWidgets);
    });

    testWidgets('aperçu : 15 PA vers PO = 10 PA contre 1 PO, 5 PA restent', (
      tester,
    ) async {
      final result = await _open(tester, currency: CurrencyKind.silver);
      await openConversion(tester);

      // Source = PA (préselectionnée), cible = PO.
      await tester.tap(find.widgetWithText(ChoiceChip, 'PO · 25').last);
      await tester.pump();
      await tester.enterText(find.byType(TextField), '15');
      await tester.pump();

      expect(find.text('10 PA contre 1 PO'), findsOneWidget);
      expect(find.textContaining('5 PA non converties'), findsOneWidget);

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      // Une seule écriture groupée : débit PA et crédit PO ensemble.
      expect(result.converted, hasLength(1));
      expect(result.converted.single, {
        CurrencyKind.silver: 5,
        CurrencyKind.gold: 26,
      });
    });

    testWidgets('montant trop faible : message et Appliquer désactivé', (
      tester,
    ) async {
      await _open(tester, currency: CurrencyKind.silver);
      await openConversion(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'PO · 25').last);
      await tester.pump();
      await tester.enterText(find.byType(TextField), '5');
      await tester.pump();

      expect(
        find.text('Ce montant ne suffit pas pour obtenir une pièce entière.'),
        findsOneWidget,
      );
      expect(
        tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
        isNull,
      );
    });

    testWidgets('solde source insuffisant : saisie bornée au solde', (
      tester,
    ) async {
      final result = await _open(tester, currency: CurrencyKind.gold);
      await openConversion(tester);

      // Source PO (25), cible PA par défaut ; 999 est écrêté à 25.
      await tester.enterText(find.byType(TextField), '999');
      await tester.pump();

      expect(find.text('25 PO contre 250 PA'), findsOneWidget);
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(result.converted.single, {
        CurrencyKind.gold: 0,
        CurrencyKind.silver: 265,
      });
    });

    testWidgets('aucun montant saisi : Appliquer désactivé, pas d\'aperçu', (
      tester,
    ) async {
      await _open(tester);
      await openConversion(tester);

      expect(
        tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
        isNull,
      );
      expect(find.textContaining(' contre '), findsNothing);
    });

    testWidgets('tient à 320 px avec texte agrandi', (tester) async {
      await _open(tester, size: const Size(320, 640), textScale: 1.6);
      await tester.ensureVisible(find.text('CHANGER'));
      await tester.tap(find.text('CHANGER'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
