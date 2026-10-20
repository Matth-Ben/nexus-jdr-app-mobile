// Tests de widget de `CharacterSelectionActionBar` (barre d'action en pied
// de `CharacterListScreen` pendant le mode sélection multiple).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/presentation/widgets/character_selection_action_bar.dart';

Future<void> _pump(
  WidgetTester tester, {
  required int selectedCount,
  VoidCallback? onCancel,
  VoidCallback? onDelete,
  bool isDeleting = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: CharacterSelectionActionBar(
            selectedCount: selectedCount,
            onCancel: onCancel ?? () {},
            onDelete: onDelete,
            isDeleting: isDeleting,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('libellé central (nombre de personnages sélectionnés)', () {
    testWidgets('0 sélection : "Aucun personnage sélectionné"', (tester) async {
      await _pump(tester, selectedCount: 0);

      expect(find.text('Aucun personnage sélectionné'), findsOneWidget);
    });

    testWidgets('1 sélection : singulier "1 personnage sélectionné"', (
      tester,
    ) async {
      await _pump(tester, selectedCount: 1);

      expect(find.text('1 personnage sélectionné'), findsOneWidget);
    });

    testWidgets('plusieurs sélections : pluriel "n personnages sélectionnés"', (
      tester,
    ) async {
      await _pump(tester, selectedCount: 3);

      expect(find.text('3 personnages sélectionnés'), findsOneWidget);
    });
  });

  testWidgets('"Annuler" appelle onCancel au tap', (tester) async {
    var cancelled = false;
    await _pump(tester, selectedCount: 2, onCancel: () => cancelled = true);

    await tester.tap(find.text('Annuler'));
    expect(cancelled, isTrue);
  });

  testWidgets(
    '"Annuler" désactivé pendant une suppression en cours (isDeleting)',
    (tester) async {
      var cancelled = false;
      await _pump(
        tester,
        selectedCount: 2,
        onCancel: () => cancelled = true,
        isDeleting: true,
      );

      await tester.tap(find.text('Annuler'), warnIfMissed: false);
      expect(cancelled, isFalse);
    },
  );

  testWidgets('"Supprimer" désactivé (onDelete null) : aucune sélection', (
    tester,
  ) async {
    await _pump(tester, selectedCount: 0);

    await tester.tap(find.text('SUPPRIMER'), warnIfMissed: false);
    // Pas d'assertion d'appel ici : onDelete est `null`, seul le fait que le
    // tap ne lève aucune exception compte.
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Supprimer" appelle onDelete au tap', (tester) async {
    var deleted = false;
    await _pump(tester, selectedCount: 2, onDelete: () => deleted = true);

    await tester.tap(find.text('SUPPRIMER'));
    expect(deleted, isTrue);
  });

  testWidgets(
    'isDeleting: true affiche un indicateur de progression au lieu du '
    'libellé "Supprimer"',
    (tester) async {
      await _pump(tester, selectedCount: 2, onDelete: () {}, isDeleting: true);

      expect(find.text('SUPPRIMER'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );
}
