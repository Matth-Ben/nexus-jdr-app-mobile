// Tests de widget de l'onglet "Histoire" de la fiche personnage — voir
// `docs/cahier-des-charges/09-maquettes-captures.md`, section "Onglet
// Histoire".
//
// `CharacterStoryTabBody` est un `StatelessWidget` pur (pas de Riverpod, pas
// de réseau) : même approche que `character_skills_tab_body_test.dart`/
// `character_inventory_tab_body_test.dart`, un simple
// `MaterialApp(home: ...)` suffit à le monter.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/presentation/widgets/character_story_tab_body.dart';

CharacterDetail _detail({
  String appearanceText = '',
  String traitsText = '',
  String idealsText = '',
  String bondsText = '',
  String flawsText = '',
  String backstoryText = '',
  String alliesText = '',
  String featuresText = '',
  String treasureText = '',
}) {
  return CharacterDetail(
    id: '1',
    name: 'Test',
    classes: const [],
    xp: 0,
    currentHp: 10,
    maxHp: 10,
    temporaryHp: 0,
    abilityScores: const {},
    appearanceText: appearanceText,
    traitsText: traitsText,
    idealsText: idealsText,
    bondsText: bondsText,
    flawsText: flawsText,
    backstoryText: backstoryText,
    alliesText: alliesText,
    featuresText: featuresText,
    treasureText: treasureText,
  );
}

// Surface de test agrandie : avec les 9 champs renseignés (le cas le plus
// chargé, 8 lignes de carte), les dernières cartes ("PARTICULARITÉS"/
// "TRÉSOR") sont autrement en dehors du `cacheExtent` par défaut d'un
// `ListView` sur la taille d'écran de test standard (800×600) — mêmes
// causes/remède que `character_detail_screen_test.dart::pumpDetail`.
Future<void> _pump(
  WidgetTester tester,
  CharacterDetail detail, {
  VoidCallback? onEdit,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CharacterStoryTabBody(
          detail: detail,
          onEdit: onEdit ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('affiche les 9 champs avec leur libellé et leur contenu quand '
      'tous renseignés', (tester) async {
    await _pump(
      tester,
      _detail(
        appearanceText: 'Cheveux argentés tressés.',
        traitsText: "Curieuse jusqu'à l'imprudence.",
        idealsText: 'Le savoir doit être partagé.',
        bondsText: 'Recherche le maître qui a scellé le grimoire.',
        flawsText: 'Incapable de résister à un mystère.',
        backstoryText: 'Élevée dans une enclave forestière.',
        alliesText: "L'Ordre des Archivistes.",
        featuresText: 'Une cicatrice fine sur la joue.',
        treasureText: 'Un grimoire scellé.',
      ),
    );

    for (final label in const [
      'APPARENCE PHYSIQUE',
      'TRAITS DE PERSONNALITÉ',
      'IDÉAUX',
      'LIENS',
      'DÉFAUTS',
      'HISTOIRE PERSONNELLE',
      'ALLIÉS',
      'PARTICULARITÉS',
      'TRÉSOR',
    ]) {
      expect(find.text(label), findsOneWidget);
    }

    expect(find.text('Cheveux argentés tressés.'), findsOneWidget);
    expect(find.text("Curieuse jusqu'à l'imprudence."), findsOneWidget);
    expect(find.text('Le savoir doit être partagé.'), findsOneWidget);
    expect(
      find.text('Recherche le maître qui a scellé le grimoire.'),
      findsOneWidget,
    );
    expect(find.text('Incapable de résister à un mystère.'), findsOneWidget);
    expect(find.text('Élevée dans une enclave forestière.'), findsOneWidget);
    expect(find.text("L'Ordre des Archivistes."), findsOneWidget);
    expect(find.text('Une cicatrice fine sur la joue.'), findsOneWidget);
    expect(find.text('Un grimoire scellé.'), findsOneWidget);
  });

  testWidgets('masque la carte (titre + texte) d\'un champ vide ou blanc', (
    tester,
  ) async {
    await _pump(
      tester,
      _detail(appearanceText: 'Cheveux argentés.', traitsText: '   '),
    );

    expect(find.text('APPARENCE PHYSIQUE'), findsOneWidget);
    expect(find.text('Cheveux argentés.'), findsOneWidget);
    expect(find.text('TRAITS DE PERSONNALITÉ'), findsNothing);
  });

  testWidgets(
    'IDÉAUX et DÉFAUTS sont affichés côte à côte (2 colonnes) quand tous '
    'les deux sont renseignés',
    (tester) async {
      await _pump(
        tester,
        _detail(
          idealsText: 'Le savoir avant tout.',
          flawsText: 'Trop curieuse.',
        ),
      );

      final idealsPosition = tester.getTopLeft(find.text('IDÉAUX'));
      final flawsPosition = tester.getTopLeft(find.text('DÉFAUTS'));
      // Même hauteur (même ligne) mais IDÉAUX strictement à gauche de
      // DÉFAUTS : preuve d'une disposition à 2 colonnes plutôt que 2 lignes
      // séparées.
      expect(idealsPosition.dy, flawsPosition.dy);
      expect(idealsPosition.dx, lessThan(flawsPosition.dx));
    },
  );

  testWidgets(
    'IDÉAUX seul (DÉFAUTS vide) est affiché pleine largeur, sans Row',
    (tester) async {
      await _pump(tester, _detail(idealsText: 'Le savoir avant tout.'));

      expect(find.text('IDÉAUX'), findsOneWidget);
      expect(find.text('DÉFAUTS'), findsNothing);
      expect(
        find.ancestor(of: find.text('IDÉAUX'), matching: find.byType(Row)),
        findsNothing,
      );
    },
  );

  testWidgets('affiche un état vide clair quand les 9 champs sont vides, sans '
      'aucune des 9 cartes', (tester) async {
    await _pump(tester, _detail());

    expect(find.text('AUCUNE HISTOIRE RENSEIGNÉE'), findsOneWidget);
    for (final label in const [
      'APPARENCE PHYSIQUE',
      'TRAITS DE PERSONNALITÉ',
      'IDÉAUX',
      'LIENS',
      'DÉFAUTS',
      'HISTOIRE PERSONNELLE',
      'ALLIÉS',
      'PARTICULARITÉS',
      'TRÉSOR',
    ]) {
      expect(find.text(label), findsNothing);
    }
  });

  testWidgets(
    'état vide : le bouton "Renseigner mon histoire" appelle onEdit',
    (tester) async {
      var editCallCount = 0;
      await _pump(tester, _detail(), onEdit: () => editCallCount++);

      expect(find.text('RENSEIGNER MON HISTOIRE'), findsOneWidget);
      await tester.tap(find.text('RENSEIGNER MON HISTOIRE'));
      await tester.pumpAndSettle();

      expect(editCallCount, 1);
    },
  );
}
