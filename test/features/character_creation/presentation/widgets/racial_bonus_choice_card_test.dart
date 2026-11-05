// Tests de widget de la carte de répartition des bonus raciaux au choix
// (`presentation/widgets/racial_bonus_choice_card.dart`) — composant
// contrôlé, pas de provider/dépôt réseau à doubler : même patron minimal que
// `step_help_sheet_test.dart`.
//
// Jamais testé isolément jusqu'ici (seulement en contexte, via
// `ability_score_step_screen_test.dart`/`xml_import_review_screen_test.dart`) ;
// ce fichier ajoute la couverture du texte fixe introduit par ce lot,
// français et anglais.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/presentation/widgets/racial_bonus_choice_card.dart';
import 'package:personnages/features/character_creation/domain/racial_bonus_choice.dart';
import 'package:personnages/l10n/app_localizations.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('fr')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets(
    'spec "choice_others" (Demi-elfe) : titre, règle "— à répartir" tant que '
    "la répartition n'est pas complète, puis règle seule une fois complète",
    (tester) async {
      const spec = OthersRacialBonusSpec(
        count: 2,
        amount: 1,
        excluded: {'cha'},
      );
      Map<String, int> choices = const {};

      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) => RacialBonusChoiceCard(
              spec: spec,
              choices: choices,
              onChanged: (next) => setState(() => choices = next),
            ),
          ),
        ),
      );

      expect(find.text('Bonus racial au choix'), findsOneWidget);
      expect(
        find.text('+1 à 2 caractéristiques au choix — à répartir'),
        findsOneWidget,
      );

      await tester.tap(find.text('For +1'));
      await tester.pump();
      await tester.tap(find.text('Dex +1'));
      await tester.pump();

      expect(
        find.text('+1 à 2 caractéristiques au choix'),
        findsOneWidget,
        reason: 'répartition complète : plus de suffixe "— à répartir"',
      );
    },
  );

  testWidgets('spec "choice_flexible" : motifs "+2 / +1" et "+1 / +1 / +1" du '
      '`SegmentedToggle`', (tester) async {
    await tester.pumpWidget(
      _wrap(
        RacialBonusChoiceCard(
          spec: const FlexibleRacialBonusSpec(),
          choices: const {},
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.text('+2 / +1'), findsOneWidget);
    expect(find.text('+1 / +1 / +1'), findsOneWidget);
  });

  group('traduction anglaise', () {
    testWidgets('titre et règle "— to assign" en anglais', (tester) async {
      const spec = OthersRacialBonusSpec(
        count: 2,
        amount: 1,
        excluded: {'cha'},
      );

      await tester.pumpWidget(
        _wrap(
          RacialBonusChoiceCard(
            spec: spec,
            choices: const {},
            onChanged: (_) {},
          ),
          locale: const Locale('en'),
        ),
      );

      expect(find.text('Racial bonus to assign'), findsOneWidget);
      expect(find.textContaining('— to assign'), findsOneWidget);
    });
  });
}
