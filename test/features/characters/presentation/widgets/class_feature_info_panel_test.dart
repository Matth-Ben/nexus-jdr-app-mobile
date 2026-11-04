// Tests de widget du panneau "Infos" d'une aptitude de classe
// (`presentation/widgets/class_feature_info_panel.dart`) — même patron que
// `class_feature_action_sheet_test.dart`, qui couvre déjà l'ouverture de ce
// panneau depuis la sheet d'actions ; ce fichier couvre son ouverture
// directe ([showClassFeatureInfoPanel]), notamment [canUse].

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/domain/character_class_feature.dart';
import 'package:personnages/features/characters/presentation/widgets/class_feature_info_panel.dart';
import 'package:personnages/l10n/app_localizations.dart';

const _passiveFeature = CharacterClassFeature(
  id: 1,
  name: 'Ascendance draconique',
  level: 1,
  description: 'Choisissez un type de dégâts.',
);

const _limitedFeature = CharacterClassFeature(
  id: 2,
  name: 'Rage',
  level: 1,
  usesMax: 2,
  usesRemaining: 1,
  restType: 'repos_long',
  description: 'Entrez dans une rage destructrice.',
);

void main() {
  List<CharacterClassFeature> useCalls = [];

  Future<void> pumpPanel(
    WidgetTester tester, {
    required CharacterClassFeature feature,
    bool canUse = true,
    Locale locale = const Locale('fr'),
  }) async {
    useCalls = [];
    await tester.pumpWidget(
      MaterialApp(
        // `showClassFeatureInfoPanel` lit `AppLocalizations.of(context)!`
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
                onPressed: () => showClassFeatureInfoPanel(
                  context,
                  feature: feature,
                  onUseFeature: useCalls.add,
                  canUse: canUse,
                ),
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

  testWidgets(
    'aptitude passive : niveau, "Passive", description, pas de bouton',
    (tester) async {
      await pumpPanel(tester, feature: _passiveFeature);

      expect(find.text('ASCENDANCE DRACONIQUE'), findsOneWidget);
      expect(find.text('Obtenue au niveau 1.'), findsOneWidget);
      expect(find.text('Utilisations'), findsOneWidget);
      expect(find.text('Passive'), findsOneWidget);
      expect(find.text('DESCRIPTION'), findsOneWidget);
      expect(find.text('Choisissez un type de dégâts.'), findsOneWidget);
      expect(find.byType(PrimaryButton), findsNothing);
    },
  );

  testWidgets(
    'aptitude à usage limité : compteur formaté littéralement, bouton '
    '"Utiliser" délègue à onUseFeature',
    (tester) async {
      await pumpPanel(tester, feature: _limitedFeature);

      expect(find.text('1 / 2 · repos long'), findsOneWidget);

      await tester.tap(find.widgetWithText(PrimaryButton, 'UTILISER'));
      await tester.pumpAndSettle();

      expect(useCalls, [_limitedFeature]);
    },
  );

  testWidgets('description vide : repli "Description indisponible."', (
    tester,
  ) async {
    await pumpPanel(
      tester,
      feature: const CharacterClassFeature(
        id: 3,
        name: 'Sans description',
        level: 1,
      ),
    );

    expect(find.text('Description indisponible.'), findsOneWidget);
  });

  testWidgets('canUse à faux : bouton "Utiliser" désactivé', (tester) async {
    await pumpPanel(tester, feature: _limitedFeature, canUse: false);

    final button = tester.widget<PrimaryButton>(
      find.widgetWithText(PrimaryButton, 'UTILISER'),
    );
    expect(button.onPressed, isNull);
  });

  group('locale anglaise', () {
    // Même rationale que les autres lots du chantier "traduction de l'app"
    // Phase B : vérifie qu'un texte anglais s'affiche réellement.
    testWidgets('niveau, "Uses", "DESCRIPTION" et bouton en anglais', (
      tester,
    ) async {
      await pumpPanel(
        tester,
        feature: _limitedFeature,
        locale: const Locale('en'),
      );

      expect(find.text('Obtained at level 1.'), findsOneWidget);
      expect(find.text('Uses'), findsOneWidget);
      expect(find.text('DESCRIPTION'), findsOneWidget);
      expect(find.widgetWithText(PrimaryButton, 'USE'), findsOneWidget);
    });

    testWidgets('"Passive" et description indisponible en anglais', (
      tester,
    ) async {
      await pumpPanel(
        tester,
        feature: const CharacterClassFeature(
          id: 3,
          name: 'No description',
          level: 1,
        ),
        locale: const Locale('en'),
      );

      expect(find.text('Passive'), findsOneWidget);
      expect(find.text('Description unavailable.'), findsOneWidget);
    });
  });
}
