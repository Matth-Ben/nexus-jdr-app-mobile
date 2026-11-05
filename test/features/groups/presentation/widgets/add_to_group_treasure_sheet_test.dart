// Tests de widget de `showAddToGroupTreasureSheet` — sheet "Ajouter au
// butin du groupe" ouverte depuis l'onglet "Butin" de l'écran "Groupe", voir
// `group_treasure_tab_body.dart`. `group_screen_test.dart` ne teste pas
// cette sheet directement (seul le bouton qui l'ouvre) ; ce fichier couvre
// son contenu complet (champs de monnaie, objets composés localement,
// traduction).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/characters/domain/reward_item_draft.dart';
import 'package:personnages/features/groups/presentation/widgets/add_to_group_treasure_sheet.dart';
import 'package:personnages/l10n/app_localizations.dart';

Widget _buildTestWidget({
  required void Function(Map<CurrencyKind, int>, List<RewardItemDraft>) onApply,
  Locale locale = const Locale('fr'),
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showAddToGroupTreasureSheet(
            context,
            onApply: (deltas, items) => onApply(deltas, items),
          ),
          child: const Text('Ouvrir'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'titre, sections et bouton "Ajouter au butin" désactivé sans saisie',
    (tester) async {
      await tester.pumpWidget(_buildTestWidget(onApply: (_, _) {}));
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      expect(find.text('AJOUTER AU BUTIN DU GROUPE'), findsOneWidget);
      expect(find.text('MONNAIE'), findsOneWidget);
      expect(find.text('OBJETS'), findsOneWidget);
      expect(find.text('Ajouter des objets'), findsOneWidget);

      final applyButton = tester.widget<PrimaryButton>(
        find.byType(PrimaryButton),
      );
      expect(applyButton.label, 'Ajouter au butin');
      expect(applyButton.onPressed, isNull);
    },
  );

  testWidgets(
    'saisir une monnaie active le bouton et transmet les deltas à onApply',
    (tester) async {
      Map<CurrencyKind, int>? deltas;
      await tester.pumpWidget(_buildTestWidget(onApply: (d, _) => deltas = d));
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      // Ordre des champs : PO, PA, PC, PP, PE.
      await tester.enterText(find.byType(TextFormField).at(0), '12');
      await tester.pumpAndSettle();

      final applyButton = tester.widget<PrimaryButton>(
        find.byType(PrimaryButton),
      );
      expect(applyButton.onPressed, isNotNull);

      applyButton.onPressed!();
      expect(deltas?[CurrencyKind.gold], 12);
    },
  );

  testWidgets('"Annuler" ferme la sheet sans appeler onApply', (tester) async {
    var applyCalled = false;
    await tester.pumpWidget(
      _buildTestWidget(onApply: (_, _) => applyCalled = true),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    // `SecondaryButton` met son libellé en majuscules à l'affichage.
    await tester.tap(find.text('ANNULER'));
    await tester.pumpAndSettle();

    expect(find.text('AJOUTER AU BUTIN DU GROUPE'), findsNothing);
    expect(applyCalled, isFalse);
  });

  group('traduction anglaise', () {
    testWidgets('titre, sections et boutons en anglais', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(onApply: (_, _) {}, locale: const Locale('en')),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      expect(find.text("ADD TO THE GROUP'S LOOT"), findsOneWidget);
      expect(find.text('CURRENCY'), findsOneWidget);
      expect(find.text('ITEMS'), findsOneWidget);
      expect(find.text('Add items'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);

      final applyButton = tester.widget<PrimaryButton>(
        find.byType(PrimaryButton),
      );
      expect(applyButton.label, 'Add to the loot');
    });
  });
}
