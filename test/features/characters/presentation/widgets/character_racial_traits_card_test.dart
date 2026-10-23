// Tests de widget de `CharacterRacialTraitsCard` — voir sa documentation de
// classe. Même approche que `character_class_features_card_test.dart` : un
// simple `MaterialApp(home: ...)` suffit (pas de Riverpod, pas de réseau).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_racial_trait.dart';
import 'package:personnages/features/characters/presentation/widgets/character_racial_traits_card.dart';

void main() {
  testWidgets('affiche une ligne par trait, dans l\'ordre reçu (PAS de tri '
      'alphabétique) — chacune porte le libellé "Passive"', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CharacterRacialTraitsCard(
            traits: [
              CharacterRacialTrait(
                name: 'Vision dans le noir',
                description: '12 mètres.',
              ),
              CharacterRacialTrait(
                name: 'Ancêtre draconique',
                description: 'Choisissez un type de dégâts.',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('TRAITS RACIAUX'), findsOneWidget);
    expect(find.text('Vision dans le noir'), findsOneWidget);
    expect(find.text('Ancêtre draconique'), findsOneWidget);
    expect(find.text('Passive'), findsNWidgets(2));

    final traitAY = tester.getTopLeft(find.text('Vision dans le noir')).dy;
    final traitBY = tester.getTopLeft(find.text('Ancêtre draconique')).dy;
    expect(traitAY, lessThan(traitBY));
  });

  testWidgets(
    'un trait actif à usages limités (ex. Poussée d\'adrénaline de l\'Orc) '
    'affiche quand même "Passive", sans compteur ni bouton "Utiliser" — '
    'décision tranchée, voir la doc de classe de CharacterRacialTraitsCard',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CharacterRacialTraitsCard(
              traits: [
                CharacterRacialTrait(
                  name: 'Poussée d\'adrénaline',
                  description:
                      'Une fois par repos long, en tant qu\'action '
                      'bonus...',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Passive'), findsOneWidget);
      expect(find.textContaining('/'), findsNothing);
    },
  );

  testWidgets('taper un trait ouvre le panneau "Infos" (SheetHeaderBar + '
      'description), SANS ligne "Prérequis" ni "Obtenue au niveau X"', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CharacterRacialTraitsCard(
            traits: [
              CharacterRacialTrait(
                name: 'Vision dans le noir',
                description: 'Vous voyez dans le noir jusqu\'à 12 mètres.',
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Vision dans le noir'));
    await tester.pumpAndSettle();

    expect(find.text('VISION DANS LE NOIR'), findsOneWidget);
    expect(find.text('DESCRIPTION'), findsOneWidget);
    expect(
      find.text('Vous voyez dans le noir jusqu\'à 12 mètres.'),
      findsOneWidget,
    );
    expect(find.textContaining('Prérequis'), findsNothing);
    expect(find.textContaining('Obtenue au niveau'), findsNothing);
    expect(find.text('UTILISER'), findsNothing);
  });

  testWidgets('n\'affiche aucune ligne quand traits est vide (appelant '
      'responsable de ne pas monter cette carte, voir '
      'character_skills_tab_body.dart)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CharacterRacialTraitsCard(traits: [])),
      ),
    );

    expect(find.text('TRAITS RACIAUX'), findsOneWidget);
    expect(find.byType(InkWell), findsNothing);
  });
}
