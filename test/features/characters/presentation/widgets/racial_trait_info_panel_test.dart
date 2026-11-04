// Tests de widget du panneau "Infos" d'un trait racial
// (`presentation/widgets/racial_trait_info_panel.dart`) — voir sa
// documentation de classe. Même patron que `feat_info_panel_test.dart` :
// ouverture directe via [showRacialTraitInfoPanel].

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_racial_trait.dart';
import 'package:personnages/features/characters/presentation/widgets/racial_trait_info_panel.dart';
import 'package:personnages/l10n/app_localizations.dart';

Future<void> _pumpPanel(
  WidgetTester tester, {
  required CharacterRacialTrait trait,
  Locale locale = const Locale('fr'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      // `showRacialTraitInfoPanel` lit `AppLocalizations.of(context)!`
      // (chantier "traduction de l'app" Phase B, lot "Characters —
      // classe/race/maîtrises") : sans ces delegates, l'appel renverrait
      // `null` et le `!` planterait. `fr` par défaut, `en` passé
      // explicitement par le groupe "locale anglaise" plus bas.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showRacialTraitInfoPanel(context, trait: trait),
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
  testWidgets(
    'affiche le nom, "DESCRIPTION" et la description, sans "Prérequis" ni '
    '"Obtenue au niveau X"',
    (tester) async {
      await _pumpPanel(
        tester,
        trait: const CharacterRacialTrait(
          name: 'Vision dans le noir',
          description: 'Vous voyez dans le noir jusqu\'à 12 mètres.',
        ),
      );

      expect(find.text('VISION DANS LE NOIR'), findsOneWidget);
      expect(find.text('DESCRIPTION'), findsOneWidget);
      expect(
        find.text('Vous voyez dans le noir jusqu\'à 12 mètres.'),
        findsOneWidget,
      );
      expect(find.textContaining('Prérequis'), findsNothing);
      expect(find.textContaining('Obtenue au niveau'), findsNothing);
    },
  );

  testWidgets('description vide : repli "Description indisponible."', (
    tester,
  ) async {
    await _pumpPanel(
      tester,
      trait: const CharacterRacialTrait(
        name: 'Sans description',
        description: '',
      ),
    );

    expect(find.text('Description indisponible.'), findsOneWidget);
  });

  group('locale anglaise', () {
    // Même rationale que les autres lots du chantier "traduction de l'app"
    // Phase B : vérifie qu'un texte anglais s'affiche réellement.
    testWidgets('"DESCRIPTION" et repli en anglais', (tester) async {
      await _pumpPanel(
        tester,
        trait: const CharacterRacialTrait(
          name: 'Sans description',
          description: '',
        ),
        locale: const Locale('en'),
      );

      expect(find.text('DESCRIPTION'), findsOneWidget);
      expect(find.text('Description unavailable.'), findsOneWidget);
    });
  });
}
