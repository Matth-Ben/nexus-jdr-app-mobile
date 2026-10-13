// Tests de widget de la carte "PRÉPARATION DES SORTS"
// (`presentation/widgets/spell_preparation_card.dart`), en tête de l'onglet
// "Sorts" — couvre le rendu mono-classe historique, le rendu par classe
// introduit par le chantier de blocage RAW du 13/10/2026
// (`PreparedSpellsLimit.limitsByClass`), et la note d'aide ouverte par
// l'icône ⓘ. Aucun test de ce fichier n'existait avant ce renfort QA.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/prepared_spells_limit.dart';
import 'package:personnages/features/characters/domain/spell_preparation_filter.dart';
import 'package:personnages/features/characters/presentation/widgets/spell_preparation_card.dart';

ClassPreparedSpells _classLimit(
  String className, {
  required int limit,
  required int preparedCount,
  Object classId = 1,
}) => ClassPreparedSpells(
  classId: classId,
  className: className,
  limit: limit,
  preparedCount: preparedCount,
);

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    List<ClassPreparedSpells> classLimits = const [],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpellPreparationCard(
            filter: SpellPreparationFilter.all,
            onFilterChanged: (_) {},
            classLimits: classLimits,
          ),
        ),
      ),
    );
  }

  group('SpellPreparationCard', () {
    testWidgets('aucune classe qui prépare : aucun compteur affiché', (
      tester,
    ) async {
      await pumpCard(tester);

      expect(find.byType(PreparedSpellsCounter), findsNothing);
    });

    testWidgets(
      'une seule classe : un seul compteur, libellé générique inchangé',
      (tester) async {
        await pumpCard(
          tester,
          classLimits: [_classLimit('Clerc', limit: 5, preparedCount: 3)],
        );

        expect(find.byType(PreparedSpellsCounter), findsOneWidget);
        expect(find.text('SORTS PRÉPARÉS'), findsOneWidget);
        expect(find.text('3 / 5'), findsOneWidget);
      },
    );

    testWidgets(
      'deux classes qui préparent : un compteur par classe, libellé avec '
      'le nom de la classe',
      (tester) async {
        await pumpCard(
          tester,
          classLimits: [
            _classLimit('Clerc', limit: 5, preparedCount: 5, classId: 10),
            _classLimit('Paladin', limit: 3, preparedCount: 1, classId: 20),
          ],
        );

        expect(find.byType(PreparedSpellsCounter), findsNWidgets(2));
        expect(find.text('SORTS PRÉPARÉS — CLERC'), findsOneWidget);
        expect(find.text('SORTS PRÉPARÉS — PALADIN'), findsOneWidget);
        expect(find.text('5 / 5'), findsOneWidget);
        expect(find.text('1 / 3'), findsOneWidget);
        // Clerc est à sa limite : la phrase d'état bascule sur "Limite
        // atteinte", jamais un décompte négatif.
        expect(find.text('Limite atteinte'), findsOneWidget);
      },
    );

    testWidgets(
      'trois classes qui préparent (Clerc/Druide/Paladin) : un compteur '
      'par classe, générique au-delà de deux classes',
      (tester) async {
        await pumpCard(
          tester,
          classLimits: [
            _classLimit('Clerc', limit: 5, preparedCount: 2, classId: 10),
            _classLimit('Druide', limit: 4, preparedCount: 1, classId: 20),
            _classLimit('Paladin', limit: 2, preparedCount: 3, classId: 30),
          ],
        );

        expect(find.byType(PreparedSpellsCounter), findsNWidgets(3));
        expect(find.text('SORTS PRÉPARÉS — CLERC'), findsOneWidget);
        expect(find.text('SORTS PRÉPARÉS — DRUIDE'), findsOneWidget);
        expect(find.text('SORTS PRÉPARÉS — PALADIN'), findsOneWidget);
        // Paladin dépasse sa limite (3 préparés / 2) : signal de
        // dépassement, jamais de blocage ici (indicatif, voir la doc de
        // `SpellPreparationCard.classLimits`).
        expect(find.text('Limite dépassée de 1'), findsOneWidget);
      },
    );

    testWidgets(
      'icône ⓘ : ouvre la note d\'aide avec la bascule tous/préparés/non '
      'préparés toujours présente',
      (tester) async {
        await pumpCard(
          tester,
          classLimits: [_classLimit('Clerc', limit: 5, preparedCount: 3)],
        );

        await tester.tap(find.byIcon(Icons.info_outline_rounded));
        await tester.pumpAndSettle();

        expect(find.text('PRÉPARATION DES SORTS'), findsWidgets);
        expect(
          find.textContaining('Votre limite actuelle : 5.'),
          findsOneWidget,
        );
        // Bug trouvé par qa-testeur (13/10/2026) : l'Artificier était cité
        // dans les deux phrases, à la fois comme lanceur complet ET comme
        // demi-lanceur — faux et contredit `PreparedSpellsLimit.limitFor`
        // (`CasterType.half`, D41). Seule la phrase des demi-lanceurs doit
        // le citer.
        expect(
          find.textContaining('Clerc, Druide et Magicien : modificateur'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Paladin et Artificier (demi-lanceurs)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'icône ⓘ, multiclassé : la note cite la limite de chaque classe',
      (tester) async {
        await pumpCard(
          tester,
          classLimits: [
            _classLimit('Clerc', limit: 5, preparedCount: 5, classId: 10),
            _classLimit('Paladin', limit: 3, preparedCount: 1, classId: 20),
          ],
        );

        await tester.tap(find.byIcon(Icons.info_outline_rounded));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Vos limites actuelles : Clerc 5, Paladin 3.'),
          findsOneWidget,
        );
      },
    );
  });
}
