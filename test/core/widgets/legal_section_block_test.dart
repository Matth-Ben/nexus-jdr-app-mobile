// Tests de widget de `LegalSectionBlock` — bloc "titre + paragraphes" du
// gabarit "texte légal long" (spec direction-artistique des écrans
// "Politique de confidentialité"/"Mentions légales / CGU"/"Crédits &
// licences") : titre `font.body` 15px/800 `textPrimary`, paragraphes
// `font.body` 13px/400 `textPrimary`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/widgets/legal_section_block.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  testWidgets('affiche le titre en 15px/w800/textPrimary', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const LegalSectionBlock(
          title: 'Introduction',
          paragraphs: ['Un paragraphe.'],
        ),
      ),
    );

    final titleStyle = tester.widget<Text>(find.text('Introduction')).style;
    expect(titleStyle?.fontSize, 15);
    expect(titleStyle?.fontWeight, FontWeight.w800);
    expect(titleStyle?.color, AppColors.textPrimary);
  });

  testWidgets('affiche chaque paragraphe fourni en 13px/textPrimary', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const LegalSectionBlock(
          title: 'Données collectées',
          paragraphs: ['Premier paragraphe.', 'Second paragraphe.'],
        ),
      ),
    );

    expect(find.text('Premier paragraphe.'), findsOneWidget);
    expect(find.text('Second paragraphe.'), findsOneWidget);
    final paragraphStyle = tester
        .widget<Text>(find.text('Premier paragraphe.'))
        .style;
    expect(paragraphStyle?.fontSize, 13);
    expect(paragraphStyle?.color, AppColors.textPrimary);
  });

  testWidgets('un seul paragraphe -> un seul SizedBox (titre -> paragraphe)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const LegalSectionBlock(
          title: 'Conservation',
          paragraphs: ['Un seul paragraphe.'],
        ),
      ),
    );

    expect(find.byType(SizedBox), findsOneWidget);
  });

  testWidgets(
    '4 paragraphes -> 4 SizedBox (titre->p1, p1->p2, p2->p3, p3->p4)',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          const LegalSectionBlock(
            title: 'Données collectées',
            paragraphs: ['Compte.', 'Photos.', 'Contenu de jeu.', 'Aucune.'],
          ),
        ),
      );

      expect(find.byType(SizedBox), findsNWidgets(4));
    },
  );
}
