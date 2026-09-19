// Tests de widget de l'écran "Questions fréquentes"
// (`presentation/profile_faq_screen.dart`) — bandeau bois "QUESTIONS
// FRÉQUENTES" + retour, un seul `SettingsListCard` regroupant les 6
// questions/réponses en accordéon (chevron `expand_more`/`expand_less`,
// plusieurs tuiles peuvent être ouvertes simultanément), pré-ouverture
// d'une question via `initialQuestionId` (avec bordure `accent.brick`
// tant qu'elle reste ouverte, qui disparaît définitivement une fois
// refermée).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/theme/app_spacing.dart';
import 'package:personnages/core/widgets/settings_list_card.dart';
import 'package:personnages/features/profile/presentation/profile_faq_screen.dart';

const List<String> _questions = [
  'Comment importer un personnage depuis aidedd.org ?',
  "Comment rejoindre l'histoire de mon MJ ?",
  'Mes personnages sont-ils sauvegardés hors ligne ?',
  'Comment fonctionne la montée de niveau ?',
  'Comment changer le portrait de mon personnage ?',
  'Comment supprimer mon compte ?',
];

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  testWidgets('affiche le bandeau bois "QUESTIONS FRÉQUENTES"', (tester) async {
    await tester.pumpWidget(_wrap(const ProfileFaqScreen()));

    expect(find.text('QUESTIONS FRÉQUENTES'), findsOneWidget);
  });

  testWidgets(
    'affiche les 6 questions regroupées dans un seul SettingsListCard, '
    'toutes fermées par défaut',
    (tester) async {
      await tester.pumpWidget(_wrap(const ProfileFaqScreen()));

      for (final question in _questions) {
        expect(find.text(question), findsOneWidget);
      }
      expect(find.byType(SettingsListCard), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsNWidgets(6));
      expect(find.byIcon(Icons.expand_less), findsNothing);
    },
  );

  testWidgets('taper une question la déplie (chevron -> expand_less, '
      'réponse visible)', (tester) async {
    await tester.pumpWidget(_wrap(const ProfileFaqScreen()));

    expect(find.textContaining('Sur aidedd.org, ouvre la fiche'), findsNothing);

    await tester.tap(find.text(_questions[0]));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.expand_less), findsOneWidget);
    expect(find.byIcon(Icons.expand_more), findsNWidgets(5));
    expect(
      find.textContaining('Sur aidedd.org, ouvre la fiche'),
      findsOneWidget,
    );
  });

  testWidgets('taper à nouveau une question ouverte la referme', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const ProfileFaqScreen()));

    await tester.tap(find.text(_questions[0]));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.expand_less), findsOneWidget);

    await tester.tap(find.text(_questions[0]));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.expand_less), findsNothing);
    expect(find.textContaining('Sur aidedd.org, ouvre la fiche'), findsNothing);
  });

  testWidgets('plusieurs questions peuvent être ouvertes simultanément (état '
      'indépendant par tuile)', (tester) async {
    await tester.pumpWidget(_wrap(const ProfileFaqScreen()));

    await tester.tap(find.text(_questions[0]));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_questions[2]));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.expand_less), findsNWidgets(2));
    expect(find.byIcon(Icons.expand_more), findsNWidgets(4));
  });

  testWidgets(
    'initialQuestionId démarre la question visée dépliée avec une bordure '
    'accent.brick',
    (tester) async {
      await tester.pumpWidget(
        _wrap(const ProfileFaqScreen(initialQuestionId: 2)),
      );

      expect(find.byIcon(Icons.expand_less), findsOneWidget);
      expect(
        find.textContaining("Ton MJ te partage un code d'invitation"),
        findsOneWidget,
      );

      final borderedBox = find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).border?.top.color ==
                AppColors.accentBrick,
      );
      expect(borderedBox, findsOneWidget);
      final decoration =
          tester.widget<DecoratedBox>(borderedBox).decoration as BoxDecoration;
      expect(decoration.border?.top.width, AppBorders.card);
    },
  );

  testWidgets(
    'la bordure de la question pré-ouverte disparaît définitivement une '
    'fois refermée, même si rouverte ensuite',
    (tester) async {
      await tester.pumpWidget(
        _wrap(const ProfileFaqScreen(initialQuestionId: 2)),
      );

      final accentBorder = find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).border?.top.color ==
                AppColors.accentBrick,
      );
      expect(accentBorder, findsOneWidget);

      // Referme la question pré-ouverte.
      await tester.tap(find.text(_questions[1]));
      await tester.pumpAndSettle();
      expect(accentBorder, findsNothing);

      // La rouvre : reste sans bordure ("pas de traitement spécial
      // au-delà").
      await tester.tap(find.text(_questions[1]));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
      expect(accentBorder, findsNothing);
    },
  );

  testWidgets('initialQuestionId == null (pas de pré-ouverture) : toutes '
      'les questions démarrent fermées', (tester) async {
    await tester.pumpWidget(_wrap(const ProfileFaqScreen()));

    expect(find.byIcon(Icons.expand_less), findsNothing);
  });

  testWidgets(
    'initialQuestionId hors bornes (0, au-dela de 6, negatif) : navigation '
    "gracieuse, aucune question pre-ouverte, pas de crash -- cas d'un "
    "`?question=N` invalide en deep link (`app_router.dart`)",
    (tester) async {
      for (final outOfRangeId in [0, 7, 99, -1]) {
        await tester.pumpWidget(
          _wrap(ProfileFaqScreen(initialQuestionId: outOfRangeId)),
        );

        expect(find.byIcon(Icons.expand_less), findsNothing);
        expect(find.byIcon(Icons.expand_more), findsNWidgets(6));
        for (final question in _questions) {
          expect(find.text(question), findsOneWidget);
        }
      }
    },
  );

  testWidgets('le bandeau bois propose un bouton retour', (tester) async {
    await tester.pumpWidget(_wrap(const ProfileFaqScreen()));

    expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
  });
}
