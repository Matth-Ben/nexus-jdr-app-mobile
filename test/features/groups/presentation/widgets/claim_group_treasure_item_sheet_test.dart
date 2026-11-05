// Tests de widget de `showClaimGroupTreasureItemSheet` — sheet légère
// "Réclamer {nom}" ouverte depuis l'onglet "Butin" de l'écran "Groupe",
// voir `group_treasure_tab_body.dart`. `group_screen_test.dart` couvre déjà
// le flux complet (appel réseau) ; ce fichier couvre son contenu isolé
// (plafonnement par quantité disponible, pluriel ICU, traduction).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/groups/domain/group_treasure_item.dart';
import 'package:personnages/features/groups/presentation/widgets/claim_group_treasure_item_sheet.dart';
import 'package:personnages/l10n/app_localizations.dart';

Widget _buildTestWidget({
  required GroupTreasureItem item,
  required ValueChanged<int?> onResult,
  Locale locale = const Locale('fr'),
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            final result = await showClaimGroupTreasureItemSheet(
              context,
              item: item,
            );
            onResult(result);
          },
          child: const Text('Ouvrir'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('titre avec le nom de l\'objet, quantité disponible au pluriel '
      '(plusieurs unités)', (tester) async {
    await tester.pumpWidget(
      _buildTestWidget(
        item: const GroupTreasureItem(
          itemId: 7,
          displayName: 'Potion de soins',
          quantity: 3,
        ),
        onResult: (_) {},
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Réclamer Potion de soins'), findsOneWidget);
    expect(find.text('3 disponibles'), findsOneWidget);
  });

  testWidgets('quantité disponible au singulier (une seule unité)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTestWidget(
        item: const GroupTreasureItem(
          itemId: 7,
          displayName: 'Épée',
          quantity: 1,
        ),
        onResult: (_) {},
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('1 disponible'), findsOneWidget);
  });

  testWidgets('le compteur est plafonné à la quantité disponible et "Réclamer" '
      'retourne la quantité choisie', (tester) async {
    int? result;
    await tester.pumpWidget(
      _buildTestWidget(
        item: const GroupTreasureItem(
          itemId: 7,
          displayName: 'Potion',
          quantity: 2,
        ),
        onResult: (value) => result = value,
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    // Déjà au maximum (2) : un 2e tap ne doit rien changer.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    final applyButton = tester.widget<PrimaryButton>(
      find.byType(PrimaryButton),
    );
    applyButton.onPressed!();
    await tester.pumpAndSettle();

    expect(result, 2);
  });

  group('traduction anglaise', () {
    testWidgets('titre, quantité et bouton en anglais', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          item: const GroupTreasureItem(
            itemId: 7,
            displayName: 'Healing Potion',
            quantity: 3,
          ),
          onResult: (_) {},
          locale: const Locale('en'),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      expect(find.text('Claim Healing Potion'), findsOneWidget);
      expect(find.text('3 available'), findsOneWidget);

      final applyButton = tester.widget<PrimaryButton>(
        find.byType(PrimaryButton),
      );
      expect(applyButton.label, 'Claim');
    });

    testWidgets('quantité disponible au singulier en anglais', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          item: const GroupTreasureItem(
            itemId: 7,
            displayName: 'Sword',
            quantity: 1,
          ),
          onResult: (_) {},
          locale: const Locale('en'),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      expect(find.text('1 available'), findsOneWidget);
    });
  });
}
