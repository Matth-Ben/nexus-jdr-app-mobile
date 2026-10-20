// Tests de widget de `CharacterClassFeaturesCard` — rendu d'une liste de
// [CharacterClassFeature] déjà résolue par l'appelant (`character_repository
// .dart`/`class_feature_row_mapper.dart`), sans distinction classe/
// sous-classe au niveau du widget (voir sa doc de classe) : la carte se
// contente d'afficher [features] telle que fournie, dans l'ordre reçu —
// c'est entièrement la couche données qui décide désormais d'y inclure les
// aptitudes de sous-classe (bug architectural corrigé, voir
// `ClassFeatureRowMapper.filterAttained`). Ce test fixe donc le
// comportement : une aptitude de classe de base et une aptitude de
// sous-classe, toutes deux représentées par le même type [CharacterClassFeature]
// sans marqueur d'origine, s'affichent côte à côte sans traitement
// particulier.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_class_feature.dart';
import 'package:personnages/features/characters/presentation/widgets/character_class_features_card.dart';

void main() {
  testWidgets(
    'affiche une ligne par aptitude, aptitudes de classe de base et de '
    'sous-classe mélangées sans distinction',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CharacterClassFeaturesCard(
              features: const [
                CharacterClassFeature(
                  id: 10,
                  name: 'Deuxième souffle',
                  level: 1,
                ),
                CharacterClassFeature(
                  id: 20,
                  name: 'Supériorité martiale',
                  level: 3,
                  usesMax: 4,
                  usesRemaining: 4,
                  restType: 'repos_long',
                ),
              ],
              onUseFeature: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('APTITUDES DE CLASSE'), findsOneWidget);
      expect(find.text('Deuxième souffle'), findsOneWidget);
      expect(find.text('Passive'), findsOneWidget);
      expect(find.text('Supériorité martiale'), findsOneWidget);
      expect(find.text('4 / 4 · repos long'), findsOneWidget);
    },
  );

  testWidgets('n\'affiche rien (aucune ligne) quand features est vide', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CharacterClassFeaturesCard(features: [], onUseFeature: _noop),
        ),
      ),
    );

    expect(find.text('APTITUDES DE CLASSE'), findsOneWidget);
    expect(find.byType(InkWell), findsNothing);
  });
}

void _noop(CharacterClassFeature feature) {}
