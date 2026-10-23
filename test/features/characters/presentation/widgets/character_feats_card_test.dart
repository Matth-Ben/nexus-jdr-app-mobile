// Tests de widget de `CharacterFeatsCard` — voir sa documentation de
// classe. Même approche que `character_class_features_card_test.dart` : un
// simple `MaterialApp(home: ...)` suffit (pas de Riverpod, pas de réseau).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_feat_summary.dart';
import 'package:personnages/features/characters/presentation/widgets/character_feats_card.dart';

void main() {
  testWidgets('affiche une ligne par don, dans l\'ordre reçu — pas de '
      'libellé "Passive" (un don n\'a pas ce statut)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CharacterFeatsCard(
            feats: [
              CharacterFeatSummary(name: 'Robuste', description: '+2 PV.'),
              CharacterFeatSummary(
                name: 'Vigilant',
                description: 'Toujours sur vos gardes.',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('DONS'), findsOneWidget);
    expect(find.text('Robuste'), findsOneWidget);
    expect(find.text('Vigilant'), findsOneWidget);
    expect(find.text('Passive'), findsNothing);

    final featAY = tester.getTopLeft(find.text('Robuste')).dy;
    final featBY = tester.getTopLeft(find.text('Vigilant')).dy;
    expect(featAY, lessThan(featBY));
  });

  testWidgets(
    'taper un don ouvre le panneau "Infos" (même panneau que la montée de '
    'niveau), avec ligne "Prérequis" quand renseigné, sans bouton d\'action',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CharacterFeatsCard(
              feats: [
                CharacterFeatSummary(
                  name: 'Robuste',
                  description: 'Vos points de vie maximum augmentent.',
                  prerequisiteText: 'Aucun.',
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Robuste'));
      await tester.pumpAndSettle();

      expect(find.text('ROBUSTE'), findsOneWidget);
      expect(find.text('Prérequis : Aucun.'), findsOneWidget);
      expect(find.text('DESCRIPTION'), findsOneWidget);
      expect(
        find.text('Vos points de vie maximum augmentent.'),
        findsOneWidget,
      );
      expect(find.text('UTILISER'), findsNothing);
    },
  );

  testWidgets('taper un don sans prérequis renseigné n\'affiche pas la ligne '
      '"Prérequis"', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CharacterFeatsCard(
            feats: [
              CharacterFeatSummary(
                name: 'Chanceux',
                description: 'Vous avez des points de chance.',
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Chanceux'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Prérequis'), findsNothing);
  });

  testWidgets('n\'affiche aucune ligne quand feats est vide (appelant '
      'responsable de ne pas monter cette carte, voir '
      'character_skills_tab_body.dart)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CharacterFeatsCard(feats: [])),
      ),
    );

    expect(find.text('DONS'), findsOneWidget);
    expect(find.byType(InkWell), findsNothing);
  });
}
