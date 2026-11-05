// Tests de widget de `showClaimGroupTreasureCurrencySheet` — sheet
// "S'attribuer de la monnaie" ouverte depuis l'onglet "Butin" de l'écran
// "Groupe", voir `group_treasure_tab_body.dart`. `group_screen_test.dart`
// couvre déjà le flux complet (appel réseau, cas partiel/total) ; ce fichier
// couvre son contenu isolé (plafonnement par solde, traduction).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/groups/domain/group_treasure.dart';
import 'package:personnages/features/groups/presentation/widgets/claim_group_treasure_currency_sheet.dart';
import 'package:personnages/l10n/app_localizations.dart';

Widget _buildTestWidget({
  required GroupTreasure treasure,
  required ClaimGroupTreasureCurrencyCallback onApply,
  Locale locale = const Locale('fr'),
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showClaimGroupTreasureCurrencySheet(
            context,
            treasure: treasure,
            onApply: onApply,
          ),
          child: const Text('Ouvrir'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'titre et solde max affichés, bouton "S\'attribuer" désactivé sans '
    'saisie',
    (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          treasure: const GroupTreasure(groupId: 'group-1', currencyGp: 20),
          onApply: (_) {},
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      expect(find.text("S'ATTRIBUER DE LA MONNAIE"), findsOneWidget);
      expect(find.text('/ 20'), findsOneWidget);

      final applyButton = tester.widget<PrimaryButton>(
        find.byType(PrimaryButton),
      );
      expect(applyButton.label, "S'attribuer");
      expect(applyButton.onPressed, isNull);
    },
  );

  testWidgets('une saisie au-delà du solde est plafonnée immédiatement', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTestWidget(
        treasure: const GroupTreasure(groupId: 'group-1', currencyGp: 5),
        onApply: (_) {},
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '99');
    await tester.pumpAndSettle();

    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('saisir un montant valide active le bouton et transmet les '
      'montants à onApply', (tester) async {
    Map<CurrencyKind, int>? applied;
    await tester.pumpWidget(
      _buildTestWidget(
        treasure: const GroupTreasure(groupId: 'group-1', currencyGp: 20),
        onApply: (amounts) => applied = amounts,
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '7');
    await tester.pumpAndSettle();

    final applyButton = tester.widget<PrimaryButton>(
      find.byType(PrimaryButton),
    );
    expect(applyButton.onPressed, isNotNull);

    applyButton.onPressed!();
    expect(applied?[CurrencyKind.gold], 7);
  });

  group('traduction anglaise', () {
    testWidgets('titre et boutons en anglais', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          treasure: const GroupTreasure(groupId: 'group-1', currencyGp: 20),
          onApply: (_) {},
          locale: const Locale('en'),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      expect(find.text('CLAIM CURRENCY'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);

      final applyButton = tester.widget<PrimaryButton>(
        find.byType(PrimaryButton),
      );
      expect(applyButton.label, 'Claim');
    });
  });
}
