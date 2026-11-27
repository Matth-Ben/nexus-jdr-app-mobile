// Tests de widget de la sheet autonome de surcharge de prix d'un objet du
// catalogue (spec du prix d'un objet modifiable, §2b/§2d) — ouverte par la
// nouvelle action « Modifier » de `item_action_sheet.dart`, jamais pour un
// objet personnalisé.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/characters/presentation/widgets/item_price_override_sheet.dart';
import 'package:personnages/l10n/app_localizations.dart';

Future<ItemPriceOverrideResult?> _open(
  WidgetTester tester, {
  String itemName = 'Dague',
  double? officialPriceAmount,
  num? initialAmount,
  CurrencyKind? initialCurrency,
}) async {
  ItemPriceOverrideResult? result;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showItemPriceOverrideSheet(
                context,
                itemName: itemName,
                officialPriceAmount: officialPriceAmount,
                initialAmount: initialAmount,
                initialCurrency: initialCurrency,
              );
            },
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
  testWidgets('titre « Prix de {nom} », légende du prix officiel '
      'présente s\'il est connu', (tester) async {
    await _open(tester, itemName: 'Dague', officialPriceAmount: 2);

    expect(find.text('Prix de Dague'), findsOneWidget);
    expect(find.text('Prix officiel : 2 PO'), findsOneWidget);
  });

  testWidgets('sans prix officiel connu : aucune légende', (tester) async {
    await _open(tester, itemName: 'Amulette +1');

    expect(find.textContaining('Prix officiel'), findsNothing);
  });

  testWidgets('aucune surcharge existante : champ vide/à 0, pas de lien '
      '« Retirer la surcharge »', (tester) async {
    await _open(tester, officialPriceAmount: 2);

    expect(find.text('Retirer la surcharge'), findsNothing);
  });

  testWidgets('surcharge existante : préremplie (jamais le prix officiel '
      'pré-converti), lien « Retirer la surcharge » présent', (tester) async {
    await _open(
      tester,
      officialPriceAmount: 2,
      initialAmount: 15,
      initialCurrency: CurrencyKind.silver,
    );

    expect(find.text('15'), findsOneWidget);
    expect(find.text('Retirer la surcharge'), findsOneWidget);
  });

  testWidgets('Enregistrer avec un montant : résultat amount/currency, pas '
      'removedViaLink', (tester) async {
    ItemPriceOverrideResult? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showItemPriceOverrideSheet(
                  context,
                  itemName: 'Dague',
                );
              },
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '15');
    await tester.pump();
    await tester.tap(find.text('PA'));
    await tester.pump();
    await tester.tap(find.text('ENREGISTRER'));
    await tester.pumpAndSettle();

    expect(result?.amount, 15);
    expect(result?.currency, CurrencyKind.silver);
    expect(result?.removedViaLink, isFalse);
  });

  testWidgets('Enregistrer à 0 (valeur de départ) : amount/currency null, '
      'aucun prix stocké', (tester) async {
    ItemPriceOverrideResult? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showItemPriceOverrideSheet(
                  context,
                  itemName: 'Dague',
                );
              },
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ENREGISTRER'));
    await tester.pumpAndSettle();

    expect(result?.amount, isNull);
    expect(result?.currency, isNull);
    expect(result?.removedViaLink, isFalse);
  });

  testWidgets('Retirer la surcharge : ferme directement, amount/currency '
      'null, removedViaLink', (tester) async {
    ItemPriceOverrideResult? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showItemPriceOverrideSheet(
                  context,
                  itemName: 'Dague',
                  initialAmount: 15,
                  initialCurrency: CurrencyKind.silver,
                );
              },
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Retirer la surcharge'));
    await tester.pumpAndSettle();

    expect(result?.amount, isNull);
    expect(result?.currency, isNull);
    expect(result?.removedViaLink, isTrue);
  });

  testWidgets('Annuler : ferme sans résultat', (tester) async {
    ItemPriceOverrideResult? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showItemPriceOverrideSheet(
                  context,
                  itemName: 'Dague',
                );
              },
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ANNULER'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });
}
